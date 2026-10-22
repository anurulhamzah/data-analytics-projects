"""Derive one row per submission with workflow milestones, step durations and responsible editors.

Reads ./out/{submissions,decisions}.csv, writes ./out/steps_per_submission.csv.

Milestones come only from labelled decisions. Two things are deliberately NOT interpreted:
  * decision code 1 / 19 (blank label in the API)
  * stage-1 'Decline Submission' on articles that were later published (owner: not a real rejection)
They are counted in qc_* columns so they stay visible, never used as a milestone.
"""
from pathlib import Path

import pandas as pd

OUT = Path(__file__).resolve().parent / "out"
s = pd.read_csv(OUT / "submissions.csv", parse_dates=["date_submitted", "date_published"])
d = pd.read_csv(OUT / "decisions.csv", parse_dates=["date_decided"])
d = d.sort_values(["submission_id", "date_decided", "decision_id"])

CODE = {"send_review": 3, "decline_s1": 8, "accept": 2, "revisions": 4, "resubmit": 5, "decline_review": 6,
        "send_prod": 7, "recommend_accept": 9}


def first(code, col="date_decided", stage=None):
    x = d[d.decision_code == code]
    if stage is not None:
        x = x[x.stage_id == stage]
    return x.groupby("submission_id").first()[["date_decided", "editor_id"]].rename(
        columns={"date_decided": f"t_{col}", "editor_id": f"editor_{col}"})


def last(code, col):
    x = d[d.decision_code == code]
    return x.groupby("submission_id").last()[["date_decided", "editor_id"]].rename(
        columns={"date_decided": f"t_{col}", "editor_id": f"editor_{col}"})


r = s[["submission_id", "status", "stage_id", "date_submitted", "date_published"]].set_index("submission_id")
parts = [
    first(3, "send_review"),
    first(4, "first_revisions"),
    last(4, "last_revisions"),
    last(5, "last_resubmit"),
    first(2, "accept"),
    d[(d.decision_code == 7)].groupby("submission_id").first()[["date_decided", "editor_id", "stage_id"]].rename(
        columns={"date_decided": "t_send_prod", "editor_id": "editor_send_prod", "stage_id": "stage_send_prod"}),
    d[(d.decision_code.isin([6, 8])) & (d.stage_id.isin([1, 3]))].groupby("submission_id").last()[
        ["date_decided", "editor_id", "stage_id", "decision_code"]].rename(
        columns={"date_decided": "t_decline", "editor_id": "editor_decline", "stage_id": "stage_decline",
                 "decision_code": "code_decline"}),
]
for p in parts:
    r = r.join(p)

r["n_revision_requests"] = d[d.decision_code == 4].groupby("submission_id").size().reindex(r.index).fillna(0).astype(int)
r["n_resubmits"] = d[d.decision_code == 5].groupby("submission_id").size().reindex(r.index).fillna(0).astype(int)
r["max_round"] = d.groupby("submission_id")["round"].max().reindex(r.index)
r["n_decisions"] = d.groupby("submission_id").size().reindex(r.index).fillna(0).astype(int)

# QC counters: kept visible, never used as milestones
r["qc_blank_label_decisions"] = d[d.decision_code.isin([1, 19])].groupby("submission_id").size().reindex(r.index).fillna(0).astype(int)
r["qc_s1_decline_but_published"] = (
    (r.status == "Published") & d[(d.decision_code == 8)].groupby("submission_id").size().reindex(r.index).fillna(0).gt(0)
)
r["qc_no_decisions"] = r.n_decisions == 0


def days(a, b):
    return (r[b] - r[a]).dt.total_seconds() / 86400


# published date has no time part: compare calendar days only
r["d_submit_to_send_review"] = days("date_submitted", "t_send_review")
r["d_submit_to_first_revisions"] = days("date_submitted", "t_first_revisions")
r["d_first_revisions_to_accept"] = days("t_first_revisions", "t_accept")
r["d_accept_to_send_prod"] = days("t_accept", "t_send_prod")
r["d_submit_to_send_prod"] = days("date_submitted", "t_send_prod")
r["d_send_prod_to_published"] = (r.date_published - r.t_send_prod.dt.normalize()).dt.days
r["d_submit_to_published"] = (r.date_published - r.date_submitted.dt.normalize()).dt.days
r["d_submit_to_decline"] = days("date_submitted", "t_decline")
# only meaningful for declined submissions
r.loc[r.status != "Declined", ["d_submit_to_decline"]] = pd.NA
r.loc[r.status != "Published", ["d_send_prod_to_published", "d_submit_to_published"]] = pd.NA
for c in [c for c in r.columns if c.startswith("d_") and c != "d_submit_to_decline"]:
    r.loc[r[c] < 0, c] = pd.NA  # negative = inconsistent dates, not a duration

r["submit_year"] = r.date_submitted.dt.year
r.reset_index().to_csv(OUT / "steps_per_submission.csv", index=False, encoding="utf-8-sig", date_format="%Y-%m-%d %H:%M:%S")
print(len(r), "rows ->", OUT / "steps_per_submission.csv")
