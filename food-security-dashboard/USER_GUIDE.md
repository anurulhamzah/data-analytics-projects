---
editor_options: 
  markdown: 
    wrap: 72
---

## **User Guide: The Indonesia Food Security and Vulnerability Dashboard**

### **1.Getting Started**

#### **1.1. Indonesia Food Security and Vulnerability Dashboard.**

This platform is designed as a strategic asset for policymakers,
regional planners, public health officials, and analysts dedicated to
strengthening food security across the nation. The dashboard’s primary
goal is to provide both a high-level national overview and a
comprehensive, user-driven tool for exploring and understanding the
complex regional disparities in food security throughout Indonesia. The
dashboard is created interactive Thus, his enables users to become
active analysts, identifying emerging trends and drilling down into
local-level data in real time, thereby accelerating the policy analysis
and response cycle

The dashboard is built to support three core analytical tasks essential
for effective policy formulation: **identifying priority regions for
intervention, understanding the diverse determinants of food insecurity,
and assessing progress toward national targets**. It translates complex
datasets covering key indicators from 2018 to 2024 into actionable
visual narratives, designed to enhance evidence-based decision-making at
all levels of governance

The intended audience for this tool is ranging from senior officials at
national bodies like Bappenas and the National Food Agency (Badan Pangan
Nasional) to provincial governors, municipal mayors, technical
researchers at think tanks and NGOs. **This dashboard aims to empower
each user to extract the specific insights relevant to their role in
achieving a food-secure Indonesia**

#### 1.2. A Quick Tour of the Dashboard

The dashboard is organized into a series of tabs accessible via the main
navigation bar at the top of the page. It is designed to guide the user
through a logical and comprehensive policy analysis workflow, telling a
complete story about food security from the current situation to future
possibilities.

#### **The five main tabs are:**

**General Overview:** This tab is the starting point, designed to answer
the question, "Where are we now?" It provides a national and regional
snapshot of the current food security situation using key performance
indicators and interactive maps

**Global Comparison (GFSI):** This tab answers the question, "How do we
compare to others?" It benchmarks Indonesia's national performance
against global and regional peers using the Global Food Security Index
(GFSI), providing crucial context for national strengths and weaknesses

**Policy Focus:** This section applies advanced spatial analysis to
reveal the unique, local drivers of food insecurity in different
regions, helping to diagnose the root causes of vulnerability

**Government Spending:** This tab helps analyze the effectiveness of
fiscal interventions by exploring the relationship between government
investment in agricultural subsidies and food security outcomes.

**Future Projections:** This tab is to answer last RQ, "Where are we
headed?" It uses statistical forecasting to project future food security
trends, identifying regions that are on track to meet national goals and
those at risk of falling behind, thereby supporting strategic planning
and proactive intervention

By moving through these tabs sequentially, users can build a
multi-layered understanding of Indonesia's food security landscape, from
diagnosis to prognosis.

### 2. Setup and Installation

This dashboard is an R Shiny application. To run it on your local
machine, you will need to have R and RStudio installed, along with the
necessary packages and data files

#### 2.1. System Requirements

-   R: A recent version of R

-   RStudio: Recommended for ease of use

-   R Packages: The application will automatically attempt to install
    any missing packages from the following list upon launch: *"shiny",
    "shinydashboard", "shinyWidgets", "DT", "tidyverse", "tidyr", "sf",
    "leaflet", "rnaturalearth", "maps", "dplyr", "leaflet.extras",
    "readxl", "plotly", "htmltools", "GGally", "GWmodel",
    "shinycssloaders", "cluster", "factoextra", "FactoMineR", "ggplot2",
    "RColorBrewer", "shinythemes", "stringr", "scales", "janitor",
    "ggrepel", "devtools", "patchwork", "forecast", "viridis", "purrr",
    "ggradar"*

#### 2.2. Required Files For the dashboard to function correctly, you must place the following files in the same directory as the main application script (app.R):

-   **Dashboard.R**: The R script containing the dashboard's user
    interface (UI) and server logic

-   **all_kabkota_ind.geojson**: A geospatial data file containing the
    map boundaries for Indonesia's districts and cities

-   **combined_data.csv**: The primary dataset containing food security
    indicators (IKP, Stunting, Poverty, PoU) and other regional data
    from 2018-2024

-   **gfsi_full_dataset.cs**v: The dataset for the Global Food Security
    Index (GFSI) from 2012-2022

