"""Data wrangling: raw OJS extract (./out) -> analysis-ready tables (./clean).

Design
  * fact_* tables carry pseudonymous keys (E01.. editors, U001.. others) and no names/emails/titles,
    so they can be shared. dim_user (names) and dim_submission_text (title/authors/DOI) stay local.
  * Nothing ambiguous is interpreted: blank-label decision codes and stage-1 'Decline' on published
    articles are kept and flagged (qc_flag), never used as milestones.
  * All timestamps are naive server time as returned by OJS. date_published is date-only.
Run: python wrangle.py   ->  ./clean/*.csv + qc_report.md + data_dictionary.csv
"""
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
IN, OUT = HERE / "out", HERE / "clean"
OUT.mkdir(exist_ok=True)
rd = lambda n, **k: pd.read_csv(IN / f"{n}.csv", **k)

sub = rd("submissions", parse_dates=["date_submitted", "date_last_activity", "last_modified", "date_published"])
dec = rd("decisions", parse_dates=["date_decided"])
rr = rd("review_rounds")
ra = rd("review_assignments", parse_dates=["response_due", "due"])
par = rd("participants")
fil = rd("files", parse_dates=["created_at", "updated_at"])
usr = rd("users")
stp = rd("steps_per_submission", parse_dates=["date_submitted", "date_published", "t_send_review", "t_first_revisions",
                                              "t_last_revisions", "t_last_resubmit", "t_accept", "t_send_prod", "t_decline"])
qc = []  # (check, value)


def note(k, v):
    qc.append((k, v))


# ---------------------------------------------------------------- dimensions
STAFF_RE = "Journal editor|Journal manager|Section editor|Copyeditor|Production editor"
usr["is_editorial_staff"] = usr.roles.fillna("").str.contains(STAFF_RE)
ed_ids = dec.groupby("editor_id").size().sort_values(ascending=False).index.tolist()
key = {uid: f"E{i:02d}" for i, uid in enumerate(ed_ids, 1)}
others = sorted((set(usr.user_id) | set(fil.uploader_user_id.dropna().astype(int))) - set(key))
key.update({uid: f"U{i:03d}" for i, uid in enumerate(others, 1)})
usr = pd.concat([usr, pd.DataFrame({"user_id": [i for i in key if i not in set(usr.user_id)]})], ignore_index=True)
usr["user_key"] = usr.user_id.map(key)
usr["is_decision_maker"] = usr.user_id.isin(ed_ids)
usr["in_user_list"] = usr.username.notna()
usr[["user_key", "user_id", "username", "full_name", "roles", "disabled", "is_editorial_staff", "is_decision_maker",
     "in_user_list"]].sort_values("user_key").to_csv(OUT / "dim_user.csv", index=False, encoding="utf-8-sig")
note("decision-making accounts", len(ed_ids))
note("decision-making accounts missing from user list", int((~usr[usr.is_decision_maker].in_user_list).sum()))

CODES = {  # code: (event_name, category, is_milestone, status)
    3: ("send_for_review", "routing", True, "labelled"),
    2: ("accept_submission", "editor_decision", True, "labelled"),
    4: ("request_revisions", "editor_decision", True, "labelled"),
    5: ("resubmit_for_review", "editor_decision", True, "labelled"),
    14: ("new_review_round", "routing", False, "labelled"),
    7: ("send_to_production", "editor_decision", True, "labelled"),
    8: ("decline_submission_screening", "decline", False, "decline_meaning_unresolved_when_article_published"),
    6: ("decline_submission_review", "decline", False, "labelled"),
    9: ("recommend_accept", "recommendation", False, "labelled"),
    10: ("recommend_revisions", "recommendation", False, "labelled"),
    11: ("recommend_resubmit", "recommendation", False, "labelled"),
    12: ("recommend_decline", "recommendation", False, "labelled"),
    29: ("back_to_copyediting", "routing", False, "labelled"),
    30: ("cancel_copyediting", "routing", False, "labelled"),
    1: ("unlabeled_code_1", "unlabeled", False, "meaning_unconfirmed"),
    19: ("unlabeled_code_19", "unlabeled", False, "meaning_unconfirmed"),
}
pd.DataFrame([(c, *v) for c, v in CODES.items()],
             columns=["decision_code", "event_name", "category", "is_milestone", "label_status"]).to_csv(
    OUT / "dim_decision_code.csv", index=False)
