{{ config(
    materialized='view',
    schema='consumption',
    alias='battalion_incident_counts'
) }}

select
  b.battalion_sk,
  b.battalion                   as battalion_name,
  count(*)                      as incident_count
from {{ ref('fact_fire_incidents') }} f
join {{ ref('dim_battalion') }}   b
  on f.battalion_sk = b.battalion_sk
group by
  b.battalion_sk,
  b.battalion
order by
  incident_count desc