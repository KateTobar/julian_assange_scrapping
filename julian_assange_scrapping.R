##----------------------------------------------------------------------------##
##  1- install and load                                                       ##
##----------------------------------------------------------------------------##

## install rtweet and tidyverse
## install dplyr as it did not attached properly when loading tidyverse
## install all the needing packages among the process
install.packages("rtweet")
install.packages("tidyverse")
install.packages("dplyr")
install.packages("tidyr")
install.packages("tidytext")
install.packages("stringr")
install.packages("RColorBrewer")
install.packages("igraph")
install.packages("ggraph")
install.packages("ggthemes")
install.packages("extrafont")
install.packages("magick")
install.packages("Cairo")
install.packages("syuzhet")
install.packages("wordcloud")
install.packages("reshape2")
install.packages("proustr")
suppressPackageStartupMessages(library(dplyr))
library(rtweet)
library(tidyverse)
library(dplyr)
library(tidyr)
library(tidytext)
library(stringr)
library(RColorBrewer)
library(igraph)
library(ggraph)
library(ggthemes)
library(extrafont)
library(magick)
library(Cairo)
library(syuzhet)
library(wordcloud)
library(reshape2)
library(proustr)
##----------------------------------------------------------------------------##
##  2- auth vignette & store app_name & keys                                  ##
##----------------------------------------------------------------------------##

## view rtweet's authorization vignette
vignette("auth", package = "rtweet")

## name of twitter app
app_name <- "kate_tobar_twitter_app"
consumer_key <- "Nb4VzR8lq0R3HXssuvaYP70uZ"
consumer_secret <- "oxv1PkpSuJhExg5QLdzZsVb48YrYmvGtOAcO53Q011CfkbuzE6"

##----------------------------------------------------------------------------##
##  3- create_token() & save token                                            ##
##----------------------------------------------------------------------------##

token <- create_token(app_name, consumer_key, consumer_secret)
token

## save token to home directory
path_to_token <- file.path(path.expand("~"), ".twitter_token.rds")
saveRDS(token, path_to_token)

## create env variable TWITTER_PAT (with path to saved token)
env_var <- paste0("TWITTER_PAT=", path_to_token)

## save as .Renviron file (or append if the file already exists)
cat(env_var, file = file.path(path.expand("~"), ".Renviron"),
    fill = TRUE, append = TRUE)

## refresh .Renviron variables
readRenviron("~/.Renviron")

##----------------------------------------------------------------------------##
##  4- get_timeline()                                                         ##
##----------------------------------------------------------------------------##

#Get the last 3200 tweets from @Julian Assange
ja_time_line <- get_timeline("JulianAssange", n = 3200,include_rts = FALSE)