unk = set(dec.decision_code) - set(CODES)
note("decision codes not in dictionary", sorted(unk))

FILE_STAGE = {2: "submission", 4: "review", 6: "final_draft", 9: "copyedit", 10: "proof", 11: "production_ready",
              13: "attachment", 15: "review_revision"}  # OJS 3.x constants, verified only against genre content
pd.DataFrame(list(FILE_STAGE.items()), columns=["file_stage", "file_stage_name"]).to_csv(OUT / "dim_file_stage.csv", index=False)
REV_STATUS = {4: ("response_overdue", True), 6: ("review_overdue", True), 7: ("submitted", False),
              8: ("completed", False), 9: ("completed_thanked", False)}

# ---------------------------------------------------------------- submission text (local only)
t = sub[["submission_id", "title", "authors", "doi"]].copy()
for c in ("title", "authors"):
    t[c] = t[c].str.replace(r"\s+", " ", regex=True).str.strip()
note("titles with stray whitespace fixed", int((sub.title.fillna("") != t.title.fillna("")).sum()))
note("authors containing U+FFFD (encoding loss at source)", int(t.authors.fillna("").str.contains("�").sum()))
t.to_csv(OUT / "dim_submission_text.csv", index=False, encoding="utf-8-sig")

# ---------------------------------------------------------------- fact_decision
dec = dec.sort_values(["submission_id", "date_decided", "decision_id"]).reset_index(drop=True)
dec = dec.merge(pd.DataFrame([(c, *v) for c, v in CODES.items()],
                             columns=["decision_code", "event_name", "category", "is_milestone", "label_status"]), on="decision_code", how="left")
dec = dec.merge(sub[["submission_id", "status", "date_submitted"]], on="submission_id")
dec["seq"] = dec.groupby("submission_id").cumcount() + 1
dec["days_since_submit"] = (dec.date_decided - dec.date_submitted).dt.total_seconds() / 86400
dec["days_since_prev"] = dec.groupby("submission_id").date_decided.diff().dt.total_seconds() / 86400
dec["same_ts_as_other"] = dec.duplicated(["submission_id", "date_decided"], keep=False)
dec["qc_flag"] = ""
m = (dec.decision_code == 8) & (dec.status == "Published")
dec.loc[m, "qc_flag"] = "screening_decline_on_published_article"
dec.loc[dec.category == "unlabeled", "qc_flag"] = "unlabeled_code"
dec.loc[(dec.qc_flag != "") & (dec.days_since_submit < 1), "qc_flag"] += "|logged_within_1d_of_submit"

# author response time after each Request Revisions: first review_revision upload by a non-editorial uploader
upl = fil[fil.file_stage == 15].merge(usr[["user_id", "is_editorial_staff"]], left_on="uploader_user_id", right_on="user_id", how="left")
upl = upl[upl.is_editorial_staff != True][["submission_id", "created_at"]].sort_values("created_at")
rv = dec[dec.decision_code == 4][["submission_id", "decision_id", "date_decided"]].copy()
nxt = dec.groupby("submission_id").date_decided.shift(-1)
rv["next_decision_ts"] = nxt[rv.index]
mg = pd.merge_asof(rv.sort_values("date_decided"), upl.rename(columns={"created_at": "revision_upload_ts"}),
                   left_on="date_decided", right_on="revision_upload_ts", by="submission_id", direction="forward")
mg = mg.set_index("decision_id")
dec["revision_upload_ts"] = dec.decision_id.map(mg.revision_upload_ts)
dec["author_revision_days"] = (dec.revision_upload_ts - dec.date_decided).dt.total_seconds() / 86400
note("Request Revisions decisions with a matched author revision upload", f"{dec.revision_upload_ts.notna().sum()} / {(dec.decision_code == 4).sum()}")
dec["editor_key"] = dec.editor_id.map(key)
fd = dec[["submission_id", "decision_id", "seq", "date_decided", "decision_code", "event_name", "category", "is_milestone",
          "label_status", "stage_id", "review_round_id", "round", "editor_key", "days_since_submit", "days_since_prev",
          "same_ts_as_other", "qc_flag", "revision_upload_ts", "author_revision_days"]]
