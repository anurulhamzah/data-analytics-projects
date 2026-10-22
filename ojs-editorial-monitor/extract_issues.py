"""Map published submissions to their issue (edisi) via the OJS REST API (read-only).

Needs OJS_API_KEY and OJS_BASE_URL in the environment. Writes ./out/issues.csv and ./out/submission_issue.csv.
"""
import csv
import os
import sys
import time
from pathlib import Path

import requests

BASE = os.environ.get("OJS_BASE_URL")  # e.g. https://your-journal.example/index.php/<journal>/api/v1
KEY = os.environ.get("OJS_API_KEY")
if not KEY or not BASE:
    sys.exit("Set OJS_API_KEY and OJS_BASE_URL first.")
OUT = Path(__file__).resolve().parent / "out"
S = requests.Session()
S.headers.update({"Authorization": f"Bearer {KEY}", "Accept": "application/json"})


def get(path, **params):
    for attempt in range(4):
        try:
            r = S.get(BASE + path, params=params, timeout=40)
            r.raise_for_status()
            time.sleep(0.15)
            return r.json()
        except requests.RequestException as e:
            if attempt == 3:
                print(f"[FAIL] {path} {params}: {type(e).__name__}", flush=True)
                return None
            time.sleep(1.5 * (attempt + 1))


issues, off = [], 0
while True:
    d = get("/issues", count=100, offset=off, isPublished="true")
    if not d or not d.get("items"):
        break
    issues += d["items"]
    off += 100
    if off >= d["itemsMax"]:
        break
print("issues:", len(issues), flush=True)

pairs = []
for it in issues:
    sub_off = 0
    while True:
        d = get("/submissions", issueIds=[it["id"]], status=3, count=100, offset=sub_off)
        if not d or not d.get("items"):
            break
        pairs += [(x["id"], it["id"]) for x in d["items"]]
        sub_off += 100
        if sub_off >= d["itemsMax"]:
            break

with open(OUT / "issues.csv", "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.writer(fh)
    w.writerow(["issue_id", "volume", "number", "year", "date_published", "identification"])
    for it in issues:
        w.writerow([it["id"], it.get("volume"), it.get("number"), it.get("year"), it.get("datePublished"), it.get("identification")])
with open(OUT / "submission_issue.csv", "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.writer(fh)
    w.writerow(["submission_id", "issue_id"])
    w.writerows(pairs)
print("pairs:", len(pairs), "unique submissions:", len({p[0] for p in pairs}))
