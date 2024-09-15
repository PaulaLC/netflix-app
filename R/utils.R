# Function to recommend a movie based on a specific algorithm
recommend_movie <- function(MovieLenseSmall, input_ratings, algo, params, movies_to_exclude) {
  Recommender(MovieLenseSmall, algo, params) |>
    predict(input_ratings, type = "ratings") |>
    as("data.frame") |>
    arrange(desc(rating)) |>
    filter(!item %in% movies_to_exclude) |>
    head(10) |>
    mutate(norm_rating = round(normalize_rating(rating), 0))
}

# Function to normalize the rating
normalize_rating <- function(rating) {
  norm_rating <- (rating - 1) / 4 * 100
  ifelse(norm_rating > 100, 100, norm_rating)
}

# Function to generate recommendation cards
gen_reco_card <- function(df_reco, algo) {
  div_title <- switch(
    algo,
    "ubcf" = "Because others like you enjoyed it",
    "ibcf" = "Because you watched similar movies",
    "popular" = "Most popular movies",
    "random" = "Discover other movies"
  )
  
  div_id <- glue("{algo}_recommendations")
  
  reco_cards <- tagList()
  
  for (i in 1:nrow(df_reco)) {
    title <- df_reco$item[i]
    img <- df_movies[df_movies$title == title, "img_url"]
    youtube_id <- df_movies[df_movies$title == title, "youtube_id"]
    norm_rating <- df_reco$norm_rating[i]
    
    reco_cards[[i]] <- movie_card(img = img,
                                  norm_rating = norm_rating,
                                  youtube_id = youtube_id)
  }
  div_reco <-
    shiny::div(
      class = "container px-4 px-lg-5",
      id = div_id,
      shiny::h2(div_title),
      shiny::div(
        class = "container-fluid py-2 overflow-scroll",
        shiny::div(class = "d-flex flex-row flex-nowrap",
                   reco_cards)
      )
    )
  
  return(div_reco)
}

# Movie Card with bsModal for Trailer
movie_card <- function(img, norm_rating, youtube_id) {
  shiny::div(
    class = "card text-center col-md-3 movie-card",
    
    # Movie image
    shiny::img(src = img,
               class = "card-img-top mx-auto"),
    
    shiny::div(
      class = "card-body",
      
      # Recommendation percentage
      shiny::p(class = "card-text", glue::glue(norm_rating, "% recommended for you")),
      
      # "Watch Trailer" Button
      shiny::actionButton(
        glue::glue("show_trailer_{youtube_id}"),
        label = "Watch Trailer",
        class = "btn btn-primary"
      ),
      
    )
  )
}



