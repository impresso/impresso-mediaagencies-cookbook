# AGENTS.md

## Repository Purpose

This repository is a Make-based processing cookbook for Impresso media-source
NER at corpus scale. It detects cited media agencies in rebuilt newspaper content
using the `impresso_inference.tasks.mediaagencies` stages of `impresso-inference`
(`cli.prepare`, `cli.forward`, `cli.decode`, or the unified `cli.run`).

The cookbook owns orchestration only: S3/local paths, stamps, WIP locks,
logging, and output upload. Tokenization, window batching, the forward pass,
decoding, entity scoring, `wkdata_qid` enrichment and the output record format
belong to `impresso-inference`.

## Commands

Use `make` in documentation and examples.

Common targets:

- `make setup`
- `make sync-input NEWSPAPER=<paper>`
- `make processing-target NEWSPAPER=<paper>`
- `make newspaper NEWSPAPER=<paper>`

## Important Files

- `lib/cli_mediaagencies.py`: streaming media-agency processing CLI.
- `cookbook/paths_mediaagencies.mk`: run identity and output path variables.
- `cookbook/processing_mediaagencies.mk`: rebuilt input to media-agency output rule.
- `configs/config_mediaagencies-ner-mmbert-impresso-mediaagencies-ner_v2-1-0_v1-0-0.mk`: current model/run configuration (v2.1.0); the v2-0-0 config is kept for the earlier run.

## Output

Output rows use `ci_id`, `ts`, `model_id`, and `nes`, following the pinned
`impresso-schemas/json/impresso-2/semantic-enrichment/entities/entities-nel.v2.schema.json`.
Media-source types are `org.ent.pressagency` and `org.ent.radiostation`;
`fine_grained_type` preserves the full model label. The decode stage
(`impresso_inference.tasks.mediaagencies.cli.decode`) validates each row against
the pinned schema (`DECODE_VALIDATE_SCHEMAS_MEDIAAGENCIES`); validation failure
prevents Make from uploading the output. Surfaces are rebuilt from tokens and
offsets; `DECODE_TEXT_INPUT_MEDIAAGENCIES=1` additionally checks them against the
rebuilt source text. The first v2.1.0 collection run used the earlier minimal
`{"id", "entities"}` format.
