#### Load the libraries ----
library(tidyverse)
library(lubridate)
library(here) # tells us where the working directory starts, useful when you are working with downloaded data on your device 
library(skimr)

#can also get working directory with 
getwd()

#### Import the data ----
## we have 3 dataframes:
## heart disease mortality by health board, heart disease activity by health board, & health board look up codes 

# load data from a saved file 
mortality_raw <- read_csv(here::here("./data/heartdisease_mortalitybyhbr.csv"))
### note: there is a deprecated function in the lubridate packaged called here which can cause problems sometimes
### so it is best to specify you want to use here from the here package. Loading the libraries with here last will also avoid this problem  

# for your own practice, the webpage to download the mortality data is https://www.opendata.nhs.scot/dataset/0e17f3fc-9429-48aa-b1ba-2b7e55688253/resource/dc0512a8-eb49-43b9-84f1-17ef95365d57/download/hd_mortalitybyhbr.csv

# load data from a website 
activity_raw <- read_csv("https://www.opendata.nhs.scot/dataset/0e17f3fc-9429-48aa-b1ba-2b7e55688253/resource/748e2065-b447-4b75-99bd-f17f26f3eaef/download/hd_activitybyhbr.csv")
  
hb <- read_csv("https://www.opendata.nhs.scot/dataset/9f942fdb-e59e-44f5-b534-d6e17229cc7b/resource/652ff726-e676-4a20-abda-435b98dd7bdc/download/hb14_hb19.csv")


#### Check data has imported as expected ----
## view the data frame in a new window 
View(mortality_raw)
View(activity_raw)
View(hb)

## look at first few rows of the data 
head(mortality_raw)
head(activity_raw)
head(hb)

## glimpse at the data show all columns and a preview of some of the responses 
glimpse(mortality_raw)
glimpse(activity_raw)
glimpse(hb)

## summarize the dataframe 
summary(mortality_raw)
summary(activity_raw)
summary(hb)

## skim dataframe to get an overview in more detail 
skim(mortality_raw)
skim(activity_raw)
skim(hb)

#### Join the data frames together for analysis ---- 
## Note: 'All' is an aggregate variable including all levels of the variable 

activity <- activity_raw %>%
  # join activity to hb 
  left_join(hb, by = c("HBR" = "HB")) %>%
  # select the variables we are interested in 
  select(FinancialYear, 
         HBName, 
         AdmissionType,
         AgeGroup,
         Sex,
         Diagnosis,
         NumberOfDischarges) %>%
  # reformat the financial year column to be calendar year 
  separate(FinancialYear, into = c("Year", NA), sep = "/", convert = TRUE) %>%
  # rename Sex variable to be Male/Female for comparability 
  mutate(Sex = str_replace(Sex, "Females", "Female"),
         Sex = str_replace(Sex, "Males", "Male")) %>%
  # filter out aggregate ALL responses from the data 
  # HB Code S92000003 is for all of Scotland
  # under 75 years is another aggregate level variable including all people under 75 
  filter(Sex != "All" & AgeGroup != "All" & AgeGroup != "under75 years" &
           AdmissionType != "All" & HBName != "S92000003")
  
  
mortality <- mortality_raw %>%
  # join activity to hb 
  left_join(hb, by = c("HBR" = "HB")) %>%
  # select the variables we are interested in 
  select(Year, 
         HBName, 
         AgeGroup,
         Sex,
         Diagnosis,
         NumberOfDeaths) %>%
  # filter out aggregate ALL responses from the data 
  # HB Code S92000003 is for all of Scotland
  # under 75 years is another aggregate level variable including all people under 65 
  filter(Sex != "All" & AgeGroup != "All" & HBName != "S92000003" & AgeGroup != "under75 years")

## we could also create a single data frame combining all 3 
full <- activity %>%
  full_join(mortality)

## check there are 14 Health Boards in both dataframes
activity %>%
  distinct(HBName) 

mortality %>%
  distinct(HBName) 

#### Let's make a barplot ----
## Lets say we are interested in finding out what diagnosis most commonly leads to death for women
mortality %>%
  ggplot(aes(x = Diagnosis, y = NumberOfDeaths, fill = Sex)) + 
  geom_col() + 
  theme_minimal() + 
  labs(title = "Heart Disease Deaths in Scotland by Sex", 
       y = "Number of Deaths")

## What if we were interested in specifically the year 2014:
mortality %>%
  filter(Year == 2014) %>%
  ggplot(aes(x = Diagnosis, y = NumberOfDeaths, fill = Sex)) + 
  geom_col() + 
  labs(title = "Heart Disease Deaths in Scotland in 2014", 
       y = "Number of Deaths")

## or specifically in people aged under 45 years of age: 
mortality %>%
  filter(AgeGroup == "0-44 years") %>%
  ggplot(aes(x = Diagnosis, y = NumberOfDeaths, fill = Sex)) + 
  geom_col() + 
  ggtitle("Heart Disease Deaths among people under 45") + 
  ylab("Number of Deaths")

## or specifically in NHS Lothian 
mortality %>%
  filter(HBName == "NHS Lothian") %>%
  ggplot(aes(x = Diagnosis, y = NumberOfDeaths, fill = Sex)) + 
  geom_col() + 
  theme_classic() + 
  ggtitle("Heart Disease Deaths in NHS Lothian") + 
  ylab("Number of Deaths")

## Lets combine them all! How might we look at people under 45, in 2014, in NHS Lothian?
mortality %>%
  filter(AgeGroup == "0-44 years",
         Year == 2014,
         HBName == "NHS Lothian") %>%
  ggplot(aes(x = Diagnosis, 
             y = NumberOfDeaths, 
             fill = Sex)) + 
  geom_col() + 
  theme_bw() + 
  labs(title = "Heart Disease Deaths", 
       subtitle = "People under 45 in NHS Lothian in 2014", 
       y = "Number of Deaths")

## Another option is to have the columns side by side rather than stacked on top of each other 
mortality %>%
  ggplot(aes(x = Diagnosis, y = NumberOfDeaths, fill = Sex)) + 
  geom_col(position = "dodge", 
           alpha = 0.5
           ) + 
  theme_minimal() + 
  labs(title = "Heart Disease Deaths in Scotland by Sex",
      y = "Number of Deaths")

## Notice however that the total number of deaths is now much smaller on the y-axis (600 vs 60000)
## when using position = "dodge", ggplot expects only one y per x 
## this is due the nature of the data and how it is set up, there are numerous missing values (NAs) 
## so we need to summarize the data first and then pass it to geom_col(position = dodge)

mortality %>% group_by(Diagnosis, Sex) %>% 
  mutate(Total_Deaths = sum(NumberOfDeaths, na.rm=TRUE)) %>% 
  ggplot(aes(x = Diagnosis, y = Total_Deaths, fill = Sex)) + 
  geom_col(position = "dodge") + 
  theme_minimal() + 
  labs(title = "Heart Disease Deaths in Scotland by Sex",
       y = "Total Number of Deaths")


## What if we wanted to look at 4 variables? 
## Using the activity data set create a bar chart looking at admission type and number of discharges by sex and diagnosis 
activity %>%
  ggplot(aes(x = AdmissionType, y = NumberOfDischarges, fill = Sex)) + 
  geom_col() + 
  facet_wrap(~ Diagnosis) + 
  theme_dark() + 
  labs(title = "Heart Disease Activity by Sex and Diagnosis") + 
  ylab("Number of Discharges")



