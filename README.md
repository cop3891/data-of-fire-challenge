1. Add the csv file inside the data/ folder in the ingestion-pipeline and name it as input.csv
2. Execute ´docker compose -f docker-compose.common.yml -f docker-compose.yml build´
3. Execute ´docker compose -f docker-compose.common.yml -f docker-compose.yml up´
4. Execute ´docker compose -f docker-compose.common.yml -f docker-compose.yml exec ingestion-pipeline make run´
This will digest the csv using pyspark and load it into duckdb table. All the columns will be loaded as strings.
5. Execute ´docker compose -f docker-compose.common.yml -f docker-compose.yml exec transformation-pipeline make dev´
This will start the dbt pipeline to transform the raw data into a star model. Creating a fact table and multiple dimensions tables. Finally it will create a consumption view that will feed the reports.
6. Execute ´docker compose -f docker-compose.common.yml -f docker-compose.yml exec report make run´
This will start a web app served in localhost:8501. This simple application is being fed with the data in the consumption layer from duckdb.

For development environments you can use the devcontainers to start each module (ingestion-pipeline, transformation-pipeline, report) individually.