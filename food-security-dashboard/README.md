# Regional food security and vulnerability dashboard, Indonesia (2018-2024)

Team project (team of 3), 2025. R Shiny, geographically weighted regression, ARIMA.

An interactive dashboard for policymakers and analysts with three tabs: a general overview of food security index, stunting, undernourishment and poverty trends (2018-2024); a policy-focus tab using geographically weighted regression to show which socioeconomic variables drive food security locally; and a projections tab with ARIMA forecasts to 2029 against national targets (food security index of at least 82, undernourishment of at most 4.41%). Data are at regency and city level. The design follows the Five Design Sheets framework.

**Not included:** the datasets and boundary file the app reads (`gfsi_full_dataset.csv`, `all_kabkota_ind.geojson`, `combined_data.csv`, `dataset_all.csv`), because their licences are unclear, so the app does not run from this repository alone. There is no hosted version yet.

**Files:** `Dashboard.R` (the Shiny app), `USER_GUIDE.md` (user guide).