#### 2.3. Running the Application

To run the app, open the **Dashboard.R** file in RStudio. Click the
*"Run App"* button that appears at the top of the script editor.
Alternatively, you can run the app by typing *shiny::runApp()* in the R
console, make sure your working directory is set to the folder
containing the app and data files

### 3. Navigating the Dashboard

**A Tab-by-Tab Guide**; this section provides a detailed walkthrough of
each tab, explaining its purpose, features, and how to interpret the
visualizations.  

#### 3.1. The "Overview" Tab

This is designed to give you a high-level understanding of the project's
goals and key findings before you dive into the data.

-   **What is it?** The Overview tab provides a narrative summary of the
    dashboard's purpose. It is structured around three core **Research
    Questions** that the dashboard aims to answer. Each question is
    followed by a brief summary of the analysis and key insights found
    in the other tabs. It concludes with an **Executive Summary** that
    provides strategic, actionable recommendations based on the overall
    findings.

    **How to Use It:** This tab is primarily for reading. It is not
    interactive. Start here to understand the context behind the data
    and the main story the dashboard tells.

    1.  Read through the **Three Key Research Questions** to understand
        the analytical focus.

    2.  Review the text boxes that summarize the findings related to
        spatial trends, global comparisons, and future projections.

    3.  Consult the **Executive Summary & Strategic Recommendations** at
        the bottom to see the high-level takeaways and proposed policy
        actions.

#### 3.2. General Overview Tab

This tab serves as the main entry point, providing a comprehensive
summary of Indonesia's food security status, This Tab providing 3
sub-tabs

-   **Key Indicators:** At the top, four prominent boxes display the
    latest national-level values for the primary indicators: *Food
    Security Index (IKP), Stunting Rate, Poverty Rate, and Prevalence of
    Undernourishment (PoU).* these provide a quick, high-level summary

-   **Interactive Map:** The centerpiece is an interactive map for
    exploring regional disparities.

    -   **How to Use:** User can select an indicator and year from the
        filters on the left. The map will color-code each region based
        on its value for that indicator. Hover your mouse over a region
        to see a tooltip with its specific data

-   **Top & Bottom 5 Regions:** Bar charts highlight the five regions to
    have the best and worst value based on choosen indicator

-   **Trend Chart:** Under the "Trend" sub-tab, an interactive line
    chart visualizes historical performance from 2018 to 2024. This
    chart is fully integrated with the filters, allowing you to analyze
    trends for the entire country, a specific province, or a regional
    classification (e.g., "3T" regions)

-   **Indicator Insights:** The "Insight" sub-tab provides crucial
    context for the selected indicator, explaining how it is measured
    and offering a key analytical finding derived from the data. For
    example, for the IKP, it highlights the multifactorial nature of
    vulnerability in priority districts, linking food insecurity to
    poverty and stunting

-   **Detailed Data:** For analysts needing granular data, the "Show
    Detail" button opens a pop-up window with a full data table for the
    selected region and year, which can be downloaded as a CSV file

#### 3.3. Global Comparison (GFSI) Tab

This tab situates Indonesia's performance within a global context using
data from the Global Food Security Index (GFSI)

-   **Understanding the GFSI:** The GFSI is a standardized model that
    assesses food systems across four key dimension: Affordability,
    Availability, Quality & Safety, and Sustainability & Adaptation

-   **Trend Comparison:** A multi-line chart that tracks Indonesia's
    overall GFSI score over time against other selected countries, ideal
    for benchmarking progress against regional peers

-   **Sub-Index Comparison:** A radar chart provides a multi-dimensional
    snapshot for a single year. It makes it easy to see at a glance
    where Indonesia's relative strengths and weaknesses lie across the
    four GFSI dimensions compared to another country

-   **Dimension Breakdown:** A bar chart allows for a detailed ranking
    of countries based on their score for a specific GFSI dimension in a
    selected year

#### 3.4. Policy Focus Tab

This tab moves from what is happening to why, using advanced spatial
analysis to diagnose the root causes of food insecurity, which vary
significantly by location.  

-   **Geographically Weighted Regression (GWR) Map:** This map shows the
    most significant local driver of food insecurity in each priority
    district. Instead of showing an outcome like IKP, the colors
    represent the cause; for example, one color might represent regions
    where "Access to Clean Water" is the primary issue, while another
    color represents regions driven by "Poverty Rate". This helps tailor
    policy interventions to local needs

