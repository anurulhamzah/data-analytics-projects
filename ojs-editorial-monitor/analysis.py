"""Analysis of the editorial workflow (RQ11, 1-2, 3-5, 6, 7, 8, 10). Reads ./clean, writes ./analysis/*.csv and prints results."""
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from scipy import stats

HERE = Path(__file__).resolve().parent
CLEAN, A = HERE / "clean", HERE / "analysis"
A.mkdir(exist_ok=True)
fs = pd.read_csv(CLEAN / "fact_submission.csv", parse_dates=["date_submitted", "t_first_revisions", "t_accept", "t_send_prod",
                                                         "t_decline", "date_published", "t_send_review"])
fd = pd.read_csv(CLEAN / "fact_decision.csv", parse_dates=["date_decided"])
ra = pd.read_csv(CLEAN / "fact_review_assignment.csv")
# articles only: OJS front/back matter items are flagged in wrangle.py and excluded here
fs = fs[~fs.is_non_article].copy()
fd = fd[fd.submission_id.isin(fs.submission_id)].copy()
ra = ra[ra.submission_id.isin(fs.submission_id)].copy()
rng = np.random.default_rng(42)
pd.set_option("display.width", 200); pd.set_option("display.max_columns", 30)


def boot_median(v, n=2000):
    v = np.asarray(v.dropna(), float)
    if len(v) < 3:
        return (np.nan, np.nan)
    m = [np.median(rng.choice(v, len(v))) for _ in range(n)]
    return tuple(np.percentile(m, [2.5, 97.5]).round(0))


def summ(v):
    v = v.dropna()
    lo, hi = boot_median(v)
    return pd.Series({"n": len(v), "median": v.median(), "ci95_lo": lo, "ci95_hi": hi, "p25": v.quantile(.25), "p75": v.quantile(.75)})


def section(t):
    print("\n" + "=" * 8, t)


# ---- RQ11 data completeness -------------------------------------------------------------
section("RQ11 kelengkapan pencatatan, naskah terbit per tahun submit")
p = fs[fs.outcome == "published"]
rq11 = p.groupby("submit_year").agg(n=("submission_id", "size"),
                                    ada_keputusan=("qc_no_decisions", lambda v: (~v).sum()),
                                    ada_revisi=("t_first_revisions", "count"), ada_accept=("t_accept", "count"),
                                    ada_send_prod=("t_send_prod", "count"), ada_tgl_terbit=("has_published_date", "sum"),
                                    lengkap_utk_durasi=("scope_duration_published", "sum"))
rq11["pct_lengkap"] = (rq11.lengkap_utk_durasi / rq11.n * 100).round(0)
print(rq11)
rq11.to_csv(A / "rq11_completeness.csv")

# ---- RQ1 durations by period --------------------------------------------------------------
section("RQ1 durasi per fase, naskah terbit disubmit 2019+, per periode submit")
ps = fs[fs.scope_duration_published].copy()
ps["period"] = pd.cut(ps.submit_year, [2018, 2020, 2022, 2024, 2026], labels=["2019-20", "2021-22", "2023-24", "2025-26"])
cols = {"d_submit_to_first_revisions": "submit->revisi1", "d_accept_to_send_prod": "accept->send_prod",
        "d_submit_to_send_prod": "submit->send_prod", "d_send_prod_to_published": "send_prod->terbit",
        "d_submit_to_published": "submit->terbit"}
rows = []
for c, nm in cols.items():
    for per, g in ps.groupby("period", observed=True):
        rows.append({"fase": nm, "periode": per, **summ(g[c]).to_dict()})
    rows.append({"fase": nm, "periode": "ALL", **summ(ps[c]).to_dict()})
rq1 = pd.DataFrame(rows)
print(rq1.pivot(index="fase", columns="periode", values="median").round(0))
print(rq1[rq1.periode == "ALL"].round(0).to_string(index=False))
rq1.round(1).to_csv(A / "rq1_phase_durations.csv", index=False)
for c, nm in cols.items():
    x = ps.dropna(subset=[c]); rho, pv = stats.spearmanr(x.date_submitted.astype("int64"), x[c])
    print(f"  tren {nm}: Spearman rho={rho:.2f} p={pv:.3f} (n={len(x)})")

