{{
    config(
        materialized='model',
        meta = {
            'ml_config': {
                'connection_name': 'eu.vertexai-connection',
                'endpoint': 'gemini-2.0-flash'
            }
        }
    )
}}