fd.round(3).to_csv(OUT / "fact_decision.csv", index=False, encoding="utf-8-sig")
note("decisions logged with identical timestamp as another decision", int(dec.same_ts_as_other.sum()))

# ---------------------------------------------------------------- fact_submission
s = sub[["submission_id", "date_submitted", "date_last_activity", "stage_id", "status", "pub_status", "section_id", "date_published",
         "n_review_rounds", "n_review_assignments", "files_stage1", "files_stage3", "files_stage4", "files_stage5"]].copy()
s["submit_year"] = s.date_submitted.dt.year
s["outcome"] = s.status.map({"Published": "published", "Declined": "declined", "Queued": "in_progress"})
s["n_authors_approx"] = t.authors.fillna("").map(lambda a: 0 if not a else a.count(",") + 1)
# OJS stores each issue's front/back matter as submissions; they are not articles
s["is_non_article"] = s.submission_id.map(t.set_index("submission_id").title.fillna("").str.strip().str.match(r"^(front|back)[\s-]*matter$", case=False)).fillna(False).astype(bool)
note("non-article items (front/back matter) flagged", int(s.is_non_article.sum()))
s["era"] = pd.cut(s.submit_year, [0, 2018, 2024, 9999], labels=["legacy_2010_2018", "partial_2019_2024", "full_2025_plus"]).astype(str)
keep = ["submission_id", "t_send_review", "t_first_revisions", "t_last_revisions", "t_last_resubmit", "t_accept", "t_send_prod",
        "t_decline", "stage_send_prod", "code_decline", "stage_decline", "n_revision_requests", "n_resubmits", "n_decisions",
        "d_submit_to_send_review", "d_submit_to_first_revisions", "d_first_revisions_to_accept", "d_accept_to_send_prod",
        "d_submit_to_send_prod", "d_send_prod_to_published", "d_submit_to_published", "d_submit_to_decline"]
s = s.merge(stp[keep], on="submission_id", how="left")
for c, k in (("editor_first_revisions", "editor_first_revisions"), ("editor_send_prod", "editor_send_prod"), ("editor_decline", "editor_decline")):
    s[c.replace("editor_", "editor_key_")] = stp.set_index("submission_id")[k].map(key).reindex(s.submission_id).values
s["has_published_date"] = s.date_published.notna()
s["qc_no_decisions"] = s.n_decisions == 0
s["qc_published_without_date"] = (s.outcome == "published") & ~s.has_published_date
s["qc_screening_decline_but_published"] = s.submission_id.isin(dec[m].submission_id)
s["qc_blank_label_decision"] = s.submission_id.isin(dec[dec.category == "unlabeled"].submission_id)
# milestone order sanity (violations are flagged, not repaired)
s["qc_order_violation"] = ((s.t_send_prod < s.t_first_revisions) | (s.t_accept < s.t_first_revisions)
                           | (s.t_send_prod < s.t_accept) | (s.date_published < s.t_send_prod.dt.normalize()))
s["scope_duration_published"] = (s.outcome == "published") & (s.submit_year >= 2019) & s.t_send_prod.notna() & s.has_published_date
s["scope_duration_declined"] = (s.outcome == "declined") & (s.submit_year >= 2019) & s.d_submit_to_decline.notna()
s["scope_in_progress"] = s.outcome == "in_progress"
fs = s.drop(columns=["status"])
fs.round(3).to_csv(OUT / "fact_submission.csv", index=False, encoding="utf-8-sig")
for c in ("qc_no_decisions", "qc_published_without_date", "qc_screening_decline_but_published", "qc_blank_label_decision",
          "qc_order_violation", "scope_duration_published", "scope_duration_declined", "scope_in_progress"):
    note(c, int(s[c].sum()))
note("published submissions with no date_published AND no decisions", int((s.qc_published_without_date & s.qc_no_decisions).sum()))

