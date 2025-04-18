{{ config(
    materialized='incremental',
    unique_key='incident_nk',
    incremental_strategy='append',
    on_schema_change='append_new_columns',
    schema='processed'
) }}

with raw_incidents as (
  select *
  from {{ source('raw','fire_incidents') }}
),

{% if is_incremental() %}
existing as (
  select incident_nk
  from {{ this }}
),

new_incidents as (
  select ri.*
  from raw_incidents ri
  left join existing e
    on ri.id = e.incident_nk
  where e.incident_nk is null
)
{% else %}
new_incidents as (
  select *
  from raw_incidents
)
{% endif %}

select
  -- surrogate key: MD5 of natural key (you could use row_number() too)
  md5(ri.id)                                      as incident_sk,
  ri.id                                           as incident_nk,

  -- foreign keys into your dimensions
  d.date_sk,
  tp_alarm.time_sk        as alarm_time_sk,
  tp_arrival.time_sk      as arrival_time_sk,
  tp_close.time_sk        as close_time_sk,
  b.battalion_sk,
  sd.district_sk          as supervisor_district_sk,
  nd.district_sk          as neighborhood_district_sk,

  -- measures
  try_cast(ri.suppression_units    as integer)    as suppression_units,
  try_cast(ri.suppression_personnel as integer)    as suppression_personnel,
  try_cast(ri.ems_units             as integer)    as ems_units,
  try_cast(ri.ems_personnel         as integer)    as ems_personnel,
  try_cast(ri.other_units           as integer)    as other_units,
  try_cast(ri.other_personnel       as integer)    as other_personnel,
  try_cast(ri.number_of_alarms      as integer)    as number_of_alarms,
  try_cast(ri.estimated_property_loss  as double)  as estimated_property_loss,
  try_cast(ri.estimated_contents_loss  as double)  as estimated_contents_loss,
  try_cast(ri.fire_fatalities         as integer)  as fire_fatalities,
  try_cast(ri.fire_injuries           as integer)  as fire_injuries,
  try_cast(ri.civilian_fatalities     as integer)  as civilian_fatalities,
  try_cast(ri.civilian_injuries       as integer)  as civilian_injuries,

  -- you can add more measures here…

from new_incidents ri

-- join to date dim
left join {{ ref('dim_date') }} d
  on try_cast(ri.incident_date as date) = d.date_value

-- join each time to the time_period dim
left join {{ ref('dim_time_period') }} tp_alarm
  on strptime(ri.alarm_dttm, '%Y/%m/%d %I:%M:%S %p')::time = tp_alarm.time_value

left join {{ ref('dim_time_period') }} tp_arrival
  on strptime(ri.arrival_dttm, '%Y/%m/%d %I:%M:%S %p')::time = tp_arrival.time_value

left join {{ ref('dim_time_period') }} tp_close
  on strptime(ri.close_dttm, '%Y/%m/%d %I:%M:%S %p')::time = tp_close.time_value

-- join batallion
left join {{ ref('dim_battalion') }} b
  on ri.battalion = b.battalion

-- join districts
left join {{ ref('dim_district') }} sd
  on ri.supervisor_district  = sd.district_name
  and sd.district_type = 'supervisor'

left join {{ ref('dim_district') }} nd
  on ri.neighborhood_district = nd.district_name
  and nd.district_type = 'neighborhood'