-   **Cluster Analysis (PCA & K-Means):** To simplify the complex GWR
    results, the dashboard groups districts with similar vulnerability
    profiles into clusters

    -   **Cluster Plot (PCA)**: This scatter plot visualizes the
        clusters. Districts that are close together on the plot face
        similar underlying challenges

    -   **Silhouette Score:** This metric (ranging from -1 to 1)
        measures how well-defined the clusters are. A score closer to 1
        indicates a good, reliable grouping, helping you validate the
        number of clusters selected

    -   **Cluster Profile Table:** This table provides a summary of each
        cluster, listing the districts it contains and the dominant
        vulnerability factors, helping you understand the "personality"
        of each group

#### 3.5. Government Spending Tab

This tab explores the relationship between government investment in food
subsidies and food security outcomes.  

-   **Trend Analysis:** A mixed chart displays government spending as
    bars and the selected performance indicator (e.g., IKP) as a line
    over time. This helps visualize if changes in spending correlate
    with changes in the indicator

-   **Correlation Analysis:** A scatter plot shows the relationship
    between spending and the selected indicator for a single year, with
    each dot representing a province. This helps identify potential
    patterns and outliers

-   **Efficiency Analysis Tab:** The Purpose of this tab is to measures
    return on investment and spending efficiency. this tab highlights
    best-performing provinces in terms of resource utilization this tab
    has multiple components:

    -   Efficiency rankings by province
    -   ROI analysis (IKP improvement per billion rupiah)
    -   Comprehensive efficiency table

-   **Statistical Analysis Tab:** This tab provides rigorous statistical
    validation. this tab Establishes statistical significance and
    explanatory power. this tab components are:

    -   Correlation strength over time
    -   Regression analysis with R² values
    -   Residuals analysis for model validation

-   **Comparative Analysis Tab:** This tab enables multi-province
    benchmarking, this tab identifies replicable success models. the
    component are:

    -   Multi-province scatter comparison
    -   Efficiency benchmarking bubble chart
    -   Best practice analysis with recommendations

-   **Note:** It is essential to remember that **correlation is not
    causation**. A strong relationship on these charts does not prove
    that spending caused the outcome. The charts are a starting point
    for investigation, not a final answer

#### 3.6. Future Projections Tab

This tab supports strategic planning by forecasting future trends and
assessing which regions are on track to meet national targets, such as
those in the RPJMN 2025-2029 framework 

-   **Forecasting Method (ARIMA):** Projections are generated using an
    Auto-ARIMA model, a statistical method that learns the unique
    historical data pattern for each region and uses it to project the
    most likely future path

-   **Projected Trend (2025-2030) Plot:**

    -   **What it is:** A detailed line chart showing the observed
        historical trend, the forecasted trend line up to 2030, and
        shaded confidence intervals (80% and 95%)

    -   **How to interpret:** The solid line is the historical data. The
        dotted line is the model's prediction. The shaded areas
        represent the uncertainty of the forecast—the wider the area,
        the less certain the prediction. A red dashed line shows the
        official 2030 goal for that indicator

-   **Progress Toward 2030 Goal Plot:**

    -   **What it is:** This chart plots the forecasted trends for
        multiple regions on the same axes, allowing for direct
        comparison. It clearly shows which regions are projected to be
        above or below the 2030 target line
    -   **How to interpret:** Quickly identify which regions are on
        track to meet their goals and which are lagging. Use this to
        spot regional disparities in progress

-   **Regional Rankings (Top/Bottom Performers Plots):**

    -   **What it is:** Two bar charts that instantly show the 5
        best-performing regions (green) and the 5 regions needing the
        most improvement (orange) based on their projected 2030 values.

    -   **How to interpret:** Use this to immediately identify regional
        leaders and those that may require priority intervention.

-   **2030 Projection Rankings Table:**

    -   **What it is:** A detailed, sortable table that ranks all
        selected regions based on their 2030 projection.

    -   **How to interpret:** The table includes the region's rank, its
        projected 2030 value, its numerical distance from the goal, and
        a simple **Goal Status** icon (✅ for Achieved, ❌ for Not
        Achieved) for a clear final verdict.

#### 3.7 The "System Status" Tab

This is a new diagnostic tab designed to monitor the health and
performance of the dashboard itself.

-   **What is it?** This page provides real-time information about the
    application's operational status. It is intended for both users who
    might be experiencing issues and administrators maintaining the
    dashboard