#Plot the timeline 
ts_plot(ja_time_line, "days") + 
  labs(y = "Frequency of Tweets",
       x = "Date and Time",
       title = "Time Series of @Julian Assange Tweets ",
       subtitle = '"Frequency of tweets from September 21th 2017 up to April 6th 2018"', 
       caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
  theme_economist(dkpanel = TRUE) + theme(legend.position = "")

##----------------------------------------------------------------------------##
##  5- clean & transform data set                                             ##
##----------------------------------------------------------------------------##

# First, remove http elements manually
ja_time_line$stripped_text <- gsub("http.*","", ja_time_line$text)
ja_time_line$stripped_text <- gsub("https.*","", ja_time_line$stripped_text)

# Second, remove punctuation, convert to lowercase, add id for each tweet!
ja_time_line_clean <- ja_time_line %>%
  dplyr::select(stripped_text) %>%
  unnest_tokens(word, stripped_text)

# Third, remove stop words from your list of words
ja_time_line_clean_tweet_words <- ja_time_line_clean %>%
  anti_join(stop_words)

##----------------------------------------------------------------------------##
##  6- plot most common words                                                 ##
##----------------------------------------------------------------------------##

# Finally, plot the top 15 words
ja_time_line_clean_tweet_words %>%
  count(word, sort = TRUE) %>%
  top_n(15) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x = word, y = n, fill = word)) +
  geom_col() +
  xlab(NULL) +
  coord_flip() +
  labs(y = "Count",
       x = "Unique words",
       title = "15 Most Common words from @JulianAssange Tweets ",
       subtitle = '"Analysis of 3 200 tweets from September 21 2017 up to April 6 2018"', 
       caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
  theme_economist(dkpanel = TRUE) + scale_fill_pander() + theme(legend.position = "")

##----------------------------------------------------------------------------##
##  7- sentiment analysis: positive & negative                                ##
##----------------------------------------------------------------------------##

# Tokenize & get the sentiment from the cleaned data
ja_time_line_clean_tweet_words %>%
  inner_join(get_sentiments("bing")) %>% # pull out only sentiment words
  count(sentiment) %>% # count the # of positive & negative words
  spread(sentiment, n, fill = 0) %>% # made data wide rather than narrow
  mutate(sentiment = positive - negative) # # of positive words - # of negative owrds

# Plot the binary distinction 
ggplot(ja_time_line_sent, aes(days, sentiment, fill = 0)) +
  geom_col(show.legend = FALSE)

##----------------------------------------------------------------------------##
##  8- sentiment & word analysis: positive & negative most comon words        ##
##----------------------------------------------------------------------------##

# Implementing count() with word and sentiment arguments
bing_word_counts <- ja_time_line_clean_tweet_words %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

# Plot 15 most common positive & negative words
bing_word_counts %>%
  group_by(sentiment) %>%
  top_n(10) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Contribution to sentiment",
       x = NULL, 
       title = "Most Common Positive and Negative Words in Assange's Tweets ",
       subtitle = '"Sentiment Analysis from September 21th up to April 6th 2018"', 
       caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
  coord_flip() +
  theme_economist(dkpanel = TRUE) + scale_fill_brewer(palette = "Blues") + theme(legend.position = "")

##----------------------------------------------------------------------------##
##  9- word cloud plots
##----------------------------------------------------------------------------##

# Wordcloud the most common words in @JulianAssange tweets
wordcloud1 <- ja_time_line_clean_tweet_words %>%
  anti_join(stop_words) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 200))

# Wordcloud most common positive & negative words
ja_time_line_clean_tweet_words %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("gray20", "gray80"),
                   max.words = 100)

##----------------------------------------------------------------------------##
##  10- sentiment analysis: identifying specific emotions expressed           ##
##----------------------------------------------------------------------------##

## Strip text of tweets and create a variable 
ja_time_line$text_plain <- plain_tweets(ja_time_line$text)

sa <- syuzhet::get_nrc_sentiment(ja_time_line$text_plain)

# Combine ja_time_line and sa
ja_time_line <- cbind(ja_time_line, sa)

# Create function for aggregating date-time vectors
round_time <- function(x, interval = 60) {
  ## round off to lowest value
  rounded <- floor(as.numeric(x) / interval) * interval
  ## center so value is interval mid-point
  rounded <- rounded + round(interval * .5, 0)
  ## return to date-time
  as.POSIXct(rounded, origin = "1970-01-01")
} 

# Use pipe (%>%) operator for linear syntax
  long_emotion_ja <- ja_time_line %>%
# Select variables (columns) of interest
  dplyr::select(created_at, anger:positive) %>%
# Convert created_at variable to desired interval
# Here I chose 6 hour intervals (3 * 60 seconds * 60 mins = 3 hours)
  mutate(created_at = round_time(created_at, 3 * 60 * 60)) %>%
# Transform data to long form
  tidyr::gather(sentiment, score, -created_at) %>%
# Group by time, query, and sentiment
  group_by(created_at, sentiment) %>%
# Get mean for each grouping
  summarize(score = mean(score, na.rm = TRUE),
            n = n()) %>%
  ungroup()

# Identifying the amount of different emotions 
  ja_time_line %>% 
    unnest_tokens(word, text) %>%
    select(word) %>%
    left_join(proust_sentiments(type = "score")) %>%
    na.omit() %>%
    count(sentiment)
  
