
library(shiny)
library(shinydashboard)
library(tidyverse)
library(recommenderlab)
# devtools::install_github("stefanwilhelm/ShinyRatingInput")
library(ShinyRatingInput)

# load("data/data_v2.Rdata")
load("models/ibcf.RData")
rules_df <- readRDS("models/arules.RDS")
games_id_n <- read_csv("tables/games_id_n.csv")
source("override_valuebox.R")

# Function to recommend IBCF
recommend_ibcf <- function(table_preferences, n = 1000) {
  
  table_preferences <- table_preferences %>% bind_rows(data_frame(game_id = 882,game_rating=0))
  
  game_ratings_sparse_matrix_user <- Matrix::sparseMatrix(rep(1,nrow(table_preferences)),
                                                          table_preferences %>% pull(game_id),
                                                          x = table_preferences %>% pull(game_rating),
                                                          dims = c(1,n))
  game_ratings_matrix_user <- new("realRatingMatrix",data= game_ratings_sparse_matrix_user)
  colnames(game_ratings_matrix_user) <-  games_id_n %>% pull(game_matrix_id)
  
  
  predictions <- recommenderlab::predict(rec_fit,game_ratings_matrix_user,n=9)
  predictions %>% as("list") %>% .[[1]]
  
}

# Function to recommend arules
recommend_all_rules <- function(elements,n_output = 9, ignore_recommendations = c()){
  elements <- sort(elements)
  
  if(length(elements) < 2){
    elements_2 <- NULL
    elements_3 <- NULL
  } else if(length(elements) <3){
    elements_2 <-  combn(elements,2,list)
    elements_3 <- NULL
  } else {
    elements_2 <-  combn(elements,2,list)
    elements_3 <-  combn(elements,3,list)
    
  }
  
  
  lhs_df <- data_frame(lhs = c(elements, elements_2,elements_3))
  
  lhs_df %>% 
    mutate(rhs = map(lhs,recommend_rules)) %>% 
    select(-lhs) %>% 
    unnest %>% 
    filter(!(rhs %in% elements)) %>% 
    arrange(-confidence) %>% 
    select(rhs) %>% 
    distinct() %>% 
    filter(!(rhs %in% ignore_recommendations)) %>% 
    slice(1:n_output) %>% 
    pull
}
