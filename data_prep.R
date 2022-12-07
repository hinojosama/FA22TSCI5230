#'---
#' title: "TSCI 5230: Introduction to Data Science"
#' author: 'Marco Hinojosa'
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

library(ggplot2); # visualization
library(GGally);
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean data set
library(dplyr); 
library(purrr);
library(tidyr);
library(table1);
library(reticulate);

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf)

#Load Data----
#note that if the file 'working_scrip.rdata' does not exist it will run system
#[rather than source() because that would source or load a bunch of other stuff into
#our environment we do not want mucking up this scrip]

if(!file.exists("data.rdata")){system("R -f data.R")}

load("data.rdata")

#build demographics----

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
          

ggplot(data = demographics, aes(x = admits)) + 
  geom_histogram()

#table join----

# inspect what column name(s) they have in common
intersect(names(demographics), names(patients))

#compare subject_id in both of these tables to see if different number
# should return zero if no differences
setdiff(demographics$subject_id, patients$subject_id)
setdiff(patients$subject_id, demographics$subject_id)

demographics_1 <- left_join(demographics, select(patients, -dod), by = "subject_id")


# vanco / zosyn key----
# Mapping the variables...

# build list of keywords
kw_abx <- c("vanco", "zosyn", "piperacillin", "tazobactam", "cefepime", "meropenam", "ertapenem", "carbapenem", "levofloxacin")
kw_lab <- c("creatinine")
kw_aki <- c("acute renal failure", "acute kidney injury", "acute kidney failure", "acute kidney", "acute renal insufficiency")
kw_aki_pp <- c("postpartum", "labor and delivery")

# search for those keywords in the tables to find the full label names using grep function.
# here grep first argument is what to look for which will be the keywords from above sort of 
# crammed together using paste0 function collapse.  The second argument is where should grep search.
# It should search the tables$column specified, then final arguments see help on grep)
# remove post partum from aki in last line here
label_abx <- grep(paste0(kw_abx, collapse = '|'), d_items$label, ignore.case = T, value = T, invert = F)
label_lab <- grep(paste0(kw_lab, collapse = '|'), d_labitems$label, ignore.case = T, value = T, invert = F)
label_aki <- grep(paste0(kw_aki, collapse = '|'), d_icd_diagnoses$long_title, ignore.case = T, value = T, invert = F)
label_aki <- grep(paste0(kw_aki_pp, collapse = '|'), label_aki, ignore.case = T, value = T, invert = T)

# use dplyr filter to make tables with the item_id for the keywords above
item_ids_abx <- d_items %>% filter(label %in% label_abx)
item_ids_lab <- d_labitems %>% filter(label %in% label_lab)
item_ids_aki <- d_icd_diagnoses %>% filter(long_title %in% label_aki)

# Join a table using left join, the first argument is fed in by the pipe operater %>% 
# and it is feeding in only the subset of items_id_abx where category is antibiotics. 
# and pulling to it all the inputevents rows that have those same 'itemid's. 
given_abx <- subset(item_ids_abx, category == "Antibiotics") %>% left_join(inputevents, by = "itemid") 


#grep("^584|^N17", diagnoses_icd$icd_code, value = T )

aki_diagnosis <- subset(diagnoses_icd, grepl("^584|^N17", icd_code))

aki_cr_labs <- subset(item_ids_lab, fluid == "Blood") %>% left_join(labevents, by = "itemid")

emar_abx <- subset(emar, grepl(paste(kw_abx, collapse = '|'), medication, ignore.case = T))

#create a table identifying which hadm_id included either vanco, zosyn, or some other
#antibiotic  or some combination of these exposure variables.  
# Homework: add an additional exposure variable perhaps to identify and label the 
# combinations. 
abx_groupings <- group_by(given_abx, hadm_id) %>% 
  summarise(
    vanco = 'Vancomycin' %in% label, 
    zosyn = any(grepl("Piperacillin", label)), 
    other_abx = length(grep("Piperacillin|Vancomycin", label, value = T, invert = T))>0,
    exp_1 = case_when(!vanco ~ "Other",
                      vanco&zosyn ~ "Vanco plus Zosyn",
                      other_abx ~ "Vanco plus Other",
                      !other_abx ~ 'Vanco',
                      TRUE ~ "Unidentified"),
    exp_2 = case_when(!vanco&!zosyn ~ "Other",
                      !vanco&!other_abx ~ "Zosyn",
                      vanco&zosyn ~ "Vanco plus Zosyn",
                      other_abx ~ "Vanco plus Other",
                      !other_abx ~ 'Vanco',
                      TRUE ~ "Unidentified"))
    
