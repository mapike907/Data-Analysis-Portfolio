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
library(dplyr)
library(readr)


# Read data
skiing <- read.csv(file='Skiing_weather.csv')

head(skiing)
str(skiing)

#change outlook and ski data type from character to factor
skiing$outlook = as.factor(as.character(skiing$outlook))
skiing$ski= as.factor(as.character(skiing$ski))
  
str(skiing)

# Build model
model <- randomForest(ski ~ ., data = skiing, ntree = 500, mtry = 4, importance = TRUE)


# Save model to RDS file
#saveRDS(model, "model.rds")

# Read in the RF model
#model <- readRDS("model.rds")

####################################
# User interface                   #
####################################

ui <- fluidPage(theme = shinytheme("united"),
                
                # Page header
                headerPanel('Do We Ski Today?'),
                
                # Input values
                sidebarPanel(
                  HTML("<h3>Input parameters</h3>"),
                  
                  selectInput("outlook", label = "Outlook:", 
                              choices = list("Sunny" = "sunny", "Overcast" = "overcast", "Rainy" = "rainy", "Snow" = "snow"), 
                              selected = "Sunny"),
                  sliderInput("temperature", label = "Temperature:",
                              min = 10, max = 37,
                              value = 15),
                  sliderInput("humidity", label = "Humidity:",
                              min = 30, max = 45,
                              value = 40),
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
    
    # outlook,temperature,windy,humidity,visability,ski
    df <- data.frame(
      Name = c("outlook",
               "temperature",
               "humidity",
               "visability"),
      Value = as.character(c(input$outlook,
                             input$temperature,
                             input$humidity,
                             input$visability)),
      stringsAsFactors = FALSE)
    
  
    
    ski <- "ski"
    df <- rbind(df, ski)
    input <- transpose(df)
    write.table(input,"input.csv", sep=",", quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    test <-  read.csv(file='input.csv')
    
    test$outlook <- factor(test$outlook, levels = c("overcast", "rainy", "sunny", "snow"))
    test$ski <- factor(test$ski, levels = c("yes", "no"))

    Output <- data.frame(Prediction=predict(model,test), round(predict(model,test,type="prob"), 4))
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

