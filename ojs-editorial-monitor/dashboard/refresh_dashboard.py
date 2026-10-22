"""Refresh the monitoring dashboard end to end.

  python refresh_dashboard.py            pull the latest data from OJS (read-only), rebuild tables and the dashboard
  python refresh_dashboard.py --offline  skip OJS; rebuild the dashboard from the tables that already exist
  python refresh_dashboard.py --full     ignore the local cache and fetch every submission again (slow)

Needs the environment variable OJS_API_KEY (an OJS API key) unless --offline.
Extra options are passed to build_dashboard.py (e.g. --target 180 --no-titles --with-names).
Nothing is ever written to OJS.
"""
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
args = sys.argv[1:]
offline = "--offline" in args
full = "--full" in args
passthrough = [a for a in args if a not in ("--offline", "--full")]


def run(script, *extra, cwd=ROOT):
    print(f"\n>>> {script} {' '.join(extra)}", flush=True)
    r = subprocess.run([sys.executable, str(script), *extra], cwd=cwd)
    if r.returncode != 0:
        sys.exit(f"Langkah gagal: {script} (kode {r.returncode})")


if not offline:
    if not os.environ.get("OJS_API_KEY"):
        sys.exit("Atur dulu variabel OJS_API_KEY (PowerShell: $env:OJS_API_KEY='...'), atau jalankan dengan --offline.")
    run(ROOT / "ojs_extract_workflow.py", *(["--full"] if full else []))
    run(ROOT / "build_steps.py")
    run(ROOT / "wrangle.py")
    run(ROOT / "extract_issues.py")
else:
    print("Mode offline: memakai tabel yang sudah ada di folder clean dan out.")
run(HERE / "build_dashboard.py", *passthrough, cwd=HERE)
print("\nSelesai. Buka Monitoring_Dashboard.html di folder dashboard.")
