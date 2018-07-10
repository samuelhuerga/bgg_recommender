library(tidyverse)
library(janitor)
library(rvest)
library(fs)

game_html <- read_html("https://boardgamegeek.com/boardgame/205896/rising-sun/ratings")
game_html <- read_html("https://boardgamegeek.com/boardgame/205896/rising-sun")
game_html <- read_html("https://www.boardgamegeek.com/xmlapi2/boardgame?id=rising-su")


xml <- read_xml("https://www.boardgamegeek.com/xmlapi2/thing?id=205896&ratingcomments=1&pagesize=100")

xml %>% xml_nodes("comment") %>% xml_attrs()
xml %>% 
  xml_nodes("comments") %>% 
  xml_attrs() %>% 
  .[[1]] %>% 
  .[["totalitems"]]

xml %>% xml_find_all("comment")

# 1) Download game table -----------

games <- NULL
for(page in 1:100){
  Sys.sleep(0.5)
  print(page)
  game_html <- read_html(paste0("https://www.boardgamegeek.com/browse/boardgame/page/",page))
  games <- game_html %>%
    html_node("#collectionitems") %>% 
    html_table() %>% 
    clean_names %>% 
    as_data_frame %>% 
    select(-x, -shop) %>% 
    separate(title,c("title","year"),sep = "\n\t\t\t\t\n\t\t\t\t\t\t\t") %>% 
    mutate(year = str_replace(year,"^\\((.*)\\)$","\\1") %>% as.numeric) %>% 
    bind_rows(games,.)
}

dir_create("tables")
write_csv(games,"tables/games.csv")

# 2) Download game info -----------
dir_create("raw_data")
dir_create("raw_data/games_id")

games_id <- NULL
for(title in (games %>% pull(title))[6265:10000]){
  Sys.sleep(2)
  print(paste0(Sys.time(),": ",title))
  xml <- read_xml(paste0("https://www.boardgamegeek.com/xmlapi2/search?query=",
                         # RCurl::curlEscape(str_replace_all(title," ","%20")),
                         RCurl::curlEscape(title),
                         "&type=boardgame&exact=1"))
  
  xml %>%as.character() %>% write_file(paste0("raw_data/games_id/",str_replace_all(title,"[:\\/\\?\\¿\\!\\*\\\"]",""),".xml"))
  
  games_id <- data_frame(title = title,
                         game_id= xml %>% 
                           xml_node("item") %>% 
                           xml_attr("id")) %>% 
    bind_rows(games_id,.)
}

games_id %>% 
  filter(!is.na(game_id)) %>% 
  bind_rows(
    data_frame(title=c("Ca$h 'n Guns (Second Edition)","Ca$h 'n Gun$"), game_id =c("155362","19237"))
) %>% 
  mutate(game_id = as.numeric(game_id))


write_csv(games_id,"tables/games_id.csv")


# 2) Download game info -----------
dir_create("raw_data")
dir_create("raw_data/games_info")

games_info <- NULL

for(i in 4743:nrow(games_id)){
  Sys.sleep(2)
  title <- games_id %>% slice(i) %>% pull(title)
  game_id <- games_id %>% slice(i) %>% pull(game_id)
  print(paste0(Sys.time(),": ",title))
  
  xml <- read_xml(paste0("https://www.boardgamegeek.com/xmlapi2/thing?id=",
                         # RCurl::curlEscape(str_replace_all(title," ","%20")),
                         game_id,
                         "&ratingcomments=1&pagesize=100"))
  
  xml %>%as.character() %>% write_file(paste0("raw_data/games_info/",str_replace_all(title,"[:\\/\\?\\¿\\!\\*\\\"]",""),".xml"))
  
  # games_id <- data_frame(title = title,
  #                        game_id= xml %>% 
  #                          xml_node("item") %>% 
  #                          xml_attr("id")) %>% 
  #   bind_rows(games_id,.)
}

# 3) Download game image -----------
#___________________________________

games_images <- NULL
for(dir_xml_game in Sys.glob("raw_data/games_info/*.xml")){
  tryCatch({
    print(dir_xml_game)
    xml_game <- read_xml(dir_xml_game)
    game_id_i <-  xml_game %>% xml_node("item") %>%  xml_attr("id")
    image_i <- xml_game %>% xml_node("image") %>% xml_contents() %>% xml_text()
    
    games_images <- games_images %>% 
      bind_rows(
        data_frame(game_id = game_id_i,
                   image_url = image_i)
      )},error = function(e){})
}
    
