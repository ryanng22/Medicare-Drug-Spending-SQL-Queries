/*
Medicare Part D and Part B Drug Spending Data Exploration

Skills used: Arithmetic, Filtering, Aggregate Functions, Subqueries, Joins

*/

-- Exploring both data sets. Limit output to reduce query processing times

SELECT *
FROM part_d
LIMIT 5

SELECT *
FROM part_b
LIMIT 5

SELECT COUNT(DISTINCT Generic)
FROM part_d

-- Total Spending for 2016 and 2020
SELECT Generic, SUM(Tot_Spndng_2016) AS 2016_Totals, SUM(Tot_Spndng_2020) AS 2020_Totals
FROM part_d
WHERE Mftr_Name != 'Overall'
GROUP BY Generic

-- Exploring "Outlier Flag" Attribute
SELECT Generic
FROM part_d
WHERE Outlier_Flag_2020 = 1

-- Exploring antivirals with intention of viewing HIV Antiretrovirals
-- Top spending on Hep C and HIV Antivirals
SELECT Generic, SUM(Tot_Spndng_2016), SUM(Tot_Spndng_2017), SUM(Tot_Spndng_2018), SUM(Tot_Spndng_2019), SUM(Tot_Spndng_2020)
FROM part_d
WHERE Generic LIKE '%vir%' AND Mftr_Name != 'Overall'
GROUP BY Generic
ORDER BY Tot_Spndng_2020 DESC, Generic ASC

-- Exploring monoclonal antibodies
-- Top spending on rheum, osteoporosis, HLD (PCSK9 Inhibitor), eculizumab for PNH
SELECT Generic, SUM(Tot_Spndng_2016), SUM(Tot_Spndng_2017), SUM(Tot_Spndng_2018), SUM(Tot_Spndng_2019), SUM(Tot_Spndng_2020)
FROM part_d
WHERE Generic LIKE '%mab' AND Mftr_Name != 'Overall'
GROUP BY Generic
ORDER BY Tot_Spndng_2020 DESC, Generic ASC
LIMIT 10

-- Top number of claims in Y2020
-- The usual suspects: Cardiolovascular Disease Related, Pain, Diabetes Medications 
SELECT Generic, SUM(Tot_Clms_2020) AS Total_Claims
FROM part_d
WHERE Mftr_Name != 'Overall'
GROUP BY Generic
ORDER BY Total_Claims DESC

-- All Have Incr in Num of Claims Except Omeprazole
-- Num of Omeprazole Claims Decr Likely Due to Publication of Neg Impact of Long Term PPI Therapy
SELECT Generic, SUM(Tot_Clms_2016) AS Num_Claims_2016, 
			    SUM(Tot_Clms_2017) AS Num_Claims_2017, 
				SUM(Tot_Clms_2018) AS Num_Claims_2018, 
                SUM(Tot_Clms_2019) AS Num_Claims_2019, 
                SUM(Tot_Clms_2020) AS Num_Claims_2020
FROM part_d
WHERE Mftr_Name != 'Overall'
GROUP BY Generic
ORDER BY Num_Claims_2020 DESC
LIMIT 10

-- Average Spending per Claim per Year
-- Spending Increases Each Year
SELECT ROUND(SUM(Avg_Spnd_Per_Clm_2016),2),
	   ROUND(SUM(Avg_Spnd_Per_Clm_2017),2),
       ROUND(SUM(Avg_Spnd_Per_Clm_2018),2),
       ROUND(SUM(Avg_Spnd_Per_Clm_2019),2),
       ROUND(SUM(Avg_Spnd_Per_Clm_2020),2)
FROM part_d
WHERE Mftr_Name != 'Overall'

-- Percent Increase of Spending per Claim from 2016 to 2020
SELECT ROUND(((2020_Avg - 2016_Avg) / 2020_Avg) * 100) AS Percent_Incr
FROM (
	SELECT ROUND(SUM(Avg_Spnd_Per_Clm_2016),2) AS 2016_Avg, ROUND(SUM(Avg_Spnd_Per_Clm_2020),2) AS 2020_Avg
	FROM part_d
	WHERE Mftr_Name != 'Overall') AS Avg_Tab

-- Average Total Spending from 2016 to 2020: 841,931,739,863.57
-- Subquery to Avoid Nesting Aggregate Functions
SELECT AVG(2016_Total + 2017_Total + 2018_Total + 2019_Total + 2020_Total) AS Avg_Total_Spending
FROM(
	SELECT ROUND(SUM(Tot_Spndng_2016),2) AS 2016_Total,
		   ROUND(SUM(Tot_Spndng_2017),2) AS 2017_Total,
		   ROUND(SUM(Tot_Spndng_2018),2) AS 2018_Total,
		   ROUND(SUM(Tot_Spndng_2019),2) AS 2019_Total,
		   ROUND(SUM(Tot_Spndng_2020),2) AS 2020_Total
	FROM part_d
	WHERE Mftr_Name != 'Overall' ) AS Sum_Tab

-- Exploring Which Medications are Paid By Part D and Part B
-- Distinct Medications Paid for by Both
SELECT COUNT(DISTINCT b.Generic)
FROM part_d d JOIN part_b b
	ON d.Generic = b.Generic
WHERE d.Mftr_Name != 'Overall'

-- Fraction of Part D Spending per Part B Spending Organized by Generic Drug
-- Part B Clearly Shoulders Burden of National Spending on Monoclonal Antibodies
SELECT b.Generic, SUM(d.Tot_Spndng_2020) AS D_Spend, SUM(b.Tot_Spndng_2020) AS B_Spend,
	SUM(d.Tot_Spndng_2020) / b.Tot_Spndng_2020 AS Frac_Spend
FROM part_d d JOIN part_b b
	ON d.Generic = b.Generic
WHERE d.Mftr_Name != 'Overall'
GROUP BY b.Generic
ORDER BY B_Spend DESC

-- Monoclonal Antibodies Covered by Part B Not Similar to Part D MABs
-- Part B Covering Majority Oncology MABs
SELECT b.Generic, SUM(d.Tot_Spndng_2020) AS D_Spend, SUM(b.Tot_Spndng_2020) AS B_Spend,
	SUM(d.Tot_Spndng_2020) / b.Tot_Spndng_2020 AS Frac_Spend
FROM part_d d JOIN part_b b
	ON d.Generic = b.Generic
WHERE b.Generic LIKE '%mab' AND d.Mftr_Name != 'Overall'
GROUP BY b.Generic
ORDER BY B_Spend DESC
LIMIT 10