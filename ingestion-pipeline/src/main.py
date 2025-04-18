import duckdb
import pyspark
import re
from pyspark.sql import SparkSession

def normalize_col(name: str) -> str:
    return re.sub(r'[^0-9a-zA-Z]+', '_', name.strip().lower()).strip('_')

def write_to_duckdb(df, duckdb_path, dataset_name, table_name):

    parquet_path = '/app/data/fire_incidents_parquet'

    (
        df.repartition(4).write
            .mode("overwrite")
            .parquet(parquet_path)

    )

    duck_con = duckdb.connect(duckdb_path, read_only=False)
    duck_con.execute(f"CREATE SCHEMA IF NOT EXISTS {dataset_name}")

    #create table if not exists or replace
    duck_con.execute(f"""
        CREATE OR REPLACE TABLE {dataset_name}.{table_name} AS
        SELECT * FROM read_parquet('{parquet_path}/*.parquet')
    """)

    duck_con.close()

    #Works but is too slow because there is no connector from spark to duckdb
    '''
    (
        df.write
            .format("jdbc")
            .option("url", f"jdbc:duckdb:{duckdb_path}")
            .option("driver", "org.duckdb.DuckDBDriver")
            .option("dbtable", f"{dataset_name}.{table_name}")
            .mode("overwrite")
            .save()
    )
    '''

def main():
    # 1. Initialize SparkSession if not already initialized

    spark = SparkSession.getActiveSession()
    created_here = False

    if not spark:
        spark = (
            SparkSession.builder
            .appName("ingestion-pipeline")
            .master("local[*]")
            #.config("spark.jars.packages", "org.duckdb:duckdb_jdbc:1.2.2.0")
            .getOrCreate()
        )
        created_here = True

    csv_path = '/app/data/input.csv'

    df = (
        spark.read
            .option("header", True)
            .option("inferSchema", False)
            .option("mode", "DROPMALFORMED")
            .csv(csv_path)
    )

    # Normalize column names
    new_column_names = [normalize_col(c) for c in df.columns]
    df = df.toDF(*new_column_names)

    # Write to DuckDB
    duckdb_path = '/root/.duckdb/db.duckdb'
    dataset_name = 'raw'
    table_name = 'fire_incidents'
    write_to_duckdb(df, duckdb_path, dataset_name, table_name)

    
    if created_here:
        spark.stop()

if __name__ == "__main__":
    main()