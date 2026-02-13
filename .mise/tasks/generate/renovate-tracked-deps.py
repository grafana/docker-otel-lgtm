#!/usr/bin/env python3
# pylint: disable=invalid-name
# [MISE] description="Generate renovate-tracked-deps.json from Renovate's local analysis"
"""Generate renovate-tracked-deps.json from Renovate's local analysis."""

import json
import os
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(os.environ["MISE_PROJECT_ROOT"])
OUTPUT_FILE = (
    Path(sys.argv[1])
    if len(sys.argv) > 1
    else REPO_ROOT / ".github" / "renovate-tracked-deps.json"
)


def run_renovate(tmpdir):
    """Run Renovate locally and return the log path."""
    config_path = str(REPO_ROOT / ".github" / "renovate.json5")
    log_path = os.path.join(tmpdir, "renovate.log")
    env = {
        **os.environ,
        "LOG_LEVEL": "debug",
        "LOG_FORMAT": "json",
        "RENOVATE_CONFIG_FILE": config_path,
    }
    with open(log_path, "w", encoding="utf-8") as log_file:
        result = subprocess.run(
            [
                "renovate",
                "--platform=local",
                "--require-config=ignored",
            ],
            env=env,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            check=False,
            cwd=REPO_ROOT,
        )
    if result.returncode != 0:
        print(
            f"ERROR: Renovate failed (exit {result.returncode})."
            f" See log: {log_path}",
            file=sys.stderr,
        )
        sys.exit(result.returncode)
    return log_path


EXCLUDED_MANAGERS = {
    m.strip()
    for m in os.environ.get("RENOVATE_TRACKED_DEPS_EXCLUDE", "").split(",")
    if m.strip()
}


def extract_deps(log_path):
    """Parse Renovate log and return deps grouped by file and manager."""
    config = None
    with open(log_path, encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("msg") == "packageFiles with updates":
                config = entry.get("config", {})

    if config is None:
        print(
            "ERROR: 'packageFiles with updates' message not found in Renovate log.",
            file=sys.stderr,
        )
        sys.exit(1)

    # Skip reasons that mean "not a real dep"
    skip_reasons_to_exclude = {
        "contains-variable",
        "invalid-value",
        "invalid-version",
    }

    # {file_path: {manager: set(dep_names)}}
    deps_by_file = defaultdict(lambda: defaultdict(set))
    for manager, manager_files in config.items():
        if manager in EXCLUDED_MANAGERS:
            continue
        for pkg_file in manager_files:
            file_path = pkg_file.get("packageFile", "")
            for dep in pkg_file.get("deps", []):
                if dep.get("skipReason") in skip_reasons_to_exclude:
                    continue
                dep_name = dep.get("depName")
                if dep_name:
                    deps_by_file[file_path][manager].add(dep_name)

    result = {}
    for file_path in sorted(deps_by_file):
        managers = deps_by_file[file_path]
        result[file_path] = {m: sorted(managers[m]) for m in sorted(managers)}
    return result


def main():
    """Generate renovate-tracked-deps.json."""
    with tempfile.TemporaryDirectory() as tmpdir:
        log_path = run_renovate(tmpdir)
        result = extract_deps(log_path)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)
        f.write("\n")

    print(f"Wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
