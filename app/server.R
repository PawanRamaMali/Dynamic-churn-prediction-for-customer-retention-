# server.R

server <- function(input, output, session) {
  
  rv <- reactiveValues()
  
  # Data Selection Tab ---- 
  # 
  # Retrieving the customer information through the uploaded csv file.
  
  
  observeEvent(
    input$submit_data,
    {
      
    },  ignoreInit = FALSE,
  )
  
  
  rv$data_set <- reactive({
    inFile <- input$input_data_file
    if (is.null(inFile)) return(NULL)
    else read.csv(inFile$datapath)
  })
  
  
  
  observe({
    
    if(input$show_features_responsive){
      features <-  c("Responsive")
    }
    else
      features <-  c("FixedHeader")
    
    rv$data_set <- data_list %>% pluck(input$dataset_choice)
    output$show_data <- renderDataTable({
      rv$data_set %>%
        datatable(rownames = input$show_rownames,
                  options = list(scrollX = TRUE),
                  extensions = features)
    })
    
  })
  
  
  # Data preprocessing Tab ----
  # 
  
  observeEvent(
    input$show_tble,
    {
      print(rv$data_set)
    },  ignoreInit = FALSE,
  )
  
  # Linear Regression Tab ---- 
  
  extract <- function(text) {
    text <- gsub(" ", "", text)
    split <- strsplit(text, ",", fixed = FALSE)[[1]]
    as.numeric(split)
  }
  
  # Data output
  output$tbl <- DT::renderDataTable({
    y <- extract(input$y)
    x <- extract(input$x)
    DT::datatable(
      data.frame(x, y),
      extensions = "Buttons",
      options = list(
        lengthChange = FALSE,
        dom = "Blfrtip",
        buttons = c("copy", "csv", "excel", "pdf", "print")
      )
    )
  })
  
  output$data <- renderUI({
    y <- extract(input$y)
    x <- extract(input$x)
    if (anyNA(x) | length(x) < 2 | anyNA(y) | length(y) < 2) {
      "Invalid input or not enough observations"
    } else if (length(x) != length(y)) {
      "Number of observations must be equal for x and y"
    } else {
      withMathJax(
        paste0("\\(\\bar{x} =\\) ", round(mean(x), 3)),
        br(),
        paste0("\\(\\bar{y} =\\) ", round(mean(y), 3)),
        br(),
        paste0("\\(n =\\) ", length(x))
      )
    }
  })
  
  output$by_hand <- renderUI({
    y <- extract(input$y)
    x <- extract(input$x)
    fit <- lm(y ~ x)
    withMathJax(
      paste0(
        "\\(\\hat{\\beta}_1 = \\dfrac{\\big(\\sum^n_{i = 1} x_i y_i \\big) - n \\bar{x} \\bar{y}}{\\sum^n_{i = 1} (x_i - \\bar{x})^2} = \\) ",
        round(fit$coef[[2]], 3)
      ),
      br(),
      paste0(
        "\\(\\hat{\\beta}_0 = \\bar{y} - \\hat{\\beta}_1 \\bar{x} = \\) ",
        round(fit$coef[[1]], 3)
      ),
      br(),
      br(),
      paste0(
        "\\( \\Rightarrow y = \\hat{\\beta}_0 + \\hat{\\beta}_1 x = \\) ",
        round(fit$coef[[1]], 3),
        " + ",
        round(fit$coef[[2]], 3),
        "\\( x \\)"
      )
    )
  })
  
  output$summary <- renderPrint({
    y <- extract(input$y)
    x <- extract(input$x)
    fit <- lm(y ~ x)
    summary(fit)
  })
  
  output$results <- renderUI({
    y <- extract(input$y)
    x <- extract(input$x)
    fit <- lm(y ~ x)
    withMathJax(
      paste0(
        "Adj. \\( R^2 = \\) ",
        round(summary(fit)$adj.r.squared, 3),
        ", \\( \\beta_0 = \\) ",
        round(fit$coef[[1]], 3),
        ", \\( \\beta_1 = \\) ",
        round(fit$coef[[2]], 3),
        ", P-value ",
        "\\( = \\) ",
        signif(summary(fit)$coef[2, 4], 3)
      )
    )
  })
  
  output$interpretation <- renderUI({
    y <- extract(input$y)
    x <- extract(input$x)
    fit <- lm(y ~ x)
    if (summary(fit)$coefficients[1, 4] < 0.05 &
        summary(fit)$coefficients[2, 4] < 0.05) {
      withMathJax(
        paste0(
          "(Make sure the assumptions for linear regression (independance, linearity, normality and homoscedasticity) are met before interpreting the coefficients.)"
        ),
        br(),
        paste0(
          "For a (hypothetical) value of ",
          input$xlab,
          " = 0, the mean of ",
          input$ylab,
          " = ",
          round(fit$coef[[1]], 3),
          "."
        ),
        br(),
        paste0(
          "For an increase of one unit of ",
          input$xlab,
          ", ",
          input$ylab,
          ifelse(
            round(fit$coef[[2]], 3) >= 0,
            " increases (on average) by ",
            " decreases (on average) by "
          ),
          abs(round(fit$coef[[2]], 3)),
          ifelse(abs(round(
            fit$coef[[2]], 3
          )) >= 2, " units", " unit"),
          "."
        )
      )
    } else if (summary(fit)$coefficients[1, 4] < 0.05 &
               summary(fit)$coefficients[2, 4] >= 0.05) {
      withMathJax(
        paste0(
          "(Make sure the assumptions for linear regression (independance, linearity, normality and homoscedasticity) are met before interpreting the coefficients.)"
        ),
        br(),
        paste0(
          "For a (hypothetical) value of ",
          input$xlab,
          " = 0, the mean of ",
          input$ylab,
          " = ",
          round(fit$coef[[1]], 3),
          "."
        ),
        br(),
        paste0(
          "\\( \\beta_1 \\)",
          " is not significantly different from 0 (p-value = ",
          round(summary(fit)$coefficients[2, 4], 3),
          ") so there is no significant relationship between ",
          input$xlab,
          " and ",
          input$ylab,
          "."
        )
      )
    } else if (summary(fit)$coefficients[1, 4] >= 0.05 &
               summary(fit)$coefficients[2, 4] < 0.05) {
      withMathJax(
        paste0(
          "(Make sure the assumptions for linear regression (independance, linearity, normality and homoscedasticity) are met before interpreting the coefficients.)"
        ),
        br(),
        paste0(
          "\\( \\beta_0 \\)",
          " is not significantly different from 0 (p-value = ",
          round(summary(fit)$coefficients[1, 4], 3),
          ") so when ",
          input$xlab,
          " = 0, the mean of ",
          input$ylab,
          " is not significantly different from 0."
        ),
        br(),
        paste0(
          "For an increase of one unit of ",
          input$xlab,
          ", ",
          input$ylab,
          ifelse(
            round(fit$coef[[2]], 3) >= 0,
            " increases (on average) by ",
            " decreases (on average) by "
          ),
          abs(round(fit$coef[[2]], 3)),
          ifelse(abs(round(
            fit$coef[[2]], 3
          )) >= 2, " units", " unit"),
          "."
        )
      )
    } else {
      withMathJax(
        paste0(
          "(Make sure the assumptions for linear regression (independance, linearity, normality and homoscedasticity) are met before interpreting the coefficients.)"
        ),
        br(),
        paste0(
          "\\( \\beta_0 \\)",
          " and ",
          "\\( \\beta_1 \\)",
          " are not significantly different from 0 (p-values = ",
          round(summary(fit)$coefficients[1, 4], 3),
          " and ",
          round(summary(fit)$coefficients[2, 4], 3),
          ", respectively) so the mean of ",
          input$ylab,
          " is not significantly different from 0."
        )
      )
    }
  })
  
  output$plot <- renderPlotly({
    y <- extract(input$y)
    x <- extract(input$x)
    fit <- lm(y ~ x)
    dat <- data.frame(x, y)
    p <- ggplot(dat, aes(x = x, y = y)) +
      geom_point() +
      stat_smooth(method = "lm", se = input$se) +
      ylab(input$ylab) +
      xlab(input$xlab) +
      theme_minimal()
    ggplotly(p)
  })
  
  # output$downloadReport <- downloadHandler(
  #   filename = function() {
  #     paste("my-report", sep = ".", switch(
  #       input$format,
  #       PDF = "pdf",
  #       HTML = "html",
  #       Word = "docx"
  #     ))
  #   },
  #   
  #   content = function(file) {
  #     src <- normalizePath("report.Rmd")
  #     
  #     # temporarily switch to the temp dir, in case you do not have write
  #     # permission to the current working directory
  #     owd <- setwd(tempdir())
  #     on.exit(setwd(owd))
  #     file.copy(src, "report.Rmd", overwrite = TRUE)
  #     
  #     library(rmarkdown)
  #     out <- render("report.Rmd", switch(
  #       input$format,
  #       PDF = pdf_document(),
  #       HTML = html_document(),
  #       Word = word_document()
  #     ))
  #     file.rename(out, file)
  #   }
  # )
  
  
  # Correlation Tab ----
  # 
  
  output$corrplot <- renderPlotly({
    
    g <- DataExplorer::plot_correlation(rv$data_set)
    
    plotly::ggplotly(g)
  })
  
  
  observeEvent(input$tabs,if(input$tabs ==input$tab_data_overview){
    callModule(module = esquisserServer, id = "esquisse",data = rv$data_set)
  })
  
  
}
