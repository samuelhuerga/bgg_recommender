
shinyUI(dashboardPage(
  dashboardHeader(title = "BGG Recommender"),
  dashboardSidebar(collapsed = T),
  dashboardBody(
    sidebarLayout(
      sidebarPanel(
        includeCSS("www/icons.css"),
    selectizeInput('game_id', 'Games',
                   choices = setNames(games_id_n %>% 
                                        arrange(game_matrix_id)%>% 
                                        pull(game_id) ,
                                      games_id_n %>% 
                                        arrange(game_matrix_id) %>% 
                                        pull(title)),
                   multiple = T,
                   options = list(
                     placeholder = 'Look for a game',
                     valueField = 'game_id',
                     labelField = 'title',
                     searchField = 'title',
                     options = list(),
                     render = I("{
                 option: function(item, escape) {
                 return '<div>' +
                 '<strong><img src=\"images_thmb/' + escape(item.game_id) + '.jpg\" width=100 />  ' + escape(item.title) + '</strong></div>'
;
                 }
                 }")
                     
                   ))
    ,
    
    ratingInput("rating", label="Rating: ", 
                # class = "symbol",
                dataFilled = "glyphicon glyphicon-heart",
                dataEmpty = "glyphicon glyphicon-heart-empty",
                dataStop=5, 
                dataFractions=2,
                includeBootstrapCSS = T),
    br(),
    actionButton("add_to_collection","Add to collection",icon = icon("plus")),
    br(),
    uiOutput("ui_collection")
    ),
    mainPanel(
      h2("Recommendations"), 
      h5("based on your collection"),
      uiOutput("recommendations_valuebox")
      ))
  )
)
)
