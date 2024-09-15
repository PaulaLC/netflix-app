library(shiny)
library(glue)
library(bslib)
library(dplyr)
library(recommenderlab)
library(shinyRatings)

source("R/utils.R")

# Load MovieLense dataset from recommenderlab
data("MovieLense")

# Reduce MovieLense dataset to 67 movies and 100 users
MovieLenseSmall <- MovieLense[1:100, colCounts(MovieLense) > 250]

# Get movie title, img_url and youtube_id
df_movies <- read.csv("data/movies.csv")

ui <- shiny::fluidPage(
  shinyjs::useShinyjs(),
  # Load
  includeCSS("custom.css"),
  tags$head(tags$script(src = "custom.js")),
  
  theme = bslib::bs_theme(
    version = 5,
    # Boostrap 5
    bg = "#000000",
    # Dark bg
    fg = "#FFFFFF",
    primary = "#b4131d",
    # Primary Color
  ),
  
  navbarPage(
    img(id = "logo", src = 'logo.png'),
    # Retro Netflix Logo
    windowTitle = "Netflix",
    tabPanel(
      "Home",
      # Home Panel
      
      # Section to ask user for their name
      shiny::div(
        id = "input_name",
        class = "text-center mb-3",
        shiny::textInput(
          "user_name",
          "Who's watching?",
          value = "",
          placeholder = "Enter your name"
        ),
        shiny::actionButton("start_ratings", "Start")
      ),
      
      # Recommendations UI
      uiOutput("ubcf_recommendations"),
      uiOutput("ibcf_recommendations"),
      uiOutput("popular_recommendations"),
      uiOutput("random_recommendations")
    ),
    
    tabPanel("How It Works",
             sidebarLayout(
               sidebarPanel(
                 class = "left-col",
                 h1("How We Recommend Movies"),
                 p(
                   "Discover how our movie recommendation system works using algorithms to tailor movie suggestions based on your viewing history, preferences, and movie popularity."
                 )
               ),
               
               mainPanel(
                 # User Based Recommendations Card
                 card(
                   card_header(tags$span(icon("users", class = "icon")), "Because others like you enjoyed it"),
                   card_body(
                     p(tags$strong(
                       "User-Based Collaborative Filtering (UBCF)"
                     )),
                     p(
                       "This algorithm analyzes your viewing habits and compares them to others with similar tastes. If users with similar preferences liked a movie, you're likely to enjoy it as well. We recommend based on shared ratings with people like you."
                     ),
                     p(
                       "Example: If you and others liked The Usual Suspects and Apollo 13 we might recommend The Shawshank Redemption because users with similar tastes also enjoyed it."
                     )
                   ),
                 ),
                 # Item Based Recommendations Card
                 card(
                   card_header(tags$span(icon("film", class = "icon")), "Because you watched similar movies"),
                   card_body(
                     p(tags$strong(
                       "Item-Based Collaborative Filtering (IBCF)"
                     )),
                     p(
                       "Instead of looking at other users, this algorithm recommends movies based on the ones you’ve already watched. It looks for similarities in genre, actors, or themes, suggesting movies with a high similarity score to those you’ve enjoyed."
                     ),
                     p(
                       "Example: If you liked ",
                       strong("Jurassic Park"),
                       ", we might recommend ",
                       strong("Blade Runner"),
                       " or ",
                       strong("Indiana Jones"),
                       " because of their shared adventure elements."
                     )
                   ),
                 ),
                 # Popular Recommendations Card
                 card(
                   card_header(tags$span(icon("star", class = "icon")), "Most popular movies"),
                   card_body(
                     p(tags$strong("Popularity-Based Recommendation")),
                     p(
                       "This algorithm suggests movies that are currently popular or trending. These recommendations are based on what the majority of viewers are watching and enjoying right now."
                     ),
                     p(
                       "Example: Movies like ",
                       strong("Titanic"),
                       " or ",
                       strong("Star Wars"),
                       " are recommended because they have been watched and loved by many viewers."
                     )
                   ),
                 ),
                 # Random Recommendations Card
                 card(
                   card_header(tags$span(icon("random", class = "icon")), "Discover other movies"),
                   card_body(
                     p(tags$strong("Random Recommendations")),
                     p(
                       "To help you explore new content, we sometimes suggest random movies that you may not have come across. This adds an element of surprise, encouraging you to try something different."
                     ),
                     p(
                       "Example: You might be recommended a film like ",
                       strong("Broken Arrow"),
                       " or ",
                       strong("Mr. Holland's Opus"),
                       " even if they don’t match your typical viewing habits. This gives you a chance to discover hidden gems."
                     )
                   ),
                 )
               )
             )),
    tabPanel("Search",
             sidebarLayout(
               # Search a movie form
               sidebarPanel(textInput("search", "Search for a Movie", value = "")),
               mainPanel(# Dynamic UI output for the movie results
                 uiOutput("movie_results"))
             ))
  ),
  
  # Action button in the top to continue rating
  shiny::actionButton("more_ratings", "Rate More!", class = "d-none")
)

