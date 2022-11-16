#'---
#' title: "Data Extraction
#' author: 'Marco Hinojosa'
#' abstract: |
#'  | import the data, make tables, and save as an rdata file
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
# init ----
# This part does not show up in your rendered report, only in the script,
# because we are using regular comments instead of #' comments
debug <- 0;
knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0);

library(rio);# simple command for importing and exporting
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr); #add dplyr library
library(fs)

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf);
whatisthis <- function(xx){
  list(class=class(xx),info=c(mode=mode(xx),storage.mode=storage.mode(xx)
                              ,typeof=typeof(xx)))};

#' # Import the data
InputData <- 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'
dir.create("data", showWarnings = FALSE)

ZippedData <- file.path("data", "temptdata.zip")

if(!file.exists(ZippedData)){download.file(InputData,
                                           destfile = ZippedData)}

Unzipped_Data <- unzip(ZippedData,exdir = 'data') %>%
  grep('gz$',.,val=T)


TableNames <- basename(Unzipped_Data) %>%
  grep("gz", ., value = TRUE) %>%
  basename() %>%
  path_ext_remove() %>%
  path_ext_remove()

for(ii in seq_along(TableNames)) {
  assign(TableNames[ii], import(Unzipped_Data[ii], format = 'csv'), inherits = TRUE)}

#an alternative to the above for loop would be the mapply function below
# mapply(function(xx,yy)
#   assign(xx, import(yy,format = 'csv'), inherits = TRUE), TableNames, Unzipped_Data)

save(list = TableNames, file = "data.rdata")

