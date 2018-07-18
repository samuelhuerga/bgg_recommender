# Recommender system for boardgames

A web app for recommending new boardgames that you might like. 

https://samuelhuerga.shinyapps.io/bgg_recommender/

Regarding technical details, this project tries to show knowledge in three different fields:
1. Massive **data download through API** and webscraping
2. **Recommender models** such as Collaborative Filtering and Asociation Rules
3. **Shiny** web application to present results to the final user

## How to use it

Select the games you like from your collection. You can look for them by typing a few letters of its name:


Score them asigning them hearts and click on _Add to collection_ button to stage changes:


Recommendations for your collection will be shown on your right pane:


You can view specific details of recommended games in boardgamegeek by clicking _View in BGG_:


## Technical details

### 1. Data source: boardgamegeek
All data have been downloaded from www.boardgamegeek.com, which is the most popular repository for boardgames information with lots of games and users. 

Data have been extracted on March 2018, and so new games from that date may not appear.

#### boardgamegeek API

Data have been collected by using boardgamegeek API (https://boardgamegeek.com/wiki/page/BGG_XML_API2).
Main problems encountered were:
* Limitation on number on requests per second, so sleep time when downloading data was needed.
* Amount of information on users rating top ranked games. Some of top games had thousands of different ratings and API only allows to download 100 ratings at a time.
* Encoding of different game names. Non English accents and characters were handled properly when saving this information, but querying them through API in R was very tricky

All data was downloaded, but it is not uploaded to github. You can check `scrape_data.R` file to see how the process was.

#### Web scraping

In order to get most popular games, web scraping was used on hot list (http://www.boardgamegeek.com/browse/boardgame/page/1), as the API didn't handle this information.

Only first 1000 games were taken into consideration to build the recommender system.


### 2. Recommender models

#### Item Based Collaborative Filtering (IBCF)

With _Recommenderlab_ package, an IBCF was built handling only top 1000 games and user ratings. About 200K users were used to build this recommender. 

You can see full details in `collaborative_filter.R`

#### Asociation rules

In cases where there are not enough recommendations to provide to the user, asociation rules have been analized, by studing only those ratings which are good, and providing insights like _Other users who liked the games in your collection, also liked..._

You can see full details in `asoc_rules.R`

By merging these two techniques, we provide a powerful recommender system.


### 3. Shiny App

In order to handle the recommendations to a final user, a web application was built using _Shiny_ and _shinydashboard_ packages.

This projects outstands in two ways of customization:

1. valueBox were modified in order to get custom images as icons. This was extracted from https://gist.github.com/hrbrmstr/605e62c5bf6deadf304d80cf4b1f0239

2. In selectizeInput box, thumbnail of game image were shown next to title game

The rest is a common shinydashboard application, with no particularities. You can see the code in `global.R`, `server.R` and `ui.R`.





<div itemscope itemtype="https://schema.org/Person"><a itemprop="sameAs" content="https://orcid.org/0000-0001-6149-4639" href="https://orcid.org/0000-0001-6149-4639" target="orcid.widget" rel="noopener noreferrer" style="vertical-align:top;"><img src="https://orcid.org/sites/default/files/images/orcid_16x16.png" style="width:1em;margin-right:.5em;" alt="ORCID iD icon">orcid.org/0000-0001-6149-4639</a></div>

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Licencia de Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />Este obra está bajo una <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">licencia de Creative Commons Reconocimiento-NoComercial-CompartirIgual 4.0 Internacional</a>.

