{{ config(
    materialized='incremental',
    unique_key='time_sk',
    incremental_strategy='append',
    on_schema_change='append_new_columns',
    schema='processed'
) }}

with raw_times as (
  select strptime(alarm_dttm, '%Y/%m/%d %I:%M:%S %p')::time as time_value
  from {{ source('raw','fire_incidents') }}
  where alarm_dttm is not null

  union distinct

  select strptime(arrival_dttm, '%Y/%m/%d %I:%M:%S %p')::time as time_value
  from {{ source('raw','fire_incidents') }}
  where arrival_dttm is not null

  union distinct

  select strptime(close_dttm, '%Y/%m/%d %I:%M:%S %p')::time as time_value
  from {{ source('raw','fire_incidents') }}
  where close_dttm is not null
),

{% if is_incremental() %}
max_existing as (
  select max(time_value) as max_time
  from {{ this }}
),

new_times as (
  select rt.*
  from raw_times rt
  where rt.time_value > (select max_time from max_existing)
)
{% else %}
new_times as (
  select * from raw_times
)
{% endif %}

select
  time_value,
  extract(hour   from time_value)   as hour,
  extract(minute from time_value)   as minute,
  extract(second from time_value)   as second,
  case when extract(hour from time_value) < 12 then 'AM' else 'PM' end as period,

  -- deterministic surrogate key: HHMMSS as integer
  (
    extract(hour   from time_value) * 10000
  + extract(minute from time_value) *   100
  + extract(second from time_value)
  )::integer as time_sk

from new_times
order by time_value