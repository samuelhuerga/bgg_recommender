shinyServer(function(input, output,session) {
  
  rv <- reactiveValues()
  output$ui_collection <- renderUI({
    req(rv$collection)
    
    rv$collection %>% 
      rename(game_matrix_id = game_id) %>% 
      left_join(games_id_n) %>% 
      mutate(img = paste0("<img src=\"images_thmb/", game_id ,".jpg\" width=75 />")) %>% 
      mutate(everything = paste0(img,"  ",title, " (",game_rating,")")) %>% 
      summarise(everything = str_c(everything,collapse = "</br></br>")) %>%
      mutate(everything = paste0("<h4> My collection </h4> </br>",everything)) %>% 
      pull %>% 
      HTML()
  })
  
  
  observeEvent(input$add_to_collection,{
    rv$collection <- bind_rows(isolate(rv$collection),
                               data_frame(game_id = isolate(games_id_n %>% 
                                                              filter(game_id == input$game_id) %>% 
                                                              pull(game_matrix_id)),
                                          game_rating= as.numeric(input$rating)*2))
    updateSelectizeInput(session,"game_id",
                         choices = setNames(games_id_n %>% 
                                              filter(!(game_matrix_id %in% (rv$collection %>% pull(game_id)))) %>% 
                                              arrange(game_matrix_id)%>% 
                                              pull(game_id) ,
                                            games_id_n %>% 
                                              filter(!(game_matrix_id %in% (rv$collection %>% pull(game_id)))) %>% 
                                              arrange(game_matrix_id) %>% 
                                              pull(title)),
                         selected = NULL)
  })
  
  
  output$recommendations_valuebox <- renderUI({
    req(rv$collection)
    
    l <- list()
    
    recommendations <- data_frame(game_matrix_id = recommend_ibcf(rv$collection) %>% as.integer) %>% 
      left_join(games_id_n)
    
    for (i in 1:nrow(recommendations)){
      recommendation_i <-recommendations %>% slice(i)

      l[[i]] <- valueBox(value = recommendation_i$title,
                         subtitle = paste0("<a href = 'https://boardgamegeek.com/boardgame/",recommendation_i$game_id,"'> View in BGG </a>"),
                         # recommendation_i$nombre,
                         icon = icon(list(src=paste0("images_thmb/",recommendation_i$game_id,".jpg"),width="80px"), lib = "local"))
    }
    tagList(l)
  })
  
})

