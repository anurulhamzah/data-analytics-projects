# Food security and vulnerability dashboard, Indonesia (2018-2024).
# Packages are attached statically (not installed at run time) so the app can be deployed
# to hosting such as shinyapps.io. Order follows the original load order.
library(shiny)
library(shinydashboard)
library(DT)
library(tidyr)
library(sf)
library(leaflet)
library(dplyr)
library(plotly)
library(htmltools)
library(GWmodel)
library(shinycssloaders)
library(cluster)
library(factoextra)
library(FactoMineR)
library(ggplot2)
library(RColorBrewer)
library(stringr)
library(scales)
library(janitor)
library(forecast)
library(purrr)
# ----- Load Data -----####
#Using relative paths for portability. Place data files in the same directory as the app.
geojson_path <- "all_kabkota_ind.geojson"
main_data_path <- "combined_data.csv" 
gfsi_path <- "gfsi_full_dataset.csv"

# Error handling in loading dataset
tryCatch({
  spatial_data <- st_read(geojson_path)       #Reading Map data
  main_data <- read.csv(main_data_path, sep = ",") #Reading main data for food security dashboard
  gfsi_data <- read.csv(gfsi_path)           #Reading GFSI data
}, error = function(e) {
  stop("Error loading data files. Make sure 'all_kabkota_ind.geojson', 'combined_data.csv', and 'gfsi_full_dataset.csv' are in the app directory. Error: ", e$message)
})


# ---- Data Prep -----####
#Convert relevant text columns to Title Case for better readability
main_data <- main_data %>%
  mutate(
    provinsi = str_to_title(provinsi),
    kabkota = str_to_title(kabkota)
  )

spatial_data <- spatial_data %>%
  mutate(
    prov_name = str_to_title(prov_name),
    name = str_to_title(name)
  )

#Join regional data for the "General Overview" tab
spatial_data_prep <- st_make_valid(spatial_data)
spatial_data_prep <- spatial_data_prep %>%
  mutate(join_id = as.character(paste0(province_id, kabkot_id)))

main_data_prep <- main_data %>%
  mutate(join_id = as.character(kode_kabkota))

merged_data <- spatial_data_prep %>%
  left_join(main_data_prep, by = "join_id") %>%
  st_as_sf()

#Prepare for doing filter for category 
merged_data <- merged_data %>%
  mutate(
    kepulauan = replace_na(as.character(kepulauan), "Non-Kepulauan"),
    daerah_3T = replace_na(as.character(daerah_3T), "Non-3T")
  )

#clean the main_data for the trend chart
main_data <- main_data %>%
  mutate(
    kepulauan = replace_na(as.character(kepulauan), "Non-Kepulauan"),
    daerah_3T = replace_na(as.character(daerah_3T), "Non-3T")
  )

#Clean the GFSI dataset
gfsi_data <- gfsi_data %>%
  clean_names() %>%
  rename(Country = country, Year = year, Indicator = indicator, Value = value, Group = group) %>%
  mutate(
    Value = as.numeric(Value),
    Indicator = str_trim(Indicator) # Trim whitespace
  ) %>%
  filter(!is.na(Country), !is.na(Value))


#Choices for filters
indicator_choices <- c(
  "Food Security Index (IKP)" = "ikp",
  "Stunting Rate (%)" = "stunting",
  "Poverty Rate (%)" = "kemiskinan",
  "Prevalence of Undernourishment (PoU)" = "pou"
)

year_choices <- sort(unique(main_data$year))
min_year <- min(year_choices, na.rm = TRUE)
max_year <- max(year_choices, na.rm = TRUE)

province_choices <- c("All Provinces", sort(unique(na.omit(main_data$provinsi))))
regional_choices <- c("All", "Kepulauan", "Non-Kepulauan", "3T", "Non-3T")
country_group_choices <- c("All", sort(unique(na.omit(gfsi_data$Group))))
country_choices <- sort(unique(gfsi_data$Country[gfsi_data$Country != "Indonesia"]))
dimension_choices <- c(
  "Overall GFSI Score" = "FOOD SECURITY ENVIRONMENT", #change the visual name for the dashboard
  "Affordability" = "1) AFFORDABILITY", 
  "Availability" = "2) AVAILABILITY", 
  "Quality & Safety" = "3) QUALITY AND SAFETY", 
  "Sustainability & Adaptation" = "4) SUSTAINABILITY AND ADAPTATION"
)






#################################################################################################
### ----------HELPER GOVERMENT SPENDING FUNCTIONS ---- 
################################################################################################

INDICATOR_CONFIG <- list(
    ikp = list(col = "ikp", label = "Food Security Index", choice_name = "Food Security Index"),
    kemiskinan = list(col = "kemiskinan", label = "Poverty Rate", choice_name = "Poverty Rate"), 
    stunting = list(col = "stunting", label = "Stunting Rate", choice_name = "Stunting Rate"),
    pou = list(col = "pou", label = "PoU", choice_name = "PoU")
)


govt_indicator_choices <- setNames(names(INDICATOR_CONFIG), 
                                   sapply(INDICATOR_CONFIG, function(x) x$choice_name))

# ---- HELPER FUNCTIONS ---- 

get_indicator_info <- function(indicator_key) {
  INDICATOR_CONFIG[[indicator_key]]
}

process_base_data <- function(df, regional_class) {
  if (regional_class != "All") df <- filter(df, daerah_3T == regional_class)
  return(df)
}






create_aggregated_data_govt <- function(data) {
    # PROVINSI level aggregation
    provinsi_data <- data %>%
        group_by(provinsi, year) %>%
        summarise(
            stunting = mean(stunting, na.rm = TRUE),
            ikp = mean(ikp, na.rm = TRUE),
            pou = mean(pou, na.rm = TRUE), 
            kemiskinan = mean(kemiskinan, na.rm = TRUE),
            subsidi_juta = first(subsidi_juta), # Province-level data - keep as subsidi_juta
            daerah_3T = first(daerah_3T),
            num_kabkota = n(), 
            .groups = 'drop'
        )
    
    # INDONESIA level aggregation  
    indonesia_data <- data %>%
        group_by(year) %>%
        summarise(
            stunting = mean(stunting, na.rm = TRUE),
            ikp = mean(ikp, na.rm = TRUE),
            pou = mean(pou, na.rm = TRUE),
            kemiskinan = mean(kemiskinan, na.rm = TRUE),
            subsidi_juta = sum(subsidi_juta[!duplicated(provinsi)], na.rm = TRUE), # Sum unique provinces - keep as subsidi_juta
            num_kabkota = n(),
            .groups = 'drop'
        ) %>%
        mutate(level = "INDONESIA", region_name = "Indonesia")
    
    return(list(kabkota = data, provinsi = provinsi_data, indonesia = indonesia_data))
}


create_trend_data_govt <- function(agg_data, province, indicator_key) {
    if (province == "All") {
        result <- agg_data$indonesia
    } else {
        result <- agg_data$provinsi %>% filter(provinsi == province)
    }
    
    result$indicator <- result[[indicator_key]]
    return(result)
}

create_scatter_data_govt <- function(agg_data, year, province, indicator_key) {
    if (province == "All") {
        result <- agg_data$provinsi %>% filter(year == !!year)
    } else {
        result <- agg_data$provinsi %>% filter(year == !!year, provinsi == province)
    }
    
    result$indicator <- result[[indicator_key]]
    return(result)
}

create_hover_text <- function(data, indicator_info, year = NULL, province = "All") {
    data %>%
        mutate(
            hover_txt = paste0(
                if(province == "All" && "provinsi" %in% names(data)) 
                    paste0("Province: ", provinsi, "<br>") else "",
                if("year" %in% names(data)) paste0("Year: ", year, "<br>") 
                else if(!is.null(year)) paste0("Year: ", year, "<br>") else "",
                "Subsidy: Rp ", scales::comma(round(subsidi_juta/1e6, 1)), 
                " Trillion", "<br>", indicator_info$label, ": ", round(indicator, 1)  # ✅ Fixed units
            )
        )
}

create_plot_title <- function(type, indicator_info, province = "All", 
                              year = NULL, regional_class = "All") {
  base_title <- switch(type,
                       "trend" = paste0("Trend: Govt. Spending vs ", indicator_info$label),
                       "scatter" = paste0("Correlation: Spending vs ", indicator_info$label, 
                                          if(!is.null(year)) paste0(" (", year, ")") else "")
  )
  
  if (province != "All") base_title <- paste0(base_title, " - ", province)
  if (regional_class != "All") 
    base_title <- paste0(base_title, " (", regional_class, " Areas)")
  
  return(base_title)
}





#############################################################################################################################################
### ----------HELPER FORECASTING FUNCTIONS ---- 
###########################################################################################################################################
create_arima_forecast <- function(data, indicator, years_ahead = 6) {
    if (nrow(data) < 3) return(NULL)
    
    data_ordered <- data[order(data$year), ]
    years_historical <- data_ordered$year
    values_historical <- data_ordered[[indicator]]
    
    valid_indices <- !is.na(values_historical)
    years_clean <- years_historical[valid_indices]
    values_clean <- values_historical[valid_indices]
    
    if (length(values_clean) < 3) return(NULL)
    
    ts_data <- ts(values_clean, start = min(years_clean), frequency = 1)
    
    tryCatch({
        arima_model <- auto.arima(ts_data, seasonal = FALSE, stepwise = TRUE, approximation = FALSE)
        forecasts <- forecast(arima_model, h = years_ahead, level = c(80, 95))
        
        last_year <- max(years_clean)
        forecast_years <- (last_year + 1):(last_year + years_ahead)
        
        forecast_mean <- as.numeric(forecasts$mean)
        target_year <- 2030
        projection_2030 <- if (target_year %in% forecast_years) {
            forecast_mean[which(forecast_years == target_year)]
        } else forecast_mean[length(forecast_mean)]
        
        goal_2030 <- goals_2030[[indicator]]
        distance_to_goal <- if (!is.null(goal_2030)) abs(projection_2030 - goal_2030) else NA
        
        return(list(
            model = arima_model, historical_years = years_clean, historical_values = values_clean,
            fitted_values = as.numeric(fitted(arima_model)), forecast_years = forecast_years,
            forecast_mean = forecast_mean, forecast_lower_80 = as.numeric(forecasts$lower[, "80%"]),
            forecast_upper_80 = as.numeric(forecasts$upper[, "80%"]),
            forecast_lower_95 = as.numeric(forecasts$lower[, "95%"]),
            forecast_upper_95 = as.numeric(forecasts$upper[, "95%"]),
            projection_2030 = projection_2030, goal_2030 = goal_2030,
            distance_to_goal = distance_to_goal, indicator = indicator
        ))
    }, error = function(e) NULL)
}

create_regional_forecasts <- function(agg_data, level = "indonesia", indicator = "stunting", selected_province = NULL) {
    forecasts_list <- list()
    
    if (level == "indonesia") {
        national_forecast <- create_arima_forecast(agg_data$indonesia, indicator)
        if (!is.null(national_forecast)) forecasts_list[["Indonesia National"]] <- national_forecast
        
        latest_year <- max(agg_data$provinsi$year)
        top_provinces <- agg_data$provinsi %>% filter(year == latest_year) %>%
            arrange(desc(!!sym(indicator))) %>% head(7) %>% pull(PROVINSI)
        
        for (prov in top_provinces) {
            prov_data <- agg_data$provinsi %>% filter(PROVINSI == prov)
            prov_forecast <- create_arima_forecast(prov_data, indicator)
            if (!is.null(prov_forecast)) forecasts_list[[prov]] <- prov_forecast
        }
    } else if (level == "provinsi" && !is.null(selected_province)) {
        prov_data <- agg_data$provinsi %>% filter(PROVINSI == selected_province)
        prov_forecast <- create_arima_forecast(prov_data, indicator)
        if (!is.null(prov_forecast)) forecasts_list[[selected_province]] <- prov_forecast
        
        latest_year <- max(agg_data$kabkota$year)
        top_cities <- agg_data$kabkota %>%
            filter(PROVINSI == selected_province, year == latest_year) %>%
            arrange(desc(!!sym(indicator))) %>% head(7) %>% pull(KAB_KOTA)
        
        for (city in top_cities) {
            city_data <- agg_data$kabkota %>% filter(KAB_KOTA == city)
            city_forecast <- create_arima_forecast(city_data, indicator)
            if (!is.null(city_forecast)) forecasts_list[[city]] <- city_forecast
        }
    }
    return(forecasts_list)
}

rank_by_2030_projection <- function(forecasts_list, indicator) {
    if (length(forecasts_list) == 0) {
        return(data.frame(Region = character(0), Projection_2030 = numeric(0), 
            Distance_to_Goal = numeric(0), Meets_Goal = logical(0), 
            Rank = integer(0), stringsAsFactors = FALSE))
    }
    
    projections_2030 <- sapply(forecasts_list, function(x) {
        if (!is.null(x) && !is.null(x$projection_2030)) x$projection_2030 else NA
    })
    
    valid_projections <- projections_2030[!is.na(projections_2030)]
    if (length(valid_projections) == 0) {
        return(data.frame(Region = character(0), Projection_2030 = numeric(0), 
            Distance_to_Goal = numeric(0), Meets_Goal = logical(0), 
            Rank = integer(0), stringsAsFactors = FALSE))
    }
    
    ranking_df <- data.frame(Region = names(valid_projections), 
        Projection_2030 = as.numeric(valid_projections), stringsAsFactors = FALSE)
    
    goal_value <- goals_2030[[indicator]]
    if (!is.null(goal_value)) {
        ranking_df$Distance_to_Goal <- abs(ranking_df$Projection_2030 - goal_value)
        ranking_df$Meets_Goal <- ifelse(indicator %in% c("stunting", "pou"), 
            ranking_df$Projection_2030 <= goal_value,
            ranking_df$Projection_2030 >= goal_value)
    } else {
        ranking_df$Distance_to_Goal <- NA
        ranking_df$Meets_Goal <- NA
    }
    
    ranking_df <- ranking_df[order(ranking_df$Projection_2030), ]
    ranking_df$Rank <- 1:nrow(ranking_df)
    return(ranking_df)
}

# Data preprocessing for projections
create_aggregated_data_forecast <- function(data) {
    # PROVINSI level aggregation
    provinsi_data <- data %>%
        group_by(provinsi, year) %>%
        summarise(stunting = mean(stunting, na.rm = TRUE), ikp = mean(ikp, na.rm = TRUE),
            pou = mean(pou, na.rm = TRUE), daerah_3T = first(daerah_3T), 
            num_kabkota = n(), .groups = 'drop') %>%
        rename(PROVINSI = provinsi)
    
    # INDONESIA level aggregation
    indonesia_data <- data %>%
        group_by(year) %>%
        summarise(stunting = mean(stunting, na.rm = TRUE), ikp = mean(ikp, na.rm = TRUE),
            pou = mean(pou, na.rm = TRUE), num_kabkota = n(), .groups = 'drop') %>%
        mutate(level = "INDONESIA", region_name = "Indonesia")
    
    return(list(kabkota = data, provinsi = provinsi_data, indonesia = indonesia_data))
}

# Create aggregated datasets
agg_data <- create_aggregated_data_forecast(main_data)

# Define 2030 Goals
goals_2030 <- list("stunting" = 14, "ikp" = 85, "pou" = 5)

