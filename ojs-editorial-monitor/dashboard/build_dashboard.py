"""Build the monitoring dashboard from the cleaned tables.

Reads  : ../clean/*.csv, ../out/issues.csv, ../out/submission_issue.csv
Writes : dashboard_data.json            (the dataset; can also be loaded in the browser via 'Muat data baru')
         Monitoring_Dashboard.html (self-contained: template + data embedded; opens offline)

Options:
  --as-of YYYY-MM-DD   reference date for ageing (default: date of ../out/submissions.csv)
  --target 180         default target in days (6 months); adjustable in the dashboard
  --no-titles          leave manuscript titles out of the file
  --with-names         include editor usernames (default: pseudonymous keys E01.. only)
  --public             board version: writes public/index.html (+ data) with NO titles and NO editor names
  --journal-name X    journal name shown in the title (default: none)
  --hide-editors       remove every editor key and hide the "Beban editor" tab (use with --public if wanted)
"""
import argparse
import html as htmllib
import json
import re
from datetime import datetime
from pathlib import Path

import pandas as pd

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
CLEAN, OUT = ROOT / "clean", ROOT / "out"

ap = argparse.ArgumentParser()
ap.add_argument("--as-of")
ap.add_argument("--target", type=int, default=180)
ap.add_argument("--no-titles", action="store_true")
ap.add_argument("--with-names", action="store_true")
ap.add_argument("--public", action="store_true")
ap.add_argument("--hide-editors", action="store_true")
ap.add_argument("--journal-name", default="")
a = ap.parse_args()
if a.public:
    a.no_titles, a.with_names = True, False

fs = pd.read_csv(CLEAN / "fact_submission.csv", parse_dates=["date_submitted", "date_last_activity", "date_published"])
fd = pd.read_csv(CLEAN / "fact_decision.csv", parse_dates=["date_decided"])
fr = pd.read_csv(CLEAN / "fact_review_assignment.csv")
tx = pd.read_csv(CLEAN / "dim_submission_text.csv")
du = pd.read_csv(CLEAN / "dim_user.csv")
iss = pd.read_csv(OUT / "issues.csv", parse_dates=["date_published"])
si = pd.read_csv(OUT / "submission_issue.csv").merge(iss, on="issue_id").sort_values("date_published").drop_duplicates("submission_id", keep="last")
si["label"] = si.volume.astype(int).astype(str) + "." + si.number.fillna(0).astype(int).astype(str)
as_of = a.as_of or datetime.fromtimestamp((OUT / "submissions.csv").stat().st_mtime).strftime("%Y-%m-%d")

EV = {"send_for_review": "SR", "request_revisions": "RV", "resubmit_for_review": "RS", "accept_submission": "AC",
      "send_to_production": "SP", "decline_submission_screening": "DS", "decline_submission_review": "DR"}
fd = fd[fd.event_name.isin(EV) & ~fd.qc_flag.fillna("").str.contains("screening_decline_on_published")].copy()
fd["code"] = fd.event_name.map(EV)
last = fd.sort_values(["submission_id", "date_decided", "decision_id"]).groupby("submission_id").tail(1).set_index("submission_id")

s = fs.merge(tx[["submission_id", "title"]], on="submission_id", how="left").merge(si[["submission_id", "label", "year"]].rename(columns={"label": "issue", "year": "issue_year"}), on="submission_id", how="left")
D = lambda x: None if pd.isna(x) else x.strftime("%Y-%m-%d")
N = lambda x: None if pd.isna(x) else (int(x) if float(x).is_integer() else round(float(x), 1))
S = lambda x: None if pd.isna(x) else str(x)
ST = {"published": "P", "declined": "D", "in_progress": "Q"}
# OJS stores each issue's front/back matter as submissions. They are not articles and are flagged (na=1).
NON_ARTICLE = re.compile(r"^(front|back)[\s-]*matter$", re.I)
clean_title = lambda t: None if pd.isna(t) else re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", htmllib.unescape(str(t)))).strip()

