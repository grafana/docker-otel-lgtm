#!/usr/bin/env python3
# MISE description="Generate renovate-tracked-deps.json from Renovate's local analysis"

import json
import os
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
OUTPUT_FILE = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO_ROOT / ".github" / "renovate-tracked-deps.json"

def build_minimal_config(tmpdir):
    """Convert .github/renovate.json5 to a minimal JSON config with only extends + customManagers.

    Uses node + json5 package since node is already required for npx renovate.
    """
    subprocess.run(
        ["npm", "install", "--silent", "--prefix", tmpdir, "json5"],
        check=True,
        capture_output=True,
    )
    config_path = os.path.join(tmpdir, "renovate.json")
    in_path = str(REPO_ROOT / ".github" / "renovate.json5")
    script = f"""\
const fs = require('fs');
const JSON5 = require('json5');
const full = JSON5.parse(fs.readFileSync({json.dumps(in_path)}, 'utf8'));
const minimal = {{}};
if (full.extends) minimal.extends = full.extends;
if (full.customManagers) minimal.customManagers = full.customManagers;
fs.writeFileSync({json.dumps(config_path)}, JSON.stringify(minimal, null, 2));
"""
    env = {**os.environ, "NODE_PATH": os.path.join(tmpdir, "node_modules")}
    subprocess.run(["node", "-e", script], check=True, env=env)
    return config_path


def run_renovate(tmpdir, config_path):
    log_path = os.path.join(tmpdir, "renovate.log")
    env = {
        **os.environ,
        "LOG_LEVEL": "debug",
        "LOG_FORMAT": "json",
        "RENOVATE_CONFIG_FILE": config_path,
    }
    with open(log_path, "w") as log_file:
        subprocess.run(
            ["npx", "--yes", "renovate", "--platform=local", "--require-config=ignored"],
            env=env,
            stdout=log_file,
            stderr=subprocess.STDOUT,
        )
    return log_path


def extract_deps(log_path):
    config = None
    with open(log_path) as f:
        for line in f:
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("msg") == "packageFiles with updates":
                config = entry.get("config", {})

    if config is None:
        print("ERROR: 'packageFiles with updates' message not found in Renovate log.", file=sys.stderr)
        sys.exit(1)

    # Skip reasons that mean "not a real dep" vs "real dep but can't check updates locally"
    SKIP_REASONS_TO_EXCLUDE = {"contains-variable", "invalid-value", "invalid-version"}

    deps_by_file = defaultdict(set)
    for manager_files in config.values():
        for pkg_file in manager_files:
            file_path = pkg_file.get("packageFile", "")
            for dep in pkg_file.get("deps", []):
                if dep.get("skipReason") in SKIP_REASONS_TO_EXCLUDE:
                    continue
                dep_name = dep.get("depName")
                if dep_name:
                    deps_by_file[file_path].add(dep_name)

    return {k: sorted(v) for k, v in sorted(deps_by_file.items())}


def main():
    with tempfile.TemporaryDirectory() as tmpdir:
        config_path = build_minimal_config(tmpdir)
        log_path = run_renovate(tmpdir, config_path)
        result = extract_deps(log_path)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(result, f, indent=2)
        f.write("\n")

    print(f"Wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
