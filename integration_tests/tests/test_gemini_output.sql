-- Test that Gemini model generates text successfully

with generation_results as (
    select
        id,
        ml_generate_text_status,
        ml_generate_text_result
    from {{ ref('test_gemini_generation') }}
),

failed_generations as (
    select count(*) as failure_count
    from generation_results
    where ml_generate_text_status != 'OK' 
       or ml_generate_text_result is null
       or length(ml_generate_text_result) = 0
)

select
    'Text generation failed' as error,
    failure_count
from failed_generations
where failure_count > 0

