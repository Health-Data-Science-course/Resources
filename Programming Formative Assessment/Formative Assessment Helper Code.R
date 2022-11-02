library(tidyverse)
library(janitor) #you may need to install this package using install.packages() first

activity_raw <- read_csv("https://www.opendata.nhs.scot/dataset/0e17f3fc-9429-48aa-b1ba-2b7e55688253/resource/748e2065-b447-4b75-99bd-f17f26f3eaef/download/hd_activitybyhbr.csv")
mortality_raw <- read_csv("https://www.opendata.nhs.scot/dataset/0e17f3fc-9429-48aa-b1ba-2b7e55688253/resource/dc0512a8-eb49-43b9-84f1-17ef95365d57/download/hd_mortalitybyhbr.csv")
hb <- read_csv("https://www.opendata.nhs.scot/dataset/9f942fdb-e59e-44f5-b534-d6e17229cc7b/resource/652ff726-e676-4a20-abda-435b98dd7bdc/download/hb14_hb21.csv")

activity <- activity_raw %>%
  left_join(hb, by = c("HBR" = "HB")) %>%
  select(FinancialYear, 
         HBName, 
         AdmissionType,
         AgeGroup,
         Sex,
         Diagnosis,
         NumberOfDischarges) %>%
  clean_names() %>%
  separate(financial_year, into = c("Year", NA), sep = "/", convert = TRUE) %>%
  mutate(sex = str_replace(sex, "Females", "Female")) %>%
  mutate(sex = str_replace(sex, "Males", "Male")) %>%
  rowid_to_column() %>%
  filter(sex == "All" & age_group == "under75 years" &
           admission_type != "All")


mortality <- mortality_raw %>%
  left_join(hb, by = c("HBR" = "HB")) %>%
  select(Year, 
         HBName, 
         AgeGroup,
         Sex,
         Diagnosis,
         NumberOfDeaths) %>%
  clean_names() %>%
  rowid_to_column() %>% 
  filter(sex != "All" & age_group == "All")

