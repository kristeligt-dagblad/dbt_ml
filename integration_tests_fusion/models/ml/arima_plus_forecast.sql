{{
    config(
        materialized='model',
        meta = {
            'ml_config' : {
                'model_type': 'arima_plus',
                'time_series_timestamp_col': 'date',
                'time_series_data_col': 'sales',
                'auto_arima': true,
                'data_frequency': 'AUTO_FREQUENCY'
            }
        }
    )
}}

select
    date,
    sales
from {{ ref('timeseries_data') }}
order by date 
