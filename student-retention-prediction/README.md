# Student retention and dropout prediction

Multi-model predictive analytics for student dropout. Individual project, 2026. Python, scikit-learn, XGBoost.

**Data:** 4,424 student records with 36 features from a Portuguese higher-education institution, from the UCI Machine Learning Repository ("Predict Students' Dropout and Academic Success"). `data.csv` is included; check the UCI page for its licence and citation. Outcomes: Dropout, Enrolled, Graduate.

**Method:** distribution and outlier checks; chi-square tests (categorical) and ANOVA (numeric); KMeans student personas and a PCA "academic intensity" feature; Logistic Regression baseline, Random Forest and XGBoost compared with 10-fold cross-validation, then evaluated once on a held-out set (885 students).

| Model | 10-fold CV accuracy | Test accuracy | Test weighted F1 |
|---|---|---|---|
| Logistic Regression | 0.759 +/- 0.018 | 0.774 | 0.758 |
| Random Forest | 0.763 +/- 0.021 | 0.774 | 0.753 |
| XGBoost | 0.774 +/- 0.025 | 0.785 | 0.771 |

On the held-out set XGBoost finds 79% of dropouts (F1 0.80) and 93% of graduates (F1 0.87), but only 37% of students still enrolled (F1 0.45). Strongest predictors: curricular units approved and whether tuition fees are up to date.

**Limitations:** one institution's data; the margin over the linear baseline is about one accuracy point, comparable to fold-to-fold spread; much of the signal comes from units already passed.

**Files:** `student_retention.ipynb` (analysis), `student_retention.py` (script export), `data.csv`.
