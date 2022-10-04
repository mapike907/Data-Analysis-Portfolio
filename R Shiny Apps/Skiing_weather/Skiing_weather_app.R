#####################################
# Weather for Skiing Shiny App      #
#                                   #
# Written by Melissa Pike, 10/3/22  #
#####################################


# Import libraries
library(shiny)
library(shinythemes)
library(data.table)
library(RCurl)
library(randomForest)

# Read data
skiing <- read.csv(file='Skiing_weather.csv')

# Build model
model <- randomForest(ski ~ ., data = skiing, ntree = 500, mtry = 4, importance = TRUE)

# Save model to RDS file
# saveRDS(model, "model.rds")

# Read in the RF model
#model <- readRDS("model.rds")

####################################
# User interface                   #
####################################

ui <- fluidPage(theme = shinytheme("united"),
                
                # Page header
                headerPanel('Go Skiing?'),
                
                # Input values
                sidebarPanel(
                  HTML("<h3>Input parameters</h3>"),
                  
                  selectInput("outlook", label = "Outlook:", 
                              choices = list("Sunny" = "sunny", "Overcast" = "overcast", "Rainy" = "rainy", "Snow" = "snow"), 
                              selected = "Rainy"),
                  sliderInput("temperature", "Temperature:",
                              min = 5, max = 37,
                              value = 10),
                  selectInput("windy", label = "Windy:", 
                              choices = list("Yes" = "TRUE", "No" = "FALSE"), 
                              selected = "TRUE"),
                  selectInput("Visability", label = "Visability:", 
                              choices = list("Good" = "TRUE", "Poor" = "FALSE"), 
                              selected = "TRUE"),
                  
                  actionButton("submitbutton", "Submit", class = "btn btn-primary")
                ),
                
                mainPanel(
                  tags$label(h3('Status/Output')), # Status/Output Text Box
                  verbatimTextOutput('contents'),
                  tableOutput('tabledata') # Prediction results table
                  
                )
)

####################################
# Server                           #
####################################

server <- function(input, output, session) {
  
  # Input Data
  datasetInput <- reactive({  
    
    # outlook,temperature,windy, visability, ski
    df <- data.frame(
      Name = c("outlook",
               "temperature",
               "windy",
               "visability"),
      Value = as.character(c(input$outlook,
                             input$temperature,
                             input$humidity,
                             input$windy)),
      stringsAsFactors = FALSE)
    
    ski <- "ski"
    df <- rbind(df, ski)
    input <- transpose(df)
    write.table(input,"input.csv", sep=",", quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    test <- read.csv(paste("input", ".csv", sep=""), header = TRUE)
    
    test$outlook <- factor(test$outlook, levels = c("overcast", "rainy", "sunny", "snow"))
    
    
    Output <- data.frame(Prediction=predict(model,test), round(predict(model,test,type="prob"), 3))
    print(Output)
    
  })
  
  # Status/Output Text Box
  output$contents <- renderPrint({
    if (input$submitbutton>0) { 
      isolate("Calculation complete.") 
    } else {
      return("Server is ready for calculation.")
    }
  })
  
  # Prediction results table
  output$tabledata <- renderTable({
    if (input$submitbutton>0) { 
      isolate(datasetInput()) 
    } 
  })
  
}

####################################
# Create the shiny app             #
####################################
shinyApp(ui = ui, server = server)