# ---------------------------------------------------------------- fact_review_assignment
ra["status_name"] = ra.status_id.map(lambda x: REV_STATUS.get(x, ("unknown", None))[0])
ra["is_overdue_status"] = ra.status_id.map(lambda x: REV_STATUS.get(x, ("unknown", None))[1])
ra["response_to_due_days"] = (ra.due - ra.response_due).dt.days
ra = ra.merge(sub[["submission_id", "date_submitted"]], on="submission_id")
ra["submit_year"] = ra.date_submitted.dt.year
ra.drop(columns=["status", "date_submitted"]).to_csv(OUT / "fact_review_assignment.csv", index=False, encoding="utf-8-sig")
note("review assignments / review rounds / submissions with any assignment", f"{len(ra)} / {len(rr)} / {ra.submission_id.nunique()}")
note("review-assignment coverage: submissions 2019+ with >=1 assignment", f"{ra[ra.submit_year >= 2019].submission_id.nunique()} of {(sub.date_submitted.dt.year >= 2019).sum()}")
rr.to_csv(OUT / "fact_review_round.csv", index=False)

# ---------------------------------------------------------------- fact_file
fil["file_stage_name"] = fil.file_stage.map(FILE_STAGE).fillna("other")
fil["uploader_key"] = fil.uploader_user_id.map(lambda x: key.get(int(x)) if pd.notna(x) else None)
fil = fil.merge(usr[["user_id", "is_editorial_staff"]], left_on="uploader_user_id", right_on="user_id", how="left")
fil["uploader_is_editorial_staff"] = fil.is_editorial_staff
fil["hours_created_to_updated"] = (fil.updated_at - fil.created_at).dt.total_seconds() / 3600
fil[["submission_id", "file_id", "file_stage", "file_stage_name", "document_type", "genre", "mimetype", "created_at", "updated_at",
     "uploader_key", "uploader_is_editorial_staff", "hours_created_to_updated"]].round(2).to_csv(
    OUT / "fact_file.csv", index=False, encoding="utf-8-sig")
note("files without uploader", int(fil.uploader_user_id.isna().sum()))

# ---------------------------------------------------------------- submission-level assignment (participants)
# /participants/{stage} returned the same people for stages 1,3,4 -> collapse; stage 5 kept separately
pp = par.drop_duplicates(["submission_id", "user_id", "stage_id"]).copy()
same = pp[pp.stage_id.isin([1, 3, 4])].groupby("submission_id").user_id.apply(frozenset)
note("participants identical across stages 1/3/4 (share of submissions)",
     round(float(np.mean([pp[(pp.submission_id == i) & (pp.stage_id == 1)].user_id.nunique() ==
                          pp[(pp.submission_id == i) & (pp.stage_id == 3)].user_id.nunique() for i in sub.submission_id[:200]])), 3))
pp["user_key"] = pp.user_id.map(key)
pp[["submission_id", "stage_id", "user_key", "roles_of_user"]].to_csv(OUT / "fact_participant.csv", index=False, encoding="utf-8-sig")

# ---------------------------------------------------------------- fact_event (long, for timelines)
ev = [
    sub[["submission_id", "date_submitted"]].rename(columns={"date_submitted": "event_ts"}).assign(event="submitted", actor_key=None, qc_flag=""),
    fd[fd.event_name.notna()][["submission_id", "date_decided", "event_name", "editor_key", "qc_flag"]].rename(
        columns={"date_decided": "event_ts", "event_name": "event", "editor_key": "actor_key"}),
    fil[["submission_id", "created_at", "file_stage_name", "uploader_key"]].assign(event=lambda x: "file_" + x.file_stage_name, qc_flag="")
    .rename(columns={"created_at": "event_ts", "uploader_key": "actor_key"})[["submission_id", "event_ts", "event", "actor_key", "qc_flag"]],
    sub[sub.date_published.notna()][["submission_id", "date_published"]].rename(columns={"date_published": "event_ts"}).assign(
        event="published", actor_key=None, qc_flag=""),
]
fe = pd.concat(ev, ignore_index=True).sort_values(["submission_id", "event_ts"])
fe.to_csv(OUT / "fact_event.csv", index=False, encoding="utf-8-sig")
note("fact_event rows", len(fe))

# ---------------------------------------------------------------- report
with open(OUT / "qc_report.md", "w", encoding="utf-8") as fh:
    fh.write("# QC report (generated by wrangle.py)\n\n| check | value |\n|---|---|\n")
    for k, v in qc:
        fh.write(f"| {k} | {v} |\n")
for k, v in qc:
    print(f"{k}: {v}")
print("\ntables:", sorted(p.name for p in OUT.glob("*.csv")))
