import duckdb
import pandas as pd
import streamlit as st
import altair as alt

# Connect to your DuckDB database file

db_path = '/root/.duckdb/db.duckdb'
conn = duckdb.connect(db_path)

# Query the battalion incident counts
query = """
SELECT
  battalion_name,
  incident_count
FROM consumption.battalion_incident_counts
ORDER BY incident_count DESC;
"""
df = conn.execute(query).df()

# Streamlit page config
st.set_page_config(
    page_title="Fire Incidents per Battalion",
    layout="wide"
)

# Title and description
st.title("🔥 Fire Incidents per Battalion")
st.markdown("This chart shows the number of fire incidents recorded for each battalion.")

# Build a bar chart with Altair
chart = alt.Chart(df).mark_bar().encode(
    x=alt.X('battalion_name:N', title='Battalion'),
    y=alt.Y('incident_count:Q', title='Incident Count'),
    tooltip=['battalion_name', 'incident_count']
).properties(
    width=800,
    height=400,
    title="Incident Counts by Battalion"
)

# Display the chart
st.altair_chart(chart, use_container_width=True)