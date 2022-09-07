#'---
#' title: "TSCI 5230: Introduction to Data Science"
#' abstract: |
#'  | Data preparation for demo MIMIC IV dataset. 
#' documentclass: article
#' description: 'Manuscript'
#' clean: false
#' self_contained: true
#' number_sections: false
#' keep_md: true
#' fig_caption: true
#' output:
#'  html_document:
#'    toc: true
#'    toc_float: true
#'    code_folding: show
#' ---
#'
#+ init, echo=FALSE, message=FALSE, warning=FALSE
# Initialize ----

debug <- 0;
knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0);

library(ggplot2); # visualisation
library(GGally);
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr); #add dplyr library

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf)

#Load Data----
#note that if the file 'working_scrip.rdata' does not exist it will run system
#[rather than source() because that would source or load a bunch of other stuff into
#our environment we do not want mucking up this scrip]

if(!file.exists("data.rdata")){system("R -f data.R")}

load("data.rdata")

#Section 2----

ggplot(data = patients, aes(x = anchor_age, fill = gender)) + 
  geom_histogram() + geom_vline(xintercept = 65)

table(patients$gender)
# check for duplicates in the subject_id column. if no duplicates should be length 100
length(unique(patients$subject_id))

# group the admissions table by subject and use summarise () to create a column 
# for each subject that has a count of the number of admits using n(). Similiar 
# strategy to apply to the ethnicity column but as use the unique () now count this
# vector with length () rather than n(). Also use paste to add column for combined
# ethnicity.  Finally we first checked if multiplicity in language, as there was not
# we have just made it simple using the tail () to take only the last value of language
# for each grouping of the subject_id and assign this value for our demographic table
# in the language_demo column.
demographics <- group_by(admissions, subject_id) %>%
  mutate(los = round(difftime(dischtime, admittime, units = "hours"), 2)) %>% 
  summarise(admits = n(), 
            ethnicity_demo = length(unique(ethnicity)), 
            ethnicity_combo = paste(sort(unique(ethnicity)), collapse = "+"),
            language_demo = tail(language, 1),
            death = deathtime,
            los_demo = los,
            num_ED = length(na.omit(edregtime))) 
            
View(demographics)

ggplot(data = demographics, aes(x = admits)) + 
  geom_histogram()



