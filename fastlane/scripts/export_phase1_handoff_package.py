#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import shutil
import zipfile
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EXPORT_MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Review"
    / "Phase1ProfessionalHandoff"
    / "handoff_export_manifest.json"
)
PHASE1_MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Review"
    / "Phase1ProfessionalHandoff"
    / "phase1_professional_handoff_manifest.json"
)


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def write_json(path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def assert_safe_relative_path(rel_path, forbidden_tokens):
    text = str(rel_path)
    if Path(text).is_absolute() or ".." in Path(text).parts:
        raise SystemExit(f"Unsafe export path: {text}")
    if any(part.startswith("._") for part in Path(text).parts):
        raise SystemExit(f"AppleDouble sidecar must not be exported: {text}")
    for token in forbidden_tokens:
        if token and token in text:
            raise SystemExit(f"Forbidden export path token {token!r}: {text}")


def remove_apple_double(root):
    if not root.exists():
        return
    for path in root.rglob("._*"):
        if path.is_file():
            path.unlink()


def copy_source(rel_path, package_root, forbidden_tokens, copied_files):
    assert_safe_relative_path(rel_path, forbidden_tokens)
    source = ROOT / rel_path
    if not source.is_file():
        raise SystemExit(f"Missing source file for export: {rel_path}")
    destination = package_root / "repo_sources" / rel_path
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    copied_files.append(
        {
            "path": str(destination.relative_to(package_root)),
            "source_path": rel_path,
            "bytes": destination.stat().st_size,
            "sha256": sha256(destination),
        }
    )


def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def instrument_readme(item):
    takes = "\n".join(f"- {filename}" for filename in item.get("required_recording_takes", []))
    review_focus = "\n".join(f"- {focus}" for focus in item.get("recording_review_focus", []))
    return f"""# {item['name_zh']} {item['instrument_id']} recording folder

Scope: {item['recording_scope']}

Place the real-instrument WAV or AIFF takes in this folder, then copy and fill the release template as:

```text
{item['instrument_id']}.release.json
```

Required take filenames:

{takes}

Professional listening focus:

{review_focus}

Forbidden sources: Suno, AI-generated instrument tone, VST, sample library, MIDI, YouTube, CD, streaming extraction, pitch-shifted neighboring instruments, backing tracks, or copyrighted melodies without a separate composition license.
"""


def build_package(args):
    os.environ["COPYFILE_DISABLE"] = "1"
    export_manifest = load_json(EXPORT_MANIFEST_PATH)
    phase1_manifest = load_json(PHASE1_MANIFEST_PATH)
    forbidden_tokens = export_manifest.get("forbidden_export_path_tokens", [])

    output_root = ROOT / export_manifest["output_root"]
    package_root = output_root / export_manifest["package_slug"]
    zip_path = output_root / export_manifest["zip_filename"]

    if package_root.exists():
        shutil.rmtree(package_root)
    output_root.mkdir(parents=True, exist_ok=True)
    package_root.mkdir(parents=True, exist_ok=True)
    remove_apple_double(output_root)

    copied_files = []
    for rel_path in export_manifest.get("shared_source_files", []):
        copy_source(rel_path, package_root, forbidden_tokens, copied_files)

    handoff_by_id = {item["instrument_id"]: item for item in phase1_manifest.get("items", [])}
    export_by_id = {item["instrument_id"]: item for item in export_manifest.get("per_instrument_exports", [])}
    if set(handoff_by_id) != set(export_manifest.get("required_instrument_ids", [])):
        raise SystemExit("Phase-1 handoff instruments do not match export manifest required ids")
    if set(export_by_id) != set(export_manifest.get("required_instrument_ids", [])):
        raise SystemExit("Per-instrument export entries do not match required ids")

    for instrument_id in export_manifest["required_instrument_ids"]:
        handoff_item = handoff_by_id[instrument_id]
        export_item = export_by_id[instrument_id]
        recording_dir = package_root / "recording_inbox" / instrument_id
        artwork_dir = package_root / "artwork_review" / instrument_id
        recording_dir.mkdir(parents=True, exist_ok=True)
        artwork_dir.mkdir(parents=True, exist_ok=True)

        write_text(recording_dir / "README.md", instrument_readme(handoff_item))
        release_template = export_item["release_template"]
        copy_source(release_template, package_root, forbidden_tokens, copied_files)
        shutil.copyfile(ROOT / release_template, recording_dir / f"{instrument_id}.release.template.json")

        for key in ["artwork_candidate", "artwork_approval_draft"]:
            rel_path = export_item[key]
            copy_source(rel_path, package_root, forbidden_tokens, copied_files)
            shutil.copyfile(ROOT / rel_path, artwork_dir / Path(rel_path).name)

    write_text(
        package_root / "README.md",
        """# 國樂團練習室第一批實器錄音與樂器圖審核交付包

This package is for performer delivery and professional review only. It is not approval evidence and is not App Store readiness.

Recording folders are under `recording_inbox/<instrument_id>/`.
Artwork review files are under `artwork_review/<instrument_id>/`.
Original repo source files copied into this package are under `repo_sources/`.

Core audio must be real Chinese-orchestra instrument recording. Do not use Suno, AI-generated instrument tone, VST, sample library, MIDI, YouTube, CD, streaming extraction, or pitch-shifted neighboring instruments.
""",
    )
    write_text(
        package_root / "recording_inbox" / "README.md",
        "Put real-instrument recording takes and filled release JSON files in each instrument folder. Do not place generated audio or sample-library output here.\n",
    )
    write_text(
        package_root / "artwork_review" / "README.md",
        "Review only textless candidate images. Approval drafts must be filled by a qualified Chinese-orchestra reviewer before app import.\n",
    )

    remove_apple_double(package_root)

    package_files = []
    for path in sorted(package_root.rglob("*")):
        if path.is_file() and not path.name.startswith("._"):
            rel_path = str(path.relative_to(package_root))
            assert_safe_relative_path(rel_path, forbidden_tokens)
            package_files.append(
                {
                    "path": rel_path,
                    "bytes": path.stat().st_size,
                    "sha256": sha256(path),
                }
            )

    package_manifest = {
        "schema_version": 1,
        "generated_at": date.today().isoformat(),
        "status": "generated_work_packet_not_approval_evidence",
        "source_export_manifest": str(EXPORT_MANIFEST_PATH.relative_to(ROOT)),
        "source_phase1_manifest": str(PHASE1_MANIFEST_PATH.relative_to(ROOT)),
        "required_instrument_ids": export_manifest["required_instrument_ids"],
        "file_count": len(package_files),
        "copied_repo_source_count": len(copied_files),
        "files": package_files,
        "copied_repo_sources": copied_files,
    }
    write_json(package_root / "PACKAGE_MANIFEST.json", package_manifest)

    if zip_path.exists():
        zip_path.unlink()
    remove_apple_double(package_root)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(package_root.rglob("*")):
            if path.is_file() and not path.name.startswith("._"):
                rel_path = path.relative_to(output_root)
                assert_safe_relative_path(str(rel_path), forbidden_tokens)
                archive.write(path, rel_path)
    remove_apple_double(output_root)

    print(f"Exported phase-1 handoff package: {package_root.relative_to(ROOT)}")
    print(f"Created zip: {zip_path.relative_to(ROOT)}")
    print(f"Files: {len(package_files)}")


def main():
    parser = argparse.ArgumentParser(description="Export sanitized phase-1 handoff package.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Build the package and zip, then exit after printing the output paths.",
    )
    args = parser.parse_args()
    build_package(args)


if __name__ == "__main__":
    main()