rows = []
for r in s.itertuples(index=False):
    lr = last.loc[r.submission_id] if r.submission_id in last.index else None
    title = clean_title(r.title)
    flags = "".join(c for c, on in (("n", r.qc_no_decisions), ("w", r.qc_published_without_date), ("o", r.qc_order_violation), ("s", r.qc_screening_decline_but_published), ("b", r.qc_blank_label_decision)) if bool(on))
    rows.append({
        "id": int(r.submission_id), "t": None if a.no_titles else title, "na": int(bool(title and NON_ARTICLE.match(title))), "y": int(r.submit_year), "sd": D(r.date_submitted),
        "st": ST[r.outcome], "sg": N(r.stage_id), "pd": D(r.date_published), "is": S(r.issue), "iy": N(r.issue_year),
        "d": N(r.d_submit_to_published), "sc": int(bool(r.scope_duration_published)),
        "d1": N(r.d_submit_to_first_revisions), "d2": N(r.d_accept_to_send_prod), "d3": N(r.d_send_prod_to_published), "dp": N(r.d_submit_to_send_prod),
        "dd": N(r.d_submit_to_decline), "ds": N(r.stage_decline), "nr": int(r.n_revision_requests),
        "e1": S(r.editor_key_first_revisions), "ep": S(r.editor_key_send_prod), "ed": S(r.editor_key_decline),
        "ld": D(lr.date_decided) if lr is not None else None, "le": S(lr.code) if lr is not None else None, "lk": S(lr.editor_key) if lr is not None else None,
        "la": D(r.date_last_activity), "q": flags,
    })

decisions = [[int(x.submission_id), D(x.date_decided), x.code, S(x.editor_key)] for x in fd.itertuples(index=False)]
reviews = [[int(x.submit_year), S(x.status_name)] for x in fr.itertuples(index=False)]
issues = [{"id": int(x.issue_id), "l": f"{int(x.volume)}.{int(x.number) if pd.notna(x.number) else 0}", "y": int(x.year), "d": D(x.date_published)} for x in iss.itertuples(index=False)]
ed_keys = sorted({d[3] for d in decisions if d[3]} | {r["e1"] for r in rows if r["e1"]})
du = du.set_index("user_key")
editors = {k: {"roles": S(du.loc[k, "roles"]) if k in du.index else None, **({"name": S(du.loc[k, "username"]) if k in du.index else None} if a.with_names else {})} for k in ed_keys}

if a.hide_editors:
    for r in rows:
        r["e1"] = r["ep"] = r["ed"] = r["lk"] = None
    decisions = [[d[0], d[1], d[2], None] for d in decisions]
    editors = {}

data = {
    "meta": {"schema": 1, "generated": datetime.now().strftime("%Y-%m-%d %H:%M"), "as_of": as_of, "source": "OJS (REST API, akses baca)",
             "target_days": a.target, "titles": not a.no_titles, "names": a.with_names, "n_submissions": len(rows), "n_non_article": sum(r["na"] for r in rows), "public": a.public, "hide_editors": a.hide_editors, "journal": a.journal_name},
    "submissions": rows, "decisions": decisions, "reviews": reviews, "issues": issues, "editors": editors,
}
OUTDIR = HERE / "public" if a.public else HERE
OUTDIR.mkdir(exist_ok=True)
(OUTDIR / "dashboard_data.json").write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
print("bukan artikel (front/back matter):", sum(r["na"] for r in rows))
print("dashboard_data.json:", len(rows), "submissions,", len(decisions), "decisions,", len(reviews), "reviews,", len(issues), "issues |", round((OUTDIR / "dashboard_data.json").stat().st_size / 1024), "KB", "->", OUTDIR)

tpl = HERE / "dashboard_template.html"
if tpl.exists():
    html = tpl.read_text(encoding="utf-8").replace("/*__DATA__*/null", json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/"))
    name = "index.html" if a.public else "Monitoring_Dashboard.html"
    (OUTDIR / name).write_text(html, encoding="utf-8")
    print(name, "written in", OUTDIR)
else:
    print("(template not found yet: only the JSON was written)")
