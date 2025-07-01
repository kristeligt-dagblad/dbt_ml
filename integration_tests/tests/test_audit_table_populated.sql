-- Test that models are being audited properly

with model_audits as (
    select
        model, schema, created_at
    from `{{ target.project }}.audit.ml_models`
    where model in ('arima_plus_forecast', 'logistic_regression')
),

audit_count as (
    select count(*) as actual_count
    from model_audits
)

select
    'Missing audits' as error,
     actual_count,
    ">2" as expected_count,
from audit_count 
where actual_count < 2  -- Should have (at least) 2 audits for each model
