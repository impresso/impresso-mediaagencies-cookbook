# Configuration for S3 path suffix:
# mediaagencies/mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-1-0
#
# Re-decode of the v1-0-0 run (model v2.1.0) without new inference: reads the
# v1-0-0 stage-2 logits and writes entities-nel.v2 records to the v1-1-0 folder.
# The decoder fills the content-item IDs that the v1-0-0 stage 1 lost (rebuilt
# files with 'ci_id': all BNF and FedGaz) by position from the rebuilt input,
# and checks all other IDs against it. Only the decode stage runs:
#   make processing-target CFG=<this file>
#
# Inference settings below are those of the v1-0-0 run (see its config).

MODEL_ID_MEDIAAGENCIES ?= mmbert-impresso-mediaagencies-ner_v2-1-0
HF_MODEL_MEDIAAGENCIES ?= impresso-project/mmbert-impresso-mediaagencies-ner
HF_MODEL_REVISION_MEDIAAGENCIES ?= v2.1.0

RUN_VERSION_MEDIAAGENCIES ?= v1-1-0
STAGE_RUN_VERSION_MEDIAAGENCIES ?= v1-0-0
MEDIAAGENCIES_STAGE ?= decode
S3_BUCKET_MEDIAAGENCIES ?= 141-processed-data-staging

BATCH_SIZE_MEDIAAGENCIES ?= 256
OUTER_BATCH_SIZE_MEDIAAGENCIES ?= 512
OUTER_BATCH_MAX_CHARS_MEDIAAGENCIES ?=
DTYPE_MEDIAAGENCIES ?= bf16
DEVICE_MEDIAAGENCIES ?= cuda
MIN_YEAR_MEDIAAGENCIES ?= 1835
SAMPLE_MEDIAAGENCIES ?= 1.0
SAMPLE_SEED_MEDIAAGENCIES ?=
FILTER_ANACHRONISTIC_MEDIAAGENCIES ?= --filter-anachronistic
DIAGNOSTICS_MEDIAAGENCIES ?=
