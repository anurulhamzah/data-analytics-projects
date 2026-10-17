# Climate change and global agriculture: causal analysis of adaptation strategies

Individual project, 2025. R, CRISP-DM.

**Question:** which climate-adaptation strategies (crop rotation, water management, drought-resistant crops, organic farming) work best, by crop and region.

**Data:** a synthetic climate-agriculture panel, 1990-2024, 10,000 observations and 15 features (yield, economic impact in USD million, temperature, precipitation, fertilizer, pesticide, CO2, irrigation, soil and more). It was sanity-checked against EDGAR, NOAA and FAOSTAT patterns. **The data file (`Climate_Agri_Dataset.xlsx`) is not included**; the analysis expects it next to the R Markdown file.

**Method:** cleaning (19 rows, about 0.19%, with impossible negative pesticide/fertilizer values removed; countries grouped into climate zones); EDA (fertilizer-yield correlation 0.73; weak linear climate-yield correlation, which motivated GAMs); linear mixed-effects models (lme4) with random intercepts for crop and region nested in country; generalized additive models (mgcv); Random Forest in tidymodels (80/20 split, 5-fold CV); multinomial propensity-score weighting and causal forests (grf) for heterogeneous treatment effects.

The data are synthetic and treatment effects from observational data rest on assumptions that cannot be checked here, so this demonstrates method rather than evidence about real farms.

**File:** `climate_causal_analysis.Rmd`.
