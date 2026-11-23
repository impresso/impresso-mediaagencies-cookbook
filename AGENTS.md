# AGENTS.md

## Repository Purpose

This repository is a Make-based processing cookbook for Impresso media-source
NER at corpus scale. It detects cited media sources in rebuilt newspaper content
using `impresso_pipelines.mediasources.MediaSourcesPipeline`.

The cookbook owns orchestration only: S3/local paths, stamps, streaming JSONL
I/O, outer batching, length bucketing, logging, and output upload. Model
tokenization, window batching, decoding, entity scoring, and `wkdata_qid`
enrichment belong to `impresso-pipelines`.

## Commands

Use `make` in documentation and examples.

Common targets:

- `make setup`
- `make sync-input NEWSPAPER=<paper>`
- `make processing-target NEWSPAPER=<paper>`
- `make newspaper NEWSPAPER=<paper>`

## Important Files

- `lib/cli_mediasources.py`: streaming media-source processing CLI.
- `cookbook/paths_mediasources.mk`: run identity and output path variables.
- `cookbook/processing_mediasources.mk`: rebuilt input to media-source output rule.
- `configs/config_mediasources-ner-mmbert-impresso-mediasources-ner_v2-1-0_v1-0-0.mk`: current model/run configuration (v2.1.0); the v2-0-0 config is kept for the earlier run.

## Output

Output rows use `ci_id`, `ts`, `model_id`, and `nes`, following the pinned
`impresso-schemas/json/impresso-2/semantic-enrichment/entities/entities-nel.v2.schema.json`.
Media-source types are `org.ent.pressagency` and `org.ent.radiostation`;
`fine_grained_type` preserves the full model label. The CLI validates each row,
source-text offsets, and the pipeline label-to-QID mapping before writing it.
Validation failure prevents Make from uploading the output.
