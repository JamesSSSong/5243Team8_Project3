library(shiny)
library(shinythemes)
library(DT)
library(ggplot2)
library(readr)
library(readxl)
library(jsonlite)
library(tools)
library(dplyr)
library(glmnet)
library(olsrr)
library(shinyjs)

`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

# User Interface (UI)
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    
    tags$script(HTML("
  var preprocessStartTime;

  function startPreprocessStep(stepIndex) {
    preprocessStartTime = new Date().getTime();
  }

  function endPreprocessStep(stepIndex) {
    var endTime = new Date().getTime();
    var duration = (endTime - preprocessStartTime) / 1000;
    Shiny.setInputValue('preprocessStepEnded', {
      step: stepIndex,
      duration: duration,
      timestamp: new Date().toISOString()
    }, {priority: 'event'});
  }
")),
    
    #google analytics
    HTML(glue::glue('
  <!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){{dataLayer.push(arguments);}}
    gtag("js", new Date());
    gtag("config", "G-Y1XF4Z9S7Y", {{
    group: new URLSearchParams(window.location.search).get("group")
    }});
  </script>
')),
    #random AB group
    tags$script(HTML("
  (function() {
    let group = localStorage.getItem('ab_group');
    
    if (!group) {
      group = Math.random() < 0.5 ? 'A' : 'B';
      localStorage.setItem('ab_group', group);
    }
    
    const currentUrl = new URL(window.location.href);
    currentUrl.searchParams.set('group', group);
    if (!window.location.href.includes('group=')) {
      window.location.replace(currentUrl.toString());
    }
       
    if (typeof gtag === 'function') {
      gtag('set', {'user_properties': {'ab_group': group}});
    }
  })();
")),
    
    tags$script(HTML("
      Shiny.addCustomMessageHandler('trackEvent', function(data) {
        gtag('event', data.event, {
          'event_category': data.category,
          'event_label': data.label
        });
      });
    ")),
    
    
    tags$style(HTML("
    .tutorial-overlay {
      position: fixed;
      top: 0; left: 0; width: 100%; height: 100%;
      background-color: rgba(0,0,0,0.6);
      z-index: 1050;
    }
    .tutorial-box {
      position: absolute;
      top: 20%; left: 50%;
      transform: translateX(-50%);
      background-color: white;
      padding: 20px;
      border-radius: 10px;
      width: 45%;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      z-index: 1060;
      text-align: center;
    }
  ")),
    tags$script(HTML("
    Shiny.addCustomMessageHandler('disable-clicks-uni', function(x) {
      if (x) {
        $('#edaTabs-tab-1').parent().siblings().css('pointer-events', 'none');
      } else {
        $('#edaTabs-tab-1').parent().siblings().css('pointer-events', 'auto');
      }
    });
    
    // Disable clicks for Data Processing tab when tutorial is active
    Shiny.addCustomMessageHandler('disable-clicks-data', function(x) {
      if (x) {
        $('#dataprocessingTab-tab').parent().siblings().css('pointer-events', 'none');  // Disable clicks for Data Processing
      } else {
        $('#dataprocessingTab-tab').parent().siblings().css('pointer-events', 'auto'); // Enable clicks for Data Processing
      }
    });
  "))
  ),
  
  
  theme = shinytheme("flatly"),
  
  # Tutorial Overlay content for Loading Datasets page
  shinyjs::hidden(
    div(
      id = "loadingTutorialOverlay", 
      class = "tutorial-overlay", 
      div(
        class = "tutorial-box", 
        h4("👋 Welcome to Dataset Loader!"),
        HTML("<p>Please upload your <strong>dataset</strong> or select a built-in dataset to get started.</p>"),
        actionButton("nextLoadingTutorial", "Start", class = "btn btn-primary")
      )
    )
  ),
  
  navbarPage(
    "Interactive Data Analysis App",
    id = "mainTabs", 
    
    tabPanel(
      title = "Loading Datasets",
      titlePanel("Loading Datasets"),
      
      sidebarLayout(
        sidebarPanel(
          fileInput("file", "Upload Dataset", accept = c(".csv", ".xlsx", ".json", ".rds")),
          selectInput("dataset", "Or Select a Sample Dataset", choices = c("mtcars", "iris")),
          actionButton("loadData", "Load Data")
        ),
        mainPanel(
          h4("Instructions"),
          p("Upload your dataset or select a sample dataset (e.g., mtcars or iris), then click 'Load Data'."),
          
          tabsetPanel(
            tabPanel("Original Data Preview", DTOutput("originalDataTable"))
          )
        )
      )
    ),
    
    # 2. Data Processing
    tabPanel(
      title = "Data Preprocess",
      value = "preprocess",
      id = "dataprocessingTab", 
      titlePanel("Data Preprocess"),
      
      shinyjs::hidden(
        div(
          id = "dataProcessingTutorialOverlay",  # ID for overlay
          class = "tutorial-overlay",  # Class for styling
          div(
            class = "tutorial-box",
            uiOutput("dataProcessingTutorialText"), 
            actionButton("nextDataProcessingTutorial", 
                         "Next", class = "btn btn-primary")
          )
        )
      ),
      
      sidebarLayout(
        sidebarPanel(
          h4("Data Cleaning & Preprocessing"),
          
          selectInput("missingStrategy", "Missing Value Strategy", 
                      choices = c("Remove Rows", "Impute Values")),
          
          checkboxInput("removeDuplicates", "Remove Duplicates", value = FALSE),
          
          hr(),
          # User manually converse
          selectizeInput("manualNumeric", "Make Selected Columns to Numeric", 
                         choices = NULL, multiple = TRUE),
          selectizeInput("manualCategorical", "Make Selected Columns to Categorical", 
                         choices = NULL, multiple = TRUE),
          
          selectizeInput("scaleCols", "Columns to Scale", 
                         choices = NULL, multiple = TRUE),
          
          hr(),
          selectizeInput("encodeCols", "Categorical Columns to Encode", choices = NULL, multiple = TRUE),
          selectInput("encodingStrategy", "Categorical Encoding Strategy",
                      choices = c("None", "One-Hot Encoding", "Dummy Encoding")),
          
          hr(),
          
          selectInput("outlierStrategy", "Outlier Handling Strategy", 
                      choices = c("None", "Remove Outliers", "Winsorize Outliers")),
          hr(),
          actionButton("processData", "Process Data", class = "btn-primary")
        ),
        
        mainPanel(
          tabsetPanel(
            tabPanel("Data Statistics", verbatimTextOutput("dataSummary")),
            tabPanel("Duplicates", DTOutput("dupTable")),
            tabPanel("Distribution",
                     selectInput("distCol", "Select Column for Impact Analysis", choices = NULL),
                     radioButtons("distPlotType", "Plot Type", choices = c("Histogram", "Boxplot")),
                     plotOutput("distPlot")
            ),
            tabPanel("Historical Activities", verbatimTextOutput("summaryInfo")),  
            tabPanel("Processed Data", DTOutput("processedDataTable"))
          )
        )
      )
    ),
    
    # 3. Feature Engineering
    tabPanel(
      title = "Feature Engineering",
      titlePanel("Feature Engineering"),
      
      shinyjs::hidden(
        div(
          id = "featureTutorialOverlay", 
          class = "tutorial-overlay", 
          div(
            class = "tutorial-box", 
            uiOutput("featureTutorialText"),
            actionButton("nextFeatureTutorial", "Next", class = "btn btn-primary")
          )
        )
      ),
      
      
      sidebarLayout(
        sidebarPanel(
          tabsetPanel(
            # PCA
            tabPanel("PCA",
                     h4("PCA (Principal Component Analysis)"),
                     selectizeInput("pcaCols", "Select Columns for PCA", choices = NULL, multiple = TRUE),
                     numericInput("numPCA", "Number of Principal Components", value = 2, min = 1, max = 10, step = 1),
                     actionButton("applyPCA", "Apply PCA", class = "btn-primary"),
                     actionButton("savePCA", "Save PCA Result", class = "btn-primary")
            ),
            #Feature Selection
            tabPanel("Feature Selection",
                     h4("Feature Selection"),
                     selectizeInput("FSCols", "Select Methods for Feature Selection", 
                                    choices = c("LASSO", "Elastic Net", "Forward Stepwise", "Backward Stepwise","Bothway Stepwise")),
                     selectizeInput("FSyCols", "Select Dependent Variable", choices = NULL, multiple = FALSE),
                     numericInput("lambdaL", "Value of Lambda for Regularization", value = 0.01, min = 0, max = 100, step = 0.01),
                     checkboxInput("lambdaCV", "Cross Validation for Select Lambda", value = FALSE),
                     selectizeInput("criteriaFS", "Selection Criteria for Stepwise", 
                                    choices = c("p-value","adjust R^2", "AIC","SBIC")),
                     checkboxInput("detailFS", "Show the more detail", value = FALSE),
                     actionButton("applyFS", "Apply Feature Selection", class = "btn-primary")
            ),
            #New Feature
            tabPanel("Making New Feature",
                     h4("Making New Feature"),
                     uiOutput("col1_ui"),
                     radioButtons("input_type", "Choose Input Type:", choices = c("Select Column", "Enter Number"), selected = "Select Column"),
                     uiOutput("col2_or_number_ui"),
                     textInput("NewF", "New Feature Name",value = "New Feature"),
                     selectizeInput("opF", "Operation Choice", choices = c("Addition","Subtraction","Multiplication","Division","Natural Log","Power")),
                     actionButton("applyOP", "Apply Operation", class = "btn-primary"),
                     actionButton("saveNF", "Save the New Feature", class = "btn-primary")
            )
          ) 
        ),
        
        mainPanel(
          tabsetPanel(
            tabPanel("PCA Summary", verbatimTextOutput("pcaSummary")),
            tabPanel("PCA Transformed Data", DTOutput("pcaDataTable")),
            tabPanel("Feature Selection Summary", verbatimTextOutput("FSSummary")),
            tabPanel("New Feature Summary", verbatimTextOutput("newSummary"))
          )
        )
      )
      
      
    ),
    
    # 4. EDA tab
    tabPanel(
      title = "EDA",
      titlePanel("EDA"),
      
      tabsetPanel(
        # Univariate Analysis Tab
        id = "edaTabs",
        tabPanel(
          title = "Univariate Analysis",
          
          shinyjs::hidden(
            div(id = "uniTutorialOverlay", class = "tutorial-overlay",
                div(class = "tutorial-box",
                    uiOutput("uniTutorialText"),
                    actionButton("nextUniTutorial", "Next", class = "btn btn-primary")
                )
            )
          ),
          
          sidebarLayout(
            sidebarPanel(
              h3("Numerical Analysis"),
              selectInput("statVar", "Select Numerical Variable for Analysis:",
                          choices = NULL, selected = NULL),
              
              # Horizontal layout for Plot Type Selection
              fluidRow(
                column(4, checkboxInput("histogram", "Histogram")),
                column(4, checkboxInput("boxplot", "Boxplot")),
                column(4, checkboxInput("dotplot", "Dotplot"))
              ),
              
              # Histogram Options
              conditionalPanel(
                condition = "input.histogram == true",
                sliderInput("binWidth", "Select Binwidth For Histogram:",
                            min = 5, max = 150, value = 30),
                checkboxGroupInput("histOptions", "Histogram Options:",
                                   choices = c("Enter Binwidth", 
                                               "Select Starting Bin", 
                                               "Display Percent")),
                
                conditionalPanel(
                  condition = "input.histOptions.indexOf('Enter Binwidth') > -1",
                  numericInput("customBinwidth", "Custom Binwidth:", value = 30, min = 1, step = 1)
                ),
                
                conditionalPanel(
                  condition = "input.histOptions.indexOf('Select Starting Bin') > -1",
                  numericInput("startBin", "Lower Bound of First Bin:", value = 0, step = 1)
                )
              ),
              
              # Boxplot Options
              conditionalPanel(
                condition = "input.boxplot == true",
                h4("Boxplot Options:"),
                checkboxInput("verticalPlot", "Vertical Plot", value = FALSE)
              ),
              
              br(), br(), br(), br(), hr(), br(), br(), br(), br(),
              
              h3("Categorical Analysis"),
              selectInput("catVar", "Select Categorical Variable for Analysis:",
                          choices = NULL, selected = NULL),
              
              # Horizontal layout for Bar Chart & Pie Chart Selection
              fluidRow(
                column(6, checkboxInput("barChart", "Bar Chart")),
                column(6, checkboxInput("pieChart", "Pie Chart"))
              ),
              
              # Bar Chart Options (Only if Bar Chart is selected)
              conditionalPanel(
                condition = "input.barChart == true",
                h4("Bar Chart Options:"),
                checkboxInput("displayPercent", "Display Percent", value = FALSE)
              )
            ),
            
            mainPanel(
              h4("Statistical Summary"),
              verbatimTextOutput("statSummary"),
              
              h4("Numerical Data Plots"),
              plotOutput("histPlot", height = "250px"),
              plotOutput("boxPlot", height = "250px"),
              plotOutput("dotPlot", height = "250px"),
              
              h4("Categorical Data Plots"),
              plotOutput("barChartPlot", height = "300px"),
              plotOutput("pieChartPlot", height = "300px")
            )
          )
        ),
        
        # Bivariate Analysis Tab
        tabPanel(
          title = "Bivariate Analysis",
          shinyjs::hidden(
            div(id = "bivTutorialOverlay", class = "tutorial-overlay",
                div(class = "tutorial-box",
                    uiOutput("bivTutorialText"),
                    actionButton("nextBivTutorial", "Next", class = "btn btn-primary")
                )
            )
          ),
          
          sidebarLayout(
            sidebarPanel(
              h3("Numerical Variable Analysis"),
              
              # Select two numerical variables in the same row
              fluidRow(
                column(6, selectInput("xNumVar", "Select X (Numerical):", choices = NULL, selected = NULL)),
                column(6, selectInput("yNumVar", "Select Y (Numerical):", choices = NULL, selected = NULL))
              ),
              
              # Checkboxes for numerical plot selection
              fluidRow(
                column(6, checkboxInput("scatterPlot", "Scatter Plot")),
                column(6, checkboxInput("linePlot", "Line Plot"))
              ),
              
              # Scatter Plot Options
              conditionalPanel(
                condition = "input.scatterPlot == true",
                h4("Scatter Plot Options"),
                checkboxInput("smooth", "Add Smooth Line")
              ),
              
              # Line Plot Options
              conditionalPanel(
                condition = "input.linePlot == true",
                h4("Line Plot Options"),
                checkboxInput("lineSmooth", "Add Smooth Line")
              ),
              
              # Space before categorical section
              br(), br(), hr(), br(),
              
              h3("Categorical Variable Analysis"),
              
              # Select two categorical variables
              fluidRow(
                column(6, selectInput("xCatVar", "Select X (Categorical):", choices = NULL, selected = NULL)),
                column(6, selectInput("yCatVar", "Select Y (Categorical):", choices = NULL, selected = NULL))
              ),
              
              # Select categorical plot type
              selectInput("catPlotType", "Select Categorical Plot Type:", 
                          choices = c("Grouped Bar Chart", "Stacked Bar Chart", "100% Stacked Bar")),
              
              # Space before categorical-numerical section
              br(), br(), hr(), br(),
              
              h3("Categorical-Numerical Variable Analysis"),
              
              # Select numerical and categorical variable
              fluidRow(
                column(6, selectInput("numVar", "Select Numerical Variable:", choices = NULL, selected = NULL)),
                column(6, selectInput("catVarCN", "Select Categorical Variable:", choices = NULL, selected = NULL))
              ),
              
              # Select plot type for categorical-numerical analysis
              selectInput("catNumPlotType", "Select Plot Type:", 
                          choices = c("Boxplot", "Violin Plot"))
            ),
            
            mainPanel(
              h4("Numerical Variable Visualization"),
              plotOutput("scatterPlotOutput", height = "300px"),
              plotOutput("linePlotOutput", height = "300px"),
              
              # Space before categorical plots
              br(), br(), hr(), br(),
              
              h4("Categorical Variable Visualization"),
              plotOutput("catPlotOutput", height = "300px"),
              
              # Space before categorical-numerical plots
              br(), br(), hr(), br(),
              
              h4("Categorical-Numerical Variable Visualization"),
              plotOutput("catNumPlotOutput", height = "300px")
            )
          )
        ),
        
        # Heat Map Tab
        tabPanel(
          title = "Heat Map",
          
          shinyjs::hidden(
            div(id = "heatTutorialOverlay", class = "tutorial-overlay",
                div(class = "tutorial-box",
                    uiOutput("heatTutorialText"),
                    actionButton("nextHeatTutorial", "Next", class = "btn btn-primary")
                )
            )
          ),
          
          sidebarLayout(
            sidebarPanel(
              h4("Correlation Heatmap"),
              p("Displays the correlation between all numeric variables in the dataset.")
            ),
            
            mainPanel(
              plotOutput("heatmapOutput", height = "500px")
            )
          )
        ),
        
        tabPanel(
          title = "Statistical Test",
          
          shinyjs::hidden(
            div(id = "statTutorialOverlay", class = "tutorial-overlay",
                div(class = "tutorial-box",
                    uiOutput("statTutorialText"),
                    actionButton("nextStatTutorial", "Next", class = "btn btn-primary")
                )
            )
          ),
          
          sidebarLayout(
            sidebarPanel(
              h3("Numerical vs. Numerical Test"),
              
              # Select correlation test
              selectInput("numNumTest", "Select Correlation Test:",
                          choices = c("Pearson Correlation", "Kendall Correlation")),
              
              # Conditional selection of numerical variables
              conditionalPanel(
                condition = "input.numNumTest != ''",
                fluidRow(
                  column(6, selectInput("numVar1", "Select First Numerical Variable:", choices = NULL, selected = NULL)),
                  column(6, selectInput("numVar2", "Select Second Numerical Variable:", choices = NULL, selected = NULL))
                )
              ),
              
              # Space before categorical section
              br(), br(), hr(), br(),
              
              h3("Categorical vs. Categorical Test"),
              
              # Select categorical test
              selectInput("catCatTest", "Select Categorical Test:",
                          choices = c("Chi-Square Test")),
              
              # Conditional selection of categorical variables
              conditionalPanel(
                condition = "input.catCatTest != ''",
                fluidRow(
                  column(6, selectInput("catVar1", "Select First Categorical Variable:", choices = NULL, selected = NULL)),
                  column(6, selectInput("catVar2", "Select Second Categorical Variable:", choices = NULL, selected = NULL))
                )
              )
            ),
            
            mainPanel(
              h4("Numerical Test Result"),
              verbatimTextOutput("numNumTestResult"),
              
              br(), br(), hr(), br(),
              
              h4("Categorical Test Result"),
              verbatimTextOutput("catCatTestResult")
            )
          )
        )
      )
    ),
    
    # About Page
    tabPanel(
      title = "About",
      titlePanel("About This Project"),
      h3("How to Use This App?"),
      tags$ol(
        tags$li("Upload a dataset or use a provided sample dataset."),
        tags$li("Navigate to the 'Data Preprocess' tab."),
        tags$li("Clean and transform your data by selecting the appropriate variables and strategies."),
        tags$li("Navigate to the 'Feature Engineering' tab."),
        tags$li("Choose preferred method."),
        tags$li("Specify columns, parameters, or operations as needed."),
        tags$li("Apply and review the results."),
        tags$li("Navigate to the 'EDA' tab."),
        tags$li("Choose the appropriate analysis type."),
        tags$li("Select variables and visualization options."),
        tags$li("Analyze and interpret insights dynamically.")
      ),
      hr(),
      
      h3("Key Features"),
      tags$ul(
        tags$li("🔹 Easy data visualization with interactive graphs."),
        tags$li("🔹 Dynamic selection of variables and plot types."),
        tags$li("🔹 Supports numerical, categorical, and mixed data."),
        tags$li("🔹 Provides different feature engineering techniques."),
        tags$li("🔹 Correlation heatmaps for in-depth analysis.")
      ),
      
      h3("Data Cleaning and Preprocessing"),
      p("The Data Cleaning and Preprocessing modules allows users to initially clean, transform, and enrich raw data using the following functions:"),
      tags$ul(
        tags$li(strong("Missingness and Duplication"), " – Handle missing and duplicated values."),
        tags$li(strong("Data Type Conversion"), " – Convert columns to appropriate data type."),
        tags$li(strong("Transformation"), " – Standardize numeric columns, and encode categorical columns."),
        tags$li(strong("Outliers"), " – Detect and handle outliers.")
      ),
      
      h3("1️⃣ Missingness and Duplication"),
      tags$ul(
        tags$li("Data statistics are presented under 'Data Statistics'."),
        tags$li("The system automatically identifies missing values."),
        tags$li("Select strategy to deal with null values: remove or impute with median for numeric columns or mode for categorical columns."),
        tags$li("The system will identify duplicated values, see 'Duplicates'."),
        tags$li("Remove duplicated values by clicking 'Remove Duplicates'.")
      ),
      
      h3("2️⃣ Data Type Conversion"),
      p("This function allows users to manually select columns to convert."),
      tags$ul(
        tags$li("The system can automatically recognize data type of every columns."),
        tags$li("For columns that are incorrectly recognized, user can select column(s) to convert to appropriate types.")
      ),
      
      h3("3️⃣ Transformation"),
      p("This function perform necessary transformations to numeric and categorical columns."),
      tags$ul(
        tags$li("Select numeric column(s) to standardize."),
        tags$li("Select categorical column(s) to encode through One-Hot encoding or Dummy encoding."),
        tags$li("Click 'Distribution' to  view the effect of transformations.")
      ),
      
      h3("4️⃣ Outliers"),
      p("This function allows user to handle outliers"),
      tags$ul(
        tags$li("The system can automatically detect outliers using an interquartile range (IQR)."),
        tags$li("Select strategy to handle outliers."),
        tags$li("Click 'Processed Data' to  view the current dataset.")
      ),
      hr(),
      
      h3("Feature Engineering"),
      p("The Feature Engineering module allows users to modify and enhance dataset features. It consists of three main functions:"),
      
      tags$ul(
        tags$li(strong("Principal Component Analysis (PCA)"), " – Reduce dimensionality and extract important components."),
        tags$li(strong("Feature Selection"), " – Identify the most relevant features for modeling."),
        tags$li(strong("Custom Feature Creation"), " – Generate new features based on mathematical operations.")
      ),
      
      h3("1️⃣ Principal Component Analysis (PCA)"),
      p("PCA helps users transform features into principal components for dimensionality reduction."),
      tags$ul(
        tags$li("Select features for PCA transformation."),
        tags$li("Choose the number of principal components."),
        tags$li("Remove incorrect selections using the Backspace key."),
        tags$li("The summary of principal components appears in the 'PCA Summary' subpanel."),
        tags$li("Click 'Apply PCA' to transform data and view results in 'PCA Transformed Data'."),
        tags$li("If satisfied, save the transformed data for further analysis in the EDA section by clicking 'Save PCA Result' .")
      ),
      
      h3("2️⃣ Feature Selection"),
      p("This function helps users select the most important features for modeling."),
      tags$ul(
        tags$li("Select the dependent variable and feature selection method."),
        tags$li("Set relevant parameters (irrelevant ones can be ignored)."),
        tags$li("If using regularization, enable cross-validation via 'Cross Validation for Select Lambda'."),
        tags$li("View selected features in 'Feature Selection Summary'."),
        tags$li("For detailed insights, enable 'Show More Detail'.")
      ),
      
      h3("3️⃣ Custom Feature Creation"),
      p("Users can create new features using mathematical operations."),
      tags$ul(
        tags$li("Choose 'Selected Column' for operations on two features or 'Enter Number' for single feature operations."),
        tags$li("Operations include Addition, Subtraction, Multiplication, Division, and Logarithm."),
        tags$li("For division, the first feature is the dividend, the second is the divisor. The same goes for subtraction."),
        tags$li("For the natural logarithm option, only the first feature will take effect. "),
        tags$li("Results appear in 'New Feature Summary' after clicking 'Apply Operation'."),
        tags$li("To save the new feature, click 'Save the New Feature' for further analysis in the EDA section.")
      ),
      hr(),
      
      h3("Exploratory Data Analysis (EDA)"),
      p("The EDA module helps users explore and visualize datasets interactively. It consists of four sections:"),
      tags$ul(
        tags$li(strong("Univariate Analysis"), " – Analyze individual variables."),
        tags$li(strong("Bivariate Analysis"), " – Analyze relationships between two variables."),
        tags$li(strong("Heat Map Analysis"), " – Visualize correlations between numerical variables."),
        tags$li(strong("Statistical Test"), " – Perform hypothesis testing on numerical and categorical data.")
      ),
      
      h3("1️⃣ Univariate Analysis"),
      p("Examine the distribution of a single variable:"),
      tags$ul(
        tags$li(strong("Numerical Analysis:"), "Histogram (custom binwidth, starting bin, percent display), Boxplot (horizontal/vertical), Dotplot."),
        tags$li(strong("Categorical Analysis:"), "Bar Chart (option to display percentages), Pie Chart.")
      ),
      
      h3("2️⃣ Bivariate Analysis"),
      p("Analyze relationships between two variables:"),
      tags$ul(
        tags$li(strong("Numerical vs. Numerical:"), "Scatter Plot (optional trend line), Line Plot (optional smoothing)."),
        tags$li(strong("Categorical vs. Categorical:"), "Grouped Bar Chart, Stacked Bar Chart, 100% Stacked Bar Chart."),
        tags$li(strong("Numerical vs. Categorical:"), "Boxplot, Violin Plot.")
      ),
      
      h3("3️⃣ Heat Map Analysis"),
      p("Displays correlations between numerical variables:"),
      tags$ul(
        tags$li("Color-coded matrix (darker = stronger correlation)."),
        tags$li("Helps identify patterns and dependencies.")
      ),
      
      h3("4️⃣ Statistical Test"),
      p("The Statistical Test module allows users to perform hypothesis testing and assess relationships between variables:"),
      tags$ul(
        tags$li(strong("Numerical vs. Numerical Test:"), "Choose between Pearson and Kendall correlation to measure the strength and direction of the relationship between two numerical variables."),
        tags$li(strong("Categorical vs. Categorical Test:"), "Use the Chi-Square test to evaluate the association between two categorical variables."),
        tags$li(strong("Numerical vs. Categorical Test:"), "Compare means between groups using t-tests (for two groups) or ANOVA (for multiple groups) to assess differences between numerical and categorical variables.")
      ),
      
      hr(),
      p("Created with R Shiny, March 2025.")
    )
  )
)


# Data Cleaning Function
clean_data <- function(df, missing_strategy = "Remove Rows") {
  df <- df %>% mutate(across(where(is.character), ~ ifelse(. %in% c("?", "N/A", "NaN", "", " "), NA, .)))
  df <- df %>% mutate(across(where(is.character), ~ trimws(.) %>% tolower()))
  df <- df %>% mutate(across(where(is.character), ~ ifelse(grepl("^\\d{4}-\\d{2}-\\d{2}$", .),
                                                           lubridate::ymd(.), .)))
  df <- df %>% mutate(across(where(is.character), ~ ifelse(grepl("^[0-9\\.]+$", .),
                                                           readr::parse_number(.), .)))
  df <- df %>% mutate(across(where(is.character), ~ {if(length(unique(.)) <= 10) {
    factor(.)
  } else {.}
  }))
  
  if(missing_strategy == "Remove Rows") {
    df <- na.omit(df)
  } else if(missing_strategy == "Impute Values") {
    df <- df %>% mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))
    df <- df %>% mutate(across(where(is.factor), ~ {
      if(any(is.na(.))) {
        mode_val <- names(sort(table(.), decreasing = TRUE))[1]
        replace(., is.na(.), mode_val)
      } else {.}
    }))
  }
  
  return(df)
}

# Standardization Function
standardize <- function(df, scale_cols) {
  if (!is.null(scale_cols) && length(scale_cols) > 0) {
    df <- df %>% mutate(across(all_of(scale_cols), ~ as.numeric(scale(.))))
  }
  return(df)
}

# Encoding categorical features
encode_categorical <- function(df, encode_cols, strategy = "None") {
  if (!is.null(encode_cols) && length(encode_cols) > 0 && strategy != "None") {
    for (col in encode_cols) {
      if (is.factor(df[[col]])) {
        if(strategy == "One-Hot Encoding") {
          # One-hot encoding
          dummies <- model.matrix(~ . -1, data = df[col])
          dummies <- as.data.frame(dummies)
          df[[col]] <- NULL
          df <- cbind(df, dummies)
        } else if (strategy == "Dummy Encoding") {
          # Dummy encoding
          dummies <- model.matrix(~ . , data = df[col])
          dummies <- as.data.frame(dummies[,-1, drop = FALSE])
          df[[col]] <- NULL
          df <- cbind(df, dummies)
        }
      }
    }
  }
  return(df)
}

# Detect and handle outliers
handle_outliers <- function(df, outlier_strategy = "None") {
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  
  if(outlier_strategy == "Remove Outliers") {
    for(col in numeric_cols) {
      Q1 <- quantile(df[[col]], 0.25, na.rm = TRUE)
      Q3 <- quantile(df[[col]], 0.75, na.rm = TRUE)
      IQR <- Q3 - Q1
      lower_bound <- Q1 - 1.5 * IQR
      upper_bound <- Q3 + 1.5 * IQR
      # Remove rows with outliers
      df <- df %>% filter(df[[col]] >= lower_bound & df[[col]] <= upper_bound)
    }
  } else if(outlier_strategy == "Winsorize Outliers") {
    for(col in numeric_cols) {
      Q1 <- quantile(df[[col]], 0.25, na.rm = TRUE)
      Q3 <- quantile(df[[col]], 0.75, na.rm = TRUE)
      IQR_val <- Q3 - Q1
      lower_bound <- Q1 - 1.5 * IQR_val
      upper_bound <- Q3 + 1.5 * IQR_val
      df[[col]] <- ifelse(df[[col]] < lower_bound, lower_bound,
                          ifelse(df[[col]] > upper_bound, upper_bound, df[[col]]))
    }
  }
  return(df)
}

#PCA funtion
apply_pca <- function(df, pca_cols, n_components) {
  if (!is.null(pca_cols) && length(pca_cols) > 0) {
    pca_model <- prcomp(df[, pca_cols, drop = FALSE], center = TRUE, scale. = TRUE)
    pca_data <- as.data.frame(pca_model$x[, 1:n_components])
    colnames(pca_data) <- paste0("PC", 1:n_components)
    df <- cbind(df, pca_data)
  }
  return(df)
}

ols_step_way_c <- function(lm, way, c) {
  if (way == "for") {
    if (c == "p-value") {
      return(ols_step_forward_p(lm))
    }
    if (c == "adjust R^2") {
      return(ols_step_forward_adj_r2(lm))
    }
    if (c == "AIC") {
      return(ols_step_forward_aic(lm))
    }
    if (c == "SBIC") {
      return(ols_step_forward_sbic(lm))
    }
  }
  if (way == "back") {
    if (c == "p-value") {
      return(ols_step_backward_p(lm))
    }
    if (c == "adjust R^2") {
      return(ols_step_backward_adj_r2(lm))
    }
    if (c == "AIC") {
      return(ols_step_backward_aic(lm))
    }
    if (c == "SBIC") {
      return(ols_step_backward_sbic(lm))
    }
    
  }
  if (way == "both") {
    if (c == "p-value") {
      return(ols_step_both_p(lm))
    }
    if (c == "adjust R^2") {
      return(ols_step_both_adj_r2(lm))
    }
    if (c == "AIC") {
      return(ols_step_both_aic(lm))
    }
    if (c == "SBIC") {
      return(ols_step_both_sbic(lm))
    }
  }
  return(NULL) 
}


#feature_selection function
applyFS <- function(df, y_cols,method, lambdaL=0.01, lambdaCV=FALSE, criteriaFS="p-value"){
  if(!is.data.frame(df)){
    df <-as.data.frame(df)
  }
  
  X <- df[, setdiff(colnames(df), y_cols)] 
  y<- df[,y_cols]
  lambda_val <- lambdaL
  message<-""
  error_check <- FALSE
  
  if (!all(sapply(X, is.numeric)) || !is.numeric(y)) {
    message <- "The data contained non-numeric data. This program automatically converts the data into numeric. If you want to customize the data, please considering the function in Data Preprocess Page."
  } else {
    X <- as.matrix(sapply(X, as.numeric))  
    y <- as.numeric(y)  
  }
  
  
  if (method == "LASSO") {
    if (lambdaCV) {
      cv_fit <- cv.glmnet(X, y, alpha = 1)
      lambda_val <- cv_fit$lambda.min  
    }
    model <- glmnet(X, y, alpha = lambdaL, lambda = lambda_val)
    selected_features <- rownames(coef(model))[coef(model)[, 1] != 0]
    
    
  } else if (method == "Elastic Net") {
    if (lambdaCV) {
      cv_fit <- cv.glmnet(X, y, alpha = 0.5)
      lambda_val <- cv_fit$lambda.min
    }
    model <- glmnet(X, y, alpha = lambdaL, lambda = lambda_val)
    selected_features <- rownames(coef(model))[coef(model)[, 1] != 0]
    
    
  } else if (method == "Forward Stepwise") {
    lm_model <- lm(as.formula(paste(y_cols, "~", paste(colnames(X), collapse = " + "))), data = df)
    model <- ols_step_way_c(lm_model,"for",criteriaFS) 
    selected_features <-  names(coef(model$model))[-1]  
    
  } else if (method == "Backward Stepwise") {
    lm_model <- lm(as.formula(paste(y_cols, "~", paste(colnames(X), collapse = " + "))), data = df)
    model <- ols_step_way_c(lm_model,"back",criteriaFS) 
    selected_features <- names(coef(model$model))[-1]  
  }else if(method == "Bothway Stepwise"){
    lm_model <- lm(as.formula(paste(y_cols, "~", paste(colnames(X), collapse = " + "))), data = df)
    model <- ols_step_way_c(lm_model,"both",criteriaFS) 
    selected_features <- names(coef(model$model))[-1]  
  }
  result<-list(method = method,
               lambda = lambda_val,
               selected_features = selected_features,
               error_check = error_check,
               model = model)
  return(result)
}

#new Feature
new_maker <- function(df, col1, operation, input_type, col2 = NULL, number_input = NULL, new_col_name) {
  operation_map <- list(
    "Addition" = `+`,
    "Subtraction" = `-`,
    "Multiplication" = `*`,
    "Division" = `/`,
    "Natural Log" = log,
    "Power" = `^`
  )
  
  if (input_type == "Select Column" && !is.null(col2)) {
    df[[new_col_name]] <- operation_map[[operation]](df[[col1]], df[[col2]])
  } else if (input_type == "Enter Number" && !is.null(number_input)) {
    if (operation == "Natural Log") {
      df[[new_col_name]] <- log(df[[col1]])
    } else {
      df[[new_col_name]] <- operation_map[[operation]](df[[col1]], number_input)
    }
  }
  return(df)
}

# Server Logic
server <- function(input, output, session) {
  origionData <- reactiveVal(NULL)  
  reactiveData <- reactiveVal(NULL)  
  summaryLog <- reactiveVal(c("Preprocessing activities:"))
  PCA_transformed_Data<- reactiveVal(NULL)  
  FS_result<- reactiveVal(NULL)  
  NF_Data <- reactiveVal(data.frame())  
  new_feature_name <- reactiveVal(NULL)  
  
  #check the user is group A or B
  userGroup <- reactive({
    parseQueryString(session$clientData$url_search)$group %||% "A"
  })
  
  isTutorialGroup <- reactive({
    userGroup() == "A"
  })
  
  
  # Show the tutorial for Loading Datasets page
  observe({
    if(isTutorialGroup()){
      shinyjs::show("loadingTutorialOverlay")  # Show the tutorial overlay
      session$sendCustomMessage("disable-clicks-uni", TRUE)  # Disable other clicks temporarily
    }
  })
  
  observeEvent(input$nextLoadingTutorial, {
    shinyjs::hide("loadingTutorialOverlay")  # Hide the tutorial overlay when 'Next' is clicked
    session$sendCustomMessage("disable-clicks-uni", FALSE)  # Enable other clicks
  })
  
  # Upload & Read Data
  observeEvent(input$loadData, {
    df <- if (!is.null(input$file)) {
      ext <- tools::file_ext(input$file$name)
      switch(ext,
             csv = read_csv(input$file$datapath),
             xlsx = read_excel(input$file$datapath),
             json = fromJSON(input$file$datapath),
             rds = readRDS(input$file$datapath),
             stop("Invalid file format"))
    } else {
      get(input$dataset)
    }
    
    df <- clean_data(df, missing_strategy = input$missingStrategy)
    
    origionData(df)
    reactiveData(df)
    summaryLog(c(summaryLog(), "Data loaded successfully."))
    
    session$sendCustomMessage("trackEvent", list(
      event    = "LoadData",
      category = userGroup(),
      label    = "LoadingDatasets"
    ))
  })
  
  dataProcessingSteps <- c(
    "<span style='font-size:18px;'>Welcome to Data Preprocessing! Let's clean and transform your data.</span>",
    "<span style='font-size:18px;'>1️⃣ Choose how to handle <strong>missing values</strong> from the dropdown.</span>",
    "<span style='font-size:18px;'>2️⃣ View <strong>Duplicates</strong> and decide whether to <strong>remove duplicates</strong>.</span>",
    "<span style='font-size:18px;'>3️⃣ Check the <strong>Data Statistics</strong> and then select column(s) you'd like to convert to <strong>numeric</strong> or <strong>categorical</strong>.</span>",
    "<span style='font-size:18px;'>4️⃣ Specify column(s) to <strong>standardize</strong>, if needed.</span>",
    "<span style='font-size:18px;'>5️⃣ Select column(s) and choose your <strong>categorical encoding</strong> strategy.</span>",
    "<span style='font-size:18px;'>6️⃣ Handle <strong>outliers</strong> with strategies from the dropdown options.</span>",
    "<span style='font-size:18px;'>✅ All set! Click <strong>Run Preprocessing</strong> to apply and view the effect of your change from <strong>Distribution & Processed Data</strong>.</span>"
  )
  
  dataProcessingIndex <- reactiveVal(1)
  dataProcessingTutorialShown <- reactiveVal(FALSE)
  
  observe({
    if (isTutorialGroup() && input$mainTabs == "preprocess" && !dataProcessingTutorialShown()) {
      dataProcessingIndex(1)
      shinyjs::runjs("startPreprocessStep(1);")
      shinyjs::show("dataProcessingTutorialOverlay")
      session$sendCustomMessage("disable-clicks-data", TRUE)
      dataProcessingTutorialShown(TRUE)
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  observe({
    # When on the final step, change button to "Done"
    final_step <- dataProcessingIndex() == length(dataProcessingSteps)
    updateActionButton(
      session,
      "nextDataProcessingTutorial",
      label = if (final_step) "Done" else "Next"
    )
  })
  
  output$dataProcessingTutorialText <- renderUI({
    HTML(dataProcessingSteps[dataProcessingIndex()])
  })
  
  observeEvent(input$nextDataProcessingTutorial, {
    shinyjs::runjs(paste0("endPreprocessStep(", dataProcessingIndex(), ");"))
    
    if (dataProcessingIndex() < length(dataProcessingSteps)) {
      dataProcessingIndex(dataProcessingIndex() + 1)
      shinyjs::runjs(paste0("startPreprocessStep(", dataProcessingIndex(), ");"))
    } else {
      shinyjs::hide("dataProcessingTutorialOverlay")
      session$sendCustomMessage("disable-clicks-data", FALSE)
    }
  })
  
  observeEvent(input$preprocessStepEnded, {
    info <- input$preprocessStepEnded
    print(paste(
      "[Timer] Step", info$step, ":", round(info$duration, 2), "sec at", info$timestamp
    ))
  })
  
  observe({
    df <- reactiveData()
    if (!is.null(df)) {
      updateSelectInput(session, "xvar", choices = names(df)) 
      updateSelectInput(session, "yvar", choices = names(df))
      
      updateSelectizeInput(session, "manualNumeric", choices = names(df), server = TRUE)
      updateSelectizeInput(session, "manualCategorical", choices = names(df), server = TRUE)
      
      numeric_cols <- names(df)[sapply(df, is.numeric)]
      updateSelectInput(session, "distCol", choices = numeric_cols)
      updateSelectizeInput(session, "scaleCols", choices = numeric_cols, server = TRUE)
      
      categorical_cols <- names(df)[sapply(df, is.factor)]
      updateSelectizeInput(session, "encodeCols", choices = categorical_cols, server = TRUE)
    }
  })
  
  observeEvent(input$processData, {
    req(origionData())
    df <- origionData()
    
    session$sendCustomMessage("trackEvent", list(
      event    = "ProcessData",
      category = userGroup(),
      label    = "DataPreprocess"
    ))
    
    # 1. Remove Duplicates if checked
    if (input$removeDuplicates) {
      num_duplicates <- sum(duplicated(df))
      if (num_duplicates > 0) {
        df <- unique(df)
        summaryLog(c(summaryLog(), paste("Removed Duplicates:", num_duplicates)))
      } else {
        summaryLog(c(summaryLog(), "No duplicates found."))
      }
    }
    # 2. let user manually select columns to convert to corresponding type
    if (!is.null(input$manualNumeric) && length(input$manualNumeric) > 0) {
      for(col in input$manualNumeric) {
        df[[col]] <- as.numeric(as.character(df[[col]]))
      }
      summaryLog(c(summaryLog(), 
                   paste("Manually converted to numeric:", 
                         paste(input$manualNumeric, collapse = ", "))))
    }
    
    if (!is.null(input$manualCategorical) && length(input$manualCategorical) > 0) {
      for(col in input$manualCategorical) {
        df[[col]] <- as.factor(as.character(df[[col]]))
      }
      summaryLog(c(summaryLog(), 
                   paste("Manually converted to categorical:", 
                         paste(input$manualCategorical, collapse = ", "))))
    }
    
    # 3. Scale if user selected columns
    if (!is.null(input$scaleCols) && length(input$scaleCols) > 0) {
      df <- standardize(df, input$scaleCols)
      summaryLog(c(summaryLog(), 
                   paste("Scaled columns:", paste(input$scaleCols, collapse = ", "))))
    }
    
    # 4. Encode categorical cols if user selected cols & strategy != "None"
    if (!is.null(input$encodeCols) && length(input$encodeCols) > 0 && input$encodingStrategy != "None") {
      df <- encode_categorical(df, input$encodeCols, strategy = input$encodingStrategy)
      summaryLog(c(summaryLog(), 
                   paste("Encoded columns:", paste(input$encodeCols, collapse = ", "),
                         "Strategy:", input$encodingStrategy)))
    }
    
    # 5. Handle Outliers
    if (input$outlierStrategy != "None") {
      df <- handle_outliers(df, 
                            outlier_strategy = input$outlierStrategy)
      summaryLog(c(summaryLog(), paste("Outlier Handling:", input$outlierStrategy)))
    }
    
    # Update reactiveData
    reactiveData(df)
  })
  
  
  output$originalDataTable <- renderDT({
    req(origionData())
    datatable(origionData())
  })
  
  output$processedDataTable <- renderDT({
    req(reactiveData())
    datatable(reactiveData())
  })
  
  output$summaryInfo <- renderPrint({
    cat(summaryLog(), sep = "\n")
  })
  
  output$dataSummary <- renderPrint({
    summary(reactiveData())
  })
  
  output$dupTable <- renderDT({
    df <- reactiveData()
    if (!is.null(df)) {
      dup_rows <- df[duplicated(df), ]
      datatable(dup_rows)
    }
  })
  
  output$plot <- renderPlot({
    req(input$xvar, input$yvar) 
    ggplot(reactiveData(), aes_string(x = input$xvar, y = input$yvar)) +
      geom_point() + theme_minimal()
  })
  
  output$distPlot <- renderPlot({
    req(input$distCol, origionData(), reactiveData())
    col <- input$distCol
    
    # Extract the chosen column from both original and processed data
    orig_values <- origionData()[[col]]
    proc_values <- reactiveData()[[col]]
    
    # Build two data frames 
    plot_data_orig <- data.frame(value = orig_values, Dataset = "Original")
    plot_data_proc <- data.frame(value = proc_values, Dataset = "Processed")
    
    # Combine
    plot_data <- rbind(plot_data_orig, plot_data_proc)
    
    if (input$distPlotType == "Histogram") {
      ggplot(plot_data, aes(x = value, fill = Dataset)) +
        geom_histogram(aes(y = ..density..), bins = 30, alpha = 0.5, position = "identity") +
        geom_density(alpha = 0.2) +
        facet_wrap(~Dataset, scales = "free_x") +
        theme_minimal() +
        labs(title = paste("Distribution Impact for", col),
             x = col, y = "Density")
    } else { # boxplot
      ggplot(plot_data, aes(x = Dataset, y = value, fill = Dataset)) +
        geom_boxplot(alpha = 0.5) +
        theme_minimal() +
        labs(title = paste("Boxplot Comparison for", col),
             x = "Dataset", y = col)
    }
  })
  
  #PCA 
  observe({
    df <- reactiveData()
    if (!is.null(df)) {
      numeric_cols <- names(df)[sapply(df, is.numeric)]
      updateSelectizeInput(session, "pcaCols", choices = numeric_cols, server = TRUE)
    }
  })
  
  
  observeEvent(input$applyPCA, {
    req(reactiveData(), input$pcaCols, input$numPCA)
    df <- reactiveData()
    df <- apply_pca(df, input$pcaCols, input$numPCA)
    PCA_transformed_Data(df)
    
    session$sendCustomMessage("trackEvent", list(
      event = "ApplyPCA",
      category = userGroup(),
      label = "FeatureEngineering"
    ))
    
  })
  
  
  output$pcaSummary <- renderPrint({
    req(input$pcaCols)
    df <- reactiveData()
    pca_model <- prcomp(df[, input$pcaCols, drop = FALSE], center = TRUE, scale. = TRUE)
    summary(pca_model)
  })
  
  output$pcaDataTable <- renderDT({
    req(PCA_transformed_Data())
    datatable(PCA_transformed_Data(),options = list(scrollX = TRUE))
  })
  
  observeEvent(input$savePCA, {
    df<- PCA_transformed_Data()
    reactiveData(df)
    
    session$sendCustomMessage("trackEvent", list(
      event = "SavePCA",
      category = userGroup(),
      label = "FeatureEngineering"
    ))
    
  })
  
  #feature selection
  observeEvent(input$applyFS, {
    req(reactiveData(), input$FSyCols, input$FSCols)
    df <- reactiveData()
    result<- applyFS(df, input$FSyCols, input$FSCols,input$lambdaL,input$lambdaCV,input$criteriaFS)
    FS_result(result)
    
    session$sendCustomMessage("trackEvent", list(
      event = "ApplyFeatureSelection",
      category = userGroup(),
      label = "FeatureEngineering"
    ))
  })
  
  observe({
    df <- reactiveData()
    if (!is.null(df)) {
      updateSelectizeInput(session, "FSyCols", choices = colnames(df), server = TRUE)
    }
  })
  
  # Output feature selection 
  output$FSSummary <- renderPrint({
    result <- FS_result() 
    req(result)
    if(result$error_check){
      cat("Error Message:", result$message, "\n") 
    }  
    cat("Feature Selection Method:", result$method, "\n")    
    if (result$method %in% c("LASSO", "Elastic Net")) {
      cat("Lambda:", result$lambda, "\n")
    }    
    cat("Selected Features:", 
        if (length(result$selected_features) > 0) {
          paste(result$selected_features, collapse = ", ")
        } else {
          "No features selected."
        }, "\n"
    )
    
    if(input$detailFS){
      cat("\n---------- Model Detail ----------\n")
      if (result$method %in% c("LASSO", "Elastic Net")){
        cat("\nCoefficients at Best Lambda:\n") 
        print(coef(result$model, s = "lambda.min"))
        cat("\nDeviance Ratio:\n")
        print(result$model$dev.ratio)      			
      }
      else{
        print(result$model)
      }
    }
    
  })
  
  #new feature 
  output$col1_ui <- renderUI({
    data <- reactiveData()
    req(data)
    selectInput("col1", "Select First Column:", choices = names( data))
  })
  
  output$col2_or_number_ui <- renderUI({
    data <- reactiveData()
    req(data)
    if (input$input_type == "Select Column") {
      selectInput("col2", "Select Second Column:", choices = names( data))
    } else {
      numericInput("number_input", "Enter Number:", value = 1)
    }
  })
  
  observeEvent(input$applyOP, {
    df <- reactiveData()  
    
    updated_df <- new_maker(
      df = df,
      col1 = input$col1,
      operation = input$opF,
      input_type = input$input_type,
      col2 = input$col2,
      number_input = input$number_input,
      new_col_name = input$NewF
    )
    NF_Data(updated_df)  
    new_feature_name(input$NewF)
    
    session$sendCustomMessage("trackEvent", list(
      event = "ApplyNewFeature",
      category = userGroup(),
      label = "FeatureEngineering"
    ))
  })
  
  
  observeEvent(input$saveNF,{
    req(NF_Data())
    reactiveData(NF_Data())
    
    session$sendCustomMessage("trackEvent", list(
      event = "SaveNewFeature",
      category = userGroup(),
      label = "FeatureEngineering"
    ))
  })
  
  output$newSummary <- renderPrint({
    req(NF_Data(), new_feature_name())  
    df <- NF_Data()
    colname <- new_feature_name()
    if (any(is.infinite(df[[colname]]))){
      message_MN <-  paste0("Warning: The new feature '", colname, "' contains Inf values.\n ",
                            "Check for division by zero or log of non-positive numbers or Exponentiation Overflow.")
      
      cat(message_MN,"\n")
    }
    cat("New Feature Name:",colname,"\n")
    cat("Distribution:","\n")
    print(summary(df[[colname]]))
  })
  
  
  observe({
    df <- reactiveData()
    if (!is.null(df)) {
      updateSelectInput(session, "statVar", choices = names(df), selected = names(df)[1])
    }
  })
  
  output$statSummary <- renderPrint({
    df <- reactiveData()
    req(df, input$statVar)
    
    summary(df[[input$statVar]])
  })
  
  # Render Histogram
  output$histPlot <- renderPlot({
    df <- reactiveData()
    req(df, input$statVar, input$histogram)
    
    # Set default binwidth
    binwidth <- input$binWidth
    
    # Apply custom binwidth if "Enter Binwidth" is selected
    if ("Enter Binwidth" %in% input$histOptions) {
      binwidth <- input$customBinwidth
    }
    
    # Set default histogram plot
    p <- ggplot(df, aes_string(x = input$statVar)) +
      geom_histogram(binwidth = binwidth, fill = "skyblue", color = "black") +
      theme_minimal() +
      labs(title = "Histogram", x = input$statVar, y = "Frequency")
    
    # Adjust starting bin if selected
    if ("Select Starting Bin" %in% input$histOptions) {
      max_value <- max(df[[input$statVar]], na.rm = TRUE)
      p <- p + scale_x_continuous(limits = c(input$startBin, max_value))
    }
    
    # Convert to percentage if "Display Percent" is selected
    if ("Display Percent" %in% input$histOptions) {
      p <- ggplot(df, aes_string(x = input$statVar)) +
        geom_histogram(aes(y = ..density.. * 100), binwidth = binwidth, fill = "skyblue", color = "black") +
        theme_minimal() +
        labs(title = "Histogram (Percent)", x = input$statVar, y = "Percent (%)")
    }
    
    p
  })
  
  # Render Boxplot
  output$boxPlot <- renderPlot({
    df <- reactiveData()
    req(df, input$statVar, input$boxplot)
    
    is_vertical <- input$verticalPlot
    
    if (!is_vertical) {
      p <- ggplot(df, aes_string(y = input$statVar, x = "1")) +
        geom_boxplot(fill = "skyblue", color = "black") +
        theme_minimal() +
        labs(title = "Boxplot", y = input$statVar, x = "Values") +
        theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
    } else {
      p <- ggplot(df, aes_string(x = input$statVar, y = "1")) +
        geom_boxplot(fill = "skyblue", color = "black") +
        theme_minimal() +
        labs(title = "Boxplot", x = input$statVar, y = "Values") +
        theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
    }
    
    p
  })
  
  # Render Dotplot
  output$dotPlot <- renderPlot({
    df <- reactiveData()
    req(df, input$statVar, input$dotplot)
    
    ggplot(df, aes_string(x = input$statVar)) +
      geom_dotplot(binwidth = 0.1, dotsize = 0.5, fill = "skyblue") +
      theme_minimal() +
      labs(title = "Dotplot", x = input$statVar, y = "Count")
  })
  
  # Track when user enables histogram
  observeEvent(input$histogram, {
    if (input$histogram) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnableHistogram",
        category = "EDA-Univariate",
        label = "NumericalAnalysis"
      ))
    }
  })
  
  # Track boxplot click
  observeEvent(input$boxplot, {
    if (input$boxplot) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnableBoxplot",
        category = "EDA-Univariate",
        label = "NumericalAnalysis"
      ))
    }
  })
  
  # Track dotplot click
  observeEvent(input$dotplot, {
    if (input$dotplot) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnableDotplot",
        category = "EDA-Univariate",
        label = "NumericalAnalysis"
      ))
    }
  })
  
  # Track bar chart click
  observeEvent(input$barChart, {
    if (input$barChart) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnableBarChart",
        category = "EDA-Univariate",
        label = "CategoricalAnalysis"
      ))
    }
  })
  
  # Track pie chart click
  observeEvent(input$pieChart, {
    if (input$pieChart) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnablePieChart",
        category = "EDA-Univariate",
        label = "CategoricalAnalysis"
      ))
    }
  })
  
  # Render Correlation Heatmap
  output$heatmapOutput <- renderPlot({
    df <- reactiveData()
    req(df)
    
    # Select only numeric columns
    numeric_df <- df %>% select(where(is.numeric))
    
    # Check if there are numeric variables to compute correlation
    if (ncol(numeric_df) < 2) {
      showNotification("Not enough numeric variables for correlation heatmap.", type = "warning")
      return(NULL)
    }
    
    # Compute correlation matrix
    cor_matrix <- cor(numeric_df, use = "pairwise.complete.obs")
    
    # Convert correlation matrix into long format for ggplot
    cor_long <- reshape2::melt(cor_matrix)
    
    # Create heatmap using ggplot2
    ggplot(cor_long, aes(Var1, Var2, fill = value)) +
      geom_tile(color = "white") +
      scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                           midpoint = 0, limit = c(-1,1), space = "Lab", 
                           name="Correlation") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
      labs(title = "Correlation Heatmap", x = "", y = "")
  })
  
  
  observe({
    df <- reactiveData()
    req(df)  
    
    # Select only numeric columns
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    
    # Select only categorical columns
    categorical_cols <- names(df)[sapply(df, is.factor) | sapply(df, is.character)]
    
    # Update selectInput choices
    updateSelectInput(session, "statVar", choices = numeric_cols, selected = numeric_cols[1])
    updateSelectInput(session, "catVar", choices = categorical_cols, selected = categorical_cols[1])
  })
  
  output$barChartPlot <- renderPlot({
    df <- reactiveData()
    req(df, input$catVar, input$barChart)  # Ensure input is selected
    
    # Convert categorical variable to factor (needed for ggplot)
    df[[input$catVar]] <- as.factor(df[[input$catVar]])
    
    # Count frequency of each category
    plot_data <- df %>%
      count(!!sym(input$catVar)) %>%
      mutate(Percent = n / sum(n) * 100)
    
    # Create the bar chart
    p <- ggplot(plot_data, aes(x = !!sym(input$catVar), y = n, fill = !!sym(input$catVar))) +
      geom_bar(stat = "identity", color = "black") +
      theme_minimal() +
      labs(title = "Bar Chart", x = input$catVar, y = "Count") +
      theme(legend.position = "none")
    
    # Display Percent if selected
    if (input$displayPercent) {
      p <- p + geom_text(aes(label = paste0(round(Percent, 1), "%")), vjust = -0.5)
    }
    
    p
  })
  
  output$pieChartPlot <- renderPlot({
    df <- reactiveData()
    req(df, input$catVar, input$pieChart)  # Ensure input is selected
    
    # Convert categorical variable to factor (needed for ggplot)
    df[[input$catVar]] <- as.factor(df[[input$catVar]])
    
    # Count frequency of each category
    plot_data <- df %>%
      count(!!sym(input$catVar)) %>%
      mutate(Percent = n / sum(n) * 100)
    
    # Create the pie chart
    ggplot(plot_data, aes(x = "", y = n, fill = !!sym(input$catVar))) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar(theta = "y") +
      theme_void() +
      labs(title = "Pie Chart", fill = input$catVar) +
      theme(legend.position = "right")
  })
  
  observe({
    df <- reactiveData()
    req(df)  
    
    # Select only numeric columns
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    
    # Select only categorical columns
    categorical_cols <- names(df)[sapply(df, is.factor) | sapply(df, is.character)]
    
    # Update selectInput choices
    updateSelectInput(session, "xNumVar", choices = numeric_cols, selected = numeric_cols[1])
    updateSelectInput(session, "yNumVar", choices = numeric_cols, selected = numeric_cols[1])
    updateSelectInput(session, "xCatVar", choices = categorical_cols, selected = categorical_cols[1])
    updateSelectInput(session, "yCatVar", choices = categorical_cols, selected = categorical_cols[1])
    updateSelectInput(session, "numVar", choices = numeric_cols, selected = numeric_cols[1])
    updateSelectInput(session, "catVarCN", choices = categorical_cols, selected = categorical_cols[1])
  })
  
  
  output$scatterPlotOutput <- renderPlot({
    df <- reactiveData()
    req(df, input$xNumVar, input$yNumVar, input$scatterPlot)
    
    p <- ggplot(df, aes_string(x = input$xNumVar, y = input$yNumVar)) +
      geom_point(color = "blue", alpha = 0.7) +
      theme_minimal() +
      labs(title = "Scatter Plot", x = input$xNumVar, y = input$yNumVar)
    
    if (input$smooth) {
      p <- p + geom_smooth(method = "lm", se = FALSE, color = "red")
    }
    
    p
  })
  
  output$linePlotOutput <- renderPlot({
    df <- reactiveData()
    req(df, input$xNumVar, input$yNumVar, input$linePlot)
    
    p <- ggplot(df, aes_string(x = input$xNumVar, y = input$yNumVar)) +
      geom_line(color = "blue") +
      theme_minimal() +
      labs(title = "Line Plot", x = input$xNumVar, y = input$yNumVar)
    
    if (input$lineSmooth) {
      p <- p + geom_smooth(method = "lm", se = FALSE, color = "red")
    }
    
    p
  })
  
  output$catPlotOutput <- renderPlot({
    df <- reactiveData()
    req(df, input$xCatVar, input$yCatVar, input$catPlotType)
    
    df[[input$xCatVar]] <- as.factor(df[[input$xCatVar]])
    df[[input$yCatVar]] <- as.factor(df[[input$yCatVar]])
    
    p <- ggplot(df, aes(x = !!sym(input$xCatVar), fill = !!sym(input$yCatVar)))
    
    if (input$catPlotType == "Grouped Bar Chart") {
      p <- p + geom_bar(position = "dodge") + labs(title = "Grouped Bar Chart")
    } else if (input$catPlotType == "Stacked Bar Chart") {
      p <- p + geom_bar(position = "stack") + labs(title = "Stacked Bar Chart")
    } else if (input$catPlotType == "100% Stacked Bar") {
      p <- p + geom_bar(position = "fill") + labs(title = "100% Stacked Bar Chart", y = "Proportion")
    }
    
    p + theme_minimal() + labs(x = input$xCatVar, y = "Count")
  })
  
  output$catNumPlotOutput <- renderPlot({
    df <- reactiveData()
    req(df, input$numVar, input$catVarCN, input$catNumPlotType)
    
    df[[input$catVarCN]] <- as.factor(df[[input$catVarCN]])
    
    p <- ggplot(df, aes(x = !!sym(input$catVarCN), y = !!sym(input$numVar), fill = !!sym(input$catVarCN)))
    
    if (input$catNumPlotType == "Boxplot") {
      p <- p + geom_boxplot() + labs(title = "Boxplot: Numerical vs Categorical")
    } else if (input$catNumPlotType == "Violin Plot") {
      p <- p + geom_violin() + labs(title = "Violin Plot: Numerical vs Categorical")
    }
    
    p + theme_minimal()
  })
  
  observeEvent(input$scatterPlot, {
    if (input$scatterPlot) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnableScatterPlot",
        category = "EDA-Bivariate",
        label = "NumericalAnalysis"
      ))
    }
  })
  
  observeEvent(input$linePlot, {
    if (input$linePlot) {
      session$sendCustomMessage("trackEvent", list(
        event = "EnableLinePlot",
        category = "EDA-Bivariate",
        label = "NumericalAnalysis"
      ))
    }
  })
  
  
  observeEvent(input$catPlotType, {
    session$sendCustomMessage("trackEvent", list(
      event = paste0("CatPlotType_", input$catPlotType),
      category = "EDA-Bivariate",
      label = "CategoricalAnalysis"
    ))
  })
  
  
  observeEvent(input$catNumPlotType, {
    session$sendCustomMessage("trackEvent", list(
      event = paste0("CatNumPlotType_", input$catNumPlotType),
      category = "EDA-Bivariate",
      label = "CatNumAnalysis"
    ))
  })
  
  
  observe({
    df <- reactiveData()
    req(df)  
    
    # Select only numeric columns
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    
    # Update selectInput choices for numerical correlation tests
    updateSelectInput(session, "numVar1", choices = numeric_cols, selected = numeric_cols[1])
    updateSelectInput(session, "numVar2", choices = numeric_cols, selected = numeric_cols[2])
  })
  
  output$numNumTestResult <- renderPrint({
    df <- reactiveData()
    req(df, input$numVar1, input$numVar2, input$numNumTest)
    
    # Determine test method
    test_method <- ifelse(input$numNumTest == "Pearson Correlation", "pearson", "kendall")
    
    # Perform the correlation test
    test_result <- cor.test(df[[input$numVar1]], df[[input$numVar2]], method = test_method)
    
    # Extract key values
    correlation_coefficient <- test_result$estimate
    p_value <- test_result$p.value
    
    # Interpretation
    interpretation <- if (p_value < 0.05) {
      "The correlation is statistically significant (p < 0.05), meaning there is evidence of an association."
    } else {
      "The correlation is not statistically significant (p ≥ 0.05), meaning there is no strong evidence of an association."
    }
    
    strength <- ifelse(abs(correlation_coefficient) > 0.7, "strong",
                       ifelse(abs(correlation_coefficient) > 0.4, "moderate",
                              ifelse(abs(correlation_coefficient) > 0.2, "weak", "very weak or none")))
    
    relationship <- ifelse(correlation_coefficient > 0, "positive", "negative")
    
    cat("📌", input$numNumTest, "Results:\n")
    cat("----------------------------------\n")
    cat("🔹 Correlation Coefficient:", round(correlation_coefficient, 3), "\n")
    cat("🔹 P-Value:", format.pval(p_value, digits = 3), "\n")
    cat("🔹 Interpretation:", interpretation, "\n")
    cat("🔹 Strength of Relationship:", strength, "(", relationship, "correlation )\n")
    
    if (strength == "strong") {
      cat("✅ This suggests a strong association between", input$numVar1, "and", input$numVar2, ".\n")
    } else if (strength == "moderate") {
      cat("⚠ There is a moderate relationship, indicating some degree of association.\n")
    } else if (strength == "weak") {
      cat("🔍 The correlation is weak, meaning the variables might not be strongly related.\n")
    } else {
      cat("❌ The correlation is very weak or non-existent.\n")
    }
  })
  
  observeEvent({
    input$numVar1
    input$numVar2
    input$numNumTest
  }, {
    df <- reactiveData()
    if (!is.null(df) && !is.null(input$numVar1) && !is.null(input$numVar2) && input$numNumTest != "") {
      session$sendCustomMessage("trackEvent", list(
        event = "RunNumNumTest",
        category = "EDA-StatisticalTest",
        label = input$numNumTest
      ))
    }
  }, ignoreInit = TRUE)
  
  
  observe({
    df <- reactiveData()
    req(df)  
    
    # Select only categorical columns
    categorical_cols <- names(df)[sapply(df, is.factor) | sapply(df, is.character)]
    
    # Update selectInput choices for categorical test
    updateSelectInput(session, "catVar1", choices = categorical_cols, selected = categorical_cols[1])
    updateSelectInput(session, "catVar2", choices = categorical_cols, selected = categorical_cols[2])
  })
  
  output$catCatTestResult <- renderPrint({
    df <- reactiveData()
    req(df, input$catVar1, input$catVar2, input$catCatTest)
    
    # Create contingency table
    contingency_table <- table(df[[input$catVar1]], df[[input$catVar2]])
    
    # Perform Chi-Square Test
    test_result <- chisq.test(contingency_table)
    
    # Extract key values
    chi_square_value <- test_result$statistic
    p_value <- test_result$p.value
    expected_values <- test_result$expected
    
    # Interpretation
    interpretation <- if (p_value < 0.05) {
      "The test is statistically significant (p < 0.05), meaning there is an association between these categorical variables."
    } else {
      "The test is not statistically significant (p ≥ 0.05), meaning there is no strong evidence of an association."
    }
    
    strength <- ifelse(p_value < 0.01, "very strong",
                       ifelse(p_value < 0.05, "moderate",
                              ifelse(p_value < 0.1, "weak", "no significant")))
    
    cat("📌 Chi-Square Test Results:\n")
    cat("----------------------------------\n")
    cat("🔹 Chi-Square Value:", round(chi_square_value, 3), "\n")
    cat("🔹 P-Value:", format.pval(p_value, digits = 3), "\n")
    cat("🔹 Interpretation:", interpretation, "\n")
    cat("🔹 Strength of Association:", strength, "\n")
    
    if (strength == "very strong") {
      cat("✅ This suggests a strong association between", input$catVar1, "and", input$catVar2, ".\n")
    } else if (strength == "moderate") {
      cat("⚠ There is a moderate association, indicating some dependence between these variables.\n")
    } else if (strength == "weak") {
      cat("🔍 The association is weak and should be interpreted with caution.\n")
    } else {
      cat("❌ There is no significant association between", input$catVar1, "and", input$catVar2, ".\n")
    }
  })
  
  observeEvent({
    input$catVar1
    input$catVar2
    input$catCatTest
  }, {
    df <- reactiveData()
    if (!is.null(df) && !is.null(input$catVar1) && !is.null(input$catVar2) && input$catCatTest != "") {
      session$sendCustomMessage("trackEvent", list(
        event = "RunCatCatTest",
        category = "EDA-StatisticalTest",
        label = input$catCatTest
      ))
    }
  }, ignoreInit = TRUE)
  
  
  univariateSteps <- c(
    "<span style='font-size:18px;'>Welcome to Univariate Analysis! Let’s explore one variable at a time.</span>",
    "<span style='font-size:18px;'>1️⃣ Select a <strong>numerical variable</strong> from the dropdown at the top left.</span>",
    "<span style='font-size:18px;'>2️⃣ Choose which charts to show: <strong>Histogram</strong>, <strong>Boxplot</strong>, or <strong>Dotplot</strong>.</span>",
    "<span style='font-size:18px;'>3️⃣ Customize your <strong>Histogram</strong> (binwidth, start point, percent view).</span>",
    "<span style='font-size:18px;'>4️⃣ Select a <strong>categorical variable</strong> and pick a <strong>Bar Chart</strong> or <strong>Pie Chart</strong>.</span>",
    "<span style='font-size:18px;'>✅ You’re ready to analyze!</span>"
  )
  
  uniIndex <- reactiveVal(1)
  uniTutorialShown <- reactiveVal(FALSE)
  
  observe({
    if (isTutorialGroup() && input$edaTabs == "Univariate Analysis" && !uniTutorialShown()) {
      uniIndex(1)
      shinyjs::show("uniTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", TRUE)
      
      uniTutorialShown(TRUE)  # ✅ Mark as shown
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  observe({
    isLast <- uniIndex() == length(univariateSteps)
    updateActionButton(
      session,
      "nextUniTutorial",
      label = if (isLast) "Done" else "Next"
    )
  })
  
  output$uniTutorialText <- renderUI({
    HTML(univariateSteps[uniIndex()])
  })
  
  observeEvent(input$nextUniTutorial, {
    if (uniIndex() < length(univariateSteps)) {
      uniIndex(uniIndex() + 1)
    } else {
      shinyjs::hide("uniTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", FALSE)
    }
  })
  
  bivariateSteps <- c(
    "<span style='font-size:18px;'>Welcome to Bivariate Analysis! This helps you explore relationships between two variables.</span>",
    "<span style='font-size:18px;'>1️⃣ Select two <strong>numerical variables</strong> to visualize with <strong>Scatter Plot</strong> or <strong>Line Plot</strong>.</span>",
    "<span style='font-size:18px;'>2️⃣ Add a <strong>Smooth Line</strong> for clearer trends (optional).</span>",
    "<span style='font-size:18px;'>3️⃣ Select two <strong>categorical variables</strong> and choose a <strong>Grouped</strong>, <strong>Stacked</strong>, or <strong>100% Stacked Bar Chart</strong>.</span>",
    "<span style='font-size:18px;'>4️⃣ Try <strong>Categorical‑Numerical</strong> plots like <strong>Boxplot</strong> or <strong>Violin Plot</strong>.</span>",
    "<span style='font-size:18px;'>✅ Great! You’re ready to explore two‑variable relationships.</span>"
  )
  
  bivIndex <- reactiveVal(1)
  bivTutorialShown <- reactiveVal(FALSE)
  
  observe({
    if (isTutorialGroup() && input$edaTabs == "Bivariate Analysis" && !bivTutorialShown()) {
      bivIndex(1)
      shinyjs::show("bivTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", TRUE)
      bivTutorialShown(TRUE)
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  observe({
    isLast <- bivIndex() == length(bivariateSteps)
    updateActionButton(
      session,
      "nextBivTutorial",
      label = if (isLast) "Done" else "Next"
    )
  })
  
  output$bivTutorialText <- renderUI({
    HTML(bivariateSteps[bivIndex()])
  })
  
  observeEvent(input$nextBivTutorial, {
    if (bivIndex() < length(bivariateSteps)) {
      bivIndex(bivIndex() + 1)
    } else {
      shinyjs::hide("bivTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", FALSE)
    }
  })
  
  heatmapSteps <- c(
    "<span style='font-size:18px;'>Welcome to the Heat Map! Here you’ll see correlations among numerical variables.</span>",
    "<span style='font-size:18px;'>1️⃣ A <strong>Correlation Matrix</strong> is color‑coded: darker means stronger correlation.</span>",
    "<span style='font-size:18px;'>2️⃣ Use it to detect variables with <strong>high correlation</strong> or <strong>potential multicollinearity</strong>.</span>",
    "<span style='font-size:18px;'>✅ Done! Use these insights for feature engineering or regression prep.</span>"
  )
  
  heatIndex <- reactiveVal(1)
  heatTutorialShown <- reactiveVal(FALSE)
  
  observe({
    if (isTutorialGroup() && input$edaTabs == "Heat Map" && !heatTutorialShown()) {
      heatIndex(1)
      shinyjs::show("heatTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", TRUE)
      heatTutorialShown(TRUE)
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  observe({
    isLast <- heatIndex() == length(heatmapSteps)
    updateActionButton(
      session,
      "nextHeatTutorial",
      label = if (isLast) "Done" else "Next"
    )
  })
  
  output$heatTutorialText <- renderUI({
    HTML(heatmapSteps[heatIndex()])
  })
  
  observeEvent(input$nextHeatTutorial, {
    if (heatIndex() < length(heatmapSteps)) {
      heatIndex(heatIndex() + 1)
    } else {
      shinyjs::hide("heatTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", FALSE)
    }
  })
  
  statTestSteps <- c(
    "<span style='font-size:18px;'>Welcome to Statistical Tests! Run formal tests between variables.</span>",
    "<span style='font-size:18px;'>1️⃣ Choose two <strong>numerical variables</strong> and select <strong>Pearson</strong> or <strong>Kendall</strong> correlation test.</span>",
    "<span style='font-size:18px;'>2️⃣ Choose two <strong>categorical variables</strong> and apply the <strong>Chi‑Square Test</strong>.</span>",
    "<span style='font-size:18px;'>✅ Results appear on the right — ready for interpretation.</span>"
  )
  
  statIndex <- reactiveVal(1)
  statTutorialShown <- reactiveVal(FALSE)
  
  observe({
    if (isTutorialGroup() && input$edaTabs == "Statistical Test" && !statTutorialShown()) {
      statIndex(1)
      shinyjs::show("statTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", TRUE)
      statTutorialShown(TRUE)
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  observe({
    isLast <- statIndex() == length(statTestSteps)
    updateActionButton(
      session,
      "nextStatTutorial",
      label = if (isLast) "Done" else "Next"
    )
  })
  
  output$statTutorialText <- renderUI({
    HTML(statTestSteps[statIndex()])
  })
  
  observeEvent(input$nextStatTutorial, {
    if (statIndex() < length(statTestSteps)) {
      statIndex(statIndex() + 1)
    } else {
      shinyjs::hide("statTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", FALSE)
    }
  })
  
  featureSteps <- c(
    "<span style='font-size:18px;'>Welcome to Feature Engineering! Let's explore the features of the data.</span>",
    "<span style='font-size:18px;'>1️⃣ Choose method you want to use <strong>PCA, feature selection or making new feature</strong> .</span>",
    "<span style='font-size:18px;'>2️⃣ Apply <strong>Principal Component Analysis </strong> to reduce dimensionality.</span>",
    "<span style='font-size:18px;'>3️⃣ Choose your preferred <strong>Feature Selection</strong> method to identify the most informative variables.</span>",
    "<span style='font-size:18px;'>4️⃣ Create your own <strong>custom features</strong> by applying mathematical transformations or combining existing columns.</span>",
    "<span style='font-size:18px;'>✅ All set! Click <strong>Apply button</strong> for each methods to run and don't forget click the <strong>Save button</strong> if you want to save the pc / feature you made.</span>"
  )
  
  featureIndex_FE <- reactiveVal(1)
  featureTutorialShown_FE <- reactiveVal(FALSE)
  
  observe({
    if (isTutorialGroup() && input$mainTabs == "Feature Engineering" && !featureTutorialShown_FE()) {
      featureIndex_FE(1)
      shinyjs::show("featureTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", TRUE)
      featureTutorialShown_FE(TRUE)
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  output$featureTutorialText <- renderUI({
    HTML(featureSteps[featureIndex_FE()])
  })
  
  observeEvent(input$nextFeatureTutorial, {
    if (featureIndex_FE() < length(featureSteps)) {
      featureIndex_FE(featureIndex_FE() + 1)
    } else {
      shinyjs::hide("featureTutorialOverlay")
      session$sendCustomMessage("disable-clicks-uni", FALSE)
    }
  })
  
  observe({
    req(input$mainTabs)
    if (input$mainTabs == "Feature Engineering") {
      shinyjs::runjs("window.scrollTo(0, 0);")
    }
  })
  
  observe({
    final_step_FE <-FALSE
    req(input$mainTabs == "Feature Engineering")
    if(featureIndex_FE() == length(featureSteps)){
      final_step_FE <- TRUE
    }  
    updateActionButton(
      session,
      "nextFeatureTutorial",
      label = if (final_step_FE) "Done" else "Next"
    )  
  })
  
  userGroup <- reactive({
    parseQueryString(session$clientData$url_search)$group %||% "A"
  })
  
}
# Run Shiny App
shinyApp(ui, server)