-   **Components:**

    -   **Current Status:** A quick look at whether the data is loaded
        correctly, the last update time, how much memory the app is
        using, and a count of any errors that have occurred

    -   **Data Quality Metrics:** This table gives a summary of the
        underlying dataset's completeness, showing the total number of
        records, how many are complete, and the count of missing values
        for key columns

    -   **Recent Errors:** A log table that displays the timestamp and
        message for any errors that have happened while the app is
        running

-   **How to Use It:** If you find that a chart is not loading or the
    dashboard is slow, check this tab. The "Data Quality Metrics" might
    indicate an issue with the source data, while the "Recent Errors"
    table can provide specific clues to a technical problem. This helps
    in diagnosing issues quickly and ensuring the data you are viewing
    is reliable.

### 4. Guide to Using the Dashboard's Filters

To help you explore the data easily, the dashboard is equipped with
several interactive filters. These controls allow you to customize the
charts and maps to answer your specific questions. Here’s a general
guide to what they do and how to use them effectively.

#### 4.1. Geographic Filters

These dropdown menus let you control the location you are viewing. You
can see the national picture, zoom into a specific **Province** or
**Regency/City**, or focus on special classifications like archipelagic
(`Kepulauan`) or underdeveloped (`3T`) regions.

-   **How to Use It:**

    -   **For Comparison:** Start with the "All Provinces" view to
        understand the national average. Then, select a specific
        province like "Jawa Barat" or "Papua" to see how its situation
        compares to the rest of the country

    -   **For Targeted Analysis:** Use the "Regional Classifications"
        filter to isolate specific types of areas. For example,
        selecting "3T" will show you the collective data for
        underdeveloped, frontier, and outermost regions, helping you
        understand the unique challenges they face compared to "Non-3T"
        areas.

#### 4.2. Indicator & Data Filters

These controls are central to your analysis, allowing you to change the
main data point shown in the visualizations. You can switch between key
metrics like the **Food Security Index (IKP)**, **Stunting Rate**, or
**Poverty Rate**. In the global comparison tab, you can select different
dimensions of the GFSI, such as **Affordability** or **Availability**.

-   **How toUse It:**

    -   **To Find Relationships:** Switch between different indicators
        to uncover potential connections. For example, after viewing the
        map for "Poverty Rate," switch to "Stunting Rate." Do the same
        regions light up? This can help you see where different social
        and health issues overlap.

    -   **For Global Benchmarking:** In the "Global Comparison" tab,
        select "Indonesia" and a peer country like "Malaysia" or
        "Vietnam." Then, switch between the GFSI dimensions. This will
        reveal if Indonesia's food security challenges are more related
        to supply (`Availability`), cost (`Affordability`), or
        `Quality & Safety` compared to its neighbors

#### 4.3. Time Filters

Use the **year sliders** and dropdowns to view data for a specific year
or to see how trends have changed over time. It also funcioning as
selected years for map, or other single years chart, it will show the
data in the highest year the user choose

-   **How to Use It:**

    -   **To See Progress:** On the "General Overview" tab, move the
        year slider back and forth. Watch how the colors on the map
        change. This provides a quick visual assessment of whether
        conditions in a particular region have improved or worsened over
        the years

    -   **To Evaluate Goals:** On the "Future Projections" tab, select
        an indicator and a region, then move the projection year slider
        to 2030. The chart will show the forecasted value, allowing you
        to assess whether that region is on track to meet its long-term
        development goals.

#### 4.4. Getting More Details & Help

Across the dashboard, you will find buttons that provide more
information or allow you to save your findings.

-   **How to Use It:**

    -   If a chart or map sparks your interest, click the **"Show
        Detail"** button to view the underlying numbers in a table

    -   Use the **"Download"** button to save the data from your
        specific query as a CSV file for your own reports or offline
        analysis.

    -   If you're ever unsure about a chart or an indicator, click the
        **"Help/Info"** button on that tab for a quick explanation.

#### **Technical Appendix:** Projection Logic

For analysts interested in the underlying mechanics, here is how the
projection data is handled:

```         
## Raw data → 3 hierarchical levels
df (raw) → agg_data$kabkota (cities)
           agg_data$provinsi (provinces - averaged from cities) 
           agg_data$indonesia (national - aggregated from provinces)
```

