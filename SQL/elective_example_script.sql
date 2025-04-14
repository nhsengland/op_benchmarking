
SELECT 
	REF.[STP_Code]
	,CASE
		WHEN RIGHT(APC.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 
		WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(APC.Der_Provider_Code,3)
		END as Der_Provider_Code
	,CASE WHEN APC.[Der_Dischg_Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','420','421') THEN 'Paeds'
		WHEN APC.[Der_Dischg_Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN APC.[Der_Dischg_Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
		ELSE APC.[Der_Dischg_Treatment_Function_Code] 
		END AS [Treatment_Function_Code]
	,[Der_Management_Type]
	   	 
INTO [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_5]

FROM
	[NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_APCS] AS APC
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS REF 
		ON (CASE
				WHEN RIGHT(APC.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 			
				WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
				WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
				ELSE LEFT(APC.Der_Provider_Code,3) END) = REF.Organisation_Code

WHERE 					
	[Der_Management_Type] in ('DC','EL')
	AND Der_Financial_Year = @index_value
	AND APC.[Der_Activity_Month] =  @report_period
	AND APC.[Der_Dischg_Treatment_Function_Code] <> '812'	
	AND REF.Region_Code = 'Y59'
	AND Administrative_Category in ('01','1')
	AND REF.NHSE_Organisation_Type IN ('NHS Trust', 'Acute Trust')
	AND REF.Effective_To IS NULL
	
	
	
/*XXX EL Activity metrics XXX*/ 


SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'Daycases' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_5]

WHERE
	Der_Management_Type = 'DC'
	
GROUP BY
	[STP_Code]
	,Der_Provider_Code

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,[Treatment_Function_Code] AS [Treatment_Function_Code]
	,'Daycases' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_5]

WHERE
	Der_Management_Type = 'DC'
	
GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,[Treatment_Function_Code] AS [Treatment_Function_Code]
	,'Total_Elective' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_5]

	
GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'Total_Elective' AS Metric_Name
	,COUNT(*) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_5]

	
GROUP BY
	[STP_Code]
	,Der_Provider_Code