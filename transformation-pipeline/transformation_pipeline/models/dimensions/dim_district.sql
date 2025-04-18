{{ config(
    materialized='incremental',
    unique_key=['district_type','district_name'],
    incremental_strategy='append',
    on_schema_change='append_new_columns',
    schema='processed'
) }}

with raw_districts as (

  -- supervisor districts
  select
    supervisor_district as district_name,
    'supervisor'             as district_type
  from {{ source('raw','fire_incidents') }}
  where supervisor_district is not null

  union distinct

  -- neighborhood districts
  select
    neighborhood_district as district_name,
    'neighborhood'              as district_type
  from {{ source('raw','fire_incidents') }}
  where neighborhood_district is not null
),

{% if is_incremental() %}
existing as (
  select district_type, district_name
  from {{ this }}
),

new as (
  select rd.*
  from raw_districts rd
  left join existing e
    using (district_type, district_name)
  where e.district_name is null
)
{% else %}
new as (
  select *
  from raw_districts
)
{% endif %}

select
  district_type,
  district_name,

  -- MD5 of “type|name” for a stable surrogate key
  md5(district_type || '|' || district_name) as district_sk

from new
order by district_type, district_name