# Regional food security and vulnerability dashboard, Indonesia (2018-2024)

Team project (team of 3), 2025. R Shiny, geographically weighted regression, ARIMA.

An interactive dashboard for policymakers and analysts with seven tabs: an overview of the research questions; a general overview of food security index, stunting, poverty and undernourishment trends (2018-2024) with a district map; a global comparison on the Global Food Security Index; a policy-focus tab using geographically weighted regression to show which socioeconomic variables drive food security locally, plus PCA and K-Means clusters of districts; government spending (agricultural subsidies against the food security index); future projections, with ARIMA forecasts of the food security index, stunting and undernourishment for 2025-2030 against 2030 goals (food security index 85, stunting 14%, undernourishment 5%); and a system-status tab with data-quality checks. Data are at regency and city level. The design follows the Five Design Sheets framework.

**Not included:** the datasets and boundary file the app reads (`gfsi_full_dataset.csv`, `all_kabkota_ind.geojson`, `combined_data.csv`, `dataset_all.csv`), because their licences are unclear, so the app does not run from this repository alone. There is no hosted version yet.

**Files:** `Dashboard.R` (the Shiny app), `USER_GUIDE.md` (user guide).

Changes made when preparing the code for hosting: packages are attached with `library()` instead of being installed at run time; the overview map uses OpenStreetMap tiles instead of a provider that now requires an API key; and the map is rendered at start so the district polygons draw on first view.
