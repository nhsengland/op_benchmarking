
DECLARE @report_period AS Varchar(6)
SET @report_period = '202308'

Declare @reporting_month AS DATE
SET @reporting_month = '2023-08-01'

DECLARE @index_value AS varchar(7)
SET @index_value = '2023/24'



IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_1', 'U') IS NOT NULL 
  DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_1; 

IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_2', 'U') IS NOT NULL 
  DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_2; 

IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_3', 'U') IS NOT NULL 
  DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_3; 

SELECT 
	REF.[STP_Code]
	,CASE
		WHEN RIGHT(OPA.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 
		WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(OPA.Der_Provider_Code,3)
		END as Der_Provider_Code
	,CASE WHEN OPA.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Paeds'
		ELSE OPA.[Treatment_Function_Code] 
		END AS [Treatment_Function_Code]
	,[First_Attendance]
	,[Attendance_Status]
	,[Core_HRG]
	,[Referral_Request_Received_Date]
	,[Appointment_Date]
	,OPA.[Outcome_of_Attendance]


INTO [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]

FROM
	[NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA] AS OPA
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS REF 
		ON (CASE
				WHEN RIGHT(OPA.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 			
				WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
				WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
				ELSE LEFT(OPA.Der_Provider_Code,3) END) = REF.Organisation_Code

WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('3','7','5','6')				
	AND Der_Financial_Year = @index_value
	AND OPA.[Der_Activity_Month] =  @report_period
	AND OPA.[Treatment_Function_Code] <> '812'	
	AND REF.Region_Code = 'Y59'
	AND Administrative_Category = '01'
	AND REF.NHSE_Organisation_Type IN ('NHS Trust', 'Acute Trust')
	AND REF.Effective_To IS NULL

/* XXXX Staging 2 XXXX*/
SELECT
	REF.[STP_Code]
	,(CASE							
		WHEN LEFT(ERC.[ReceivingResponding_OrgCode],3) = 'RXH' THEN 'RYR'
		WHEN LEFT(ERC.[ReceivingResponding_OrgCode],3) = 'RD7' THEN 'RDU'
		ELSE LEFT(ERC.[ReceivingResponding_OrgCode],3) END)  AS [Der_Provider_Code]
	,CASE WHEN ERC.[TFC_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Paeds'
		ELSE ERC.[TFC_Code] 
		END AS [Treatment_Function_Code]
	,[Status_Code]
	,[Outcome_Code]
	,Count_of_Requests

INTO [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

FROM 
	[NHSE_Reference].[dbo].[tbl_Ref_System_EROC] AS ERC
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS REF 
		ON (CASE							
				WHEN LEFT(ERC.[ReceivingResponding_OrgCode],3) = 'RXH' THEN 'RYR'
				WHEN LEFT(ERC.[ReceivingResponding_OrgCode],3) = 'RD7' THEN 'RDU'
				ELSE LEFT(ERC.[ReceivingResponding_OrgCode],3) END) = REF.Organisation_Code

WHERE 
	[Latest_Flag] in ( 'Yes','n/a')	
	AND [Month_of_Request] = @reporting_month
	AND REF.Region_Code = 'Y59'	
	AND REF.NHSE_Organisation_Type IN ('NHS Trust', 'Acute Trust')
	AND REF.Effective_To IS NULL

/*XXXX staging_3 XXXX*/

SELECT 
	REF.STP_Code
	,(CASE
		WHEN RIGHT(ERC.[Provider_code],2) = '00' THEN LEFT([Provider_code],3) 			
		WHEN LEFT(ERC.[Provider_code],3) = 'RXH' THEN 'RYR'
		WHEN LEFT(ERC.[Provider_code],3) = 'RD7' THEN 'RDU'
		ELSE LEFT(ERC.[Provider_code],3) END) AS Der_Provider_Code
	,CASE 
		WHEN ERC.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Paeds'
		ELSE ERC.[Treatment_Function_Code] 
		END AS [Treatment_Function_Code]   
	,[Metric_code]  
	,[Metric_name]  
	,[Value]
 
INTO [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_3]

FROM    
	[NHSE_Reference].[dbo].[tbl_Ref_Provider_EROC] AS ERC  
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS REF 
		ON (CASE
				WHEN RIGHT(ERC.[Provider_code],2) = '00' THEN LEFT([Provider_code],3) 			
				WHEN LEFT(ERC.[Provider_code],3) = 'RXH' THEN 'RYR'
				WHEN LEFT(ERC.[Provider_code],3) = 'RD7' THEN 'RDU'
				ELSE LEFT(ERC.[Provider_code],3) END) = REF.Organisation_Code

WHERE 
	[Latest_data] = 'yes'  
	AND Activity_month = @reporting_month
	AND [Metric_name] = 'Moved or Discharged'
	AND REF.Region_Code = 'Y59'	
	AND REF.NHSE_Organisation_Type IN ('NHS Trust', 'Acute Trust')
	AND REF.Effective_To IS NULL

/*XXXX staging 4 XXXX*/








/*XXXX OPFA metrics XXXX*/
SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'OPFA_Count' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]	
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')

GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'OPFA_Count' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')				


GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX OPFU metrics XXXX*/
UNION ALL

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'OPFU_Count' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]
				
WHERE 					
	[First_Attendance] IN ('2','4')				
	AND [Attendance_Status] IN ('5','6')				


GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'OPFU_Count' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]
				
WHERE 					
	[First_Attendance] IN ('2','4')				
	AND [Attendance_Status] IN ('5','6')				

GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX OP All metrics XXXX*/
UNION ALL

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'OP_All_Attended' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1] 
				
WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('5','6')				


GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'OP_All_Attended' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1] 
				
WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('5','6')				


GROUP BY 
	[STP_Code]
	,Der_Provider_Code

UNION ALL

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'OP_All_Inc_DNA' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1] 
				
WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('3','7','5','6')						


GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'OP_All_Inc_DNA' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1] 
				
WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('3','7','5','6')				


GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX DNA total metrics XXXX*/
UNION ALL

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'DNA_Count' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1] 
				
WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('3','7')				

GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'DNA_Count' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1] 
				
WHERE 					
	[First_Attendance] IN ('1','2','3','4')				
	AND [Attendance_Status] IN ('3','7')				

GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX OPFA_noProc metrics XXXX*/
UNION ALL 

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'OPFA_noProc' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]	
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')	
	AND LEFT(Core_HRG,2) = 'WF'

GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'OPFA_noProc' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')	
	AND LEFT(Core_HRG,2) = 'WF'
	
GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX OPFA no proc discharged XXXX*/
	
UNION ALL 

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'OPFA_noProc_disch' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]	
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')	
	AND LEFT(Core_HRG,2) = 'WF'
	AND [Outcome_of_Attendance]  = '1'

GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'OPFA_noProc_disch' AS Metric_Name
	,COUNT(*) AS Metric_Value					
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')	
	AND LEFT(Core_HRG,2) = 'WF'
	AND [Outcome_of_Attendance]  = '1'
	
GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX mean_weeks_to_first metrics XXXX*/
UNION ALL

SELECT 						 					
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'Mean_weeks_to_first' AS Metric_Name
	,SUM(CASE 				
		WHEN (DATEDIFF(week,[Referral_Request_Received_Date],[Appointment_Date])) >156 THEN 156 			
		ELSE (DATEDIFF(week,[Referral_Request_Received_Date],[Appointment_Date])) 			
		END)/COUNT(*) AS Metric_Value				
			
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]	
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')	
	AND [Referral_Request_Received_Date] <> '1900-01-01'
	AND [Referral_Request_Received_Date] IS NOT NULL
	AND LEFT(Core_HRG,2) = 'WF'
	AND [Appointment_Date] >= [Referral_Request_Received_Date]

GROUP BY 
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	   
UNION ALL

SELECT 						
	[STP_Code]
	,Der_Provider_Code
	,'Total' AS [Treatment_Function_Code]
	,'Mean_weeks_to_first' AS Metric_Name
	,SUM(CASE 				
		WHEN (DATEDIFF(week,[Referral_Request_Received_Date],[Appointment_Date])) >156 THEN 156 			
		ELSE (DATEDIFF(week,[Referral_Request_Received_Date],[Appointment_Date])) 			
		END)/COUNT(*) AS Metric_Value				
					
FROM
	[NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_1]
				
WHERE 					
	[First_Attendance] IN ('1','3')				
	AND [Attendance_Status] IN ('5','6')	
	AND [Referral_Request_Received_Date] <> '1900-01-01'
	AND [Referral_Request_Received_Date] IS NOT NULL
	AND LEFT(Core_HRG,2) = 'WF' 
	AND [Appointment_Date] >= [Referral_Request_Received_Date]
	
GROUP BY 
	[STP_Code]
	,Der_Provider_Code

/*XXXX SA Diversions XXXX*/

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'SA_Diversions' AS Metric_Name
	,SUM(Count_of_Requests) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

WHERE 
Status_Code not in ('2','02') 
 AND Outcome_Code in ('10','12')

GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]


UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'SA_Diversions' AS Metric_Name
	,SUM(Count_of_Requests) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

WHERE 
 Status_Code not in ('2','02') 
 AND Outcome_Code in ('10','12')

GROUP BY
	[STP_Code]
	,Der_Provider_Code

/*XXXX SA Processed XXXX*/

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'SA_Processed' AS Metric_Name
	,SUM(Count_of_Requests) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

WHERE 
Status_Code not in ('2','02') 
	AND Outcome_Code not in ('40')


GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]


UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'SA_Processed' AS Metric_Name
	,SUM(Count_of_Requests) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

WHERE 
Status_Code not in ('2','02') 
	AND Outcome_Code not in ('40')

