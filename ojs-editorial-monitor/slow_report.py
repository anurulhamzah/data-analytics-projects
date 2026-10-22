"""Per-step slow-submission list and per-editor summary (no minimum n).

Reads ./out/{steps_per_submission,submissions,users}.csv
Writes ./out/slow_steps.csv (every submission above P90 of its step, with responsible editor)
       ./out/editor_summary_all.csv (every editor, n shown, nothing hidden)
Scope: submitted 2019 or later (earlier years have no usable decision log).
"""
from pathlib import Path

import pandas as pd

OUT = Path(__file__).resolve().parent / "out"
r = pd.read_csv(OUT / "steps_per_submission.csv", parse_dates=["t_first_revisions", "t_send_prod", "t_decline"])
sub = pd.read_csv(OUT / "submissions.csv", usecols=["submission_id", "title"]).set_index("submission_id").title
u = pd.read_csv(OUT / "users.csv").set_index("user_id").username
r = r[r.submit_year >= 2019].copy()

# step -> (duration column, responsible-editor column, status filter)
STEPS = {
    "submit_to_first_revisions": ("d_submit_to_first_revisions", "editor_first_revisions", "Published"),
    "accept_to_send_prod": ("d_accept_to_send_prod", "editor_send_prod", "Published"),
    "send_prod_to_published": ("d_send_prod_to_published", "editor_send_prod", "Published"),
    "submit_to_published": ("d_submit_to_published", "editor_send_prod", "Published"),
    "submit_to_decline": ("d_submit_to_decline", "editor_decline", "Declined"),
}
slow, summ = [], []
for step, (dcol, ecol, st) in STEPS.items():
    x = r[(r.status == st)].dropna(subset=[dcol]).copy()
    p90 = x[dcol].quantile(0.9)
    x["step"], x["days"], x["p90_of_step"] = step, x[dcol], round(p90, 1)
    x["editor_id"] = x[ecol]
    slow.append(x[x[dcol] > p90][["step", "submission_id", "submit_year", "days", "p90_of_step", "editor_id"]])
    g = x.groupby(ecol, dropna=False)[dcol].agg(n="size", median="median", p75=lambda v: v.quantile(.75), max="max").reset_index()
    g.insert(0, "step", step)
    g = g.rename(columns={ecol: "editor_id"})
    summ.append(g)

slow = pd.concat(slow)
slow["editor_username"] = slow.editor_id.map(u)
slow["title"] = slow.submission_id.map(sub)
slow.sort_values(["step", "days"], ascending=[True, False]).round(1).to_csv(OUT / "slow_steps.csv", index=False, encoding="utf-8-sig")

summ = pd.concat(summ)
summ["editor_username"] = summ.editor_id.map(u)
summ.round(1).to_csv(OUT / "editor_summary_all.csv", index=False, encoding="utf-8-sig")

# naskah yang masih berjalan: lama sejak keputusan terakhir
q = pd.read_csv(OUT / "steps_per_submission.csv", parse_dates=["date_submitted"])
q = q[q.status == "Queued"]
print("slow_steps rows:", len(slow), "| editor_summary rows:", len(summ), "| queued:", len(q))
