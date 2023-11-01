WITH RAW_DATA as (
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
	,CASE
		WHEN [TCI_Date] BETWEEN [derWeekEnding] AND  DATEADD(WEEK,4,[derWeekEnding]) THEN 1
		WHEN [Outpatient_Future_Appointment_Date] BETWEEN [derWeekEnding] AND  DATEADD(WEEK,4,[derWeekEnding]) THEN 1
		ELSE 0 END AS [Future Activity]
	,CASE
		WHEN [Date_Last_Attended] BETWEEN DATEADD(WEEK,-12,[derWeekEnding]) AND [derWeekEnding] THEN 1
		WHEN [DECISION_TO_ADMIT_DATE] BETWEEN DATEADD(WEEK,-12,[derWeekEnding]) AND [derWeekEnding] THEN 1
		ELSE 0 END AS [Recent Attendance]
	,CASE 
		WHEN Referral_To_Treatment_Period_Start_Date IS NULL 
			OR Referral_To_Treatment_Period_Start_Date > derWeekEnding 
			OR Referral_To_Treatment_Period_Start_Date = '1900-01-01'
			THEN NULL
		ELSE DATEDIFF(DAY,Referral_To_Treatment_Period_Start_Date,derWeekEnding)/7.00
		END AS 'Current Weeks Wait'
	,CASE 
		WHEN Last_PAS_Validation_Date IS NULL 
			OR Last_PAS_Validation_Date > derWeekEnding 
			OR Last_PAS_Validation_Date = '1900-01-01'
			THEN NULL
		ELSE DATEDIFF(DAY,Last_PAS_Validation_Date,[derWeekEnding]) / 7.00
		END AS 'Weeks Since PAS Validation'
	,Last_PAS_Validation_Date


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
	)

SELECT 
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'validation_cohort' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM Raw_data

WHERE 
	[Future Activity] = 0 AND [Recent Attendance] = 0 AND ([Current Weeks Wait] > 12 OR [Current Weeks Wait] IS NULL)
	AND ([Last_PAS_Validation_Date] IS NULL OR [Weeks Since PAS Validation] >=12 OR [Weeks Since PAS Validation] < 12)

GROUP BY 
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT 
	STP_Code
	,Der_Provider_Code
	,'Total' as [Treatment_Function_Code]
	,'validation_cohort' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM Raw_data

WHERE 
	[Future Activity] = 0 AND [Recent Attendance] = 0 AND ([Current Weeks Wait] > 12 OR [Current Weeks Wait] IS NULL)
	AND ([Last_PAS_Validation_Date] IS NULL OR [Weeks Since PAS Validation] >=12 OR [Weeks Since PAS Validation] < 12)

GROUP BY 
	STP_Code
	,Der_Provider_Code

UNION ALL

SELECT 
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'validated_pathways' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM Raw_data

WHERE 
	[Future Activity] = 0 AND [Recent Attendance] = 0 AND ([Current Weeks Wait] > 12 OR [Current Weeks Wait] IS NULL)
	AND ([Weeks Since PAS Validation] IS NOT NULL AND [Weeks Since PAS Validation] < 12)

GROUP BY 
	STP_Code
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT 
	STP_Code
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'validated_pathways' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM Raw_data

WHERE 
	[Future Activity] = 0 AND [Recent Attendance] = 0 AND ([Current Weeks Wait] > 12 OR [Current Weeks Wait] IS NULL)
	AND ([Weeks Since PAS Validation] IS NOT NULL AND [Weeks Since PAS Validation] < 12)

GROUP BY 
	STP_Code
	,Der_Provider_Code

