#!/usr/bin/env python3
# pylint: disable=invalid-name
# [MISE] description="Verify renovate-tracked-deps.json is up to date"
"""Verify renovate-tracked-deps.json is up to date."""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
COMMITTED = REPO_ROOT / ".github" / "renovate-tracked-deps.json"


def main():
    """Verify renovate-tracked-deps.json is up to date."""
    with tempfile.TemporaryDirectory() as tmpdir:
        generated = Path(tmpdir) / "renovate-tracked-deps.json"

        result = subprocess.run(
            ["mise", "run", "generate:renovate-tracked-deps", str(generated)],
            check=False,
        )
        if result.returncode != 0:
            print("ERROR: generator failed.", file=sys.stderr)
            sys.exit(1)

        committed_data = json.loads(COMMITTED.read_text())
        generated_data = json.loads(generated.read_text())

        if committed_data == generated_data:
            print("renovate-tracked-deps.json is up to date.")
        else:

            def normalize(d):
                return json.dumps(d, indent=2, sort_keys=True) + "\n"

            norm_committed = Path(tmpdir) / "committed.json"
            norm_generated = Path(tmpdir) / "generated.json"
            norm_committed.write_text(normalize(committed_data))
            norm_generated.write_text(normalize(generated_data))
            diff = subprocess.run(
                ["diff", "-u", str(norm_committed), str(norm_generated)],
                capture_output=True,
                text=True,
                check=False,
            )
            print(diff.stdout)
            print("ERROR: renovate-tracked-deps.json is out of date.", file=sys.stderr)
            print(
                "Run 'mise run generate:renovate-tracked-deps' and commit the result.",
                file=sys.stderr,
            )
            sys.exit(1)


if __name__ == "__main__":
    main()
