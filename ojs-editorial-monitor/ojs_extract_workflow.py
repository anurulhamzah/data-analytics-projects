"""Extract the full editorial workflow of every submission from the OJS REST API.

Output (CSV, UTF-8 with BOM, in ./out):
  submissions, decisions, review_rounds, review_assignments, participants, files, users

Usage:
  set OJS_API_KEY=<key>        (never hardcode the key in this file)
  set OJS_BASE_URL=<api base>  (the journal's OJS REST API root, ending in /api/v1)
  python ojs_extract_workflow.py            # all submissions, resumes from ./raw cache
  python ojs_extract_workflow.py --limit 20 # quick test

Raw API responses are cached per submission in ./raw (contain personal data; keep local).
"""
import csv, json, os, sys, time
from pathlib import Path

import requests

BASE = os.environ.get("OJS_BASE_URL")  # e.g. https://your-journal.example/index.php/<journal>/api/v1
KEY = os.environ.get("OJS_API_KEY")
DELAY = 0.15
STAGES = (1, 3, 4, 5)
HERE = Path(__file__).resolve().parent
RAW, OUT = HERE / "raw", HERE / "out"

if not KEY or not BASE:
    sys.exit("Set the OJS_API_KEY and OJS_BASE_URL environment variables first.")

S = requests.Session()
S.headers.update({"Authorization": f"Bearer {KEY}", "Accept": "application/json"})


def get(path, **params):
    for attempt in range(4):
        try:
            r = S.get(BASE + path, params=params, timeout=40)
            if r.status_code == 404:
                return None
            r.raise_for_status()
            time.sleep(DELAY)
            return r.json()
        except requests.RequestException as e:
            if attempt == 3:
                print(f"  [FAIL] {path}: {type(e).__name__}", flush=True)
                return None
            time.sleep(1.5 * (attempt + 1))


def list_ids():
    """id -> (dateLastActivity, status) as OJS reports them now; used to decide what must be re-fetched."""
    items, off = {}, 0
    while True:
        d = get("/submissions", count=100, offset=off)
        if not d or not d.get("items"):
            break
        for x in d["items"]:
            items[x["id"]] = (x.get("dateLastActivity"), x.get("status"))
        off += 100
        if off >= d["itemsMax"]:
            break
    return items


REFETCHED = []


def fetch_raw(sid, now=None):
    f = RAW / f"{sid}.json"
    if f.exists() and "--full" not in sys.argv:
        cached = json.loads(f.read_text(encoding="utf-8"))
        cs = cached.get("submission") or {}
        # unchanged since the last extraction -> reuse the cache
        if now is None or (cs.get("dateLastActivity"), cs.get("status")) == now:
            return cached
    REFETCHED.append(sid)
    raw = {
        "submission": get(f"/submissions/{sid}"),
        "decisions": get(f"/submissions/{sid}/decisions") or [],
        "files": (get(f"/submissions/{sid}/files") or {}).get("items", []),
        "participants": {st: get(f"/submissions/{sid}/participants/{st}") or [] for st in STAGES},
    }
    f.write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
    return raw


def en(v):
    """Pick a string out of a {locale: text} dict."""
    if isinstance(v, dict):
        return v.get("en") or v.get("id") or next(iter(v.values()), "")
    return v if v is not None else ""


