#!/usr/bin/env python3
# [MISE] description="Verify renovate-tracked-deps.json is up to date"

import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
COMMITTED = REPO_ROOT / ".github" / "renovate-tracked-deps.json"


def main():
    with tempfile.TemporaryDirectory() as tmpdir:
        generated = Path(tmpdir) / "renovate-tracked-deps.json"

        result = subprocess.run(
            ["mise", "run", "generate:renovate-tracked-deps", str(generated)],
            capture_output=False,
        )
        if result.returncode != 0:
            print("ERROR: generator failed.", file=sys.stderr)
            sys.exit(1)

        diff = subprocess.run(
            ["diff", "-u", str(COMMITTED), str(generated)],
            capture_output=True,
            text=True,
        )

        if diff.returncode == 0:
            print("renovate-tracked-deps.json is up to date.")
        elif diff.returncode == 1:
            print(diff.stdout)
            print("ERROR: renovate-tracked-deps.json is out of date.", file=sys.stderr)
            print(
                "Run 'mise run generate:renovate-tracked-deps' and commit the result.",
                file=sys.stderr,
            )
            sys.exit(1)
        else:
            print(diff.stderr, file=sys.stderr)
            print("ERROR: diff failed.", file=sys.stderr)
            sys.exit(diff.returncode)


if __name__ == "__main__":
    main()
