{{
    config(
        materialized='table'
    )
}}

-- Test text generation using the Gemini remote model
select 
    id,
    prompt,
    ml_generate_text_result,
    ml_generate_text_status
from ml.generate_text(
    model {{ ref('gemini_flash_connection') }},
    (select id, prompt from {{ ref('text_generation_data') }}),
    struct(
        0.3 as temperature,
        100 as max_output_tokens
    )
)