# ---- RQ2 share of total time ---------------------------------------------------------------
section("RQ2 komposisi waktu (naskah dengan 3 segmen lengkap)")
x = fs[fs.scope_duration_published].dropna(subset=["d_submit_to_first_revisions", "d_send_prod_to_published"]).copy()
x["seg_review"] = x.d_submit_to_first_revisions
x["seg_revise_to_prod"] = (x.t_send_prod - x.t_first_revisions).dt.total_seconds() / 86400
x["seg_production"] = x.d_send_prod_to_published
x = x[(x.seg_revise_to_prod >= 0)]
tot = x.seg_review + x.seg_revise_to_prod + x.seg_production
comp = pd.DataFrame({"median_hari": [x.seg_review.median(), x.seg_revise_to_prod.median(), x.seg_production.median()],
                     "rata2_porsi_%": [(x.seg_review / tot).mean() * 100, (x.seg_revise_to_prod / tot).mean() * 100, (x.seg_production / tot).mean() * 100]},
                    index=["submit->revisi1 (screening+review)", "revisi1->send_prod (revisi+copyedit)", "send_prod->terbit (production)"]).round(1)
print(comp, "\nn =", len(x)); comp.to_csv(A / "rq2_composition.csv")

# ---- RQ3/5 editor concentration & slow cases ---------------------------------------------------
section("RQ3/5 beban dan naskah lambat per editor (submit->revisi1; P90)")
e = fs[fs.scope_duration_published].dropna(subset=["d_submit_to_first_revisions"])
p90 = e.d_submit_to_first_revisions.quantile(.9)
t = e.groupby("editor_key_first_revisions").agg(n=("submission_id", "size"), median=("d_submit_to_first_revisions", "median"),
                                              lambat=("d_submit_to_first_revisions", lambda v: (v > p90).sum()))
t["pct_lambat"] = (t.lambat / t.n * 100).round(0)
print(f"P90={p90:.0f} hari\n", t.sort_values("n", ascending=False).round(0))
main = e.editor_key_first_revisions == "E01"
u = stats.mannwhitneyu(e[main].d_submit_to_first_revisions, e[~main].d_submit_to_first_revisions)
print(f"E01 vs lainnya: median {e[main].d_submit_to_first_revisions.median():.0f} vs {e[~main].d_submit_to_first_revisions.median():.0f}, Mann-Whitney p={u.pvalue:.4f}")
by_year = e.groupby(["submit_year", main.rename("E01")]).size().unstack(fill_value=0)
print("E01 vs lain per tahun submit:\n", by_year.T)
# E01 vs others WITHIN the same submit year (control for period)
w = []
for yr, g in e.groupby("submit_year"):
    a, b = g[g.editor_key_first_revisions == "E01"].d_submit_to_first_revisions, g[g.editor_key_first_revisions != "E01"].d_submit_to_first_revisions
    w.append((yr, len(a), a.median(), len(b), b.median() if len(b) else np.nan))
print(pd.DataFrame(w, columns=["tahun", "n_E01", "med_E01", "n_lain", "med_lain"]).round(0).to_string(index=False))
t.to_csv(A / "rq5_editor_first_revisions.csv")

section("RQ3 beban masuk (inflow) vs lama revisi pertama, per bulan submit")
fs["ym"] = fs.date_submitted.dt.to_period("M")
inflow = fs[fs.submit_year >= 2019].groupby("ym").size().rename("inflow")
dur = e.groupby(e.date_submitted.dt.to_period("M")).d_submit_to_first_revisions.median().rename("median_d")
m = pd.concat([inflow, dur], axis=1).dropna()
rho, pv = stats.spearmanr(m.inflow, m.median_d)
print(f"bulan={len(m)} Spearman inflow vs median hari ke revisi1: rho={rho:.2f}, p={pv:.3f}")
print("naskah masuk per tahun:", fs[fs.submit_year >= 2019].groupby("submit_year").size().to_dict())

# ---- RQ4 production queue ----------------------------------------------------------------------
section("RQ4 antrean di production (jumlah naskah di tahap copyedit/production saat naskah masuk)")
q = fs[(fs.outcome == "published") & fs.t_send_prod.notna() & fs.has_published_date & (fs.submit_year >= 2019)].copy()
q["end"] = q.date_published + pd.Timedelta(days=1)
q["wip"] = [((q.t_send_prod <= r.t_send_prod) & (q.end > r.t_send_prod)).sum() - 1 for r in q.itertuples()]
x = q.dropna(subset=["d_send_prod_to_published"])
rho, pv = stats.spearmanr(x.wip, x.d_send_prod_to_published)
print(f"n={len(x)}  WIP median={x.wip.median():.0f} (max {x.wip.max()})  Spearman WIP vs hari production: rho={rho:.2f}, p={pv:.4f}")
print(x.groupby(pd.cut(x.wip, [-1, 3, 6, 10, 100])).d_send_prod_to_published.agg(["size", "median"]).round(0))
x.groupby("editor_key_send_prod").d_send_prod_to_published.agg(["size", "median"]).round(0).to_csv(A / "rq4_prod_by_editor.csv")