server <- function(input, output, session) {
  ### Intro
  # Show the GIF modal when the app starts
  observe({
    showModal(
      modalDialog(
        id = "intro",
        easyClose = FALSE,
        fade = TRUE,
        size = "xl",
        
        # Netflix Intro GIF image
        shiny::tags$img(src = "intro.gif",
                        style = "width: 100%; height: 100%;"),
        
        # No footer, modal closes automatically
        footer = NULL
      )
    )
    
    # Automatically close the modal after a GIF duration
    session$sendCustomMessage(type = 'close-modal', message = list(delay = 3000))
  })
  
  ### Ratings
  # Initialize with all movies set to NA
  user_ratings <- reactiveValues(data = {
    all_movies <- df_movies$title
    data.frame(
      movie = all_movies,
      rating = rep(NA, length(all_movies)),
      stringsAsFactors = FALSE
    )
  },
  
  # Store unrated movies
  unrated_movies = df_movies$title)
  
  # Reactive to store the current movie
  current_movie <- reactiveVal(NULL)
  
  # Function to update the movie content in the modal
  update_movie_modal <- function() {
    # Check if there are any unrated movies left
    if (length(user_ratings$unrated_movies) > 0) {
      # Select a random movie from unrated movies
      random_movie <- sample(user_ratings$unrated_movies, 1)
      current_movie(random_movie)  # Update the current movie being rated
      
      movie_img <-
        df_movies[df_movies$title == random_movie, "img_url"]
      
      output$movie_img <- renderUI({
        shiny::img(src = movie_img, height = "400px")  # Render new movie image
      })
    } else {
      # If all movies are rated, show a message in the modal
      output$movie_img <- renderUI({
        shiny::h2("You've done! 🎉 All movies have been rated!")
      })
      
      # Remove all elements from modal
      shinyjs::addClass(selector = "#title-rate", class = "d-none")
      shinyjs::addClass(selector = "#subtitle-rate", class = "d-none")
      shinyjs::addClass(selector = "#submit_rating", class = "d-none")
      shinyjs::addClass(selector = "#next_movie", class = "d-none")
      shinyjs::addClass(selector = "#rate", class = "d-none")
      shinyjs::addClass(selector = "#rating_feedback", class = "d-none")
      
    }
  }
  
  # Open the modal and start showing movies
  observeEvent(ignoreInit = TRUE,
               list(input$start_ratings, input$more_ratings),
               {
                 # Show the modal dialog
                 showModal(
                   modalDialog(
                     id = "rating_modal",
                     class = "text-center",
                     shiny::h2(
                       id = "title-rate",
                       glue("Hi {input$user_name}! Rate the Movie You've Watched!")
                     ),
                     shiny::h3(id = "subtitle-rate", "If you haven´t seen the movie, click next!"),
                     
                     # Render Movie Image
                     uiOutput("movie_img"),
                     
                     # Rate movie
                     shinyRatings("rate", no_of_stars = 5, default = 1),
                     
                     # Buttons to submit rating or finish
                     shiny::actionButton("next_movie", "Next Movie"),
                     shiny::actionButton("submit_rating", "Submit Rating"),
                     shiny::actionButton("done_rating", "Done!"),
                     shiny::textOutput("rating_feedback"),
                     
                     footer = NULL,
                     # Remove default footer
                     easyClose = FALSE  # Prevent the modal from closing until the user finishes
                   )
                 )
                 
                 # Show the first movie in the modal
                 update_movie_modal()
                 
               })
  
  # When the user submits a rating
  observeEvent(input$submit_rating, {
    # Get the current movie being rated
    movie <- current_movie()
    
    # Get the rating from the starts rating
    rating <- input$rate
    
    # Update the user ratings dataframe
    user_ratings$data$rating[user_ratings$data$movie == movie] <-
      rating
    
    # Remove the rated movie from the unrated_movies list
    user_ratings$unrated_movies <-
      user_ratings$unrated_movies[user_ratings$unrated_movies != movie]
    
    # Update the movie content in the modal without closing it
    update_movie_modal()
    
    # Return rating feedback
    output$rating_feedback <- renderText({
      glue::glue("You rated {movie} a {rating} out of 5!")
    })
    
  })
  
  observeEvent(input$next_movie, {
    # Update the movie content in the modal without closing it
    update_movie_modal()
    
  })
  
  ### Build Recommendations
  # Run recommendations after user ends the rating process
  observeEvent(input$done_rating, {
    if (sum(!is.na(user_ratings$data$rating)) == 0) {
      showModal(
        modalDialog(
          class = "text-center",
          shiny::h2("You didn´t rate any movie!"),
          shiny::h3("Start rating to discover your recommendations."),
          footer = modalButton(label = "Close"),
        )
      )
      
    } else {
      # Convert user ratings into a realRatingMatrix
      user_rating_vector <- user_ratings$data$rating
      names(user_rating_vector) <- user_ratings$data$movie
      
      # Convert the user rating vector into a matrix
      user_matrix <- t(as(user_rating_vector, "matrix"))
      user_ratings_matrix <- as(user_matrix, "realRatingMatrix")
      
      # Generate updated recommendations based on the user input
      df_ubcf <-
        recommend_movie(MovieLenseSmall,
                        user_ratings_matrix,
                        "UBCF",
                        list(nn = 3),
                        NULL)
      df_ibcf <-
        recommend_movie(MovieLenseSmall,
                        user_ratings_matrix,
                        "IBCF",
                        list(k = 100),
                        df_ubcf$item)
      df_popular <-
        recommend_movie(
          MovieLenseSmall,
          user_ratings_matrix,
          "POPULAR",
          NULL,
          c(df_ubcf$item, df_ibcf$item)
        )
      df_random <-
        recommend_movie(
          MovieLenseSmall,
          
          user_ratings_matrix,
          "RANDOM",
          NULL,
          c(df_ubcf$item, df_ibcf$item, df_popular$item)
        )
      
      # Update the recommendation UI with new ratings
      if (nrow(df_ubcf) > 0) {
        output$ubcf_recommendations <-
          renderUI({
            gen_reco_card(df_ubcf, "ubcf")
          })
      }
      
      if (nrow(df_ibcf) > 0) {
        output$ibcf_recommendations <-
          renderUI({
            gen_reco_card(df_ibcf, "ibcf")
          })
      }
      
      if (nrow(df_ibcf) > 0) {
        output$popular_recommendations <-
          renderUI({
            gen_reco_card(df_popular, "popular")
          })
      }
      
      if (nrow(df_ibcf) > 0) {
        output$random_recommendations <-
          renderUI({
            gen_reco_card(df_random, "random")
          })
      }
      
      # Hide the input_name div after first submission and rate button
      shinyjs::addClass(selector = "#input_name", class = "d-none")
      shinyjs::removeClass(selector = "#more_ratings", class = "d-none")
      
      # Remove Rating Modal
      removeModal()
      
    }
  })
  
  ### Youtube Action
  # Observe all button clicks for trailer buttons
  observe({
    lapply(df_movies$youtube_id, function(youtube_id) {
      observeEvent(input[[glue("show_trailer_{youtube_id}")]], {
        showModal(
          modalDialog(
            id = "youtube_trailer",
            size = c("xl"),
            shiny::tags$iframe(
              src = glue("https://www.youtube.com/embed/{youtube_id}"),
              frameborder = "0",
              allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
              allowfullscreen = TRUE,
              width = "100%",
              height = "600px"
            ),
            footer = modalButton(label = "Close"),
            easyClose = TRUE
          )
        )
      })
    })
  })
  
  ### Search Panel
  # Reactive expression to filter movies based on search input
  filtered_movies <- reactive({
    search_term <-
      tolower(input$search)  # Convert input to lowercase for case-insensitive search
    df_movies[grepl(search_term, tolower(df_movies$title)), ]  # Filter movies
  })
  
  # Render the movie results dynamically using Bootstrap grid classes
  output$movie_results <- renderUI({
    movies <- filtered_movies()
    
    if (nrow(movies) == 0) {
      return(tags$p("No movies found matching the search input."))
    }
    
    # Create UI elements to display movie images in a responsive Bootstrap grid
    movie_ui <- lapply(1:nrow(movies), function(i) {
      tags$div(class = "col-6 col-md-3 mb-4",
               # Bootstrap grid: 2 columns on small screens, 4 columns on medium+
               tags$a(
                 href = paste0(
                   "https://www.youtube.com/results?search_query=",
                   URLencode(movies$title[i])
                 ),
                 target = "_blank",
                 tags$img(src = movies$img_url[i], class = "img-fluid rounded shadow")
               ))
    })
    
    # Wrap the movie images in a Bootstrap row
    tags$div(class = "row", movie_ui)
  })
}

shinyApp(ui, server)
