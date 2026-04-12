library(shiny)
library(tidyverse)

# Load data
watchlist <- readr::read_csv("../outputs/watchlists/watchlist.csv", show_col_types = FALSE)

ui <- fluidPage(
  titlePanel("Credit Risk Watchlist"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "risk_filter",
        "Select Risk Level:",
        choices = c("All", "High", "Medium", "Low"),
        selected = "All"
      ),
      
      sliderInput(
        "prob_filter",
        "Minimum Risk Probability:",
        min = 0,
        max = 1,
        value = 0.5,
        step = 0.01
      )
    ),
    
    mainPanel(
      h3("Filtered Watchlist"),
      tableOutput("watchlist_table"),
      
      h3("ROA vs Predicted Risk"),
      plotOutput("scatter_plot")
    )
  )
)

server <- function(input, output, session) {
  
  filtered_data <- reactive({
    
    df <- watchlist
    
    if (input$risk_filter != "All") {
      df <- df %>% filter(risk_bucket == input$risk_filter)
    }
    
    df <- df %>% filter(pred_prob >= input$prob_filter)
    
    df %>% arrange(desc(pred_prob))
  })
  
  output$watchlist_table <- renderTable({
    filtered_data() %>%
      select(bank_name, pred_prob, risk_bucket, roa, npa_ratio) %>%
      head(20)
  })
  
  output$scatter_plot <- renderPlot({
    ggplot(filtered_data(), aes(x = roa, y = pred_prob)) +
      geom_point(alpha = 0.6) +
      labs(
        title = "ROA vs Predicted Risk",
        x = "ROA",
        y = "Predicted Risk"
      )
  })
}

shinyApp(ui, server)
