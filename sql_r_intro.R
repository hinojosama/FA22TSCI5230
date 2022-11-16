#install.packages("RPostgres")

#DBI is a generic database accessing tool.  We will use the drive from RPostgres 
#here
library(DBI)
source("local_config.R")
con <- dbConnect(RPostgres::Postgres(),dbname = 'postgres',
                 host = my_server, # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'
                 port = 5432, # or any other port specified by your DBA
                 user = my_user,
                 password = my_password)
dbGetQuery(con, "SELECT * FROM patients limit 10")

dbListTables(con)