# Central indicator reference
indicator_labels <- list("stunting" = "Stunting (%)", "ikp" = "Food Security Index (IKP)", "pou" = "PoU (%)")
indicator_choices_proj <- list("Stunting (%)" = "stunting", "Food Security Index (IKP)" = "ikp", "PoU (%)" = "pou")

### ----------END HELPER FORECASTING FUNCTIONS ---- 
################################################################################################


# UI ####
## ---- Styling ----
ui <- navbarPage(
  "Food Security and Vulnerability Dashboard",
  id = "main_nav",
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
       /* STORY TEXT: light background w/ green accent */
    .box .story-text {
      background: #ffffff !important;
      border-left: 6px solid #6B8E23 !important;  /* moss green */
      color: #2F4F2F !important;                  /* dark slate green */
      padding: 15px !important;
      border-radius: 8px !important;
      margin-bottom: 15px !important;
      box-shadow: 0 2px 4px rgba(0,0,0,0.08) !important;
    }
    .box .story-text h4 {
      color: #6B8E23 !important;
      margin-top: 0;
      margin-bottom: 8px;
      font-size: 1.2em;
    }

    /* RESEARCH QUESTION: pale green bg with bold left bar */
    .box .research-question {
      background: #F1F8E9 !important;              /* light lime */
      border-left: 6px solid #8BC34A !important;  /* lime green */
      color: #33691E !important;                  /* dark olive */
      padding: 14px !important;
      border-radius: 8px !important;
      margin-bottom: 12px !important;
      font-weight: 600;
      font-size: 1.1em;
      box-shadow: 0 2px 4px rgba(0,0,0,0.06) !important;
    }

    /* INSIGHT BOX: soft yellow bg with orange accent */
    .box .insight-box {
      background: #FFFDE7 !important;              /* pale yellow */
      border-left: 6px solid #FFC107 !important;  /* amber */
      color: #795548 !important;                  /* brown */
      padding: 12px !important;
      margin: 10px 0 !important;
      border-radius: 6px !important;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05) !important;
    }
      
      
      
      
    /* center both the <h3> (value) and the <p> (subtitle) in every .small-box */
    .small-box .inner h3,
    .small-box .inner p {
      text-align: center !important;
    }
    
    /* Header/Navbar Styling */
    .navbar { background-color: #004d00 !important; border-color: #003300; }
    .navbar-default .navbar-brand { color: white; }
    .navbar-default .navbar-nav > li > a { color: #f0f0f0; }
    .navbar-default .navbar-nav > .active > a, 
    .navbar-default .navbar-nav > .active > a:hover { 
      color: #ffffff; 
      background-color: #005a00; 
    }
    
    /* Sidebar Styling */
    .well { background-color: #D5E8D4 !important; } /* Lighter green background */
    .well h4, .well .control-label { color: #333333 !important; } /* Dark text for headers */
    .well .selectize-input, .well .selectize-control.single .selectize-input { 
      background-color: #FFFFFF !important; /* White background for inputs */
      color: #333; 
    }
    
    /* Box Header Styling */
    .box.box-solid.box-primary>.box-header,
    .box.box-solid.box-info>.box-header {
      color: #fff;
      background: #004d00;
      background-color: #004d00;
    }
    
    
    /* Projection Styling Styling */
    .info-box {
        padding: 1rem;
        border-left: 8px solid #3B82F6;
        background-color: #EFFCF6;
        border-radius: 4px;
        margin: 1rem 0;
        color: #1F2937;
    }
    .info-box-small {
        padding: 1rem;
        border-left: 5px solid #c8f3c5;
        background-color: #EFFCF6;
        border-radius: 4px;
        margin: 1rem 0;
        color: #1F2937;
    }
    
    .regional-rankings {
        background: #f8f8ff;
        border: 1px solid green;
        padding-bottom: 20px;
    }
    
    .ranking-title {
        margin-top: 0px;
        background: #024802; 
        color: white; 
        padding: 15px 10px;
    }
    
    .regional-rankings .col-sm-6 h4 {
            margin-left: 20px;
    
    }
    
    
    
     /* General CSS */
    
    #ikp_box, #stunting_box, #poverty_box, #pou_box {
        background-color: #f8f8f8;
        border: 1px solid #ddd;
        border-radius: 8px;
        box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.1);
    }
    
    
    
    
    
    
    
  ")))),
  
  
  ## ---- Overview tab ----
  tabPanel("Overview",
           fluidRow(
             box(width = 12, status = "primary", solidHeader = TRUE,
                 title = "Assessing Regional Food Security and Vulnerability in Indonesia (2018–2024): 
                   Addressing Food Issues, Poverty, and Stunting",
                 HTML("
              <div class='story-text'>
                <h4>Three Key Research Questions Driving Our Analysis</h4>
                <p>This dashboard is to support three analytical tasks
                : identifying priority regions, understanding determinants, 
                and assessing progress toward national targets.</p>
              </div>
            ")
             )
           ),
           # Research Question 1
           fluidRow(
             box(width = 12, status = "info", solidHeader = TRUE,
                 div(class = "research-question",
                     "Research Question 1: Which regions should be prioritized for food security interventions, 
                       and what are their dominant vulnerabilities? 
                       How do regional food security trends in Indonesia compare across time and space?"),
                 div(class = "story-text",
                     HTML("<h4>Priority Regions & Vulnerability Profiles: Spatial–Temporal Food Security Trends</h4>
                     <p>visualizes the spatial distribution of food security status (IKP composite scores) across all regions
                     (regencies/cities) from 2018 to 2024. From this entry point, users can explore trends in key indicators—stunting,
                     undernourishment (PoU), and poverty—to understand how food security has evolved nationally and regionally.
                     This tab also aims to xplores food security trends over time across Indonesian regions.
                            Denpasar tops the 2024 IKP rankings while Paniai trails, against a national average IKP of 77.3, 
                            with 22.7 % stunting and 10.5 % poverty. Since 2018, average IKP has climbed steadily, 
                            signaling moderate progress yet persistent regional gaps.</p>")),
                 div(class = "story-text",
                     HTML("<h4>Analysis of Local Food Insecurity Drivers (2024)</h4>
                     <p>This tab provides a geospatial view of locally significant variables influencing food security 
                     using GWR-based visualizations to highlight key contributing factors in each priority region. 
                            It also clusters districts by their dominant vulnerability patterns.
                            GWR reveals that priority districts are driven by different factor combos—most by poverty, 
                            water and electricity, while eastern areas face production shortfalls (NCPR) 
                            and parts of Sumatra struggle with low female schooling. 
                            PCA+KMeans then clusters these into four groups based on fiscal capacity and dominant drivers, 
                            enabling tailored intervention packages.</p>")),
                 div(class = "story-text",
                     HTML("<h4>Subsidy Impact on Food Security: A Temporal Perspective</h4>
                     <p>Evaluating the effectiveness of agricultural subsidies on IKP improvement. This visualization examining 
                            the temporal relationship between agricultural subsidies and IKP Score. Subsidy spending fell in 2022 
                            then jumped in 2023–24, paralleled by a dip and recovery in national IKP. A 2024 scatterplot reveals 
                            a moderate positive link—higher subsidies often mean higher IKP, though a few regions perform well 
                            on less funding.</p>"))
             )
           ),
           # Research Question 2
           fluidRow(
             box(width = 12, status = "info", solidHeader = TRUE,
                 div(class = "research-question",
                     "Research Question 2: How does Indonesia’s food security performance compare internationally, 
                       and what lessons can be drawn to improve national strategies?"),
                 div(class = "story-text",
                     HTML("<h4>Global Food Security Index Benchmark: Indonesia vs. International Peers (2012–2022)</h4>
                     <p>We incorporate GFSI data to benchmark Indonesia’s position in the global food security landscape
                            to identify structural gaps—such as affordability or supply chain resilience—that may influence 
                            national food security policy.
                            Indonesia’s GFSI climbed from the mid-50s to about 60 (2012–22), placing it 63rd out of 
                            113 countries—outpacing some ASEAN and Asia-Pasific peers but still trailing leaders like Singapore and Japan. 
                            Strong affordability contrasts with weaker sustainability and quality scores, 
                            pinpointing those dimensions for improvement.</p>"))
             )
           ),
           # Research Question 3
           fluidRow(
             box(width = 12, status = "info", solidHeader = TRUE,
                 div(class = "research-question",
                     "Research Question 3: Based on current and projected indicators, to what extent is 
                       Indonesia progressing toward its food security targets for 2025–2029?"),
                 div(class = "story-text",
                     HTML("<h4>Progress to 2030 Targets: Regional IKP & PoU Projections</h4>
                     <p>This tab forecasts each province’s IKP and PoU to 2030 against national targets (IKP ≥ 85; PoU ≤ 4.41%), 
                            highlighting on-track regions (e.g. Sumatera Barat) and laggards (e.g. Papua). 
                            The Top/Bottom 5 lists make it easy to see where interventions should be prioritized.</p>"))
             )
           ),
           # Executive Summary
           fluidRow(
             box(width = 12, status = "warning", solidHeader = TRUE,
                 title = "Executive Summary & Strategic Recommendations",
                 div(class = "insight-box",
                     HTML("<h4>Strategic Takeaways</h4>
                     <ul>
                       <li><strong>Geographic Focus:</strong> Prioritize interventions by cluster-driven vulnerabilities—cash + water + electricity in western/central districts, agricultural boosts + water in eastern islands, and girls’ education in Sumatra hotspots.</li>
                       <li><strong>Segment Strategy:</strong> Deploy cluster-specific packages (e.g. cash transfers + clean-water projects, seed subsidies + irrigation, micro-grid expansion + scholarships) for maximum impact.</li>
                       <li><strong>Funding Allocation:</strong> Use central-government aid for low-fiscal clusters and co-financing/local budget support for higher-fiscal areas to ensure sustainable implementation.</li>
                       <li><strong>Performance Monitoring:</strong> Leverage dynamic re-clustering, trend analyses, and projection charts in the dashboard for adaptive management and continuous evaluation.</li>
                     </ul>"))
             )
           )
  ),
  
  
  ## ---- General Overview tab ----
  tabPanel("General Overview",
           fluidRow(
             div(style = "padding: 5px 0; margin-left: 15px; margin-right: 15px;",
                 tags$p("This dashboard’s primary goal is to provide a national overview and a comprehensive, 
                         user-driven tool for exploring regional disparities in food security across Indonesia. 
                         The data cover the years 2018–2024, except for POU, which is available only from 2018 to 2023, 
                         and Stunting not available only for 2021.", 
                        style = "margin-bottom: 20px; font-size: 14px;")),
             fluidRow(valueBoxOutput("ikp_box", 3), valueBoxOutput("stunting_box", 3), 
                      valueBoxOutput("poverty_box", 3), valueBoxOutput("pou_box", 3)),
             hr()
             
           ), # end fluidrow1
           
           fluidRow(
             sidebarPanel(
               width = 3,
               h4("Filters"),
               selectInput("indicator", "Select Indicator:", choices = indicator_choices),
               selectInput("province", "Select Province:", choices = province_choices),
               sliderInput("year", "Select Year:", min = min_year, max = max_year, value = max_year, step = 1, sep = ""),
               selectInput("regional_class", "Regional Classifications:", choices = regional_choices),
               hr(),
               actionButton("show_detail", "Show Detail", icon = icon("table"), style = "width: 100%; margin-bottom: 5px;"),
               actionButton("help_info_overview", "Help/Info", icon = icon("info-circle"), style = "width: 100%;")
             ),
             
             mainPanel(
               width = 9,
               fluidRow(tabsetPanel(id = "map_trend_tabs",
                                    tabPanel("Map", h4(textOutput("map_title")), leafletOutput("map", height = "420px")),
                                    tabPanel("Trend", h4(textOutput("trend_title")), plotlyOutput("trend_chart", height = "420px")),
                                    tabPanel("Insight", h4(textOutput("desc_title")), 
                                             box(
                                               width = 9,
                                               # IKP
                                               conditionalPanel(
                                                 condition = "input.indicator == 'ikp'",
                                                 tags$div(
                                                   style = "font-size:15px; line-height:1.4; margin-bottom: 10px;",
                                                   tags$strong("Description:"), " A 0–100 composite score reflecting regional food-security resilience, based on availability, affordability, and utilization of food.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("How it’s measured:"), " Nine indicators are standardized (z-score → 0–100), then weighted into two sub-totals—availability + affordability (0.45) and utilization (0.55)—and summed.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("Insight:"), " Districts in Priority 1–3 (most vulnerable) exhibit an average consumption-to-production ratio of 4.66, poverty 21.68%, stunting 31.33%, and 53.47% of households lack clean water—underscoring multifactorial vulnerability and dependence on external food supplies."
                                                 )
                                               ),
                                               
                                               # POU
                                               conditionalPanel(
                                                 condition = "input.indicator == 'pou'",
                                                 tags$div(
                                                   style = "font-size:15px; line-height:1.4; margin-bottom: 10px;",
                                                   tags$strong("Description:"), " Share of people whose habitual dietary energy intake is below the minimum requirement, capturing chronic hunger (a core FAO/GHI metric).",
                                                   tags$br(), tags$br(),
                                                   tags$strong("How it’s measured:"), " FAO combines national food-balance sheets with household surveys to estimate dietary energy gaps annually.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("Insight:"), " Indonesia’s GHI score fell from 18.3 (2016) to 16.9 (2024), ranking 77th out of 127; by contrast, China scores <5 and India 27.3—emphasizing progress yet mid-range positioning among populous peers."
                                                 )
                                               ),
                                               
                                               # Stunting
                                               conditionalPanel(
                                                 condition = "input.indicator == 'stunting'",
                                                 tags$div(
                                                   style = "font-size:15px; line-height:1.4; margin-bottom: 10px;",
                                                   tags$strong("Description:"), " Percentage of under-five children whose height-for-age falls below –2 SD of the WHO 2005 growth standard, indicating chronic under-nutrition.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("How it’s measured:"), " Anthropometric surveys (e.g., Studi Status Gizi Indonesia, Survei Kesehatan Indonesia) compare measured heights to WHO reference charts.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("Insight:"), " Vulnerable districts average 31.33% stunting versus 23.30% in resilient ones—both exceeding the WHO “moderate” threshold—calling for integrated nutrition-specific and water-sanitation interventions."
                                                 )
                                               ),
                                               
                                               # Poverty
                                               conditionalPanel(
                                                 condition = "input.indicator == 'kemiskinan'",
                                                 tags$div(
                                                   style = "font-size:15px; line-height:1.4; margin-bottom: 10px;",
                                                   tags$strong("Description:"), " The share of people whose per-capita monthly expenditure falls below the national poverty line.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("How it’s measured:"), " Household-level data from BPS’s Susenas survey classify expenditure against the official poverty threshold.",
                                                   tags$br(), tags$br(),
                                                   tags$strong("Insight:"), " In food-insecure districts, poverty averages 21.68%, versus 11.08% in food-secure areas—both well above the 9.36% national average—highlighting persistent income gaps in eastern and remote regions."
                                                 )
                                               ),
                                               
                                               # Source footnote
                                               tags$p(em("Source: Badan Pangan Nasional"), style = "font-size:0.8em; color:#666;")
                                             )
                                    )
               )),
               fluidRow(br(), h4(textOutput("bar_chart_title")), plotlyOutput("top_bottom_chart", height = "400px"))
             )
             
           ) # end fluidrow2
  ),
  
  ## ---- GFSI tab ----
  tabPanel("Global Comparison (GFSI)",
           sidebarLayout(
             sidebarPanel(
               width = 3,
               h4("Comparison Filters"),
               sliderInput("gfsi_year", "Select Year:", min = min(gfsi_data$Year), max = max(gfsi_data$Year), value = max(gfsi_data$Year), step = 1, sep = ""),
               selectInput("country_group", "Filter by Country Group:", choices = country_group_choices, selected = "All"),
               selectizeInput("compare_country", "Compare Indonesia with (for Trend & Radar):", choices = country_choices, selected = "Malaysia", multiple = TRUE),
               hr(),
               h4("Dimension Breakdown Filter"),
               selectInput("dimension_choice", "Select Dimension for Bar Chart:", choices = dimension_choices, selected = "FOOD SECURITY ENVIRONMENT"),
               radioButtons("sort_order", "Sort Order:", choices = c("Descending" = "desc", "Ascending" = "asc"), selected = "desc", inline = TRUE),
               hr(),
               actionButton("help_info_gfsi", "Help/Info", icon = icon("info-circle"), style = "width: 100%;")
             ),
             mainPanel(
               width = 9,
               div(style = "padding: 10px 0;",
                   h4("Global Food Security Index Benchmark: Indonesia vs. International Peers (2012–2022)"),
                   p("Compare Indonesia’s food security performance globally using the Global Food Security Index (GFSI). 
                      Analyze trends from 2012 to 2022 across four key dimensions: Affordability, Availability, 
                      Sustainability & Adaptation, and Quality & Safety. Use the line, radar, and bar charts to 
                      benchmark Indonesia against regional or global peers and identify areas for improvement.")
               ),
               tabsetPanel(
                 id = "gfsi_sub_tabs",
                 tabPanel("Trend Comparison",
                          h4(textOutput("gfsi_trend_title")),
                          plotlyOutput("gfsi_line_chart", height = "400px")
                 ),
                 tabPanel("Sub-Index Comparison",
                          h4(textOutput("gfsi_radar_title")),
                          plotlyOutput("gfsi_radar_chart", height = "400px")
                 ),
                 tabPanel("Dimension Breakdown",
                          h4(textOutput("gfsi_bar_title")),
                          uiOutput("gfsi_bar_chart_ui")
                 )
               )
             )
           )
  ),
  
  ## ---- Policy Focus tab ----
  tabPanel("Policy Focus",
           
           fluidPage(
             div(style = "padding: 5px; margin-left: -15px; margin-right: -15px;",
                 h4("Policy Focus: Local Determinants of Food Security"),
                 p("Policy Focus applies GWR to reveal local food-security drivers (particulary the priority regions in 2024), 
                     then uses PCA + K-Means to group districts by their dominant vulnerability patterns, 
                     and lets you adjust the “Number of Clusters” slider to instantly update PCA plot; 
                     check cluster validity via the silhouette score; 
                     compare cluster profiles; and export data for offline analysis.")
             ),
             fluidRow(
               box(width = 12, status = "primary", solidHeader = TRUE,
                   title = "Local Significant Variables Driving Food Insecurity",
                   withSpinner(leafletOutput("policy_map", height = "350px")),
                   uiOutput("interpretasi_mapgwr")
               )
             ),
             #place controls beside the cluster charts
             fluidRow(
               column(width = 3,
                      box(width = NULL, status = "primary", solidHeader = TRUE,
                          title = "Analysis Control",
                          sliderInput("n_cluster", "Number of Clusters:", min = 2, max = 6, value = 4),
                          hr(),
                          htmlOutput("silhouette_score"),
                          hr(),
                          actionButton("help_info_policy", "Help/Info", icon = icon("info-circle"), style = "width: 100%;")
                      )
               ),
               column(width = 9,
                      box(width = NULL, status = "primary", solidHeader = TRUE, title = "Cluster Analysis Results",
                          tabsetPanel(
                            tabPanel("Cluster Plot (PCA)",
                                     br(),
                                     withSpinner(plotlyOutput("cluster_plot")),
                                     verbatimTextOutput("interpretasi"),
                                     downloadButton("downloadPlotData", "Download Cluster Data (CSV)")
                            ),
                            tabPanel("Cluster Profile",
                                     br(),
                                     withSpinner(DTOutput("profileTbl")),
                                     uiOutput("interpretasiTbl")
                            )
                          )
                      )
               )
             )
           )
  ),
  
  ## ---- Government Spending tab ----
tabPanel("Government Spending",
    sidebarLayout(
        sidebarPanel(
            width = 3,
            h4("Govt. Spending Filters"),
            selectInput("govt_province", "Province:", 
                choices = c("Indonesia" = "All", sort(unique(main_data$provinsi))), 
                selected = "All"),
            selectInput("govt_indicators", "Compare With:", 
                choices = govt_indicator_choices, selected = "ikp"),
            selectInput("govt_regional_class", "Regional Classification:", 
                choices = c("All", sort(unique(main_data$daerah_3T))), 
                selected = "All"),
            hr(),
            actionButton("help_info_spending", "Help/Info", icon = icon("info-circle"), style = "width: 100%;")
        ),
        
        mainPanel(
            width = 9,
            div(class = "info-box",
                h4("Subsidy Impact on Food Security: A Temporal Perspective"),
                p("Evaluating the effectiveness of agricultural subsidies on IKP improvement. This visualization examining 
                        the temporal relationship between agricultural subsidies and IKP Score.")), 
            
            
            tabsetPanel(id = "analysis_tabs", type = "tabs",
                tabPanel("Trend Analysis", br(),
                    div(div(class = "plot-title", textOutput("trend_title_govt", inline = TRUE)), # Use new ID to avoid conflict
                        plotlyOutput("trendPlot", height = "520px"),
                        style = "border: 1px solid #ddd; border-radius: 8px; 
                   padding: 10px; background: white;"),
                    #br(),
                    div(h5("Trend Analysis", style = "color: #2c5aa0; margin-bottom: 10px;"),
                        p("Temporal relationship between government food subsidies and selected indicator."),
                        tags$ul(tags$li("Green bars: subsidy amounts"), 
                            tags$li("Orange line: indicator values")),
                        style = "background: linear-gradient(135deg, #f8f9ff 0%, #e8f4fd 100%); 
                   border-left: 4px solid #2c5aa0; padding: 15px; 
                   border-radius: 8px; margin-top: 10px;")
                ),
                tabPanel("🎯 Correlation Analysis", br(),
                    div(div(class = "plot-title", 
                        textOutput("scatter_title_govt", inline = TRUE), # Use new ID to avoid conflict
                        selectInput("govt_year", "Year:", 
                            choices = sort(unique(main_data$year)), 
                            selected = max(main_data$year))),
                        plotlyOutput("scatterPlot", height = "320px"),
                        style = "border: 1px solid #ddd; border-radius: 8px; 
                   padding: 10px; background: white;"),
                    #br(),
                    div(h5("🎯 Correlation Analysis", style = "color: #00A86B; margin-bottom: 10px;"),
                        p("Relationship between subsidy amounts and indicator values for specific year."),
                        tags$ul(tags$li("Each dot: a province"), 
                            tags$li("Position shows subsidy vs. indicator relationship")),
                        style = "background: linear-gradient(135deg, #f0fff4 0%, #e8f5e8 100%); 
                   border-left: 4px solid #00A86B; padding: 15px; 
                   border-radius: 8px; margin-top: 10px;")
                ),
                
                tabPanel("📊 Efficiency Analysis", br(),
                    fluidRow(
                        column(6,
                            h4("Spending Efficiency by Province"),
                            plotlyOutput("efficiencyPlot", height = "400px")
                        ),
                        column(6,
                            h4("ROI Analysis: IKP Improvement per Billion Rupiah"),
                            plotlyOutput("roiPlot", height = "400px")
                        )
                    ),
                    br(),
                    fluidRow(
                        column(12,
                            h4("Efficiency Rankings"),
                            DT::dataTableOutput("efficiencyTable")
                        )
                    )
                ),
                
                
                ## 2. ADD STATISTICAL CORRELATION TAB
                tabPanel("📈 Statistical Analysis", br(),
                    fluidRow(
                        column(8,
                            h4("Correlation Strength Over Time"),
                            plotlyOutput("correlationTrendPlot", height = "400px")
                        ),
                        column(4,
                            div(class = "info-box",
                                h5("📊 Statistical Summary"),
                                verbatimTextOutput("correlationStats")
                            )
                        )
                    ),
                    br(),
                    fluidRow(
                        column(6,
                            h4("Regression Analysis"),
                            plotlyOutput("regressionPlot", height = "350px")
                        ),
                        column(6,
                            h4("Residuals Analysis"),
                            plotlyOutput("residualsPlot", height = "350px")
                        )
                    )
                ),
                
                ## 3. ADD COMPARATIVE ANALYSIS TAB
                tabPanel("🔍 Comparative Analysis", br(),
                    fluidRow(
                        column(12,
                            h4("Multi-Province Comparison"),
                            selectizeInput("compare_provinces", "Select Provinces to Compare:",
                                choices = NULL, multiple = TRUE, options = list(maxItems = 5))
                        )
                    ),
                    fluidRow(
                        column(6,
                            h4("Spending vs Outcomes Comparison"),
                            plotlyOutput("multiProvinceScatter", height = "400px")
                        ),
                        column(6,
                            h4("Efficiency Benchmarking"),
                            plotlyOutput("benchmarkPlot", height = "400px")
                        )
                    ),
                    br(),
                    fluidRow(
                        column(12,
                            h4("Best Practice Analysis"),
                            div(class = "info-box",
                                htmlOutput("bestPracticeAnalysis")
                            )
                        )
                    )
                )
                
                
                
                
                
            ) # end SUB tab panel
        )
    )
),
  
    

#################################################################################################
### ---------- Future Projections tab  ---- 
################################################################################################
    
    tabPanel("Future Projections",
        sidebarLayout(
            sidebarPanel(width = 3,
                h4("Projection Filters:", style = "color: #2C3E50;"),
                selectInput("proj_province_new", "Select Region:",
                    choices = c("Indonesia" = "indonesia", 
                        setNames(sort(unique(main_data$provinsi)), sort(unique(main_data$provinsi)))),
                    selected = "indonesia"),
                selectInput("proj_indicator_new", "Select Indicator:",
                    choices = indicator_choices_proj, selected = "ikp"),
                selectInput("regional_filter_new", "Regional Classification:",
                    choices = list("All Regions" = "all", "3T Regions" = "3T", "Non-3T Regions" = "Non-3T"),
                    selected = "all"),
                hr(),
                sliderInput("proj_year_range_new", "Year Range (Historical):",
                    min = 2018, max = 2030, value = c(2018, 2024),
                    step = 1, sep = ""),
                hr(),
                h5("2030 Goals:", style = "color: #2C3E50;"),
                p("Stunting: 14% (WHO target)", style = "color: #7F8C8D; font-size: 12px;"),
                p("IKP: 85 points", style = "color: #7F8C8D; font-size: 12px;"),
                p("PoU: 5% (zero hunger)", style = "color: #7F8C8D; font-size: 12px;"),
                actionButton("help_info_projections", "Help/Info", icon = icon("info-circle"), style = "width: 100%;")
            ),
            
            mainPanel(width = 9,
                div(class = "info-box",
                    h4("📊 Projection Analysis Overview", style = "color: #2C3E50;"),
                    p("This analysis uses ARIMA forecasting to predict future trends (2025-2030) based on historical data. 
      Compare projected performance against 2030 Sustainable Development Goals. Use regional classification 
      filter to focus on 3T (remote/disadvantaged) or Non-3T regions.")
                ),
                tabsetPanel(
                    tabPanel("Projected Trend (2025-2030)", br(),
                        plotlyOutput("projection_trend_plot", height = "500px"),
                        div(class = "info-box-small",
                            p("🔮 Shows historical data + 6-year forecast with confidence intervals. 
                          Shaded areas represent uncertainty ranges (80% and 95% confidence)."))
                        
                    ),
                    tabPanel("Progress Toward 2030 Goal", br(),
                        plotlyOutput("progress_goal_plot", height = "500px"),
                        div(class = "info-box-small",
                            p("🎯 Tracks multiple regions' projected paths toward 2030 targets. 
                          Lines above/below the goal line indicate expected achievement status."))
                    )
                ),
                
                br(),
                div(class = "regional-rankings",
                    h4("Regional Rankings", class = "ranking-title"),
                    fluidRow(
                        column(6, h4("Top Performers", style = "color: #27AE60;"),
                            plotlyOutput("top_performers_plot", height = "300px")),
                        column(6, h4("Bottom Performers", style = "color: #E67E22;"),
                            plotlyOutput("bottom_performers_plot", height = "300px"))
                    ),
                    br(),
                    h4("2030 Projection Rankings", class = "ranking-title"),
                    DT::dataTableOutput("projection_rankings_table")
                ),
                
                div(class = "info-box-small",
                    p("• Green bars: Best projected 2030 performance (lowest stunting/POU or highest IKP)", 
                        style = "color: #27AE60; font-size: 12px; margin: 5px 0;"),
                    p("• Orange bars: Areas needing most improvement for 2030 goals", 
                        style = "color: #E67E22; font-size: 12px; margin: 5px 0;"),
                    p("• ✅ Expected to achieve 2030 goal | ❌ Unlikely to meet target", 
                        style = "color: #7F8C8D; font-size: 12px; margin: 5px 0;")
                )
            )
        )
    ),
    
    

### ---------- END Future Projections tab  
################################################################################################
  
  
  
  ## ---- System Status tab ----
  tabPanel("System Status",
           fluidRow(
             box(width = 12, status = "info", solidHeader = TRUE, title = "System Health Monitor",
                 div(class = "story-text",
                     HTML("<h4>🔍 Dashboard Diagnostics</h4>
                     <p>Monitor dashboard's health and track any issues that occur during operation.
                     This helps maintain optimal performance and user experience.</p>"))
             )
           ),
           fluidRow(
             box(width = 6, status = "primary", solidHeader = TRUE, title = "Current Status",
                 verbatimTextOutput("system_status")
             ),
             box(width = 6, status = "primary", solidHeader = TRUE, title = "Data Quality Metrics",
                 tableOutput("data_quality"),
                 tags$p(strong("Notes:"),
                        "Data incompleteness is due to missing values in the 
                     PoU and Stunting datasets for the years 2021 and 2024.",
                        style = "margin-top: 15px; font-size:12px;"
                 )
             )
           ),
           fluidRow(
             box(width = 12, class = "insight-box", solidHeader = TRUE, title = "Recent Errors",
                 DT::dataTableOutput("error_table")
             )
           )
           
  ) # end tab system status
  
)


#---------------Server---------------------####

server <- function(input, output, session) {
  
  #General Overview Tab####
  base_filtered_data <- reactive({
    data <- merged_data
    if (input$province != "All Provinces") { data <- data %>% filter(provinsi == input$province) }
    if (input$regional_class == "Kepulauan") { data <- data %>% filter(kepulauan == "Kepulauan") }
    else if (input$regional_class == "Non-Kepulauan") { data <- data %>% filter(kepulauan == "Non-Kepulauan") }
    else if (input$regional_class == "3T") { data <- data %>% filter(daerah_3T == "3T") }
    else if (input$regional_class == "Non-3T") { data <- data %>% filter(daerah_3T == "Non-3T") }
    return(data)
  })
  
  year_filtered_data <- reactive({ base_filtered_data() %>% filter(year == input$year) })
  
  output$map_title <- renderText({
    region <- if (input$regional_class == "All") "" else paste("for", input$regional_class, "Regions")
    paste("Regional Distribution of", names(indicator_choices)[indicator_choices == input$indicator], "in", input$year, region)
  })
  
  output$trend_title <- renderText({
    province <- if (input$province == "All Provinces") "Indonesia" else input$province
    region <- if (input$regional_class == "All") "" else paste("in", input$regional_class, "Regions")
    paste("Trend of", names(indicator_choices)[indicator_choices == input$indicator], "in", province, region)
  })
  
  output$desc_title <- renderText({
    paste(names(indicator_choices)[indicator_choices == input$indicator])
  })
  
  output$bar_chart_title <- renderText({
    province <- if (input$province == "All Provinces") "Indonesia" else input$province
    region <- if (input$regional_class == "All") "" else paste("for", input$regional_class, "Regions")
    paste("Top & Bottom 5 Regions by", names(indicator_choices)[indicator_choices == input$indicator], "in", province, region, "(", input$year, ")")
  })
  
  output$ikp_box <- renderValueBox({
    df <- year_filtered_data(); avg <- if(nrow(df) > 0) mean(df$ikp, na.rm = TRUE) else 0
    valueBox(round(avg, 2), "Average IKP", color = "green")
  })
  
  #### ---- stunting_box ----
  output$stunting_box <- renderValueBox({
    df <- year_filtered_data()
    
    avg <- if(nrow(df) > 0) {
      mean_val <- mean(df$stunting, na.rm = TRUE)
      ifelse(is.na(mean_val), NA, mean_val)
    } else NA
    
    display_value <- if(is.na(avg)) {
      "Data Not Available"
    } else {
      paste0(round(avg, 2), "%")
    }
    
    valueBox(
      display_value, 
      "Average Stunting", 
      color = "orange"
    )
  })
  
  output$poverty_box <- renderValueBox({
    df <- year_filtered_data(); avg <- if(nrow(df) > 0) mean(df$kemiskinan, na.rm = TRUE) else 0
    valueBox(paste0(round(avg, 2), "%"), "Average Poverty", color = "red")
  })
  
  #### ---- pou_box ----
  output$pou_box <- renderValueBox({
    df <- year_filtered_data()
    
    avg <- if(nrow(df) > 0) {
      mean_val <- mean(df$pou, na.rm = TRUE)
      ifelse(is.na(mean_val), NA, mean_val)
    } else NA
    
    display_value <- if(is.na(avg)) {
      "Data Not Available"
    } else {
      paste0(round(avg, 2), "%")
    }
    
    valueBox(
      display_value, 
      "Average PoU", 
      color = "yellow"
    )
  })
  
  output$map <- renderLeaflet({ leaflet() %>% addTiles() %>% setView(lng = 118, lat = -2, zoom = 5) })
  outputOptions(output, "map", suspendWhenHidden = FALSE)  # render at start so the polygon observer's leafletProxy calls are not lost while the tab is hidden
  
  observe({
    data_map_obs <- year_filtered_data() %>% select(provinsi, kabkota, indicator_col = !!sym(input$indicator), geometry) %>% filter(!is.na(indicator_col))
    if (nrow(data_map_obs) == 0) { leafletProxy("map") %>% clearShapes() %>% clearControls(); return() }
    pal <- colorNumeric(if (input$indicator == "ikp") "YlGn" else "YlOrRd", domain = data_map_obs$indicator_col, na.color = "#f0f0f0")
    popup <- paste0("<strong>District/City:</strong> ", data_map_obs$kabkota, "<br><strong>Province:</strong> ", data_map_obs$provinsi, "<br><strong>", names(indicator_choices)[indicator_choices == input$indicator], ":</strong> ", round(data_map_obs$indicator_col, 2))
    leafletProxy("map", data = data_map_obs) %>% clearShapes() %>% clearControls() %>%
      addPolygons(fillColor = ~pal(indicator_col), weight = 1, color = "white", dashArray = "3", fillOpacity = 0.7, label = ~lapply(popup, htmltools::HTML), highlightOptions = highlightOptions(weight = 2, color = "#666", bringToFront = TRUE), layerId = ~kabkota) %>%
      addLegend(pal = pal, values = ~indicator_col, title = names(indicator_choices)[indicator_choices == input$indicator], position = "bottomright")
  })
  
  output$trend_chart <- renderPlotly({
    trend_df <- main_data
    
    if (input$province != "All Provinces") {
      trend_df <- trend_df %>% filter(provinsi == input$province)
    }
    if (input$regional_class == "Kepulauan") {
      trend_df <- trend_df %>% filter(kepulauan == "Kepulauan")
    } else if (input$regional_class == "Non-Kepulauan") {
      trend_df <- trend_df %>% filter(kepulauan == "Non-Kepulauan")
    } else if (input$regional_class == "3T") {
      trend_df <- trend_df %>% filter(daerah_3T == "3T")
    } else if (input$regional_class == "Non-3T") {
      trend_df <- trend_df %>% filter(daerah_3T == "Non-3T")
    }
    
    # Filter data based on the year slider
    trend_df_filtered <- trend_df %>% filter(year <= input$year)
    
    df_agg <- trend_df_filtered %>%
      group_by(year) %>%
      summarise(avg = mean(.data[[input$indicator]], na.rm = TRUE)) %>%
      mutate(tooltip_text = paste0("<b>Year: ", year, "</b><br>",
                                   "Average ", names(indicator_choices)[indicator_choices == input$indicator], ": ",
                                   round(avg, 2)))
    
    p <- ggplot(df_agg, aes(x = year, y = avg, text = tooltip_text, group = 1)) +
      geom_area(fill = "#a1d99b", alpha = 0.7) +
      geom_line(color = "#006400", size = 1.5) + 
      geom_point(color = "#00441b", size = 3) +
      labs(x = "Year", y = paste("Average", names(indicator_choices)[indicator_choices == input$indicator])) + 
      theme_minimal(base_size = 14) +
      scale_x_continuous(breaks = scales::pretty_breaks(n=length(unique(main_data$year))))
    
    ggplotly(p, tooltip = "text")
  })
  
  
  output$top_bottom_chart <- renderPlotly({
    df <- year_filtered_data() %>% 
      select(kabkota, indicator_col = !!sym(input$indicator)) %>% 
      filter(!is.na(indicator_col))
    
    if (nrow(df) < 10) return(NULL)
    
    top5 <- df %>% arrange(desc(indicator_col)) %>% slice(1:5)
    bottom5 <- df %>% arrange(indicator_col) %>% slice(1:5)
    
    combined <- bind_rows(top5, bottom5) %>% 
      mutate(
        type = rep(c("Top 5", "Bottom 5"), each = 5),
        kabkota = factor(kabkota, levels = kabkota),
        tooltip_text = paste0("<b>", kabkota, "</b><br>",
                              names(indicator_choices)[indicator_choices == input$indicator], ": ", 
                              round(indicator_col, 2))
      )
    
    p <- ggplot(combined, aes(x = reorder(kabkota, indicator_col), y = indicator_col, 
                              fill = type, text = tooltip_text)) +
      geom_col() + 
      coord_flip() + 
      facet_wrap(~type, scales = "free_y") +
      scale_fill_manual(values = c("Top 5" = "#006400", "Bottom 5" = "#d9534f")) +
      labs(x = "", y = names(indicator_choices)[indicator_choices == input$indicator]) + 
      theme_minimal(base_size = 12)
    
    ggplotly(p, tooltip = "text") %>% 
      layout(
        showlegend = FALSE,
        margin = list(t = 50) 
      )
  })
  
  observeEvent(input$show_detail, { 
    showModal(modalDialog(
      title = paste("Detailed Data for", input$year), 
      DT::dataTableOutput("detail_table"), 
      footer = downloadButton("download_detail_data", "Download as CSV"),
      easyClose = TRUE, 
      size = "l"
    )) 
  })
  
  output$detail_table <- DT::renderDataTable({
    df <- year_filtered_data() %>% st_drop_geometry() %>% select(Province = provinsi, `District/City` = kabkota, `Indicator Value` = !!sym(input$indicator))
    datatable(df, options = list(pageLength = 10), rownames = FALSE)
  })
  
  output$download_detail_data <- downloadHandler(
    filename = function() {
      paste0("detailed_data_", input$indicator, "_", input$year, ".csv")
    },
    content = function(file) {
      df <- year_filtered_data() %>% 
        st_drop_geometry() %>% 
        select(
          Province = provinsi, 
          `District/City` = kabkota, 
          Indicator_Value = !!sym(input$indicator),
          Year = year,
          Regional_Classification_3T = daerah_3T,
          Regional_Classification_Island = kepulauan
        )
      write.csv(df, file, row.names = FALSE)
    }
  )
  
  ## ---- help info modals ----
  observeEvent(input$help_info_overview, { 
    showModal(modalDialog(title = "General Overview Information", 
                          h4("Indicator Definitions"), 
                          p(strong("IKP:"), " Food Security Index. A composite measure of food availability, affordability, and utilization."), 
                          p(strong("Stunting:"), " Percentage of children with impaired growth due to malnutrition. Data is not available for 2021."), 
                          p(strong("Poverty:"), " Percentage of the population living below the national poverty line."), 
                          p(strong("PoU:"), " Prevalence of Undernourishment, indicating chronic hunger. Data is available only for the years 2018-2023."), 
                          h4("How to Use"),
                          p("Use the filters on the left to explore the data. You can view data by indicator, province, year, and regional classification. The map, trend chart, and top/bottom charts will update based on your selections."),
                          easyClose = TRUE)) 
  })
  
  observeEvent(input$help_info_gfsi, {
    showModal(modalDialog(
      title = "Global Comparison (GFSI) Information",
      h4("About GFSI"),
      p("The Global Food Security Index (GFSI) is a dynamic quantitative and qualitative benchmarking model that constructs an understanding of the drivers of food security across 113 countries."),
      h4("Dimensions"),
      p(strong("Affordability:"), " Measures the ability of consumers to purchase food, their vulnerability to price shocks, and the presence of programs and policies that support them."),
      p(strong("Availability:"), " Measures the sufficiency of the national food supply, the risk of supply disruption, national capacity to disseminate food, and research efforts to expand agricultural output."),
      p(strong("Quality & Safety:"), " Measures the variety and nutritional quality of average diets, as well as the safety of food."),
      p(strong("Sustainability & Adaptation:"), " Assesses a country’s exposure to the impacts of climate change; its sensitivity to natural resource risks; and how the country is adapting to these risks."),
      easyClose = TRUE
    ))
  })
  
  observeEvent(input$help_info_policy, {
    showModal(modalDialog(
      title = "Policy Focus Information",
      h4("Analysis Methods"),
      p(strong("Geographically Weighted Regression (GWR):"), " This method is used to model local relationships between food insecurity (dependent variable) and its potential drivers (independent variables). Unlike standard regression, GWR allows the relationships to vary across space, providing insights into local-level drivers."),
      p(strong("Principal Component Analysis (PCA) & K-Means Clustering:"), " PCA is used to reduce the dimensionality of the GWR coefficient data. The principal components, which capture the main patterns of variation, are then used in K-Means clustering to group districts with similar food security driver profiles."),
      h4("How to Interpret"),
      p(strong("Map:"), " Shows the most significant local driver or combination of drivers for food insecurity in each priority district."),
      p(strong("Cluster Plot:"), " Visualizes the district clusters based on their primary underlying vulnerability patterns. Districts in the same cluster face similar challenges."),
      p(strong("Silhouette Score:"), " Measures how well-defined the clusters are. A score closer to 1 indicates a good clustering structure."),
      easyClose = TRUE
    ))
  })
  
  observeEvent(input$help_info_spending, {
    showModal(modalDialog(
      title = "Government Spending Information",
      h4("About This Tab"),
      p("This tab explores the relationship between government food subsidy spending and key food security indicators (IKP, Stunting, Poverty, PoU) at the provincial and national levels."),
      h4("Visualizations"),
      p(strong("Trend Analysis:"), " Shows the year-over-year trend of government spending (bars) against the selected food security indicator (line). This helps to see if changes in spending correlate with changes in the indicator over time."),
      p(strong("Correlation Analysis:"), " This scatter plot shows the relationship between spending and the selected indicator for a single year. Each dot represents a province, helping to identify potential outliers or patterns."),
      easyClose = TRUE
    ))
  })
  
  observeEvent(input$help_info_projections, {
    showModal(modalDialog(
      title = "Future Projections Information",
      h4("Forecasting Method"),
      p("The projections are generated using an ", strong("Auto-ARIMA model")," (Autoregressive Integrated Moving Average). This statistical model is widely used for time-series forecasting. It automatically selects the best model parameters based on the historical data for the selected indicator and geographical level."),
      h4("How to Use"),
      p("Select an indicator (IKP or PoU) and a geographical level to see the projected trend until 2030. The charts show the historical data, the forecasted trend, and confidence intervals (80% and 95%). You can also see a comparison of regional progress towards 2030 goals and a ranking of the top/bottom 5 performing regions for your selected year."),
      easyClose = TRUE
    ))
  })
  
  #Global Comparison Tab####
  
  observe({
    if (input$country_group == "All") {
      choices <- sort(unique(gfsi_data$Country[gfsi_data$Country != "Indonesia"]))
    } else {
      choices <- sort(unique(gfsi_data$Country[gfsi_data$Group == input$country_group & gfsi_data$Country != "Indonesia"]))
    }
    updateSelectizeInput(session, "compare_country", choices = choices, selected = if(length(choices)>0) choices[1] else NULL)
  })
  
  gfsi_filtered_trend <- reactive({
    req(input$compare_country)
    gfsi_data %>% filter(Country %in% c("Indonesia", input$compare_country))
  })
  
  output$gfsi_trend_title <- renderText({
    req(input$compare_country)
    paste("GFSI Score Trend Comparison for Indonesia and", paste(input$compare_country, collapse = ", "))
  })
  
  output$gfsi_radar_title <- renderText({
    req(input$compare_country)
    paste("GFSI Sub-Index Comparison for", paste(c("Indonesia", input$compare_country), collapse = ", "), "in", input$gfsi_year)
  })
  
  output$gfsi_bar_title <- renderText({
    dimension_name <- names(dimension_choices)[dimension_choices == input$dimension_choice]
    group_name <- if (input$country_group == "All") "All Countries" else input$country_group
    paste("Country Comparison for", dimension_name, "in", input$gfsi_year, "(Group:", group_name, ")")
  })
  
  output$gfsi_line_chart <- renderPlotly({
    line_data <- gfsi_filtered_trend() %>% 
      filter(
        Indicator == "FOOD SECURITY ENVIRONMENT",
        Year <= input$gfsi_year
      ) %>%
      mutate(tooltip_text = paste0("<b>", Country, " (", Year, ")</b><br>",
                                   "GFSI Score: ", round(Value, 2)))
    
    if(nrow(line_data) == 0) return(NULL)
    
    countries <- unique(line_data$Country)
    other_countries <- countries[countries != "Indonesia"]
    
    colors <- if(length(other_countries) > 0) {
      c("red", brewer.pal(n = max(3, length(other_countries)), name = "Paired")[1:length(other_countries)])
    } else { "red" }
    names(colors) <- c("Indonesia", other_countries)
    
    p <- ggplot(line_data, aes(x = Year, y = Value, color = Country, group = Country, text = tooltip_text)) +
      geom_line(size = 1.5) +
      geom_point(size = 3) +
      scale_color_manual(name = "Country", values = colors) +
      scale_x_continuous(breaks = scales::pretty_breaks(n = length(unique(line_data$Year)))) +
      theme_minimal(base_size = 14) +
      labs(x = "Year", y = "GFSI Score")
    
    ggplotly(p, tooltip = "text")
  })
  
  gfsi_filtered_year <- reactive({
    req(input$compare_country, input$gfsi_year)
    gfsi_data %>% filter(Country %in% c("Indonesia", input$compare_country), Year == input$gfsi_year)
  })
  
  output$gfsi_radar_chart <- renderPlotly({
    main_indicators_numbered <- c("1) AFFORDABILITY", "2) AVAILABILITY", 
                                  "3) QUALITY AND SAFETY", "4) SUSTAINABILITY AND ADAPTATION")
    
    main_indicator_labels <- sub(".*\\) ", "", main_indicators_numbered)
    
    radar_data_long <- gfsi_filtered_year() %>% 
      filter(Indicator %in% main_indicators_numbered) %>%
      distinct(Country, Indicator, .keep_all = TRUE) %>%
      mutate(Indicator = sub(".*\\) ", "", Indicator)) %>%
      mutate(Indicator = factor(Indicator, levels = main_indicator_labels)) %>%
      arrange(Country, Indicator) %>%
      group_by(Country) %>%
      filter(n() == length(main_indicators_numbered)) %>%
      ungroup()
    
    if(nrow(radar_data_long) == 0) return(NULL)
    
    countries <- unique(radar_data_long$Country)
    other_countries <- countries[countries != "Indonesia"]
    colors <- if(length(other_countries) > 0) {
      c("red", brewer.pal(n = max(3, length(other_countries)), name = "Paired")[1:length(other_countries)])
    } else { "red" }
    names(colors) <- c("Indonesia", other_countries)
    
    fig <- plot_ly(type = 'scatterpolar', mode = 'lines+markers', fill = 'toself')
    
    for (country_name in countries) {
      country_data <- radar_data_long %>% filter(Country == country_name)
      
      if(nrow(country_data) > 0) {
        # Append first row to the end to close the radar loop
        country_data <- bind_rows(country_data, country_data[1, ])
      }
      
      fig <- fig %>% add_trace(
        r = country_data$Value,
        theta = country_data$Indicator,
        name = country_name,
        marker = list(color = colors[country_name]),
        line = list(color = colors[country_name]),
        fillcolor = toRGB(colors[country_name], alpha = 0.3),
        hoverinfo = "text",
        text = ~paste('<b>', country_data$Country, '</b><br>',
                      country_data$Indicator,
                      ': ', round(country_data$Value, 2))
      )
    }
    
    fig %>% layout(
      polar = list(
        radialaxis = list(
          visible = T,
          range = c(0, 100)
        )
      ),
      showlegend = TRUE,
      legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.1)
    )
  })
  
  output$gfsi_bar_chart_ui <- renderUI({
    bar_data <- gfsi_data %>% filter(Year == input$gfsi_year)
    if (input$country_group != "All") {
      bar_data <- bar_data %>% filter(Group == input$country_group)
    }
    num_countries <- length(unique(bar_data$Country))
    plot_height <- max(600, num_countries * 25) # Dynamic height
    plotlyOutput("gfsi_bar_chart_plotly", height = paste0(plot_height, "px")) # Switched to plotlyOutput
  })
  
  output$gfsi_bar_chart_plotly <- renderPlotly({ # Switched to renderPlotly
    req(input$dimension_choice, input$sort_order)
    
    bar_data_filtered <- gfsi_data %>%
      filter(
        Year == input$gfsi_year,
        Indicator == input$dimension_choice
      )
    
    if (input$country_group != "All") {
      bar_data_filtered <- bar_data_filtered %>% filter(Group == input$country_group)
    }
    
    bar_data_filtered <- bar_data_filtered %>%
      distinct(Country, .keep_all = TRUE)
    
    if(nrow(bar_data_filtered) == 0) {
      return(plot_ly() %>% layout(title = "No data available for selected options."))
    }
    
    
    plot_data <- bar_data_filtered %>%
        arrange(if(input$sort_order == "desc") desc(Value) else Value) %>%
        mutate(Country_f = factor(Country, levels = Country[order(Value, decreasing = (input$sort_order == "desc"))]),
             color = ifelse(Country == "Indonesia", "#e41a1c", "#377eb8"))
    
    p <- plot_ly(plot_data, y = ~Country_f, x = ~Value, type = 'bar', orientation = 'h',
                 marker = list(color = ~color),
                 text = ~round(Value, 1),
                 textposition = 'outside',
                 hoverinfo = 'text',
                 hovertext = ~paste0("<b>", Country, "</b><br>Score: ", round(Value, 1))) %>%
      layout(
        yaxis = list(title = "", categoryorder = "trace"), # Use trace order
        xaxis = list(title = "Score"),
        showlegend = FALSE,
        margin = list(l = 150) # Add left margin for long country names
      )
    
    p
  })
  
  
  
  # Server For policy focus ####
  
  ## ---- policy_data_prep ----
  #This reactive expression will perform the heavy GWR and PCA calculations
  #It will only run once its inputs change or when it's first called.
  policy_data_prep <- reactive({
    
    #Filter only year 2024 for GWR analysis
    data_2024 <- main_data %>%
      filter(year == 2024)
    
    #Check and Create Priority Column (komposit <= 3)
    data_2024 <- data_2024 %>%
      mutate(prioritas = ifelse(komposit <= 3, 1, 0))
    
    #Select only priority regions
    data_prioritas <- data_2024 %>%
      filter(prioritas == 1)
    
    #Select relevant columns
    data_model <- data_prioritas %>%
      select(provinsi, kabkota, kode_kabkota, ikp, komposit, ncpr, kemiskinan, pengeluaran_pangan, 
             tanpa_listrik, tanpa_air, lama_sekolah_perempuan, rasio_nakes, ahh, 
             kepulauan, daerah_3T, fiskal, longitude, latitude)
    
    #Convert to sf object
    data_sf <- st_as_sf(data_model, coords = c("longitude", "latitude"), crs = 4326)
    
    #Find Optimal GWR Bandwidth
    bw <- bw.gwr(
      formula = komposit ~ ncpr + kemiskinan + pengeluaran_pangan + tanpa_listrik +
        tanpa_air + lama_sekolah_perempuan + rasio_nakes + ahh,
      data = as(data_sf, "Spatial"),
      approach = "AICc", kernel = "bisquare", adaptive = TRUE
    )
    
    #Running GWR to Find GWR Model
    gwr_model <- gwr.basic(
      formula = komposit ~ ncpr + kemiskinan + pengeluaran_pangan + tanpa_listrik +
        tanpa_air + lama_sekolah_perempuan + rasio_nakes + ahh,
      data = as(data_sf, "Spatial"),
      bw = bw, kernel = "bisquare", adaptive = TRUE
    )
    
    result_df <- as.data.frame(gwr_model$SDF)
    
    #Marking Local Sig Variable (|t| > 2)
    result_df <- result_df %>%
      mutate(
        sig_ncpr = abs(ncpr_TV) > 2,
        sig_kemiskinan = abs(kemiskinan_TV) > 2,
        sig_pengeluaran = abs(pengeluaran_pangan_TV) > 2,
        sig_listrik = abs(tanpa_listrik_TV) > 2,
        sig_air = abs(tanpa_air_TV) > 2,
        sig_lsp = abs(lama_sekolah_perempuan_TV) > 2,
        sig_nakes = abs(rasio_nakes_TV) > 2,
        sig_ahh = abs(ahh_TV) > 2
      ) %>%
      rename(
        ncpr_koef = ncpr, kemiskinan_koef = kemiskinan, pengeluaran_koef = pengeluaran_pangan,
        tlistrik_koef = tanpa_listrik, tair_koef = tanpa_air, lsp_koef = lama_sekolah_perempuan,
        rnakes_koef = rasio_nakes, ahh_koef = ahh
      )
    
    data_sf_result <- bind_cols(data_sf, result_df)
    
    # Create Category Column for Combination of Significant Variables
    data_sf_result <- data_sf_result %>%
      mutate(
        signif_group = pmap_chr(list(sig_ncpr, sig_kemiskinan, sig_pengeluaran, sig_listrik,
                                     sig_air, sig_lsp, sig_nakes, sig_ahh),
                                function(ncpr, kemiskinan, pengeluaran, listrik, air, lsp, nakes, ahh) {
                                  vars <- c("ncpr", "kemiskinan", "pengeluaran", "listrik", "air", "lama sekolah perempuan", "nakes", "ahh")
                                  flags <- c(ncpr, kemiskinan, pengeluaran, listrik, air, lsp, nakes, ahh)
                                  group <- vars[which(flags)]
                                  if (length(group) == 0) "Tidak terdapat variabel signifikan" else paste(group, collapse = ", ")
                                })
      )
    
    data_result <- data_sf_result %>% 
      mutate(join_id = as.character(kode_kabkota)) %>%
      st_drop_geometry()
    
    # Use pre-loaded spatial data
    # Merge by region (Kabupaten/Kota)
    data_map <- data_result %>%
      left_join(spatial_data_prep, by = "join_id") %>%
      st_as_sf()
    
    cluster_data <- data_map %>%
      st_drop_geometry() %>%
      filter(!is.na(fiskal)) %>% 
      select(kabkota, provinsi, ends_with("_koef"), fiskal, signif_group) %>%
      mutate(
        fiskal_num = case_when(
          fiskal == "Sangat Rendah" ~ 1,
          fiskal == "Rendah" ~ 2,
          fiskal == "Sedang" ~ 3,
          fiskal == "Tinggi" ~ 4,
          fiskal == "Sangat Tinggi" ~ 5
        ))
    
    scaled_cluster_data <- cluster_data %>%
      select(-kabkota, -provinsi, -fiskal, -signif_group) %>%
      scale() %>%
      as.data.frame() %>%
      mutate(kabkota = cluster_data$kabkota, provinsi = cluster_data$provinsi, 
             fiskal = cluster_data$fiskal, signif_group = cluster_data$signif_group)
    
    pca_data <- scaled_cluster_data %>% select(ends_with("_koef"))
    pca_result <- PCA(pca_data, graph = FALSE)
    
    plot_coords <- data.frame(
      kabkota = scaled_cluster_data$kabkota,
      provinsi = scaled_cluster_data$provinsi,
      Dim1 = pca_result$ind$coord[, 1],
      Dim2 = pca_result$ind$coord[, 2]
    )
    
    pca_var <- get_pca_var(pca_result)
    
    dominant_vars <- data.frame(
      Variabel = rownames(pca_var$contrib),
      Kontribusi_Dim1 = round(pca_var$contrib[, 1], 1),
      Kontribusi_Dim2 = round(pca_var$contrib[, 2], 1)
    ) %>%
      arrange(desc(Kontribusi_Dim1 + Kontribusi_Dim2)) %>%
      head(3)
    
    dominant_vars$Variabel <- recode(
      dominant_vars$Variabel,
      "ncpr_koef" = "Food Production-to-Normative Consumption Ratio", "kemiskinan_koef" = "Tingkat Kemiskinan",
      "tlistrik_koef" = "Rumah Tanpa Listrik", "tair_koef" = "Rumah Tanpa Air Bersih",
      "lsp_koef" = "Lama Sekolah Perempuan usia >15 Tahun", "rnakes_koef" = "Rasio Tenaga Kesehatan",
      "ahh_koef" = "Angka Harapan Hidup"
    )
    
    #Return a list of all data objects needed for the UI
    list(
      map = data_map,
      cluster = scaled_cluster_data,
      coord = plot_coords,
      var = dominant_vars,
      pca = pca_result
    )
  })
  
  # Define Color Categories
  # 1) The exact text values coming out of your GWR -> "variabel_signifikan"
  cats <- c(
    "kemiskinan, listrik, air",
    "kemiskinan, listrik, air, lama sekolah perempuan",
    "kemiskinan, listrik, lama sekolah perempuan",
    "ncpr, kemiskinan, air",
    "ncpr, kemiskinan, listrik, air"
  )
  
  # 2) Pick a hex‐colour for each (in the same order)
  cols <- c(  
    "#129990",  
    "#D50B8B",
    "#FF2DF1",  
    "#F2C078",  
    "#FF9F00"
  )
  
  ## ---- policy_map ----
  #Leaflet Map for Policy Focus
  output$policy_map <- renderLeaflet({
    req(policy_data_prep())
    data_map_policy <- policy_data_prep()$map
    
    pal <- colorFactor(
      palette = cols,     # manual vector of colours
      domain  = cats      # in the exact same order
    )
    
    leaflet(data_map_policy) %>%
      addTiles() %>%  
      addPolygons(
        fillColor   = ~pal(signif_group),
        fillOpacity = 0.7,
        color       = "#444",
        weight      = 1,
        label       = ~signif_group
      ) %>%
      addLegend(
        position = "bottomright",
        pal      = pal,
        values   = ~signif_group,
        title    = "Variabel Signifikan Lokal",
        opacity  = 1
      )
  })
  
  ## ---- interpretasi_mapgwr ----
  #Interpretation Text
  # server.R
  output$interpretasi_mapgwr <- renderUI({
    req(policy_data_prep())
    
    tags$div(
      style = "font-size:14px; line-height:1.5; margin-bottom: 20px;",
      
      # Heading
      tags$h4("Insightful summary for the 62 priority districts (2024):",
              style = "margin-bottom: 10px;"),
      
      # Bullet list with colored markers
      tags$ul(
        style = "list-style: none; padding-left: 0; margin-left: 0;",
        
        # 1
        tags$li(
          tags$strong("Diverse driver “recipes”: "),
          "GWR uncovers multiple local combinations of vulnerability factors rather than a one-size-fits-all pattern."
        ),
        
        # 2
        tags$li(
          tags$span("●", style = "color:green; font-size:16px; margin-right:5px; vertical-align:middle;"),
          tags$strong("Poverty + Electricity + Water:"), 
          "The most common trio in middle and western districts—calls for 
                    integrated cash-support, grid expansion, and clean-water projects."
        ),
        
        # 3
        tags$li(
          tags$span("●", style = "color:deeppink; font-size:16px; margin-right:5px; vertical-align:middle;"),
          tags$strong("Female Schooling:"), 
          " In parts of Sumatera, low girls’ education amplifies basic-infra impacts—so invest in female schooling."
        ),
        
        # 4
        tags$li(
          tags$span("●", style = "color:orange; font-size:16px; margin-right:5px; vertical-align:middle;"),
          tags$strong("NCPR + Poverty + Water (± Electricity):"), 
          " In Papua/Maluku, large production–consumption gaps with poverty and water shortfalls demand 
                    agricultural boosts and water-supply improvements (and electrification in orange areas)."
        )
      ),
      
      # Additional callouts
      tags$p(
        tags$em("Majority vs. niche needs:"), 
        " About two-thirds of districts are driven by basic infra/income deficits; 
                one-third face additional production or education bottlenecks.",
        br(),
        tags$em("Targeted interventions:"), 
        " Align programs to each district’s dominant drivers—e.g., 
                cash (income support)+infrastructure for the “green” districts; 
                agriculture+water in eastern islands; education where schooling is weak."
      )
    )
  })
  
  
  #Reactive for K-Means clustering results
  cluster_results <- reactive({
    req(policy_data_prep())
    data_to_cluster <- policy_data_prep()$cluster
    req(nrow(data_to_cluster) > 0)
    set.seed(123)
    kmeans(data_to_cluster %>% select(-kabkota, -provinsi, -fiskal, -signif_group), centers = input$n_cluster)
  })
  
  ## ---- silhouette_score ----
  #Silhouette Score UI
  output$silhouette_score <- renderUI({
    req(cluster_results())
    
    # Compute the average silhouette score
    data_to_dist <- policy_data_prep()$cluster
    sil_score    <- silhouette(
      cluster_results()$cluster,
      dist(data_to_dist %>% select(-kabkota, -provinsi, -fiskal, -signif_group))
    )
    avg_score    <- round(mean(sil_score[, "sil_width"]), 2)
    
    # Decide color + interpretation tag
    ok    <- avg_score > 0.5
    color <- if (ok) "green" else "red"
    label <- if (avg_score > 0.7) {
      "Strong cluster structure"
    } else if (avg_score > 0.5) {
      "Reasonable structure"
    } else {
      "Needs reevaluation"
    }
    
    tags$div(
      style = "font-family: Arial, sans-serif; font-size: 12px; line-height:1.4; margin-bottom: 20px;",
      
      # ——— The styled score box ———
      tags$div(
        style = paste0(
          "padding: 12px; ",
          "border-left: 5px solid ", color, "; ",
          "background-color: #f5f5f5;"
        ),
        tags$strong("Silhouette Score: "), 
        span(paste0("Average = ", avg_score, " "), style = paste0("color:", color, ";")), 
        tags$br(),
        tags$em(paste0("(", label, ")"))
      ),
      
      # ——— Explanation section ———
      tags$h5("What is it?", style = "margin-top: 15px; font-size:14px;"),
      tags$p(
        "A number between –1 and 1 that shows how well each district ",
        "fits its cluster (cohesion) versus the next‐best cluster (separation)."
      ),
      
      tags$h5("Why it matters", style = "margin-top: 10px; font-size:14px;"),
      tags$p(
        "You can compare silhouette scores when you change “Number of Clusters” ",
        "to see which choice gives the clearest, most reliable grouping."
      ),
      
      tags$h5("How we did it", style = "margin-top: 10px; font-size:14px;"),
      tags$p(
        "We use PCA to reduce correlated indicators into key components, then ",
        "K-Means to quickly group districts by those main patterns—giving stable, ",
        "easy-to-interpret clusters."
      )
    )
  })
  
  
  
  ## ---- cluster_plot ----
  #PCA Cluster Plot
  output$cluster_plot <- renderPlotly({
    req(policy_data_prep(), cluster_results())
    
    plot_data <- policy_data_prep()$coord %>%
      mutate(cluster = as.factor(cluster_results()$cluster))
    
    plot_ly(
      data = plot_data, x = ~Dim1, y = ~Dim2, color = ~cluster,
      text = ~paste("Region:", kabkota, "<br>Province:", provinsi, "<br>Cluster: ", cluster),
      hoverinfo = "text", title = "Clusters on first two Principal Components"
    ) %>% layout(
      title = list(text = "Clusters on First Two Principal Components", x = 0.5),
      xaxis = list(title = "Principal Component 1"), yaxis = list(title = "Principal Component 2")
    ) 
  })
  
  ## ---- interpretasi ----
  #Interpretation Text
  output$interpretasi <- renderText({
    req(policy_data_prep())
    dominant_vars <- policy_data_prep()$var
    paste(
      "Interpretation:\n",
      "* Each point represents one regency/city.\n",
      "* Different colors indicate different clusters.\n",
      "* The most influential factors:\n  1. ", 
      dominant_vars$Variabel[1], "(Total influence on cluster pattern: ", 
      round(dominant_vars$Kontribusi_Dim1[1] + dominant_vars$Kontribusi_Dim2[1], 1),"%)\n  2. ",
      dominant_vars$Variabel[2], "(Total influence on cluster pattern: ", 
      round(dominant_vars$Kontribusi_Dim1[2] + dominant_vars$Kontribusi_Dim2[2], 1),"%)"
    )
  })
  
  ## ---- interpretasiTbl ----
  #Interpretation Text
  output$interpretasiTbl <- renderUI({
    req(policy_data_prep())
    
    tags$div(
      style = "font-size:14px; line-height:1.5; margin: 20px 0;",
      
      # Section title
      tags$h4("Interpretation", style = "margin-bottom:10px;"),
      
      # Main bullet list
      tags$ul(
        style = "padding-left: 20px; margin-bottom: 15px;",
        tags$li(tags$strong("Validate clusters:"), "Ensure each cluster has enough districts (e.g. ≥5) for reliable grouping."),
        tags$li(tags$strong("Identify key drivers:"), "Review each cluster’s “signif_group” to see dominant factors (poverty, water, NCPR, electricity, schooling)."),
        tags$li(tags$strong("Assess context & fiscal:"), "Note region and fiscal capacity—low-fiscal clusters need central-government aid, while high-fiscal clusters can be supported and scaled by local authorities."),
        tags$li(tags$strong("Map to interventions:"), "Link driver combos to policy packages (e.g. poverty+water → cash transfers + clean-water projects; NCPR → seed subsidies + agri training).")
      ),
      
      # Example subsection
      tags$h5("Example (k = 4):", style = "margin-top:10px; margin-bottom:5px;"),
      
      # Sub-list of examples
      tags$ul(
        style = "padding-left: 20px;",
        tags$li(tags$strong("C1:"), " Poverty + Water (low fiscal) → central cash + piped water"),
        tags$li(tags$strong("C2:"), " NCPR + Poverty (mixed fiscal) → agri inputs + training (central ↔ local co-fund)"),
        tags$li(tags$strong("C3:"), " Electricity + Schooling (high fiscal) → local micro-grid + girls’ scholarships"),
        tags$li(tags$strong("C4:"), " Multi-driver → integrated cash + infra + agri support (central support where needed)")
      )
    )
  })
  
  ## ---- profileTbl ----
  #Cluster Profile Table
  output$profileTbl <- renderDT({
    req(cluster_results())
    data_cluster <- policy_data_prep()$cluster
    
    # Function to delete duplicate value
    remove_duplicates <- function(x) {
      elements <- unlist(strsplit(x, ", "))
      unique_elements <- unique(elements)
      paste(unique_elements, collapse = ", ")
    }
    
    clustered_data <- data_cluster %>%
      mutate(cluster = cluster_results()$cluster)
    
    profile <- clustered_data %>% 
      group_by(cluster) %>%
      summarise(across(where(is.numeric), mean, na.rm = TRUE), .groups = "drop")
    
    id_vars <- clustered_data %>% 
      select(where(Negate(is.numeric))) %>% 
      mutate(cluster = clustered_data$cluster)
    
    id_summary <- id_vars %>% 
      group_by(cluster) %>% 
      summarise(
        across(everything(), ~ if(is.character(.)) {
          paste(unique(unlist(strsplit(., ", "))), collapse = ", ")
        } else {
          paste(unique(.), collapse = ", ")
        }),
        total = n(),
        .groups = "drop"
      )
    
    merged <- left_join(profile, id_summary, by = "cluster")
    
    datatable(merged[, c("cluster", "total", "kabkota", "provinsi", "fiskal", "signif_group")], 
              options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
  
  ## ---- downloadPlotData ----
  #Download Handler for Cluster Data
  output$downloadPlotData <- downloadHandler(
    filename = function() {
      paste("cluster-data-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(cluster_results())
      data_cluster_to_download <- policy_data_prep()$cluster %>%
        mutate(cluster = cluster_results()$cluster)
      write.csv(data_cluster_to_download, file, row.names = FALSE)
    }
  )
  
  
  
  
  #############################################################################################################################################
  ### ----------GOVERMENT SERVER LOGIC ---- 
  ###########################################################################################################################################
  #############################################################################################################################################
  ### ----------FIXED GOVERNMENT SERVER LOGIC ---- 
  ###########################################################################################################################################
  
  govt_filtered_data <- reactive({
      data <- main_data
      
      # Apply regional classification filter
      if (input$govt_regional_class != "All") {
          data <- data %>% filter(daerah_3T == input$govt_regional_class)
      }
      
      return(data)
  })
  
  govt_agg_data <- reactive({
      create_aggregated_data_govt(govt_filtered_data())
  })
  
  current_govt_indicator <- reactive({
      get_indicator_info(input$govt_indicators)
  })
  
  govt_trend_data <- reactive({
      create_trend_data_govt(govt_agg_data(), input$govt_province, input$govt_indicators)
  })
  
  govt_scatter_data <- reactive({
      create_scatter_data_govt(govt_agg_data(), input$govt_year, input$govt_province, input$govt_indicators)
  })
  
  output$trend_title_govt <- renderText({
      create_plot_title("trend", current_govt_indicator(), input$govt_province, 
          regional_class = input$govt_regional_class)
  })
  
  output$scatter_title_govt <- renderText({
      create_plot_title("scatter", current_govt_indicator(), input$govt_province, 
          input$govt_year, input$govt_regional_class)
  })
  
  output$scatterPlot <- renderPlotly({
      dat <- govt_scatter_data()
      indicator_info <- current_govt_indicator()
      dat <- create_hover_text(dat, indicator_info, input$govt_year, 
          input$govt_province)
      
      plot_ly(dat, x = ~indicator, y = ~subsidi_juta/1e6,
          text = if(input$govt_province == "All") ~provinsi else ~paste("Year:", input$govt_year),
          type = "scatter", mode = "markers",
          marker = list(size = 10, color = "#00A86B", opacity = 0.7,
              line = list(color = "white", width = 1)),
          hoverinfo = "text", hovertext = ~hover_txt
      ) %>%
          layout(
              xaxis = list(title = indicator_info$label),
              yaxis = list(title = "Govt. Spending (Rp Trillion)", tickformat = ",.0f"),
              margin = list(l = 70, r = 70, t = 30, b = 70), showlegend = FALSE
          ) %>% config(displayModeBar = FALSE)
  })
  
  output$trendPlot <- renderPlotly({
      dat <- govt_trend_data()
      indicator_info <- current_govt_indicator()
      
      dat <- dat %>% mutate(subs_tr = subsidi_juta / 1e6)
      
      dat <- dat %>%
          mutate(hover_txt = paste0("Year: ", year,
              "<br>Subsidy: Rp ", scales::comma(round(subsidi_juta/1e3, 1)), 
              " Billion", "<br>", indicator_info$label, ": ", round(indicator, 1)))
      
      max_subs <- max(dat$subs_tr, na.rm = TRUE)
      max_indicator <- max(dat$indicator, na.rm = TRUE)
      fac <- if(max_indicator > 0) max_subs / max_indicator else 1
      
      plot_ly(dat, x = ~year, y = ~subsidi_juta/1e6, type = "bar", name = "Subsidy",
          marker = list(color = "#00A86B"), hoverinfo = "text", hovertext = ~hover_txt
      ) %>%
          add_lines(x = ~year, y = ~indicator * fac, name = indicator_info$label,
              type = "scatter", mode = "lines+markers+text", text = ~round(indicator, 1),
              textposition = "top center", textfont = list(size = 10, color = "black"),
              line = list(color = "orange", width = 2),
              marker = list(size = 6, color = "white", line = list(color = "orange", width = 2)),
              yaxis = "y2", hoverinfo = "text", hovertext = ~hover_txt
          ) %>%
          layout(
              xaxis = list(title = "Year"),
              yaxis = list(title = "Govt. Spending (Rp Trillion)", tickformat = ",.1f"),
              yaxis2 = list(overlaying = "y", side = "right", title = indicator_info$label),
              margin = list(l = 70, r = 70, t = 30, b = 70),
              legend = list(x = 0.4, y = -0.3, orientation = "h")
          ) %>% config(displayModeBar = FALSE)
  })
  
  # FIXED: Efficiency calculations
  efficiency_data <- reactive({
      provinsi_data <- govt_agg_data()$provinsi
      
      if (nrow(provinsi_data) == 0) return(data.frame())
      
      data <- provinsi_data %>%
          arrange(provinsi, year) %>%
          group_by(provinsi) %>%
          mutate(
              ikp_change = ikp - lag(ikp),
              spending_change = subsidi_juta - lag(subsidi_juta),
              efficiency = case_when(
                  is.na(spending_change) | spending_change <= 0 ~ NA_real_,
                  TRUE ~ ikp_change / (spending_change/1000)
              ),
              roi = case_when(
                  is.na(subsidi_juta) | subsidi_juta <= 0 ~ NA_real_,
                  TRUE ~ ikp / (subsidi_juta/1000)
              )
          ) %>%
          ungroup() %>%
          filter(!is.na(efficiency), !is.infinite(efficiency), abs(efficiency) < 100)
      
      return(data)
  })
  
  # FIXED: Efficiency plot
  output$efficiencyPlot <- renderPlotly({
      eff_data <- efficiency_data()
      
      if (nrow(eff_data) == 0) {
          return(plotly_empty() %>% layout(title = "No efficiency data available"))
      }
      
      data <- eff_data %>%
          filter(year >= 2019, !is.na(efficiency)) %>%
          group_by(provinsi) %>%
          summarise(avg_efficiency = mean(efficiency, na.rm = TRUE), .groups = "drop") %>%
          filter(!is.na(avg_efficiency), abs(avg_efficiency) < 50) %>%
          arrange(desc(avg_efficiency)) %>%
          slice_head(n = 15)
      
      if (nrow(data) == 0) {
          return(plotly_empty() %>% layout(title = "No valid efficiency data for visualization"))
      }
      
      plot_ly(data, x = ~reorder(provinsi, avg_efficiency), y = ~avg_efficiency,
          type = "bar", marker = list(color = ~avg_efficiency, colorscale = "Viridis"),
          text = ~round(avg_efficiency, 2), textposition = "outside") %>%
          layout(
              xaxis = list(title = "Province"),
              yaxis = list(title = "IKP Points per Billion Rupiah"),
              title = "Average Spending Efficiency (2019-2024)"
          ) %>%
          config(displayModeBar = FALSE)
  })
  
  # FIXED: ROI Analysis
  output$roiPlot <- renderPlotly({
      base_data <- govt_agg_data()$provinsi
      
      if (nrow(base_data) == 0) {
          return(plotly_empty() %>% layout(title = "No data available"))
      }
      
      latest_year <- max(base_data$year, na.rm = TRUE)
      data <- base_data %>%
          filter(year == latest_year, !is.na(subsidi_juta), !is.na(ikp), subsidi_juta > 0) %>%
          mutate(roi = ikp / (subsidi_juta/1000)) %>%
          arrange(desc(roi)) %>%
          slice_head(n = 15)
      
      if (nrow(data) == 0) {
          return(plotly_empty() %>% layout(title = "No valid ROI data for visualization"))
      }
      
      plot_ly(data, x = ~reorder(provinsi, roi), y = ~roi,
          type = "bar", marker = list(color = "#2E8B57"),
          text = ~round(roi, 2), textposition = "outside") %>%
          layout(
              xaxis = list(title = "Province"),
              yaxis = list(title = "IKP Score per Billion Rupiah"),
              title = paste("ROI Analysis for", latest_year)
          ) %>%
          config(displayModeBar = FALSE)
  })
  
  # FIXED: Correlation trend over time
  output$correlationTrendPlot <- renderPlotly({
      base_data <- govt_agg_data()$provinsi
      
      if (nrow(base_data) == 0) {
          return(plotly_empty() %>% layout(title = "No data available"))
      }
      
      correlations <- base_data %>%
          filter(!is.na(subsidi_juta), !is.na(ikp)) %>%
          group_by(year) %>%
          summarise(
              correlation = ifelse(n() >= 3, cor(subsidi_juta, ikp, use = "complete.obs"), NA_real_),
              n_provinces = n(),
              .groups = "drop"
          ) %>%
          filter(!is.na(correlation)) %>%
          mutate(
              correlation_strength = case_when(
                  abs(correlation) < 0.3 ~ "Weak",
                  abs(correlation) < 0.7 ~ "Moderate", 
                  TRUE ~ "Strong"
              )
          )
      
      if (nrow(correlations) == 0) {
          return(plotly_empty() %>% layout(title = "Insufficient data for correlation analysis"))
      }
      
      plot_ly(correlations, x = ~year, y = ~correlation, 
          text = ~paste("Year:", year, "<br>Correlation:", round(correlation, 3),
              "<br>Strength:", correlation_strength, "<br>N Provinces:", n_provinces),
          type = "scatter", mode = "lines+markers",
          line = list(color = "#4472C4", width = 3),
          marker = list(size = 8, color = ~correlation, colorscale = "RdYlBu")) %>%
          layout(
              title = "Correlation Strength: Spending vs IKP Over Time",
              xaxis = list(title = "Year"),
              yaxis = list(title = "Correlation Coefficient", range = c(-1, 1)),
              hovermode = "text"
          )
  })
  
  # FIXED: Statistical summary
  output$correlationStats <- renderText({
      base_data <- govt_agg_data()$provinsi
      
      if (nrow(base_data) == 0) {
          return("No data available for analysis")
      }
      
      latest_year <- max(base_data$year, na.rm = TRUE)
      latest_data <- base_data %>% 
          filter(year == latest_year, !is.na(subsidi_juta), !is.na(ikp))
      
      if (nrow(latest_data) < 3) {
          return("Insufficient data for statistical analysis")
      }
      
      tryCatch({
          correlation <- cor(latest_data$subsidi_juta, latest_data$ikp, use = "complete.obs")
          correlation_test <- cor.test(latest_data$subsidi_juta, latest_data$ikp)
          
          paste0(
              "CORRELATION ANALYSIS (", latest_year, ")\n",
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",
              "Correlation: ", round(correlation, 3), "\n",
              "P-value: ", round(correlation_test$p.value, 4), "\n",
              "Significance: ", ifelse(correlation_test$p.value < 0.05, "Significant", "Not Significant"), "\n",
              "Sample Size: ", nrow(latest_data), " provinces\n\n",
              "INTERPRETATION:\n",
              "• ", case_when(
                  abs(correlation) < 0.3 ~ "Weak relationship",
                  abs(correlation) < 0.7 ~ "Moderate relationship",
                  TRUE ~ "Strong relationship"
              ), "\n",
              "• ", ifelse(correlation > 0, "Positive", "Negative"), " association\n",
              "• ", round(correlation^2 * 100, 1), "% of IKP variance explained"
          )
      }, error = function(e) {
          return(paste("Error in statistical calculation:", e$message))
      })
  })
  
  # FIXED: Regression analysis
  output$regressionPlot <- renderPlotly({
      base_data <- govt_agg_data()$provinsi
      
      current_year <- if(!is.null(input$govt_year)) input$govt_year else max(base_data$year, na.rm = TRUE)
      
      data <- base_data %>% 
          filter(year == current_year, !is.na(subsidi_juta), !is.na(ikp))
      
      if (nrow(data) < 3) {
          return(plotly_empty() %>% layout(title = "Insufficient data for regression analysis"))
      }
      
      tryCatch({
          model <- lm(ikp ~ subsidi_juta, data = data)
          data$predicted <- predict(model)
          r_squared <- summary(model)$r.squared
          
          plot_ly(data, x = ~subsidi_juta/1000, y = ~ikp,
              text = ~paste("Province:", provinsi, "<br>IKP:", round(ikp, 1), 
                  "<br>Spending:", round(subsidi_juta/1000, 1), "B Rp")) %>%
              add_markers(name = "Observed", marker = list(color = "#2E8B57", size = 8),
                  hoverinfo = "text") %>%
              add_lines(x = ~subsidi_juta/1000, y = ~predicted, name = "Fitted Line",
                  line = list(color = "#FF6B6B", width = 2)) %>%
              layout(
                  title = paste0("Regression: IKP vs Spending (", current_year, ") - R² = ", round(r_squared, 3)),
                  xaxis = list(title = "Government Spending (Billion Rp)"),
                  yaxis = list(title = "IKP Score"),
                  annotations = list(
                      x = max(data$subsidi_juta/1000) * 0.05, 
                      y = max(data$ikp) * 0.95,
                      text = paste0("R² = ", round(r_squared, 3), "<br>",
                          "Slope = ", round(coef(model)[2] * 1000, 2), " IKP/Billion Rp"),
                      showarrow = FALSE,
                      bgcolor = "rgba(255,255,255,0.8)",
                      bordercolor = "black",
                      borderwidth = 1
                  )
              )
      }, error = function(e) {
          return(plotly_empty() %>% layout(title = paste("Regression Error:", e$message)))
      })
  })
  
  # FIXED: Residuals analysis
  output$residualsPlot <- renderPlotly({
      base_data <- govt_agg_data()$provinsi
      
      current_year <- if(!is.null(input$govt_year)) input$govt_year else max(base_data$year, na.rm = TRUE)
      
      data <- base_data %>% 
          filter(year == current_year, !is.na(subsidi_juta), !is.na(ikp))
      
      if (nrow(data) < 3) {
          return(plotly_empty() %>% layout(title = "Insufficient data for residuals analysis"))
      }
      
      tryCatch({
          model <- lm(ikp ~ subsidi_juta, data = data)
          data$fitted <- fitted(model)
          data$residuals <- residuals(model)
          
          plot_ly(data, x = ~fitted, y = ~residuals,
              text = ~paste("Province:", provinsi, "<br>Fitted:", round(fitted, 1), 
                  "<br>Residual:", round(residuals, 1))) %>%
              add_markers(marker = list(color = "#9B59B6", size = 8),
                  hoverinfo = "text") %>%
              add_trace(y = 0, line = list(color = "red", dash = "dash", width = 2)) %>%
              layout(
                  title = "Residuals vs Fitted Values",
                  xaxis = list(title = "Fitted IKP Values"),
                  yaxis = list(title = "Residuals"),
                  showlegend = FALSE
              )
      }, error = function(e) {
          return(plotly_empty() %>% layout(title = paste("Residuals Error:", e$message)))
      })
  })
  
  # FIXED: Best practice analysis
  output$bestPracticeAnalysis <- renderUI({
      eff_data <- efficiency_data()
      
      if (nrow(eff_data) == 0) {
          return(tags$p("No efficiency data available for analysis."))
      }
      
      efficiency_summary <- eff_data %>%
          group_by(provinsi) %>%
          summarise(
              avg_efficiency = mean(efficiency, na.rm = TRUE),
              avg_ikp = mean(ikp, na.rm = TRUE),
              avg_spending = mean(subsidi_juta, na.rm = TRUE),
              .groups = "drop"
          ) %>%
          filter(!is.na(avg_efficiency)) %>%
          arrange(desc(avg_efficiency))
      
      if (nrow(efficiency_summary) == 0) {
          return(tags$p("No valid efficiency data for best practice analysis."))
      }
      
      top_performer <- efficiency_summary[1, ]
      high_spender <- efficiency_summary %>% slice_max(avg_spending, n = 1)
      low_spender_high_ikp <- efficiency_summary %>% 
          filter(avg_spending < median(avg_spending, na.rm = TRUE)) %>%
          slice_max(avg_ikp, n = 1)
      
      tagList(
          h5("🏆 Key Insights & Best Practices"),
          tags$ul(
              tags$li(strong("Most Efficient Province: "), top_performer$provinsi, 
                  " (", round(top_performer$avg_efficiency, 2), " IKP points per billion Rp)"),
              tags$li(strong("Highest Spender: "), high_spender$provinsi, 
                  " (Rp ", round(high_spender$avg_spending/1000, 1), " billion average)"),
              if(nrow(low_spender_high_ikp) > 0) {
                  tags$li(strong("Low-Spend, High-Performance: "), low_spender_high_ikp$provinsi, 
                      " (IKP: ", round(low_spender_high_ikp$avg_ikp, 1), 
                      ", Spending: Rp ", round(low_spender_high_ikp$avg_spending/1000, 1), " billion)")
              }
          ),
          tags$p(strong("Recommendation: "), 
              "Study ", top_performer$provinsi, "'s approach for replicable best practices. ",
              "Consider reallocating resources from less efficient programs to proven interventions.")
      )
  })
  
  # FIXED: Efficiency table
  output$efficiencyTable <- DT::renderDataTable({
      eff_data <- efficiency_data()
      
      if (nrow(eff_data) == 0) {
          return(DT::datatable(data.frame(Message = "No efficiency data available"), 
              options = list(dom = 't'), rownames = FALSE))
      }
      
      efficiency_summary <- eff_data %>%
          group_by(provinsi) %>%
          summarise(
              `Avg Efficiency` = round(mean(efficiency, na.rm = TRUE), 2),
              `Avg IKP` = round(mean(ikp, na.rm = TRUE), 1),
              `Avg Spending (Billion Rp)` = round(mean(subsidi_juta, na.rm = TRUE)/1000, 1),
              `ROI` = round(mean(roi, na.rm = TRUE), 2),
              .groups = "drop"
          ) %>%
          filter(!is.na(`Avg Efficiency`)) %>%
          arrange(desc(`Avg Efficiency`))
      
      if (nrow(efficiency_summary) == 0) {
          return(DT::datatable(data.frame(Message = "No valid efficiency data for table"), 
              options = list(dom = 't'), rownames = FALSE))
      }
      
      DT::datatable(efficiency_summary, 
          options = list(pageLength = 15, scrollX = TRUE),
          rownames = FALSE) %>%
          DT::formatStyle("Avg Efficiency", 
              backgroundColor = DT::styleInterval(
                  cuts = quantile(efficiency_summary$`Avg Efficiency`, c(0.33, 0.67), na.rm = TRUE),
                  values = c("#ffcccc", "#ffffcc", "#ccffcc")
              ))
  })
  
  # FIXED: Update province choices for comparison
  observe({
      base_data <- govt_agg_data()$provinsi
      if (nrow(base_data) > 0) {
          choices <- sort(unique(base_data$provinsi))
          selected_choices <- if(length(choices) >= 3) choices[1:3] else choices
          updateSelectizeInput(session, "compare_provinces", 
              choices = choices, 
              selected = selected_choices)
      }
  })
  
  # FIXED: Multi-province comparison with larger dots
  output$multiProvinceScatter <- renderPlotly({
      req(input$compare_provinces)
      
      current_year <- if(!is.null(input$govt_year)) input$govt_year else max(govt_agg_data()$provinsi$year, na.rm = TRUE)
      
      data <- govt_agg_data()$provinsi %>% 
          filter(provinsi %in% input$compare_provinces, year == current_year)
      
      if (nrow(data) == 0) {
          return(plotly_empty() %>% layout(title = "No data available for selected provinces"))
      }
      
      plot_ly(data, x = ~subsidi_juta/1000, y = ~ikp, color = ~provinsi,
          text = ~paste("Province:", provinsi, "<br>IKP:", round(ikp, 1), "<br>Spending:", 
              round(subsidi_juta/1000, 1), "B Rp"),
          type = "scatter", mode = "markers",
          marker = list(size = 15, opacity = 0.8)) %>%  # FIXED: Increased size from default to 15
          layout(
              title = paste("Multi-Province Spending vs IKP Comparison (", current_year, ")"),
              xaxis = list(title = "Government Spending (Billion Rp)"),
              yaxis = list(title = "IKP Score"),
              hovermode = "closest"
          )
  })
  
  # FIXED: Add Efficiency Benchmarking Plot
  output$benchmarkPlot <- renderPlotly({
      eff_data <- efficiency_data()
      
      if (nrow(eff_data) == 0) {
          return(plotly_empty() %>% layout(title = "No efficiency data available"))
      }
      
      # Calculate benchmark metrics
      benchmark_data <- eff_data %>%
          group_by(provinsi) %>%
          summarise(
              avg_efficiency = mean(efficiency, na.rm = TRUE),
              avg_ikp = mean(ikp, na.rm = TRUE),
              avg_spending = mean(subsidi_juta, na.rm = TRUE),
              .groups = "drop"
          ) %>%
          filter(!is.na(avg_efficiency)) %>%
          mutate(
              efficiency_rank = rank(-avg_efficiency),
              spending_category = case_when(
                  avg_spending > quantile(avg_spending, 0.75, na.rm = TRUE) ~ "High Spender",
                  avg_spending < quantile(avg_spending, 0.25, na.rm = TRUE) ~ "Low Spender",
                  TRUE ~ "Medium Spender"
              )
          )
      
      if (nrow(benchmark_data) == 0) {
          return(plotly_empty() %>% layout(title = "No valid benchmark data"))
      }
      
      plot_ly(benchmark_data, x = ~avg_spending/1000, y = ~avg_efficiency, 
          color = ~spending_category, size = ~avg_ikp,
          text = ~paste("Province:", provinsi, 
              "<br>Efficiency:", round(avg_efficiency, 2),
              "<br>IKP:", round(avg_ikp, 1),
              "<br>Spending:", round(avg_spending/1000, 1), "B Rp"),
          type = "scatter", mode = "markers",
          marker = list(sizemode = 'diameter', sizeref = 2)) %>%
          layout(
              title = "Efficiency Benchmarking: Spending vs Efficiency",
              xaxis = list(title = "Average Spending (Billion Rp)"),
              yaxis = list(title = "Average Efficiency (IKP/Billion Rp)"),
              hovermode = "closest"
          )
  })
  
  
  
  
  
  ########################################################################################################################################
  ### ---------- FUTURE PROJECTIONS TAB SERVER LOGIC  ---- 
  #########################################################################################################################
  # Reactive forecasts for Projections tab
  projection_forecasts <- reactive({
      level <- if (input$proj_province_new == "indonesia") "indonesia" else "provinsi"
      selected_prov <- if (input$proj_province_new == "indonesia") NULL else input$proj_province_new
      
      # Filter data by selected year range
      filtered_agg_data <- list(
          kabkota = agg_data$kabkota %>% filter(year >= input$proj_year_range_new[1] & year <= input$proj_year_range_new[2]),
          provinsi = agg_data$provinsi %>% filter(year >= input$proj_year_range_new[1] & year <= input$proj_year_range_new[2]),
          indonesia = agg_data$indonesia %>% filter(year >= input$proj_year_range_new[1] & year <= input$proj_year_range_new[2])
      )
      
      # Apply regional classification filter
      if (!is.null(input$regional_filter_new) && input$regional_filter_new != "all") {
          filtered_agg_data$kabkota <- filtered_agg_data$kabkota %>% filter(daerah_3T == input$regional_filter_new)
          filtered_agg_data$provinsi <- filtered_agg_data$provinsi %>% filter(daerah_3T == input$regional_filter_new)
      }
      
      create_regional_forecasts(filtered_agg_data, level, input$proj_indicator_new, selected_prov)
  })
  
  # Projection trend plot
  output$projection_trend_plot <- renderPlotly({
      forecasts <- projection_forecasts()
      if (length(forecasts) == 0) return(plotly_empty() %>% layout(title = "No forecast data available"))
      
      # Get main forecast (first in list)
      main_forecast <- forecasts[[1]]
      if (is.null(main_forecast)) return(plotly_empty())
      
      p <- plot_ly()
      
      # Add 95% confidence interval
      p <- p %>% add_ribbons(x = main_forecast$forecast_years, 
          ymin = main_forecast$forecast_lower_95,
          ymax = main_forecast$forecast_upper_95,
          fillcolor = "rgba(173, 216, 230, 0.3)", line = list(color = "transparent"),
          name = "95% Confidence", showlegend = TRUE, legendgroup = "confidence")
      
      # Add 80% confidence interval
      p <- p %>% add_ribbons(x = main_forecast$forecast_years,
          ymin = main_forecast$forecast_lower_80,
          ymax = main_forecast$forecast_upper_80,
          fillcolor = "rgba(173, 216, 230, 0.5)", line = list(color = "transparent"),
          name = "80% Confidence", showlegend = TRUE, legendgroup = "confidence")
      
      # Add historical observed data
      p <- p %>% add_trace(x = main_forecast$historical_years, y = main_forecast$historical_values,
          type = 'scatter', mode = 'lines+markers', name = 'Observed',
          line = list(color = '#2E8B57', width = 3), marker = list(size = 8, color = '#2E8B57'),
          showlegend = TRUE)
      
      # Add forecast line
      p <- p %>% add_trace(x = main_forecast$forecast_years, y = main_forecast$forecast_mean,
          type = 'scatter', mode = 'lines+markers', name = 'Prediction',
          line = list(color = '#4682B4', width = 3, dash = 'dot'), 
          marker = list(size = 8, color = '#4682B4'), showlegend = TRUE)
      
      # Add 2030 goal line
      goal_value <- goals_2030[[input$proj_indicator_new]]
      if (!is.null(goal_value)) {
          p <- p %>% add_segments(x = 2018, xend = 2030, y = goal_value, yend = goal_value,
              line = list(color = "#E74C3C", width = 2, dash = "dash"),
              name = paste("2030 Goal:", goal_value), showlegend = TRUE)
      }
      
      # Add vertical line at current year boundary
      current_year <- max(main_forecast$historical_years)
      p <- p %>% add_segments(x = current_year, xend = current_year, 
          y = min(c(main_forecast$historical_values, main_forecast$forecast_mean), na.rm = TRUE),
          yend = max(c(main_forecast$historical_values, main_forecast$forecast_mean), na.rm = TRUE),
          line = list(color = "#BDC3C7", width = 1, dash = "dash"),
          name = "Historical/Forecast Split", showlegend = FALSE)
      
      region_name <- if (input$proj_province_new == "indonesia") "Indonesia" else input$proj_province_new
      
      p %>% layout(
          title = list(text = paste0("<b>", indicator_labels[[input$proj_indicator_new]], " Projection (2025-2030)</b><br><sub>", region_name, "</sub>"),
              font = list(size = 18, color = '#2C3E50')),
          xaxis = list(title = "Year", range = c(2018, 2030)),
          yaxis = list(title = indicator_labels[[input$proj_indicator_new]]),
          hovermode = 'x unified', showlegend = TRUE
      )
  })
  
  # Progress toward goal plot
  output$progress_goal_plot <- renderPlotly({
      forecasts <- projection_forecasts()
      if (length(forecasts) <= 1) return(plotly_empty() %>% layout(title = "Insufficient data for comparison"))
      
      goal_value <- goals_2030[[input$proj_indicator_new]]
      if (is.null(goal_value)) return(plotly_empty() %>% layout(title = "No goal defined for this indicator"))
      
      p <- plot_ly()
      
      colors <- c("#E74C3C", "#F39C12", "#F1C40F", "#2ECC71", "#3498DB", "#9B59B6", "#1ABC9C", "#34495E")
      
      for (i in seq_along(forecasts)) {
          if (i > length(colors)) break
          forecast_data <- forecasts[[i]]
          region_name <- names(forecasts)[i]
          
          if (!is.null(forecast_data)) {
              p <- p %>% add_trace(x = forecast_data$forecast_years, y = forecast_data$forecast_mean,
                  type = 'scatter', mode = 'lines+markers', name = region_name,
                  line = list(width = 2, color = colors[i]), marker = list(size = 6, color = colors[i]),
                  showlegend = TRUE,
                  hovertemplate = paste0("<b>", region_name, "</b><br>Year: %{x}<br>",
                      indicator_labels[[input$proj_indicator_new]], ": %{y:.2f}<extra></extra>"))
          }
      }
      
      # Add 2030 goal line
      p <- p %>% add_segments(x = 2025, xend = 2030, y = goal_value, yend = goal_value,
          line = list(color = "#E74C3C", width = 3, dash = "dash"),
          name = paste("2030 Goal:", goal_value), showlegend = TRUE)
      
      region_type <- if (input$proj_province_new == "indonesia") "Regional Gaps" else paste(input$proj_province_new, "Cities")
      
      p %>% layout(
          title = list(text = paste0("<b>Progress Toward 2030 Goal: ", region_type, "</b>"),
              font = list(size = 18, color = '#2C3E50')),
          xaxis = list(title = "Years", range = c(2025, 2030)),
          yaxis = list(title = indicator_labels[[input$proj_indicator_new]]),
          hovermode = 'x unified', showlegend = TRUE
      )
  })
  
  # Ranking data
  ranking_data <- reactive({
      forecasts <- projection_forecasts()
      if (length(forecasts) == 0) return(data.frame())
      rank_by_2030_projection(forecasts, input$proj_indicator_new)
  })
  
  # Top performers plot
  output$top_performers_plot <- renderPlotly({
      rankings <- ranking_data()
      if (nrow(rankings) == 0) return(plotly_empty() %>% layout(title = "No ranking data available"))
      
      n_show <- min(5, nrow(rankings))
      if (n_show == 0) return(plotly_empty() %>% layout(title = "No data available"))
      
      if (input$proj_indicator_new %in% c("stunting", "pou")) {
          top_data <- head(rankings, n_show)
      } else {
          top_data <- tail(rankings, n_show)
      }
      
      if (nrow(top_data) == 0) return(plotly_empty() %>% layout(title = "No top performers data"))
      
      plot_ly(top_data, y = ~reorder(Region, Projection_2030), x = ~Projection_2030,
          type = 'bar', orientation = 'h', marker = list(color = '#27AE60'),
          text = ~paste0(round(Projection_2030, 1)), textposition = 'outside',
          hovertemplate = "<b>%{y}</b><br>2030 Projection: %{x:.2f}<extra></extra>") %>%
          layout(title = list(text = "Best Projected Performance (2030)", font = list(size = 14, color = '#27AE60')),
              xaxis = list(title = indicator_labels[[input$proj_indicator_new]]), yaxis = list(title = ""),
              showlegend = FALSE, margin = list(l = 150))
  })
  
  # Bottom performers plot
  output$bottom_performers_plot <- renderPlotly({
      rankings <- ranking_data()
      if (nrow(rankings) == 0) return(plotly_empty() %>% layout(title = "No ranking data available"))
      
      n_show <- min(5, nrow(rankings))
      if (n_show == 0) return(plotly_empty() %>% layout(title = "No data available"))
      
      if (input$proj_indicator_new %in% c("stunting", "pou")) {
          bottom_data <- tail(rankings, n_show)
      } else {
          bottom_data <- head(rankings, n_show)
      }
      
      if (nrow(bottom_data) == 0) return(plotly_empty() %>% layout(title = "No bottom performers data"))
      
      plot_ly(bottom_data, y = ~reorder(Region, -Projection_2030), x = ~Projection_2030,
          type = 'bar', orientation = 'h', marker = list(color = '#E67E22'),
          text = ~paste0(round(Projection_2030, 1)), textposition = 'outside',
          hovertemplate = "<b>%{y}</b><br>2030 Projection: %{x:.2f}<extra></extra>") %>%
          layout(title = list(text = "Needs Improvement (2030)", font = list(size = 14, color = '#E67E22')),
              xaxis = list(title = indicator_labels[[input$proj_indicator_new]]), yaxis = list(title = ""),
              showlegend = FALSE, margin = list(l = 150))
  })
  
  # Rankings table
  output$projection_rankings_table <- DT::renderDataTable({
      rankings <- ranking_data()
      if (nrow(rankings) == 0) return(data.frame(Message = "No ranking data available"))
      
      display_rankings <- rankings %>%
          mutate(Projection_2030 = round(Projection_2030, 2),
              Distance_to_Goal = round(Distance_to_Goal, 2),
              Goal_Status = ifelse(Meets_Goal, "✅ Achieved", "❌ Not Achieved")) %>%
          select(Rank, Region, `2030 Projection` = Projection_2030, `Distance to Goal` = Distance_to_Goal, `Goal Status` = Goal_Status)
      
      DT::datatable(display_rankings, options = list(pageLength = 15, dom = 'tp', scrollX = TRUE),
          rownames = FALSE) %>%
          DT::formatStyle(columns = 1:ncol(display_rankings), fontSize = '12px') %>%
          DT::formatStyle("Goal Status", 
              backgroundColor = DT::styleEqual(c("✅ Achieved", "❌ Not Achieved"), 
                  c("#D5DBDB", "#FADBD8")))
  })
  
  # Help info modal
  observeEvent(input$help_info_projections, {
      showModal(modalDialog(
          title = "Future Projections Information",
          h4("Forecasting Method"),
          p("The projections are generated using ", strong("ARIMA models"), " (Autoregressive Integrated Moving Average). This statistical method automatically selects optimal parameters for time-series forecasting based on historical data."),
          h4("How to Use"),
          p("Select an indicator (IKP, Stunting, or PoU) and geographical level to see projected trends until 2030. Charts show historical data, forecasted trends, and confidence intervals (80% and 95%). Regional rankings compare projected 2030 performance against SDG targets."),
          h4("Important Limitations"),
          p("Projections assume current trends continue and don't account for major policy changes, economic shocks, or external factors. Use as planning tools, not definitive predictions."),
          easyClose = TRUE
      ))
  })
  
  
  
  
  
  
  
  ### ---------- END FUTURE PROJECTIONS TAB SERVER LOGIC  ---- 
  ################################################################################################
  
  
  # ---- System Status ----
  # -- Error logging setup --
  error_log <- reactiveValues(errors = data.frame(
    timestamp = character(),
    error_type = character(),
    message = character(),
    stringsAsFactors = FALSE
  ))
  
  log_error <- function(error_type, message) {
    new_error <- data.frame(
      timestamp = Sys.time(),
      error_type = error_type,
      message = message,
      stringsAsFactors = FALSE
    )
    error_log$errors <- rbind(error_log$errors, new_error)
    write.table(new_error, "error_log.txt", append = TRUE,
                row.names = FALSE, col.names = FALSE)
  }
  
  # -- Data loading with validation and safe parsing --
  validate_data <- function(data, required_columns) {
    if (is.null(data) || nrow(data) == 0) {
      return(list(valid = FALSE, message = "No data available"))
    }
    missing_cols <- setdiff(required_columns, names(data))
    if (length(missing_cols) > 0) {
      return(list(valid = FALSE,
                  message = paste("Missing required columns:", paste(missing_cols, collapse = ", "))))
    }
    list(valid = TRUE, message = "Data is valid")
  }
  
  safe_calculate <- function(numerator, denominator, default_value = 0) {
    tryCatch({
      ifelse(denominator == 0 | is.na(denominator), default_value, numerator / denominator)
    }, error = function(e) {
      default_value
    })
  }
  
  fsva_data <- reactive({
    tryCatch({
      if (!file.exists("combined_data.csv")) {
        showNotification("combined_data.csv file not found. Please ensure the file is in the correct directory.",
                         type = "error", duration = 10)
        return(NULL)
      }
      data <- read.csv("combined_data.csv")
      required_cols <- c("provinsi", "kabkota", "kode_kabkota", "year", "komposit", "ikp", 
                         "kemiskinan", "stunting", "pou", "latitude", "longitude")
      validation <- validate_data(data, required_cols)
      if (!validation$valid) {
        showNotification(paste("Data validation failed:", validation$message),
                         type = "error", duration = 10)
        return(NULL)
      }
      data <- data %>%
        mutate(
          ikp    = as.numeric(ikp),
          kode_kabkota   = as.numeric(kode_kabkota),
          latitude = as.numeric(latitude),   # HINT: What column contains latitude?
          longitude= as.numeric(longitude)   # HINT: What column contains longitude?
        ) %>%
        filter(!is.na(ikp), !is.na(kode_kabkota))
      if (nrow(data) == 0) {
        showNotification("No valid data rows after cleaning", type = "warning")
        return(NULL)
      }
      data
    }, error = function(e) {
      showNotification(paste("Error loading data:", e$message), type = "error", duration = 15)
      NULL
    })
  })
  
  
  # System status outputs
  output$system_status <- renderText({
    data <- fsva_data()
    if (is.null(data)) return("❌ CRITICAL: No data loaded")
    status_lines <- c(
      paste("✅ Data Status: Loaded (", nrow(data), " records)", sep = ""),
      paste("✅ Last Updated:", Sys.time()),
      paste("✅ Memory Usage:", format(object.size(data), units = "MB")),
      paste("⚠️  Errors Today:", nrow(error_log$errors))
    )
    paste(status_lines, collapse = "\n")
  })
  
  output$data_quality <- renderTable({
    data <- fsva_data()
    if (is.null(data)) return(data.frame(Metric = "No Data", Value = "N/A"))
    data.frame(
      Metric = c("Total Records", "Complete Records", "Missing IKP", "Missing Regions ID", "Missing Locations", "Data Completeness"),
      Value = c(
        nrow(data),
        sum(complete.cases(data)),
        sum(is.na(data$ikp)),
        sum(is.na(data$kode_kabkota)),
        sum(is.na(data$latitude) | is.na(data$longitude)),
        paste0(round(sum(complete.cases(data)) / nrow(data) * 100, 1), "%")
      )
    )
  })
  
  output$error_table <- DT::renderDataTable({
    if (nrow(error_log$errors) == 0) return(data.frame(Message = "No errors recorded"))
    error_log$errors %>%
      arrange(desc(timestamp)) %>%
      head(50)
  }, options = list(pageLength = 10, scrollX = TRUE))
  
}

# Run App ------------------------------------------------------------------
shinyApp(ui = ui, server = server)




## Revison v5
