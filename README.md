# Impresso Media Sources Cookbook

Corpus-scale processing cookbook for Impresso media-source NER.

This repository streams rebuilt Impresso JSONL files, runs
`impresso_pipelines.mediasources.MediaSourcesPipeline`, and writes compact JSONL
output containing detected press-agency and radio-station mentions.

## Model

Default model:

```text
impresso-project/mmbert-impresso-mediasources-ner
```

Default revision:

```text
v2.0.0
```

The reusable pipeline owns annotation tokenization, 512-subtoken model windows,
window batching, BIO decoding, entity scoring, and `wkdata_qid` enrichment.

During development, `impresso-pipelines[mediasources]` is installed directly
from the `mediasourcespipeline` branch of
`https://github.com/impresso/impresso-pipelines`.

## Installation

Clone the cookbook repository and enter it:

```bash
git clone --recursive https://github.com/impresso/impresso-mediasources-cookbook.git
cd impresso-mediasources-cookbook
```

If you already cloned without submodules, initialize them before installing:

```bash
git submodule update --init --recursive
```

Create the local environment with Pipenv:

```bash
pipenv install --dev
```

This installs the corpus-processing dependencies plus the development notebook
tools, including `ipykernel` and `ipython`. The model stack is pinned to the
training-compatible environment (`transformers==5.9.0`, `torch==2.12.0`,
`numpy>=2.4,<2.5`). If an existing environment already has older or incompatible
model packages, refresh the model stack:

```bash
pipenv update transformers torch numpy
```

The default dependency configuration installs `impresso-pipelines` from the
`mediasourcespipeline` branch on GitHub. For local development against a sibling
checkout of `impresso-pipelines`, switch the commented/local dependency line in
`Pipfile` or install that checkout in editable mode:

```bash
pip install -e ../impresso-pipelines[mediasources]
```

If installing with `requirements.txt`, keep the `impresso-pipelines` line as
plain text. It intentionally uses the GitHub branch archive URL to avoid Git
credential prompts on servers. The separate version constraint makes pip reject
a stale branch archive whose package metadata has not advanced:

```text
impresso-pipelines==0.6.1.2
impresso-pipelines[mediasources] @ https://github.com/impresso/impresso-pipelines/archive/refs/heads/mediasourcespipeline.zip
```

If you prefer a plain virtual environment, install the runtime requirements and
then add the notebook tools:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pip install ipykernel ipython
```

## Manual Diagnostics Notebook

The manual token-diagnostics notebook is available at:

```text
notebooks/manual_token_diagnostics.ipynb
```

Start Jupyter from the cookbook environment:

```bash
pipenv run jupyter notebook
```

Open the notebook, paste one rebuilt content-item JSON object into
`CONTENT_ITEM_JSON`, and run the cells. The notebook reads the full text from
`ft`, runs `MediaSourcesPipeline` with `diagnostics=True`, and displays entity,
summary, highlighted-text, token-diagnostics, and raw JSON views.

## Usage

Process locally available rebuilt files for one newspaper:

```bash
make CFG=configs/config_mediasources-ner-mmbert-impresso-mediasources-ner_v2-0-0_v1-0-0.mk processing-target NEWSPAPER=GDL
```

Full sync/process/upload workflow:

```bash
make CFG=configs/config_mediasources-ner-mmbert-impresso-mediasources-ner_v2-0-0_v1-0-0.mk newspaper NEWSPAPER=GDL
```

## CLI

The core command is:

```bash
python3 lib/cli_mediasources.py \
  --input input.jsonl.bz2 \
  --output output.jsonl.bz2 \
  --hf-model impresso-project/mmbert-impresso-mediasources-ner \
  --revision v2.0.0 \
  --batch-size 32 \
  --outer-batch-size 512 \
  --device auto \
  --filter-anachronistic
```

`--batch-size` controls model window batch size inside
`MediaSourcesPipeline`. `--outer-batch-size` controls how many documents the
cookbook buffers before length sorting and processing.

## Output Shape

Rows are written only for documents with detected entities unless `--write-empty`
is passed.

Every output record is validated against the pinned submodule's
`json/impresso-2/semantic-enrichment/entities/entities-nel.v2.schema.json`
before it is written. References resolve locally without network access. The CLI
also verifies that offsets reproduce the source surface and that each Wikidata
QID agrees with the pipeline's label mapping. A validation failure stops the CLI;
the Make recipe skips upload and removes the incomplete output.

Initialize schemas with `git submodule update --init --recursive`.

```json
{
  "ci_id": "GDL-1951-01-01-a-i0001",
  "ts": "2026-09-01T12:00:00Z",
  "model_id": "impresso-project/mmbert-impresso-mediasources-ner@v2.0.0#float32",
  "nes": [
    {
      "type": "org.ent.pressagency",
      "fine_grained_type": "org.ent.pressagency.reuters",
      "surface": "Reuters",
      "lOffset": 120,
      "rOffset": 127,
      "confidence_ner": 0.94,
      "confidence_nel": 0.94,
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

Translated labels are currently unavailable and emitted as null. Linking uses
the pipeline's fixed label-to-QID mapping; `confidence_nel` retains the model's
entity score rather than an independently estimated linking confidence.
Existing outputs are not automatically revalidated or replaced.