# ---- RQ7 author time ----------------------------------------------------------------------------
section("RQ7 waktu penulis menyiapkan revisi vs loop revisi")
rv = fd[fd.event_name == "request_revisions"].copy()
nm = fd[fd.event_name.isin(["accept_submission", "resubmit_for_review", "send_to_production", "decline_submission_review"])][["submission_id", "date_decided"]]
rv = rv.sort_values("date_decided")
rv = pd.merge_asof(rv, nm.rename(columns={"date_decided": "next_ts"}).sort_values("next_ts"), left_on="date_decided", right_on="next_ts",
                   by="submission_id", direction="forward", allow_exact_matches=False)
rv["loop_days"] = (rv.next_ts - rv.date_decided).dt.total_seconds() / 86400
r2 = rv.dropna(subset=["author_revision_days", "loop_days"])
r2 = r2[(r2.author_revision_days <= r2.loop_days + 1) & (r2.loop_days >= 1)]
share = r2.author_revision_days.sum() / r2.loop_days.sum() * 100
print(f"n={len(r2)}: penulis median {r2.author_revision_days.median():.0f} hari; Request Revisions -> keputusan berikutnya median {r2.loop_days.median():.0f} hari; "
      f"porsi penulis dari total waktu loop (jumlah/jumlah) {share:.0f}%; upload penulis -> keputusan berikutnya (waktu editor/reviewer) median {(r2.loop_days - r2.author_revision_days).median():.0f} hari")
print(rv.dropna(subset=["author_revision_days"]).assign(r=lambda d: d["round"].clip(upper=3)).groupby("r").author_revision_days.agg(["size", "median"]).round(0))
rv.assign(year=rv.date_decided.dt.year).dropna(subset=["author_revision_days"]).groupby("year").author_revision_days.agg(["size", "median"]).round(0).to_csv(A / "rq7_author_by_year.csv")

# ---- RQ8 declines -------------------------------------------------------------------------------
section("RQ8 penolakan per tahun submit")
y = fs[fs.submit_year >= 2019]
o = pd.crosstab(y.submit_year, y.outcome)
o["decided"] = o.declined + o.published
o["pct_ditolak_dari_diputuskan"] = (o.declined / o.decided * 100).round(0)
dc = y[y.outcome == "declined"]
o["tolak_di_screening"] = dc[dc.stage_decline == 1].groupby("submit_year").size()
o["tolak_setelah_review"] = dc[dc.stage_decline == 3].groupby("submit_year").size()
o["median_hari_tolak"] = dc.groupby("submit_year").d_submit_to_decline.median().round(0)
print(o)
o.to_csv(A / "rq8_declines.csv")
print("waktu ke penolakan: screening median %.0f hari, setelah review median %.0f hari" % (
    dc[dc.stage_decline == 1].d_submit_to_decline.median(), dc[dc.stage_decline == 3].d_submit_to_decline.median()))

# ---- RQ10 reviewer assignments --------------------------------------------------------------------
section("RQ10 status penugasan reviewer per tahun (cakupan terbatas)")
r10 = pd.crosstab(ra.submit_year, ra.status_name)
r10 = r10[r10.index >= 2019]
r10["total"] = r10.sum(axis=1)
r10["pct_response_overdue"] = (r10.get("response_overdue", 0) / r10.total * 100).round(0)
r10["pct_review_overdue"] = (r10.get("review_overdue", 0) / r10.total * 100).round(0)
print(r10)
r10.to_csv(A / "rq10_reviewer_status.csv")
print("catatan: status ini adalah STATUS SAAT INI penugasan; assignment yang dibatalkan/ditolak tidak tentu tercantum.")

# ---- RQ6 model -----------------------------------------------------------------------------------------
section("RQ6 model: log(hari submit->terbit) ~ revisi + penulis + seksi + periode")
mdl = fs[fs.scope_duration_published].dropna(subset=["d_submit_to_published"]).copy()
mdl = mdl[mdl.d_submit_to_published > 0]
mdl["ly"] = np.log(mdl.d_submit_to_published)
mdl["sec"] = np.where(mdl.section_id == 18, "S18", "lain")
mdl["period"] = pd.cut(mdl.submit_year, [2018, 2021, 2023, 2026], labels=["2019-21", "2022-23", "2024-26"]).astype(str)
mdl["rev"] = mdl.n_revision_requests.clip(upper=3)
f = smf.ols("ly ~ C(rev) + n_authors_approx + C(sec) + C(period)", data=mdl).fit(cov_type="HC3")
print(f"n={int(f.nobs)} R2={f.rsquared:.2f}")
print(pd.DataFrame({"efek_%": ((np.exp(f.params) - 1) * 100).round(0), "p": f.pvalues.round(3)}).drop("Intercept"))
print("jumlah request revisions vs median hari:", mdl.groupby("rev").d_submit_to_published.agg(["size", "median"]).round(0).to_dict("index"))
