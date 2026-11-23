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

Output records follow Impresso entity enrichment conventions:

```json
{
  "id": "GDL-1950-01-03-a-p0001",
  "entities": [
    {
      "label": "org.ent.pressagency.afp",
      "surface": "AFP",
      "offset": [140, 143],
      "wikidata_id": "Q40464"
    }
  ]
}
```
