# Sandbox output; reuse the model and processing settings of the base config.
# Output prefix: s3://140-processed-data-sandbox/mediasources/
S3_BUCKET_MEDIASOURCES := 140-processed-data-sandbox

include configs/config_mediasources-ner-mmbert-impresso-mediasources-ner_v2-0-0_v1-0-0.mk
