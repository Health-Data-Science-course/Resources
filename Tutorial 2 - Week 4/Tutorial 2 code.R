# 1st load libraries ----
library(tidyverse) #already loads ggplot2 for us! 
library(lubridate)
library(kableExtra) #for making tables

# import data ----
cancelled_raw <- read_csv("https://www.opendata.nhs.scot/dataset/479848ef-41f8-44c5-bfb5-666e0df8f574/resource/0f1cf6b1-ebf6-4928-b490-0a721cc98884/download/cancellations_by_board_february_2022.csv")
hb <- read_csv("https://www.opendata.nhs.scot/dataset/9f942fdb-e59e-44f5-b534-d6e17229cc7b/resource/652ff726-e676-4a20-abda-435b98dd7bdc/download/hb14_hb19.csv")

# wrangle data for visualization ----
cancelled <- cancelled_raw %>%
  # Join cancelled to hb
  left_join(hb, by = c("HBT" = "HB")) %>%
  # Select the variables we're interested in
  select(Month,
         HBName,
         TotalOperations,
         TotalCancelled) %>%
  # Reformat the month column & create a Year variable 
  mutate(Month = ymd(Month, truncated = TRUE),
         Year = as.factor(year(Month)))

# code for the examples in the slides ----

## bar plot 
ggplot(data = cancelled, aes(x = Year, y = TotalCancelled)) + 
  geom_col()

### you can also pipe data into ggplot - note this creates the same plot as above
cancelled %>% 
  ggplot(aes(x = Year, y = TotalCancelled)) + 
  geom_col()

### you do not have to specify x = or y = either, this is the same plot as the 2 above - just different style of code
cancelled %>% 
  ggplot(aes(Year, TotalCancelled)) + 
  geom_col()

## density plot 
ggplot(data = cancelled, aes(x = TotalCancelled)) + 
  geom_density()

## scatter plot 
ggplot(data = cancelled, aes(x = TotalCancelled, y = TotalOperations)) + 
  geom_point()

## inside and outside aes() 
### inside 
ggplot(data = cancelled, aes(x = TotalCancelled, y = TotalOperations, 
                             color = Year)) + 
  geom_point()

### if you try and specify the color to represent the 3rd variable Year outside the aes() you get an error 
ggplot(data = cancelled, aes(x = TotalCancelled, y = TotalOperations)) + 
  geom_point(color = Year)

### outside
ggplot(data = cancelled, aes(x = TotalCancelled, y = TotalOperations)) + 
  geom_point(color = "mediumpurple")

### similarly, if you try and put a single value and not a variable within the aes() R things you meant it as a variable 
ggplot(data = cancelled, aes(x = TotalCancelled, y = TotalOperations, 
                             color = "mediumpurple")) + 
  geom_point()

## both aes() inside and outside 
ggplot(data = cancelled, aes(x = TotalCancelled, y = TotalOperations, 
                             color = Year)) + 
  geom_point(shape = 4)

## layered example 
ggplot(cancelled, aes(TotalCancelled, TotalOperations)) + 
  geom_point() + 
  geom_density2d()

### compare above to 
ggplot(cancelled, aes(TotalCancelled, TotalOperations)) + 
  geom_density2d() + 
  geom_point() 
  


# quick aside on tables ----
## more covered in Week 6 

# Please note that without the "simple" inside the paranthesis, you are getting the html code
# Something useful when using RMarkdown. Try it.

head(cancelled) %>% 
  knitr::kable("simple")

## to get you used to some of the code, check out the below table - change some of the code to figure out what different things do! 

#1st lets wrangle the data 
cancelled_table <- cancelled %>%
  #group the data 
  group_by(Year, HBName) %>% 
  # create summary variables 
  summarise(TotalOperationsYear = sum(TotalOperations),
            TotalCancelledYear = sum(TotalCancelled),
            PercentCancelled = (TotalCancelledYear/TotalOperationsYear)*100) %>%  
  # ungroup the data 
  ungroup() %>% 
  # filter the observations to include only those we are interested in 
  filter(Year %in% c(2020, 2021),
        HBName %in% c("NHS Greater Glasgow and Clyde", "NHS Lothian")) 


#then create the table   
cancelled_table %>%
  # select the variables we want included in the table
  select(Year,
         HBName,
         TotalCancelledYear,
         TotalOperationsYear,
         PercentCancelled) %>%
  # create the gt table object
  knitr::kable(
    "simple",
    col.names = c(
      Year = "Year",
      HBName = "Health Board",
      TotalCancelledYear = "Cancelled Operations",
      TotalOperationsYear = "Total Operations",
      PercentCancelled = "Percent Cancelled"
    ),
    caption = "An example table caption.",
    digits = 2
  )

