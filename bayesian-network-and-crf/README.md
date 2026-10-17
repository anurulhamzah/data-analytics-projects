# Risk modeling and event classification: Bayesian networks and CRFs

Team project (team of 3), 2026. Python, pgmpy, sklearn-crfsuite.

**Part A, Bayesian network.** The standard 27-node "insurance" benchmark network (socioeconomic factors and age, driver traits, accident likelihood and costs). Sensitivity analysis: conditional probability tables are edited for scenarios (more severe accidents, more theft in dense Indonesian cities, a more realistic repair-cost table), inference is re-run with pgmpy, and the effect on cost nodes is compared with the baseline.

**Part B, Conditional Random Field.** Token-level tagging of four financial event types (merger, acquisition, earnings, stock movement) as beginning/continuation tokens versus non-event tokens. Features: word and part-of-speech information from neighbouring tokens plus keyword features. Weighted F1 on the held-out test set: 0.974. A separate comparison across train, validation and test splits gave weighted F1 of 0.972, 0.970 and 0.965 as a check against overfitting. Token accuracy is flattered by the large non-event class, so per-class scores should be read alongside it.

Input data are not included. **File:** `bayesian_network_and_crf.ipynb`.
