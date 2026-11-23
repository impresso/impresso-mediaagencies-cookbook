# Configuration for S3 path suffix:
# mediaagencies/mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0
#
# Model v2.1.0 with impresso-inference feat/mediasources-tokenization-windows,
# which matches the evaluated model exactly (backend parity 490/490 test
# documents, 62/62 long concatenated documents, CPU and GPU fp32). bf16 on GPU:
# 487/490 and 58/62; on GDL 1950 it changes about 0.3% of entities (balanced)
# and is 2.8x faster, so the collection run uses bf16.

MODEL_ID_MEDIAAGENCIES ?= mmbert-impresso-mediaagencies-ner_v2-1-0
HF_MODEL_MEDIAAGENCIES ?= impresso-project/mmbert-impresso-mediaagencies-ner
HF_MODEL_REVISION_MEDIAAGENCIES ?= v2.1.0

RUN_VERSION_MEDIAAGENCIES ?= v1-0-0
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
