# Impresso Media Sources (Media Agencies) Cookbook

Corpus-scale processing cookbook for Impresso media-agency / news-agency NER.

> **Note on Naming:** This task is currently designated as `mediaagencies` in the code and S3 storage prefixes. In future Impresso releases, it will be designated as **Media Agencies** (`mediaagencies`).

This repository streams rebuilt Impresso JSONL files from S3, orchestrates distributed processing using GNU Make and S3 WIP locks (`manage_s3_wip`), executes high-throughput inference via the **`impresso-inference`** backend, and writes compact compressed JSONL output containing detected press-agency and radio-station mentions with Wikidata QID enrichment and historical anachronism filtering.

## Model

Default model:
```text
impresso-project/mmbert-impresso-mediaagencies-ner
```

Default revision:
```text
v2.1.0
```

The model is based on **ModernBERT** architecture, fine-tuned for token classification across 99 BIO tags covering 49 media agencies and radio networks with historical founding-year validation.

## Compute Engine: `impresso-inference`

This cookbook uses the decoupled, high-throughput compute engine from [`impresso-inference`](https://github.com/impresso/impresso-inference) (branch `feat/mediasources-tokenization-windows`, pinned by commit in `requirements.txt`).

This branch tokenizes with the model's `unicode-word-punctuation-v1` scheme, covers long articles with 256-word windows (32-word overlap), and uses the model's reference BIO Viterbi rules. It requires transformers 5. On CPU fp32 its output matches the evaluated model exactly (workbench backend parity check: 490/490 test documents, 62/62 long concatenated documents).

### Performance Highlights (UZH ScienceCloud NVIDIA L4, 24GB):
- **Dynamic Length-Bucketing:** Slices batches by sequence length, avoiding padding waste on shorter news briefs (**13.4× speedup** over naïve static padding).
- **Throughput:** **~2,000+ chunks/s** during GPU forward passes in `bfloat16`, saturating the GPU at 100% compute (72W / 72W).
- **End-to-End Speed:** Decodes an entire annual newspaper volume (`GDL-1950`, ~39k items) in **~1 min 20 sec**!

## Installation

Clone the cookbook repository with submodules:

```bash
git clone --recursive https://github.com/impresso/impresso-mediaagencies-cookbook.git
cd impresso-mediaagencies-cookbook
```

If you already cloned without submodules, initialize them:

```bash
git submodule update --init --recursive
```

### Environment Setup (uv or pip)

Using `uv` (recommended):
```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

If running on CUDA 12.4+ (e.g. UZH ScienceCloud L4):
```bash
uv pip install --no-cache torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

## Usage

### 1. Process One Newspaper Year
Process a specific newspaper volume directly with S3 WIP locks and upload:

```bash
make mediaagencies-target \
  CFG=configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0.mk \
  PROVIDER=LeTemps NEWSPAPER=GDL NEWSPAPER_YEARS=1950
```

### 2. Full Collection Run
Run across all newspapers in your configured newspaper list:

```bash
make processing-target \
  CFG=configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0.mk
```

### 3. Collection Completeness Audit
Audit processing completion against canonical rebuilt issues:

```bash
make check-collection-completeness \
  CFG=configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0.mk
```

## Direct CLI Invocation

The underlying compute engine can also be invoked directly from the CLI:

```bash
python3 -m impresso_inference.tasks.mediaagencies.cli.run \
  --input s3://122-rebuilt-final/LeTemps/GDL/GDL-1950.jsonl.bz2 \
  --output s3://141-processed-data-staging/mediaagencies/LeTemps/GDL/GDL-1950.jsonl.bz2 \
  --device cuda \
  --precision bf16 \
  --batch-size 256
```

Key arguments:
- `--device`: `cuda` or `cpu`.
- `--precision`: `bf16` (recommended for ModernBERT), `fp16`, or `fp32`.
- `--batch-size`: Batch size per forward pass (defaults to 256 on NVIDIA L4).
- `--num-workers`: Number of CPU workers for parallel pre-tokenization and Viterbi decoding (defaults to all available cores).
- `--no-filter-anachronistic`: Disable pruning of mentions founded after the document's publication year.

## Output Shape

Final output records follow the Impresso
[`entities-nel.v2`](https://github.com/impresso/impresso-schemas/blob/dev/json/impresso-2/semantic-enrichment/entities/entities-nel.v2.schema.json)
schema, one content item per line:

```json
{
  "ci_id": "NZZ-1900-01-04-c-i0002",
  "ts": "2026-11-26T06:53:05Z",
  "model_id": "impresso-project/mmbert-impresso-mediaagencies-ner@v2.1.0",
  "nes": [
    {
      "type": "org.ent.pressagency",
      "fine_grained_type": "org.ent.pressagency.reuters",
      "surface": "Reuter",
      "lOffset": 250,
      "rOffset": 256,
      "confidence_ner": 0.8355,
      "confidence_nel": 0.8355,
      "wkdata_qid": "Q130879",
      "wkpedia_lg": null,
      "wkpedia_pagename": null,
      "label_fr": null,
      "label_en": null,
      "label_de": null,
      "start_year": 1851
    }
  ]
}
```

- `type` is `org.ent.pressagency` or `org.ent.radiostation`; `fine_grained_type` keeps the
  full model label.
- `confidence_ner` is the lowest P(B-label) + P(I-label) over the mention's words;
  `confidence_nel` has the same value.
- `surface` is rebuilt exactly from the tokens and offsets, because the rebuilt `ft` text
  has only spaces between tokens.

The first v2.1.0 collection run (2026-11, `v1-0-0`) was written in the earlier minimal format
`{"id", "entities": [{"label", "offset", "wikidata_id"}]}`.

### Decode options

The decode stage validates every row against the pinned `impresso-schemas` submodule;
a validation failure stops the rule before upload. The decoder log ends with entity stats
(mentions, types, top labels, anachronism pruning, confidence distribution).

| Variable | Default | Effect |
|---|---|---|
| `DECODE_VALIDATE_SCHEMAS_MEDIAAGENCIES` | `impresso-schemas/json` | Schema directory for validation; empty disables it |
| `DECODE_ID_INPUT_MEDIAAGENCIES` | `1` | Read the rebuilt input's content-item IDs; fill empty stage-2 IDs by position and check all others; stops on a mismatch |
| `DECODE_WORKERS_MEDIAAGENCIES` | `1` | Decode processes per job; 1 streams the stage-2 file (about 1 GB peak); use `make -j` for parallel jobs |
| `DECODE_TEXT_INPUT_MEDIAAGENCIES` | empty | Set to `1` for a spot check: read the rebuilt input, take surfaces from the source text and verify offsets (costs extra memory) |

Example spot check of one year:

```bash
make mediaagencies-target \
  CFG=configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0.mk \
  PROVIDER=LeTemps NEWSPAPER=GDL NEWSPAPER_YEARS=1950 \
  DECODE_TEXT_INPUT_MEDIAAGENCIES=1
```

### Re-decode of the first v2.1.0 run

The first v2.1.0 run (`v1-0-0`) lost the content-item IDs of all BNF and FedGaz files:
their rebuilt records carry `ci_id`, which its stage 1 did not read. The config
`configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-1-0.mk`
re-decodes the `v1-0-0` stage-2 logits into the `v1-1-0` folder, without new inference:
it runs only the decode stage (`MEDIAAGENCIES_STAGE ?= decode`), reads stage 2 from the
earlier run (`STAGE_RUN_VERSION_MEDIAAGENCIES ?= v1-0-0`), writes `entities-nel.v2`
records and restores the IDs from the rebuilt input.

```bash
make processing-target \
  CFG=configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-1-0.mk
```

## Aggregation

Collect all mentions of a run into one file, one JSON object per mention:

```bash
make aggregate-mediaagencies-mentions \
  CFG=configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0.mk
```

The output is written next to the run folder as
`<run-id>__AGGREGATED.mentions.jsonl.gz`, with the fields `ci_id`, `newspaper`, `date`,
`label`, `wikidata_id`, `start` and `end`. The jq filter
`cookbook/lib/mediaagencies_mentions.jq` reads the minimal format of the first v2.1.0 run.
