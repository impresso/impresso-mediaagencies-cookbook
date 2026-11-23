# Sandbox output; reuse the model and processing settings of the base config.
# Output prefix: s3://140-processed-data-sandbox/mediaagencies/
S3_BUCKET_MEDIAAGENCIES := 140-processed-data-sandbox

include configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-0-0_v1-0-0.mk
