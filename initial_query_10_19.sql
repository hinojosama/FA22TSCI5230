/*CREATE table mh_patients as SELECT * FROM patients;
CREATE table mh_admissions as SELECT * FROM admissions;
CREATE table mh_inputevents as SELECT * FROM inputevents;
CREATE TABLE mh_d_items AS SELECT * FROM d_items;
CREATE TABLE mh_transfers as SELECT * FROM transfers;
CREATE TABLE mh_d_labitems as SELECT * FROM d_labitems;
CREATE TABLE mh_labevents as SELECT * FROM labevents;*/

/*CREATE table mh_demographics AS
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
FROM mh_admissions GROUP BY subject_id*/

/*SELECT COUNT(*),language_demo FROM mh_demographics GROUP by language_demo*/

--setdiff(demographics$subject_id, patients$subject_id)
--setdiff(patients$subject_id, demographics$subject_id)

/*SELECT subject_id FROM mh_demographics
EXCEPT 
SELECT subject_id FROM mh_patients;

SELECT SELECT subject_id FROM mh_patients 
EXCEPT subject_id FROM mh_demographics */

/*CREATE TABLE mh_demographics1 AS
SELECT demo.*, gender, anchor_age, anchor_year, anchor_year_group 
FROM mh_demographics AS demo
LEFT JOIN mh_patients AS pat
ON demo.subject_id = pat.subject_id*/

DROP TABLE mh_given_abx;
CREATE TABLE mh_given_abx AS 

WITH q0 AS 
(SELECT 
GENERATE_SERIES(MIN(admittime), MAX(dischtime), INTERVAL '1 DAY') AS day
FROM mh_admissions) 
, q1 AS
(SELECT hadm_id, day::DATE
FROM q0 INNER JOIN mh_admissions AS adm ON q0.day BETWEEN adm.admittime::DATE AND adm.dischtime::DATE )
, q2 AS
(SELECT hadm_id, item.abbreviation, starttime::DATE, endtime::DATE
FROM mh_d_items AS item 
INNER JOIN mh_inputevents AS inp ON item.itemid = inp.itemid
WHERE (label LIKE '%anco%'
OR label LIKE '%iperacillin%'
OR label like '%rtapenem%'
OR label like '%evofloxacin%'
OR label like '%efepime%')
AND category = 'Antibiotics')

, q3 AS
(SELECT abbreviation, q1.*
FROM q1 LEFT JOIN q2 ON q1.hadm_id = q2.hadm_id AND
q1.day BETWEEN starttime and endtime)

, q4 AS
(SELECT hadm_id, day,
SUM (CASE WHEN abbreviation = 'Vancomycin' THEN 1 ELSE 0 END) AS Vanc,
SUM (CASE WHEN abbreviation LIKE '%Zosyn%'THEN 1 ELSE 0 END) AS Zosyn,
SUM (CASE WHEN abbreviation != 'Vancomycin' AND abbreviation NOT LIKE '%Zosyn%' THEN 1 ELSE 0 END) AS Other
FROM q3
GROUP BY hadm_id, day)

, q5 AS 
(SELECT 
 ROW_NUMBER() OVER (PARTITION BY hadm_id, charttime::date ORDER BY charttime), 
 hadm_id,
 charttime,
 AVG(CAST(value AS NUMERIC)) OVER (PARTITION BY hadm_id, charttime::date) AS avg_creat, 
 --MAX(CAST(value AS NUMERIC)) AS max_creat, 
 FIRST_VALUE(CAST(value AS NUMERIC)) OVER (PARTITION BY hadm_id, charttime::date ORDER BY charttime DESC) AS last_creat,
 CAST(value AS NUMERIC) AS value,
 flag 
 --SUM(CASE WHEN flag IS NOT null THEN 1 ELSE 0 END) AS flag_count
FROM mh_d_labitems AS mhd 
INNER JOIN mh_labevents AS mhl
ON mhd.itemid = mhl.itemid
WHERE label LIKE '%reatinine%' 
AND fluid = 'Blood'
--GROUP BY hadm_id, charttime::date)
ORDER BY hadm_id, charttime)
 
,q6 AS
(SELECT 
      avg(value) AS avg_creat, 
      max(value) AS max_creat, 
      max(last_creat) AS flag_count,
       hadm_id, 
       charttime::date AS charttime, 
       sum(CASE WHEN flag is not null THEN 1
          ELSE 0 END) AS AbnormalCount 
FROM q5
 GROUP BY hadm_id, charttime::date)
 
SELECT q4.*, avg_creat, max_creat, flag_count,
CASE 
	WHEN Vanc > 0 AND Zosyn > 0 THEN 'vanc&zosyn'
	WHEN Vanc > 0 AND Other > 0 THEN 'vanc&other'
	WHEN Vanc > 0 THEN 'vanc'
	WHEN Zosyn > 0 OR Other > 0 THEN 'other'
	WHEN Vanc + Zosyn + Other = 0 THEN 'none'
	Else 'undefined'
END AS Exposure
FROM q4 

LEFT JOIN q6 ON q4.hadm_id = CAST(q6.hadm_id AS BIGINT)
AND q4.day=q6.charttime


















