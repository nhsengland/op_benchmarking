WITH RAW_DATA AS (
SELECT
	REF.STP_Code
	,CASE 
		WHEN LEFT(wl.organisation_identifier_code_of_provider,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(wl.organisation_identifier_code_of_provider,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(wl.organisation_identifier_code_of_provider,3) END AS Der_Provider_Code
	,CASE WHEN [ACTIVITY_TREATMENT_FUNCTION_CODE] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
													'221','222','223','230','240','241','242','250','251','252','253','254',
													'255','256','257','258','259','260','261','262','263','264','270','280',
													'290','291','321','421') THEN 'Paeds'
			ELSE [ACTIVITY_TREATMENT_FUNCTION_CODE]
			END AS [Treatment_Function_Code]
	,[Last_Pas_Validation_Date]
	,DerWeekEnding

FROM [Reporting].[MESH_WLMDS_Open_ASI_Combined] AS WL																								
	LEFT OUTER Join [Reporting_UKHD_ODS].[Provider_Hierarchies] AS Ref on organisation_identifier_code_of_provider = Ref.Organisation_Code																																															
	Left outer Join [Internal_RTT].[RTT_TFC_Mappings] AS TFC on cast([ACTIVITY_TREATMENT_FUNCTION_CODE] as varchar) = cast([National_TFC_code] as varchar)																		
																		
WHERE 
	Referral_To_Treatment_Period_Start_Date IS NOT NULL																		
	AND Referral_To_Treatment_Period_End_Date IS NULL																		
	AND Ref.Region_Code = 'Y59'																		
	AND Waiting_List_Type in ('ORTT')																		
	And DerWeekEnding = (SELECT MAX(DerWeekEnding) FROM [Reporting].[MESH_WLMDS_Open_ASI_Combined])																		
	AND organisation_identifier_code_of_provider in ('RPC','RHM','RWF','RYR','RTH','RHW','RXQ','RXC','RTP','RPA','RN5','RHU','RN7','R1F','RVV','RDU','RTK','RA2')
	AND DATEDIFF(WEEK,REFERRAL_REQUEST_RECEIVED_DATE,DerWeekEnding) >12)


SELECT
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'validated_pathways' as Metric_Name
	,COUNT(*) AS Metric_Value
																		
FROM RAW_DATA
																		
WHERE 
	(CASE 
		WHEN [Last_Pas_Validation_Date] = '1900-01-01' THEN 0
		WHEN [Last_Pas_Validation_Date] IS NULL THEN 0
		WHEN DATEDIFF(WEEK, [Last_Pas_Validation_Date], DerWeekEnding) <=12 THEN 1
		END) = 1 

GROUP BY 
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	STP_Code
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'validated_pathways' as Metric_Name
	,COUNT(*) AS Metric_Value
																		
FROM RAW_DATA
																		
WHERE 
	(CASE 
		WHEN [Last_Pas_Validation_Date] = '1900-01-01' THEN 0
		WHEN [Last_Pas_Validation_Date] IS NULL THEN 0
		WHEN DATEDIFF(WEEK, [Last_Pas_Validation_Date], DerWeekEnding) <=12 THEN 1
		END) = 1 


GROUP BY 
	STP_Code
	,Der_Provider_Code

/*XXXXXXXXXXXXXXX*/	

UNION ALL

SELECT
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'open_pathways' as Metric_Name
	,COUNT(*) AS Metric_Value
																		
FROM RAW_DATA
																		

GROUP BY 
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	STP_Code
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'open_pathways' as Metric_Name
	,COUNT(*) AS Metric_Value
																		
FROM RAW_DATA
																		
GROUP BY 
	STP_Code
	,Der_Provider_Code
