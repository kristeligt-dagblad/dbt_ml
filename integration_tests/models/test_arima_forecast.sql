{{
    config(
        materialized='table'
    )
}}

-- Test forecast functionality with 7 days ahead, 80% confidence
select * from {{ dbt_ml.forecast(ref('arima_plus_forecast'), 7, 0.8) }} 