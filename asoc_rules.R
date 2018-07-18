
# Asociation Rules ----------
#____________________________

library(tidyverse)
library(arules)

game_ratings_df_n <- read_csv("tables/game_ratings_df_n.csv")


transactions <- game_ratings_df_n %>% 
  filter(rating >5) %>% 
  group_by(user_id) %>%
  summarise(games = list(game_matrix_id)) %>% 
  pull(games)

transactions_ar <- as(transactions, "transactions")
gc() %>% invisible()

#' Solo el 1% es el evento que nos interesa

rules <- apriori(transactions_ar,
                  # appearance =  list(default="lhs",rhs=quiero),
                  # parameter = list(supp = 0.001, conf = 0.1)
                  parameter = list(supp = 0.005,conf = 0.2)
)

rules_df <- inspect(rules)

names(rules_df)[2] <- "impl"
rules_df <- rules_df %>% 
  tbl_df %>% 
  mutate_at(c("lhs","rhs"),as.character) %>% 
  select(-impl)

rules_df <-
  rules_df %>% arrange(lhs,-lift) %>% mutate(rhs = rhs %>% str_replace_all("[\\{\\}]","") %>% as.numeric)

rules_df %>% 
  saveRDS(file = "models/arules.RDS")

# rules_df %>% 
rules_df %>% 
  arrange(lhs,-confidence) %>% 
  # filter(lhs %>% str_detect(","))
  filter(lhs == "{228,900}")

recommend_rules <- function(elements){
rules_df %>% 
  filter(lhs == paste0("{",str_c(elements,collapse = ","),"}"))
}

recommend_rules(c(228,900))

recommend_all_rules <- function(elements){
  elements <- sort(elements)
  
  if(length(elements) < 2){
    elements_2 <- NULL
    elements_3 <- NULL
  } else if(length(elements) <3){
    elements_2 <-  combn(elements,2,list)
  } else {
    elements_2 <-  combn(elements,2,list)
    elements_3 <-  combn(elements,3,list)
    
  }
  
  
  lhs_df <- data_frame(lhs = c(elements, combn(elements,2,list) ,combn(elements,3,list)))
  
  lhs_df %>% 
    mutate(rhs = map(lhs,recommend_rules)) %>% 
    select(-lhs) %>% 
    unnest %>% 
    filter(!(rhs %in% elements)) %>% 
    arrange(-confidence) %>% 
    select(rhs) %>% 
    distinct() %>% 
    slice(1:9) %>% 
    pull
}
