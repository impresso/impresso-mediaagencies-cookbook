import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from lib import cli_mediasources


def test_processor_keeps_entities_aligned_after_length_sort(tmp_path, monkeypatch):
    input_path = tmp_path / "input.jsonl"
    output_path = tmp_path / "output.jsonl"
    log_path = tmp_path / "run.log"

    rows = [
        {
            "ci_id": "GDL-1951-01-01-a-i0001",
            "date": "1951-01-01",
            "ft": "This deliberately longer document mentions BBC near the end.",
        },
        {
            "ci_id": "GDL-1859-03-18-a-i0001",
            "date": "1859-03-18",
            "ft": "Reuters.",
        },
    ]
    input_path.write_text("".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8")

    class FakePipeline:
        def __init__(self, **kwargs):
            self.kwargs = kwargs
            self.wkdata_qids = {"org.ent.pressagency.reuters": "Q130879", "org.ent.radiostation.bbc": "Q9531"}
            self.last_inference_stats = dict.fromkeys(cli_mediasources.REQUIRED_INFERENCE_STATS, 0)
            assert kwargs["device"] == -1

        def __call__(self, texts, *, publication_date=None, filter_anachronistic=None, diagnostics=False):
            assert texts == ["Reuters.", "This deliberately longer document mentions BBC near the end."]
            assert publication_date == ["1859-03-18", "1951-01-01"]
            assert filter_anachronistic is True
            assert diagnostics is True
            return [
                {
                    "entities": [
                        {
                            "surface": "Reuters",
                            "label": "org.ent.pressagency.reuters",
                            "wkdata_qid": "Q130879",
                            "start_year": 1851,
                            "start": 0,
                            "stop": 7,
                            "score": 0.9,
                        }
                    ],
                    "summary": [],
                    "tokens": ["Reuters", "."],
                    "token_start_offsets": [0, 7],
                    "token_end_offsets": [7, 8],
                    "token_labels": ["B-org.ent.pressagency.reuters", "O"],
                    "token_scores": [0.9, 1.0],
                },
                {
                    "entities": [
                        {
                            "surface": "BBC",
                            "label": "org.ent.radiostation.bbc",
                            "wkdata_qid": "Q9531",
                            "start_year": 1922,
                            "start": 43,
                            "stop": 46,
                            "score": 0.8,
                        }
                    ],
                    "summary": [],
                    "tokens": ["This", "BBC"],
                    "token_start_offsets": [0, 43],
                    "token_end_offsets": [4, 46],
                    "token_labels": ["O", "B-org.ent.radiostation.bbc"],
                    "token_scores": [1.0, 0.8],
                },
            ]

    monkeypatch.setattr(cli_mediasources, "MediaSourcesPipeline", FakePipeline)
    monkeypatch.setattr(cli_mediasources, "get_timestamp", lambda: "2026-09-01T12:00:00Z")

    processor = cli_mediasources.MediaSourcesProcessor(
        input_file=str(input_path),
        output_file=str(output_path),
        hf_model="fake-model",
        revision="fake-revision",
        dtype="float32",
        outer_batch_max_chars=None,
        sample=1.0,
        sample_seed=None,
        batch_size=32,
        outer_batch_size=2,
        device=-1,
        min_score=None,
        filter_anachronistic=True,
        local_files_only=True,
        diagnostics=True,
        write_empty=False,
        log_level="INFO",
        log_file=str(log_path),
    )
    processor.run()

    output_rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    assert [row["ci_id"] for row in output_rows] == ["GDL-1859-03-18-a-i0001", "GDL-1951-01-01-a-i0001"]
    assert output_rows[0]["nes"][0]["surface"] == "Reuters"
    assert output_rows[0]["nes"][0]["type"] == "org.ent.pressagency"
    assert output_rows[0]["nes"][0]["label_fr"] is None
    assert output_rows[0]["nes"][0]["fine_grained_type"] == "org.ent.pressagency.reuters"
    assert output_rows[1]["nes"][0]["surface"] == "BBC"
    assert output_rows[1]["nes"][0]["fine_grained_type"] == "org.ent.radiostation.bbc"
    assert output_rows[0]["diagnostics"]["token_labels"] == ["B-org.ent.pressagency.reuters", "O"]
    assert output_rows[1]["diagnostics"]["token_labels"] == ["O", "B-org.ent.radiostation.bbc"]


def test_validation_rejects_invalid_entities():
    import copy
    import pytest
    from jsonschema import ValidationError

    label = 'org.ent.pressagency.reuters'
    entity = cli_mediasources.entity_to_nel(dict(
        label=label, surface='Reuters', start=0, stop=7, score=0.9, wkdata_qid='Q130879'))
    row = dict(ci_id='GDL-1951-01-01-a-i0001', ts='2026-09-01T12:00:00Z', model_id='test', nes=[entity])
    mapping = {label: 'Q130879'}
    cli_mediasources.validate_output_row(row, 'Reuters.', mapping)
    for field, value in [('confidence_ner', 1.01), ('wkdata_qid', 'invalid'), ('type', 'invalid')]:
        broken = copy.deepcopy(row)
        broken['nes'][0][field] = value
        with pytest.raises(ValidationError):
            cli_mediasources.validate_output_row(broken, 'Reuters.', mapping)
    broken = copy.deepcopy(row)
    del broken['nes'][0]['label_fr']
    with pytest.raises(ValidationError):
        cli_mediasources.validate_output_row(broken, 'Reuters.', mapping)
    with pytest.raises(ValueError, match='offsets'):
        cli_mediasources.validate_output_row(row, 'Different text', mapping)
    with pytest.raises(ValueError, match='mapping'):
        cli_mediasources.validate_output_row(row, 'Reuters.', {label: 'Q1'})