-   **Ploting the data**

    ```         
    ## plot_data() reactive function:
    ├── Filter by year range
    ├── IF Indonesia selected:
    │   ├── Get top 5 provinces (by latest year indicator value)
    │   ├── Get national aggregate 
    │   └── Combine both datasets
    ├── ELSE IF Province selected + "All Cities":
    │   ├── Filter cities within selected province
    │   └── Apply top N cities filter if specified
    └── ELSE (specific city):
        └── Filter to single city
    ```

-   **Data Aggregation Rules**

    -   **National Level**: National trends are calculated by averaging
        the indicator values across all cities and summing the unique
        provincial subsidy amounts

        ```         
        ### National Level
        indonesia_data = cities %>%
            group_by(year) %>%
            summarise(
                stunting/ikp/pou = mean(all_city_values),           # Average all cities
                subsidi_juta = sum(unique_province_subsidies)       # Sum unique provinces
        ```

    -   **Province Level:** Provincial trends are derived by averaging
        the values of all cities within that province

        ```         
        ### Province Level
        provinsi_data = cities %>% 
            group_by(PROVINSI, year) %>%
            summarise(
                stunting/ikp/pou = mean(city_values),  # Simple average
                subsidi_juta = first(city_subsidi)     # Already province-level
        ```

    -   **City Level:** The most granular level, using the raw data for
        each kabupaten/kota

-   **UI Control Flow:**

    -   **Geographic Selection:** The user first selects the geographic
        level (Indonesia, Province, or City)

        1.  User selects "Indonesia" → Shows national + top 5 provinces
        2.  User selects "Province X" → Shows all cities in Province X
        3.  User selects "City Y" → Shows single city Y trend

    -   **Filter Application:** The dashboard then applies filters for
        the year range and any regional classifications (e.g., 3T)

        1.  Geographic filter (Indonesia/Province/City)
        2.  Year range filter
        3.  Regional classification filter (3T/KEK)
        4.  Top N filter (if applicable)

    -   **Visualization:** The charts update based on these selections.
        For example, selecting "Indonesia" shows the national trend plus
        a comparison of the top 5 provinces. Selecting a specific
        province shows the trends for all cities within it

### 5. Troubleshooting

-   **Error on Startup:** If the app fails to load, ensure that the
    three data files (all_kabkota_ind.geojson, combined_data.csv,
    gfsi_full_dataset.csv) are located in the exact same folder as the
    app.R script.

-   **"Data Not Available" Message:** You may see this message in some
    of the KPI boxes or charts. This is expected. The Stunting Rate data
    is unavailable for 2021, and the PoU data is only available from
    2018 to 2023

-   **Slow Loading on tab with maps (General Overview, Policy Focus)
    tab**: The geojson map, GWR and clustering analyses on this tab are
    computationally intensive. Please allow a few moments for the
    calculations to complete and the visualizations to render

### 6. Individual Member Contributions

To effectively construct the dashboard, our team has established a clear
division of responsibilities based on individual strengths and the
specific demands of each analytical tab:

-   **Fauzi** will developing the **General Overview** tab, providing
    the main entry point for users

-   **Retno** is tasked with the analytically intensive **Policy Focus**
    tab, which involves complex spatial and clustering models.

-   **Ali** will handle both the **Government Spending** and **Future
    Projection** tabs, focusing on financial correlations and
    time-series forecasting.

-   For the **Global Comparison (GFSI)** tab, **Retno and Fauzi** will
    collaborate to integrate and visualize the international benchmark
    data.

as upon completion of these initial development phases, the entire team
will engage in a comprehensive review process. Each member will
critically assess every component of the dashboard, offering feedback
and making collaborative revisions to refine the user interface,
optimize performance, and ensure the final product is providing user
friendly interaction and giving maximum insight

### 7. Final Reflections/Known Issue

-   **Slow loading in map:** When Interacting with map, especially when
    it should show all region it may takes time to load. we have tried
    our best to reduce the time including using leaflet and geojson as
    map source

-   **Inclomplete data:** The Stunting Rate data is unavailable for
    2021, the PoU data is only available from 2018 to 2023, and some
    region may not show in the map because of missing data

-   **POU data imputation:** For the forecasting model, the script fills
    in missing pou values using a multi-step mean imputation. While this
    is a valid technique to prevent the model from failing, it is a
    significant analytical decision. The forecasts for PoU are therefore
    based partially on imputed, not original, data. This may causees
    issue the projections' accuracy.  
