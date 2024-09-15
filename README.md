# Netflix Oldies: A Classic Movie Recommendation Shiny App

## Overview

Welcome to **Netflix Oldies**, the app to discover you classic movies based on your preferences throught several recommendation algorithms. Designed in **Shiny**, this app combines user input with  filtering techniques to deliver personalized movie suggestions, offer insights into the recommendation process, and allow you to search for movies. The app is based on a retro style with a subset of classic movies from the popular MovieLense dataset.

## Features

### 1. **Home Panel**
- **User Input**: Enter your name to start the movie rating process.
- **Movie Rating**: Rate movies you have watched. The app will show you a series of movies to rate and collect your preferences.
- **Recommendations**: After rating, the app will provide movie recommendations based on:
  - **User-Based Collaborative Filtering (UBCF)**
  - **Item-Based Collaborative Filtering (IBCF)**
  - **Popularity-Based Recommendations**
  - **Random Recommendations**

### 2. **How It Works Panel**
- **Explanation of Algorithms**: Learn about the different recommendation algorithms used:
  - **User-Based Collaborative Filtering (UBCF)**: Suggests movies based on similar users' preferences.
  - **Item-Based Collaborative Filtering (IBCF)**: Recommends movies similar to those you've already rated.
  - **Popularity-Based Recommendations**: Highlights currently trending movies.
  - **Random Recommendations**: Offers a chance to discover new movies randomly.

### 3. **Search Panel**
- **Search Functionality**: Search for movies by title and view results in a responsive grid layout.
- **Movie Results**: Displays movie images and links to YouTube search results for trailers.

## How to Use

1. **Start by Entering Your Name**: On the Home panel, enter your name and click "Start" to begin rating movies.
2. **Rate Movies**: You will be prompted to rate movies you have watched. Rate each movie from 1 to 5 stars.
3. **Receive Recommendations**: After rating a sufficient number of movies, recommendations will be generated and displayed on the Home panel.
4. **Explore Movie Details**: Use the Search panel to find movies and view them in a grid format. Click on movie images to search for trailers on YouTube.

## Technologies Used

- **Shiny**: R package for building interactive web applications.
- **recommenderlab**: R package for building recommendation systems.
- **shinyRatings**: R package for integrating star rating input into Shiny apps.
- **bslib**: R package for theming with Bootstrap 5.
- **dplyr**: R package for data manipulation.
- **glue**: R package for string interpolation.

## Setup

1. **Install Required Packages**: Ensure you have the necessary R packages installed by running:
   ```r
   install.packages(c("shiny", "glue", "bslib", "dplyr", "recommenderlab", "shinyRatings"))
   ```
2. **Run the App**: Use the following R code to start the Shiny app:
   ```r
   shiny::runApp("path/to/your/app")
   ```

## Contribution

Feel free to fork the repository, make improvements, and create pull requests. We welcome contributions to enhance the functionality and user experience of the app.

---

For any questions or feedback, please [contact](https://x.com/paulalcasado)!

Enjoy discovering your next favorite movie! 🎬🍿