dir_create("images")
map2(games_images %>% pull(image_url),
     games_images %>% pull(game_id),
     ~download.file(.x,paste0("images/",.y,.x %>% str_extract("\\.\\w+$")),mode = 'wb'))

dir_create("images_resized")
dir_create("images_thmb")
library(magick)

walk(Sys.glob("images/*")[713:5950],
     ~tryCatch(.x %>% image_read() %>% image_resize("x1000") %>% image_write(.x %>% str_replace("images","images_resized"),format = "jpg"),
     error=function(e){}))

walk(Sys.glob("images_resized/*"),
     ~tryCatch(.x %>% image_read() %>% image_resize("x200") %>% image_write(.x %>% str_replace("images_resized","images_thmb"),format = "jpg"),
     error=function(e){}))


# 4) Download game ratings -------
# ________________________________

games_id <- games_id %>% group_by(game_id) %>% summarise(title = first(title)) %>% ungroup()
games_id %>% count(game_id) %>% filter(n> 1)

dir_create("raw_data/games_ratings/")
file_create("raw_data/game_ratings_log.txt")

for(dir_xml_game in Sys.glob("raw_data/games_info/*.xml")[4139:6247]){
  tryCatch({
    xml_game <- read_xml(dir_xml_game)
    game_id_i <-  xml_game %>% xml_node("item") %>%  xml_attr("id")
    title <-  games_id %>% filter(game_id == as.numeric(game_id_i)) %>% pull(title)
    nitems <- xml_game %>% xml_child %>% xml_nodes("comments") %>% xml_attr("totalitems") %>% as.numeric
    pages <- floor(nitems/100) + 1
    print(paste0(Sys.time(),": ", dir_xml_game," PAGES: ",pages))
    
    if(length(pages) > 0){
      for (page in 1:pages){
        Sys.sleep(2)
        print(paste0(Sys.time(),": ",page))
        
        tryCatch({
          xml <- read_xml(paste0("https://www.boardgamegeek.com/xmlapi2/thing?id=",
                                 game_id_i,
                                 "&ratingcomments=1&pagesize=100&page=",
                                 page))},
          error = function(e){
            err <- paste0(Sys.time(),": ",title, ", PAGE ",page,"|",e)
            write_lines(err,"raw_data/game_ratings_log.txt",append = T)
          })
        
        xml %>%as.character() %>% write_file(paste0("raw_data/games_ratings/",str_replace_all(title,"[:\\/\\?\\¿\\!\\*\\\"]","")," (",page," of ",pages,").xml"))
        
      }}},
    error = function(e){
      err <- paste0(Sys.time(),": ",title,"|",e)
      write_lines(err,"raw_data/game_ratings_log.txt",append = T)
    })
}

game_ratings <- Sys.glob("raw_data/games_ratings/*.xml") %>% 
  map(read_xml) %>% 
  map(function(xml){

data_frame(id = xml %>% xml_node("item") %>%  xml_attr("id"),
           username = xml %>% xml_child %>% xml_nodes("comments") %>% xml_children() %>% xml_attr("username"),
           rating = xml %>% xml_child %>% xml_nodes("comments") %>% xml_children() %>% xml_attr("rating"),
           value = xml %>% xml_child %>% xml_nodes("comments") %>% xml_children() %>% xml_attr("value"))
})
Sys.time()

# save(game_ratings,file = "data/game_ratings.Rdata")
game_ratings_df <- game_ratings %>% reduce(bind_rows)
Sys.time()

# save(game_ratings_df,file = "game_ratings_df.Rdata")
load("game_ratings_df.Rdata")

game_ratings_df <- game_ratings_df %>% 
  select(-value) %>% 
  distinct %>% 
  mutate(rating = as.numeric(rating),
         id = as.integer(id)) %>% 
  rename(game_id = id)


game_ratings_df <- game_ratings_df %>% 
  group_by(id, username) %>% 
  summarise(rating = mean(rating)) %>% 
  ungroup




# Create a new table with users_id:

users_id <- game_ratings_df %>% 
  distinct(username) %>% 
  mutate(user_id = row_number()) %>% 
  select(user_id,username)

# For games reeditions, we consider only the highest ranked:
games <- games %>% group_by(title) %>% filter(row_number() == 1) %>% ungroup
games_id <- games_id %>% group_by(title) %>% filter(row_number() == 1) %>% ungroup

# Save tables into data to pass to shiny app:
# save(game_ratings_df, games_id,users_id,games,file = "data/data_v2.Rdata")
