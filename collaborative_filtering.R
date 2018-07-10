library(recommenderlab)
library(Matrix)

# Prepare data for models
games <- read_csv("tables/games.csv")
games_id <- read_csv("tables/games_id.csv")

# For games reeditions, we consider only the highest ranked:
games <- games %>% group_by(title) %>% filter(row_number() == 1) %>% ungroup
games_id <- games_id %>% group_by(title) %>% filter(row_number() == 1) %>% ungroup

games_id <- games_id %>%
  mutate(game_id = as.integer(game_id)) %>% 
  left_join(games %>% select(title, board_game_rank)) %>% 
  mutate(game_matrix_id = rank(board_game_rank)) %>% 
  arrange(game_matrix_id)

game_ratings_df <- game_ratings_df %>% 
  left_join(users_id) %>% 
  left_join(games_id %>% select(game_id,game_matrix_id))


# We only consider first n games

n <- 1000
games_id_n <- games_id %>% filter(game_matrix_id <= n) %>% arrange(game_matrix_id)
game_ratings_df_n <- game_ratings_df %>% filter(game_matrix_id <= n)
users_id_n <- users_id %>% semi_join(game_ratings_df_n %>% select(user_id))

write_csv(games_id_n,"tables/games_id_n.csv")

# game_ids <- games_id_n %>% pull(game_matrix_id)

# UBCF train model----------
#___________________________

game_ratings_sparse_matrix <- Matrix::sparseMatrix(game_ratings_df_n %>% pull(user_id),
                                                   game_ratings_df_n %>% pull(game_id),
                                                   x = game_ratings_df_n %>% pull(rating))

game_ratings_matrix <- new("realRatingMatrix",data= game_ratings_sparse_matrix)
# game_ratings_matrix[2]

# colnames(game_ratings_matrix) <-  games_id_n %>% pull(title)
colnames(game_ratings_matrix) <-  games_id_n %>% pull(game_matrix_id)
game_ratings_df %>% filter(user_id == 2)

rec_fit <- Recommender(game_ratings_matrix[3:100000], method = "IBCF")

dir_create("models")
save(rec_fit, file="models/ibcf.RData")


# Function to recommend

recommend_ibcf <- function(table_preferences, n = n) {
  
  game_ratings_sparse_matrix_user <- Matrix::sparseMatrix(rep(1,length(table_preferences)),
                                                          table_preferences %>% pull(game_matrix_id),
                                                          x = table_preferences %>% pull(game_rating),
                                                          dims = c(1,n))
  game_ratings_matrix_user <- new("realRatingMatrix",data= game_ratings_sparse_matrix_user)
  colnames(game_ratings_matrix_user) <-  games_id_n %>% pull(game_matrix_id)
  
  
  predictions <- recommenderlab::predict(rec_fit,game_ratings_matrix_user,n=10)
  predictions %>% as("list") %>% .[[1]]
  
}

# We study distribution on number of recomendations

# game_ratings_df %>% count(user_id) %>% filter(n<200) %>% ggplot(aes(x=n)) +geom_histogram(binwidth = 1)