##----------------------------------------------------------------------------##
##  11- plotting sentiment analysis identifying emotions expressed            ##
##----------------------------------------------------------------------------##
 
long_emotion_ja %>%
  ggplot(aes(x = created_at, y = score, color = score)) +
  geom_point() +
  geom_smooth(method = "loess") +
  facet_wrap(~ sentiment, scale = "free_y", nrow = 2) +
  theme_economist(dkpanel = TRUE) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom",
        axis.text = element_text(size = 9),
        legend.title = element_blank()) +
  labs(x = NULL, y = NULL,
       title = "Sentiment Analysis of Assange's Twitter statuses",
       subtitle = "Identifying Emotions Expressed in Tweets from September 21st up to April 6th 2018") +
  scale_x_datetime(date_breaks = "18 hours", date_labels = "%b %d")

##----------------------------------------------------------------------------##
##  12- plotting identifying overall emotions expressed                       ##
##----------------------------------------------------------------------------##

# Function to round time (created_at)
round_time <- function(x, secs) as.POSIXct(hms::round_hms(x, secs))
# Function to calculate sentiment scores
sent_scores <- function(x) syuzhet::get_sentiment(plain_tweets(x)) - .5
# Calc data set with sentiment variable
ja_time_line_sent <- ja_time_line %>%
  mutate(days = round_time(created_at, 60 * 60 * 24),
         sentiment = sent_scores(text))

# Aggregate by rounded time interval
ja_time_line_sent  %>% 
  group_by(days) %>%
  summarise(sentiment = sum(sentiment, na.rm = TRUE)) %>%
  ggplot(aes(x = days, y = sentiment)) +
  geom_point(aes(colour = sentiment > 0)) + 
  geom_smooth(method = "loess", span = .2) + 
  scale_color_manual(values = c("#dd3333", "#22aa33")) + 
  geom_hline(yintercept = 0, linetype = 2, colour = "#000000cc") + 
  labs(x = NULL, y = NULL,
       title = "Sentiment Analysis of Assange's Twitter statuses",
       subtitle = "Overall Emotions Expressed in Tweets from September 21st up to April 6th 2018") +
  theme_economist(dkpanel = TRUE) + scale_fill_brewer(palette = "Blues")

##----------------------------------------------------------------------------##
##  14- search_tweets & cleaningsteps()                                                      ##
##----------------------------------------------------------------------------##

#Search for 18,000 tweets containing the word @JulianAssange in English and Spanish  

julian_assange_EN <-search_tweets(q = "@JulianAssange", n = 18000, lang = "en", include_rts = FALSE)
julian_assange_ES <-search_tweets(q = "@JulianAssange", n = 18000, lang = "es", include_rts = FALSE)

# First, remove http elements manually
julian_assange_EN$stripped_text <- gsub("http.*","", julian_assange_EN$text)
julian_assange_EN$stripped_text <- gsub("https.*","", julian_assange_EN$stripped_text)

julian_assange_ES$stripped_text <- gsub("http.*","", julian_assange_ES$text)
julian_assange_ES$stripped_text <- gsub("https.*","", julian_assange_ES$stripped_text)

# Second, remove punctuation, convert to lowercase, add id for each tweet!
julian_assange_EN_clean <- julian_assange_EN %>%
  dplyr::select(stripped_text) %>%
  unnest_tokens(word, stripped_text)
 
julian_assange_ES_clean <- julian_assange_ES %>%
  dplyr::select(stripped_text) %>%
  unnest_tokens(word, stripped_text)

# Third, remove stop words from your list of words
ja_en_cleaned_tweet_words <- julian_assange_EN_clean %>%
  anti_join(stop_words)

ja_es_cleaned_tweet_words <- julian_assange_ES_clean %>%
  anti_join(stop_words)

##----------------------------------------------------------------------------##
##  15- plot Most Common Words in mentions of @JulianAssange                  ##
##----------------------------------------------------------------------------##

# Finally, plot the top 15 words

