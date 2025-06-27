{{
    config(
        materialized='table'
    )
}}

-- Test prediction functionality using the logistic regression model
with test_data as (
    select 
        11.0 as feature1,
        22.0 as feature2, 
        6.0 as feature3
    union all
    select 
        7.0 as feature1,
        14.0 as feature2,
        3.0 as feature3
)

select * from {{ dbt_ml.predict(ref('logistic_regression'), 'test_data') }} 