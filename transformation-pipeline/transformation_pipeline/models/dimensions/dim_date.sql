{{ 
config(
    materialized='incremental',
    unique_key='date_sk',
    incremental_strategy='append',
    on_schema_change='append_new_columns',
    schema='processed'
) 
}}

with raw_dates as (
  select
    try_cast(incident_date as date) as date_value
  from {{ source('raw','fire_incidents') }}
  where incident_date is not null
),

{% if is_incremental() %}
max_existing as (
  select max(date_value) as max_date
  from {{ this }}
),
new_dates as (
  select distinct date_value
  from raw_dates, max_existing
  where date_value > max_existing.max_date
)
{% else %}
distinct_dates as (
  select distinct date_value
  from raw_dates
)
{% endif %}

select
  date_value,
  extract(year    from date_value) as year,
  extract(quarter from date_value) as quarter,
  extract(month   from date_value) as month,
  extract(day     from date_value) as day,
  extract(dow     from date_value) as day_of_week,
  extract(week    from date_value) as week_of_year,
  -- deterministic surrogate key: YYYYMMDD
  (
    extract(year  from date_value) * 10000
  + extract(month from date_value)  *   100
  + extract(day   from date_value)
  )::integer AS date_sk

from
  {% if is_incremental() %} new_dates {% else %} distinct_dates {% endif %}
order by date_value