#abx_start_time = (starttime[label == "Vancomycin"]) or may use sapply(st, between()))

# create Admissions_scaffold: days within the hospital admission. The transmute() adds
# new variables and drops existing ones unlike mutate() that adds and preserves. Variables
# can be removed by setting value = Null. Make a new variable named ip_date and it is not 
# enough to merely do ip_date - as.Date(admittime) because this will only return the 
# first value for each hadm_id. Instead we want to list every inpatient day for 
# each hadm_id. Using map2 which can apply a function over a list of elements.  
# In this case the elements are two vectors of 1 date each and it applies the base function
# seq, which fills in a sequence by desired interval specified here as by = "1 day". Then
# unnest takes us from each hadm_id having a list of dates crammed into one cell to a each
# date getting the hadm_id it belongs to shown (the table goes from ~275 obs x2 var
# to 2149 obs x 2 var).  
admissions_scaffold <- admissions %>% 
  select(hadm_id, admittime, dischtime) %>%
  transmute(hadm_id = hadm_id,
            ip_dates = map2(as.Date(admittime), as.Date(dischtime), seq, by = "1 day"))%>%
  unnest(ip_dates)

# create Abx_dates: each row represents a day with antibiotics injection. again use t
# transmute to replace variables as needed. In this case using case_when() to specify 
# the group will be either vanc/zosyn/other.Vancomycin is unique so can use it directly
# zosyn is labeled a couple of ways so use regular expression syntax and grepl() to find 
# anything with piperacillin in the 'label' colummn. Everything eles will be lumped together
# other so just use the T condition for remaining values. Start and end times are kept as is
# and then pass this to unique to remove duplicates (surprising that there are any really #629
# to 629 when applied). Then 
# we take a subset which does not include those rows where the start and end time is na which 
# removes one observation. Then pass this table to that to another transmute() the starttime and 
# endtime medication administration information into days using same map2() and unnest() as above
# apply a final unique does greatly reduce the observations down to 366 which makes sense because
# some medications are given multiple times per day. 
abx_dates <- given_abx %>%
  transmute(hadm_id = hadm_id,
            group = case_when(
              "Vancomycin" == label ~ "Vanc",
              grepl("Piperacillin", label) ~ "Zosyn",
              TRUE ~ "Other"),
            starttime = starttime,
            endtime = endtime) %>% 
  unique() %>% # not sure this is necessary
  subset(!is.na(starttime) & !is.na(endtime)) %>% 
  transmute(hadm_id = hadm_id,
            ip_dates = map2(as.Date(starttime), as.Date(endtime), seq, by = "1 day"),
            group = group) %>%
  unnest(ip_dates) %>% 
  unique()

# split abx_dates by antibiotics type.  split() first arg is x or our table, second
# arg is f or what to split by
abx_dates <- split(abx_dates, abx_dates$group)

# update abx_dates: combined with admissions_scaffold to indicate on what inpatient date,
# what antibiotics was adminstered.  Here the names(abx_dates) will give "Other", "Vanc" and "Zosyn" 
# and will apply the function in {} to each.  Simplify arg of sapply should the result be simplified 
# to a vector, matrix or higher dimensional array if possible? simplify default = True. 
# reduce() is an operation that combines the elements of a vector into a single value. 
# The combination is driven by .f, a binary function that takes two values and returns a single value:
# reducing f over 1:3 computes the value f(f(1, 2), 3)
abx_dates <- sapply(names(abx_dates), function(xx) {
  names(abx_dates[[xx]])[3] <- xx 
  abx_dates[[xx]]},
  simplify = FALSE) %>%
  Reduce(left_join, ., admissions_scaffold)

# Not every patient received every antibiotic or even any abx every single day so there are many N/As
# Next we consider how to fill those in with a string such as "no abx" or "none"

# Two ways to replace N/As with empty string
# mutate(abx_dates, Other = paste(ifelse(is.na(Other), "", Other)),
#        Vanc = coalesce(Vanc, "")) %>% View()

# Given a set of vectors, coalesce() finds the first non-missing value at each position.
mutate(abx_dates,
       across(all_of(c("Other", "Vanc", "Zosyn")), ~ coalesce(.x, "")),
       exposure = paste(Vanc, Zosyn, Other)) %>%
  select(hadm_id, exposure) %>%
  unique() %>%
  pull(exposure) %>% table()


















