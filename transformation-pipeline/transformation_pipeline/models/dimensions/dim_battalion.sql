{{ config(
    materialized='incremental',
    unique_key='battalion',
    incremental_strategy='append',
    on_schema_change='append_new_columns',
    schema='processed'
) }}

with raw_battalion as (
  select distinct battalion
  from {{ source('raw','fire_incidents') }}
  where battalion is not null
),

{% if is_incremental() %}
existing as (
  select battalion
  from {{ this }}
),

new as (
  select rb.battalion
  from raw_battalion rb
  left join existing e using (battalion)
  where e.battalion is null
)
{% else %}
new AS (
  SELECT * FROM raw_battalion
)
{% endif %}

select
  battalion,
  md5(battalion) as battalion_sk

from new
order by battalion