{{
    config(
        materialized='model',
        meta = {
            'ml_config' : {
                'model_type': 'logistic_reg',
                'input_label_cols': ['label'],
                'auto_class_weights': true
            }
        }
    )
}}

select
    feature1,
    feature2,
    feature3,
    label
from {{ ref('classification_data') }} 