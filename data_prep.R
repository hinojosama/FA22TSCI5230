#'---
#' title: "TSCI 5230: Introduction to Data Science"
#' author: 'Marco Hinojosa MD'
#' abstract: |
#'  | Provide a summary of objectives, study design, setting, participants,
#'  | sample size, predictors, outcome, statistical analysis, results,
#'  | and conclusions.
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
# This part does not show up in your rendered report, only in the script,
# because we are using regular comments instead of #' comments
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

ggplot(data = patients, aes(x = anchor_age, fill = gender))
+ geom_histogram() + geom_vline(xintercept = 65)

table(patients$gender)
# check for duplicates in the subject_id column. if no duplicates should be length 100
length(unique(patients$subject_id))


