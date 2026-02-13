#!/usr/bin/env python3
# pylint: disable=invalid-name,duplicate-code
# [MISE] description="Verify renovate-tracked-deps.json is up to date"
"""Verify renovate-tracked-deps.json is up to date."""

import difflib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

_repo_root_env = os.environ.get("MISE_PROJECT_ROOT")
if _repo_root_env is None:
    print(
        "ERROR: MISE_PROJECT_ROOT is not set. Run this script via 'mise run'.",
        file=sys.stderr,
    )
    sys.exit(1)
REPO_ROOT = Path(_repo_root_env)
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

            diff = difflib.unified_diff(
                normalize(committed_data).splitlines(keepends=True),
                normalize(generated_data).splitlines(keepends=True),
                fromfile=str(COMMITTED),
                tofile="generated",
            )
            print("".join(diff))
            print("ERROR: renovate-tracked-deps.json is out of date.", file=sys.stderr)
            print(
                "Run 'mise run generate:renovate-tracked-deps' and commit the result.",
                file=sys.stderr,
            )
            sys.exit(1)


if __name__ == "__main__":
    main()
