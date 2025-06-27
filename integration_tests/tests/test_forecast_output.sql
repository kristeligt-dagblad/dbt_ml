-- Test that forecast produces expected output structure
with forecast_output as (
    select * from {{ ref('test_arima_forecast') }}
),

forecast_count as (
    select count(*) as actual_count
    from forecast_output
)

select
    'insufficient_forecasts' as error,
    actual_count,
    7 as expected_count
from forecast_count
where actual_count != 7  -- Should forecast exactly 7 days ahead

