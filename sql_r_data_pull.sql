-- !preview conn=DBI::dbConnect(RPostgres::Postgres(), dbname = 'postgres', host = 'db.zgqkukklhncxcctlqpvg.supabase.co', port = 5432, user = 'student', password = '')

/*SELECT *
FROM mh_patients
limit 10*/
CREATE table mh_demographics
SELECT 
  subject_id, 
  COUNT(DISTINCT ethnicity) as ethnicity_demo, 
  CAST(array_agg(ethnicity)as character(20)) as ethnicity_combo, /*array_agg concatenates
  the list of values for the groups and will also need to cast it specify it as a 
  character with length 20*/
  MAX(language) as language_demo,
  MAX(deathtime) as death,
  COUNT(*) as admits, --since this will count the rows (per )
  COUNT(edregtime) as num_ED,
  AVG(DATE_PART('day', dischtime - admittime)) as los
 -- language, deathtime, edregtime
FROM mh_admissions GROUP BY subject_id


/*demographics <- group_by(admissions, subject_id) %>%
  mutate(los = round(difftime(dischtime, admittime, units = "hours"), 2)) %>% 
  summarise(admits = n(), 
            ethnicity_demo = length(unique(ethnicity)), 
            ethnicity_combo = paste(sort(unique(ethnicity)), collapse = "+"),
            language_demo = tail(language, 1),
            death = deathtime,
            los_demo = los,
            num_ED = length(na.omit(edregtime)))*/

/*SELECT subject_id
FROM mh_demographics
EXCEPT 
SELECT subject_id 
FROM mh_patients*/