GROUP BY
	[STP_Code]
	,Der_Provider_Code

/*XXXX SA Total XXXX*/

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'SA_Total' AS Metric_Name
	,SUM(Count_of_Requests) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'SA_Total' AS Metric_Name
	,SUM(Count_of_Requests) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_2]

GROUP BY
	[STP_Code]
	,Der_Provider_Code

/*XXXX PIFU Metric XXXX*/
UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'Moved_or_Discharged' AS Metric_Name
	,SUM([Value]) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_3]

GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'Moved_or_Discharged' AS Metric_Name
	,SUM([Value]) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_3]

GROUP BY
	[STP_Code]
	,Der_Provider_Code

/*XXXXX OPFU reduction metrics XXXXX*/
UNION ALL 

SELECT 
	ICS_Code_Provider AS STP_Code
	,(CASE
		WHEN RIGHT(FUR.[Provider_code],2) = '00' THEN LEFT(FUR.[Provider_code],3) 			
		WHEN LEFT(FUR.[Provider_code],3) = 'RXH' THEN 'RYR'
		WHEN LEFT(FUR.[Provider_code],3) = 'RD7' THEN 'RDU'
		ELSE LEFT(FUR.[Provider_code],3) END) AS Der_Provider_Code
	,'Total' as Treatment_Function_Code
	,'OPFU_Reduction' AS Metric_Name
	,CASE 
		WHEN SUM(Activity_WD_Adj)-SUM(Baseline_Activity_WD_Adj) = 0 THEN 0 
		WHEN SUM(Baseline_Activity_WD_Adj) = 0 THEN SUM(Activity_WD_Adj) 
		ELSE (SUM(Activity_WD_Adj)-SUM(Baseline_Activity_WD_Adj))/SUM(Baseline_Activity_WD_Adj)+1 
		END AS Metric_Value

FROM [NHSE_Reference].[dbo].[tbl_Ref_OPA_Follow_Up_Reduction] AS FUR

WHERE 
	1=1 
	AND Region_Code_Provider = 'Y59'
	AND Provider_Type = 'NHS'
	AND Missing_Actuals = 'N'
	AND Der_Activity_Month = @report_period
	AND Acute_Status = 'Acute'

GROUP BY
	ICS_Code_Provider
	,(CASE
		WHEN RIGHT(FUR.[Provider_code],2) = '00' THEN LEFT(FUR.[Provider_code],3) 			
		WHEN LEFT(FUR.[Provider_code],3) = 'RXH' THEN 'RYR'
		WHEN LEFT(FUR.[Provider_code],3) = 'RD7' THEN 'RDU'
		ELSE LEFT(FUR.[Provider_code],3) END)

UNION ALL

SELECT 
	ICS_Code_Provider AS STP_Code
	,(CASE
		WHEN RIGHT(FUR.[Provider_code],2) = '00' THEN LEFT(FUR.[Provider_code],3) 			
		WHEN LEFT(FUR.[Provider_code],3) = 'RXH' THEN 'RYR'
		WHEN LEFT(FUR.[Provider_code],3) = 'RD7' THEN 'RDU'
		ELSE LEFT(FUR.[Provider_code],3) END) AS Der_Provider_Code
	,CASE 
		WHEN CAST(FUR.[TFC] as varchar) IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Paeds'
		ELSE CAST(FUR.[TFC] as varchar) 
		END AS [Treatment_Function_Code]   
	,'OPFU_Reduction' AS Metric_Name
	,CASE 
		WHEN SUM(Activity_WD_Adj)-SUM(Baseline_Activity_WD_Adj) = 0 THEN 0 
		WHEN SUM(Baseline_Activity_WD_Adj) = 0 THEN SUM(Activity_WD_Adj) 
		ELSE (SUM(Activity_WD_Adj)-SUM(Baseline_Activity_WD_Adj))/SUM(Baseline_Activity_WD_Adj)+1 
		END AS Metric_Value

FROM [NHSE_Reference].[dbo].[tbl_Ref_OPA_TFC_Follow_Up_Reduction] AS FUR

WHERE 
	1=1 
	AND Region_Code_Provider = 'Y59'
	AND Provider_Type = 'NHS'
	AND Missing_Actuals = 'N'
	AND Der_Activity_Month = @report_period
	AND Acute_Status = 'Acute'

GROUP BY
	ICS_Code_Provider
	,(CASE
		WHEN RIGHT(FUR.[Provider_code],2) = '00' THEN LEFT(FUR.[Provider_code],3) 			
		WHEN LEFT(FUR.[Provider_code],3) = 'RXH' THEN 'RYR'
		WHEN LEFT(FUR.[Provider_code],3) = 'RD7' THEN 'RDU'
		ELSE LEFT(FUR.[Provider_code],3) END)
	,CASE 
		WHEN CAST(FUR.[TFC] as varchar) IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Paeds'
		ELSE CAST(FUR.[TFC] as varchar) 
		END