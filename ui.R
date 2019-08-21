
shinyUI(dashboardPage(
  dashboardHeader(title = "BGG Recommender"),
  dashboardSidebar(HTML('Samuel Huerga <a itemprop="sameAs" href="https://orcid.org/0000-0001-6149-4639" target="orcid.widget" rel="noopener noreferrer" style="vertical-align:top;"><img src="https://orcid.org/sites/default/files/images/orcid_16x16.png" style="width:1em;margin-right:.5em;" alt="ORCID iD icon"></a></br>'),
                   HTML('<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Licencia de Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />'),
                   collapsed = T),
  dashboardBody(
    sidebarLayout(
      sidebarPanel(
        includeCSS("www/icons.css"),
    selectizeInput('game_id', 'Select games',
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
    
    ratingInput("rating", label="Rate chosen games selecting stars: ", 
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