def write(name, header, rows):
    OUT.mkdir(exist_ok=True)
    with open(OUT / f"{name}.csv", "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        w.writerows(rows)
    print(f"  {name}.csv: {len(rows)} rows", flush=True)


def main():
    RAW.mkdir(exist_ok=True)
    items = list_ids()
    ids = list(items)
    if "--limit" in sys.argv:
        ids = ids[: int(sys.argv[sys.argv.index("--limit") + 1])]
    print(f"{len(ids)} submissions", flush=True)
    # (re-fetch count is printed after the loop)

    subs, decs, rounds, assigns, parts, files = [], [], [], [], [], []
    users = {}  # id -> (name, username, roles, disabled)
    for n, sid in enumerate(ids, 1):
        raw = fetch_raw(sid, items.get(sid))
        s = raw["submission"]
        if not s:
            continue
        pubs = s.get("publications") or []
        cur = next((p for p in pubs if p["id"] == s.get("currentPublicationId")), pubs[-1] if pubs else {})
        stage_files = {st["id"]: (st.get("files") or {}).get("count", "") for st in s.get("stages", [])}
        subs.append([
            sid, s.get("dateSubmitted"), s.get("dateLastActivity"), s.get("lastModified"),
            s.get("stageId"), s.get("status"), s.get("statusLabel"), s.get("submissionProgress"),
            s.get("locale"), cur.get("sectionId"), cur.get("datePublished"), cur.get("version"),
            cur.get("status"), (cur.get("doiObject") or {}).get("doi", ""),
            cur.get("fullTitle") and en(cur["fullTitle"]), cur.get("authorsString"),
            len(s.get("reviewRounds") or []), len(s.get("reviewAssignments") or []), len(raw["decisions"]),
            stage_files.get(1), stage_files.get(3), stage_files.get(4), stage_files.get(5),
        ])
        for d in raw["decisions"]:
            decs.append([sid, d["id"], d["dateDecided"], d["decision"], d.get("label", ""), en(d.get("description")),
                         d["stageId"], d.get("reviewRoundId"), d.get("round"), d.get("editorId")])
        for r in s.get("reviewRounds") or []:
            rounds.append([sid, r["id"], r["round"], r["stageId"], r["statusId"], r.get("status")])
        for a in s.get("reviewAssignments") or []:
            assigns.append([sid, a["id"], a.get("roundId"), a.get("round"), a.get("statusId"), a.get("status"),
                            a.get("responseDue"), a.get("due")])
        for st, plist in raw["participants"].items():
            for u in plist:
                roles = "; ".join(sorted({en(g["name"]) for g in u.get("groups", [])}))
                users[u["id"]] = (u.get("fullName"), u.get("userName"), roles, u.get("disabled"))
                parts.append([sid, int(st), u["id"], roles])
        for f in raw["files"]:
            files.append([sid, f["id"], f.get("fileStage"), f.get("documentType"), en(f.get("genreName")), f.get("mimetype"),
                          f.get("createdAt"), f.get("updatedAt"), f.get("uploaderUserId"), f.get("uploaderUserName")])
        if n % 50 == 0:
            print(f"  {n}/{len(ids)}", flush=True)

    print(f"  fetched from OJS this run: {len(REFETCHED)} submissions (new or changed); the rest came from the local cache", flush=True)
    # editors / uploaders that never appeared as stage participants
    need = {d[9] for d in decs if d[9]} | {f[8] for f in files if f[8]}
    for uid in sorted(need - users.keys()):
        u = get(f"/users/{uid}")
        if u:
            users[uid] = (u.get("fullName"), u.get("userName"),
                          "; ".join(sorted({en(g["name"]) for g in u.get("groups", [])})), u.get("disabled"))

    write("submissions", ["submission_id", "date_submitted", "date_last_activity", "last_modified", "stage_id", "status_id",
                          "status", "submission_progress", "locale", "section_id", "date_published", "pub_version",
                          "pub_status", "doi", "title", "authors", "n_review_rounds", "n_review_assignments", "n_decisions",
                          "files_stage1", "files_stage3", "files_stage4", "files_stage5"], subs)
    write("decisions", ["submission_id", "decision_id", "date_decided", "decision_code", "label", "description", "stage_id",
                        "review_round_id", "round", "editor_id"], decs)
    write("review_rounds", ["submission_id", "round_id", "round", "stage_id", "status_id", "status"], rounds)
    write("review_assignments", ["submission_id", "assignment_id", "round_id", "round", "status_id", "status",
                                 "response_due", "due"], assigns)
    write("participants", ["submission_id", "stage_id", "user_id", "roles_of_user"], parts)
    write("files", ["submission_id", "file_id", "file_stage", "document_type", "genre", "mimetype", "created_at", "updated_at",
                    "uploader_user_id", "uploader_username"], files)
    write("users", ["user_id", "full_name", "username", "roles", "disabled"],
          [[k, *v] for k, v in sorted(users.items())])


if __name__ == "__main__":
    main()