ja_en_cleaned_tweet_words %>%
  count(word, sort = TRUE) %>%
  top_n(15) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x = word, y = n, fill = word)) +
  geom_col() +
  xlab(NULL) +
  coord_flip() +
  labs(y = "Count",
       x = "Unique words",
       title = "15 Most Common words from tweets in English mentioning @JulianAssange ",
       subtitle = '"Analysis of 18 000 tweets from March 29th up to April 6th 2018"', 
       caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
  theme_economist(dkpanel = TRUE) + scale_fill_pander() + theme(legend.position = "")

ja_es_cleaned_tweet_words %>%
  count(word, sort = TRUE) %>%
  top_n(15) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x = word, y = n, fill = word)) +
  geom_col() +
  xlab(NULL) +
  coord_flip() +
  labs(y = "Count",
       x = "Unique words",
       title = "15 Most Common words from tweets in Spanish mentioning @JulianAssange  ",
       subtitle = '"Analysis of 18 000 tweets from March 29th up to April 6th 2018"', 
       caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
  theme_economist(dkpanel = TRUE) + scale_fill_pander() + theme(legend.position = "")

##----------------------------------------------------------------------------##
## 16- plot English Words Netwrok                                             ##
##----------------------------------------------------------------------------##

# First, remove punctuation, convert to lowercase, add id for each tweet!
julian_assange_EN_paired_words <- julian_assange_EN %>%
  dplyr::select(stripped_text) %>%
  unnest_tokens(paired_words, stripped_text, token = "ngrams", n = 2)

julian_assange_EN_paired_words %>%
  count(paired_words, sort = TRUE)

julian_assange_EN_separated_words <- julian_assange_EN_paired_words %>%
  separate(paired_words, c("word1", "word2"), sep = " ")

julian_assange_EN_filtered <- julian_assange_EN_separated_words %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word)

# New bigram counts
ja_en_words_counts <- julian_assange_EN_filtered %>%
  count(word1, word2, sort = TRUE)

# Plot @JulianAssange Enlgish word network
ja_en_words_counts %>%
  filter(n >= 100) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = n, edge_width = n), show.legend = TRUE) +
  geom_node_point(color = "lightblue", size = 3.5) +
  geom_node_text(aes(label = name), vjust = 1.8, size = 3, repel = TRUE) +
  labs(title = "Word Network: Tweets in English mentioning @JulianAssange",
       subtitle = "Text mining twitter data from March 29th up to April 6th 2018 ",
       x = "", y = "", caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
       theme_void()

##----------------------------------------------------------------------------##
##  17- plot Spanish Words Netwrok                                            ##
##----------------------------------------------------------------------------##

# First, remove punctuation, convert to lowercase, add id for each tweet!
julian_assange_ES_paired_words <- julian_assange_ES %>%
  dplyr::select(stripped_text) %>%
  unnest_tokens(paired_words, stripped_text, token = "ngrams", n = 2)

julian_assange_ES_paired_words %>%
  count(paired_words, sort = TRUE)

julian_assange_ES_separated_words <- julian_assange_ES_paired_words %>%
  separate(paired_words, c("word1", "word2"), sep = " ")

julian_assange_ES_filtered <- julian_assange_ES_separated_words %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word)

# New bigram counts:
ja_es_words_counts <- julian_assange_ES_filtered %>%
  count(word1, word2, sort = TRUE)

# Plot @JulianAssange Spanish word network
ja_es_words_counts %>%
  filter(n >= 45) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = n, edge_width = n), show.legend = TRUE) +
  geom_node_point(color = "lightblue", size = 3.5) +
  geom_node_text(aes(label = name), vjust = 1.8, size = 3, repel = TRUE) +
  labs(title = "Word Network: Tweets in Spanish mentioning @JulianAssange",
       subtitle = "Text mining twitter data from March 29th up to April 6th 2018",
       x = "", y = "", caption = "\nSource: Data collected from Twitter's REST API via rtweet") + 
  theme_void()

##----------------------------------------------------------------------------##
##  18- thanks for reading me                                                 ##
##----------------------------------------------------------------------------##


















