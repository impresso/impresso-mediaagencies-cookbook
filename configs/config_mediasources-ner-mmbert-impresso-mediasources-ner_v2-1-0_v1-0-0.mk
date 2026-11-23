# Configuration for S3 path suffix:
# mediasources/mediasources-ner-mmbert-impresso-mediasources-ner_v2-1-0_v1-0-0
#
# Model v2.1.0 with impresso-inference feat/mediasources-tokenization-windows,
# which matches the evaluated model exactly (backend parity 490/490 test
# documents, 62/62 long concatenated documents, CPU and GPU fp32). bf16 on GPU:
# 487/490 and 58/62; on GDL 1950 it changes about 0.3% of entities (balanced)
# and is 2.8x faster, so the collection run uses bf16.

MODEL_ID_MEDIASOURCES ?= mmbert-impresso-mediasources-ner_v2-1-0
HF_MODEL_MEDIASOURCES ?= impresso-project/mmbert-impresso-mediasources-ner
HF_MODEL_REVISION_MEDIASOURCES ?= v2.1.0

RUN_VERSION_MEDIASOURCES ?= v1-0-0
S3_BUCKET_MEDIASOURCES ?= 141-processed-data-staging

BATCH_SIZE_MEDIASOURCES ?= 256
OUTER_BATCH_SIZE_MEDIASOURCES ?= 512
OUTER_BATCH_MAX_CHARS_MEDIASOURCES ?=
DTYPE_MEDIASOURCES ?= bf16
DEVICE_MEDIASOURCES ?= cuda
MIN_YEAR_MEDIASOURCES ?= 1835
SAMPLE_MEDIASOURCES ?= 1.0
SAMPLE_SEED_MEDIASOURCES ?=
FILTER_ANACHRONISTIC_MEDIASOURCES ?= --filter-anachronistic
DIAGNOSTICS_MEDIASOURCES ?=
