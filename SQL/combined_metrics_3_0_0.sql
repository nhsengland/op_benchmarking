
DECLARE @index_value AS varchar(7)
SET @index_value = '2024/25'

DECLARE @reporting_month as date
set @reporting_month = (SELECT
				MAX(month_of_request)
				FROM 
					[NHSE_Reference].[dbo].[tbl_Ref_System_EROC] AS ERC
					LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS REF 
						ON (CASE							
								WHEN LEFT(ERC.[ReceivingResponding_OrgCode],3) = 'RXH' THEN 'RYR'
								WHEN LEFT(ERC.[ReceivingResponding_OrgCode],3) = 'RD7' THEN 'RDU'
								ELSE LEFT(ERC.[ReceivingResponding_OrgCode],3) END) = REF.Organisation_Code
				WHERE 
					[Latest_Flag] in ( 'Yes','n/a')	
					AND REF.Region_Code = 'Y59'	
					AND REF.NHSE_Organisation_Type IN ('NHS Trust', 'Acute Trust')
					AND REF.Effective_To IS NULL )

DECLARE @report_period as varchar(6)
set @report_period  = (SELECT Concat(CAST(year(@reporting_month) as varchar),CASE WHEN len(CAST(month(@reporting_month) as varchar)) = 1 then concat(0,CAST(month(@reporting_month) as varchar))
								else CAST(month(@reporting_month) as varchar) END))

IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_1', 'U') IS NOT NULL 
  DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_1; 

IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_2', 'U') IS NOT NULL 
  DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_2; 

IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_3', 'U') IS NOT NULL 
  DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_3; 

IF OBJECT_ID('NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_4', 'U') IS NOT NULL 
	DROP TABLE NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_4; 

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
												'290','291','321','420','421') THEN 'Paeds'
		WHEN OPA.[Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN OPA.[Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
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
												'290','291','321','420','421') THEN 'Paeds'
		WHEN ERC.[TFC_Code] IN ('110','111','115') THEN 'T&O'
		WHEN ERC.[TFC_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
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
	,CASE WHEN ERC.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','420','421') THEN 'Paeds'
		WHEN ERC.[Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN ERC.[Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
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

/*XXX Staging 4 XXX*/

/*
With grateful thanks to Destiny Bradley for the script that linked and matched SEM data to the costed tables to replicate the ERF methodology
This may need to change in August when the 2425 tariff and derived data comes into use
*/

SELECT
	STP_Code
	,Der_Provider_Code 
	,Treatment_Function_Code
	,activity_type
	,metric_value

INTO NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_4

FROM (
SELECT 
	STP_Code
	,Der_Provider_Code 
	,Treatment_Function_Code
	,activity_type
	,metric_value

FROM (
----------------------
--- Provider block ---
----------------------

SELECT
	ODS.STP_Code 
	,CASE
		WHEN RIGHT(OPA.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 
		WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(OPA.Der_Provider_Code,3)
		END as Der_Provider_Code
	,CASE WHEN OPA.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','420','421') THEN 'Paeds'
		WHEN OPA.[Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN OPA.[Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
		ELSE OPA.[Treatment_Function_Code] 
		END AS [Treatment_Function_Code]
	,SUM(CASE WHEN OPA.Der_Appointment_Type = 'FUp' THEN 1 ELSE 0 END) AS [ERF_FUP]
	,SUM(CASE WHEN OPA.Der_Appointment_Type = 'New' THEN 1 ELSE 0 END) AS [ERF_New] 


FROM [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA] AS OPA       
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS ODS 
		ON left(OPA.Provider_Code,3) COLLATE DATABASE_DEFAULT = ODS.Organisation_Code COLLATE DATABASE_DEFAULT AND ODS.Effective_To IS NULL
	LEFT OUTER JOIN [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA_2324_Cost] AS Cost ON OPA.OPA_Ident = Cost.OPA_Ident AND OPA.Der_Financial_Year = Cost.Der_Financial_Year                                    
	LEFT OUTER JOIN [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA_2324_Der] AS Der2324 ON OPA.OPA_Ident = Der2324.OPA_Ident AND OPA.Der_Financial_Year = Der2324.Der_Financial_Year                                    
-- Relink to prices to add back in some activity that has been excluded, if used existing Cost.Total_Tariff would exclude any activity with 'Cost_Type' <> Tariff. Prices2021 tables is simply a copy of 2023/24 National Tariff prices as  published.                                   
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_PbR_Tariff_OPA_HRG_2324] AS Prices2324 ON Cost.[HRG_Code_OPP] = Prices2324.[HRG_Code]  
          
-- Activity for private patients, overseas visitors and devolved administrations is excluded. This is based on a field derived from the Commissioner Assignment Method (CAM): Responsible_Purchaser_Assignment_Method not by using Pat commissioner Type
-- Activity for HRGs which do not have an OPROC unit price and are priced as OP attendance are included in the OP attendances calculation zero priced and unbundled activity is excluded. In PAT if you use Coded procedure flag column it might provide different results

WHERE    
	1=1
       -- with a procedure appointment date in that month                                  
       AND Der_Activity_Month = @report_period
	   AND OPA.[Appointment_Date] IS NOT NULL
       AND opa.Der_Financial_Year = @index_value       
	   AND ODS.Region_Code = 'Y59'
	   AND OPA.Der_Provider_Code in ('RPC','RHM','RWF','RYR','RTH','RHW','RXQ','RXC','RTP','RPA','RN5','RHU','RN7','R1F','RVV','RDU','RTK','RA2')
      --  which has been recorded as attended
--Method to identify patients who attended                                    
       AND Der_Attendance_Type = 'Attend'               
              
       -- Method used to exclude overseas patients, private patients and patients from Wales, Scotland, Northern Ireland and Isle of Man (i.e. responsibility of devolved administration)                              
       AND Responsible_Purchaser_Assignment_Method NOT IN ('Reciprocal OSVs', 'Non-reciprocal OSVs', 'Private Patient', 'Devolved Administration')
                                    
       -- Method to exclude maternity pathway activity procedure                                    
       AND [Attend_Core_HRG] NOT LIKE 'NZ%'
                                    
       -- Method to exclude mental health TFCs and Maternity TFCs  and diagnostics                               
       AND OPA.Treatment_Function_Code NOT IN ('812','501','560', '700', '710', '711', '712', '713', '715', '720', '721', '722', '723', '724', '725', '726', '727', '199', '499')       
                             
       -- To Exclude TOPs HRGs                                  
       AND [Attend_Core_HRG] NOT IN ('MA50Z','MA51Z','MA52A','MA52B','MA53Z','MA54Z','MA55A','MA55B','MA56A','MA56B')

-- with any WF subchapter HRG (i.e. includes first attendances that are consultant-led and non-consultant-led, face to face and non-face to face, multi-professional and single professional)    
-- Method to include all activity that is priced like an attendance (includes procedures priced as an attendance)                                    
       AND [Attend_Core_HRG] LIKE 'WF%'            
	   
	   ----AND CASE WHEN Responsible_Purchaser_Assignment_Method IN ('Sub-ICB (Host Mapped)', 'Sub-ICB (Practice Mapped)', 'Sub-ICB (Postcode Mapped)','Sub-ICB (Provider Supplied)') THEN 'ICB Commissioned'                                     
    ----   WHEN Responsible_Purchaser_Assignment_Method IN ('NHSE (Contracted Specialised)', 'NHSE (NCA Specialised)') Then 'Spec Comm'                               
    ----   WHEN Responsible_Purchaser_Assignment_Method IN ('Sub-ICB (Host Mapped) (Delegated Sec Dent)', 'Sub-ICB (Practice Mapped) (Delegated Sec Dent)', 'Sub-ICB (Postcode Mapped) (Delegated Sec Dent)') Then 'Delegated Sec Dent'         
    ----   WHEN Responsible_Purchaser_Assignment_Method = 'NHSE (Secondary Dental)' Then 'Secondary Dental'                                  
    ----   Else 'Other NHSE' End IN ('Delegated Sec Dent','ICB Commissioned','Secondary Dental')
     
                                            
GROUP BY
	ODS.STP_Code 
	,CASE
		WHEN RIGHT(OPA.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 
		WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(OPA.Der_Provider_Code,3)
		END 
	,CASE WHEN OPA.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','420','421') THEN 'Paeds'
		WHEN OPA.[Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN OPA.[Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
		ELSE OPA.[Treatment_Function_Code] 
		END 
	) as W


UNPIVOT
	(metric_value FOR activity_type in ([ERF_FUP], [ERF_New])
	) as U
	

UNION ALL

SELECT 
	ODS.STP_Code
	,CASE
		WHEN RIGHT(OPA.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 
		WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(OPA.Der_Provider_Code,3)
		END as Der_Provider_Code
	,CASE WHEN OPA.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','420','421') THEN 'Paeds'
		WHEN OPA.[Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN OPA.[Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
		ELSE OPA.[Treatment_Function_Code] 
		END AS [Treatment_Function_Code]
	,'ERF_OPPROC' AS activity_type
	,COUNT(Der_Provider_Code) as metric_value

FROM [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA] AS OPA       
	LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] AS ODS 
		ON left(OPA.Provider_Code,3) COLLATE DATABASE_DEFAULT = ODS.Organisation_Code COLLATE DATABASE_DEFAULT AND ODS.Effective_To IS NULL
	LEFT JOIN [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA_2324_Cost] AS Cost ON OPA.OPA_Ident = Cost.OPA_Ident AND OPA.Der_Financial_Year = Cost.Der_Financial_Year                                    
	LEFT JOIN [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SEM_OPA_2324_Der] AS Der2324 ON OPA.OPA_Ident = Der2324.OPA_Ident AND OPA.Der_Financial_Year = Der2324.Der_Financial_Year                                    
-- Relink to prices to add back in some activity that has been excluded, if used existing Cost.Total_Tariff would exclude any activity with 'Cost_Type' <> Tariff. Prices2021 tables is simply a copy of 2023/24 National Tariff prices as  published.                                   
	LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_PbR_Tariff_OPA_HRG_2324] AS Prices2324 ON Cost.[HRG_Code_OPP] = Prices2324.[HRG_Code]            
-- Activity for private patients, overseas visitors and devolved administrations is excluded. This is based on a field derived from the Commissioner Assignment Method (CAM): Responsible_Purchaser_Assignment_Method not by using Pat commissioner Type
-- Activity for HRGs which do not have an OPROC unit price and are priced as OP attendance are included in the OP attendances calculation zero priced and unbundled activity is excluded. In PAT if you use Coded procedure flag column it might provide different results

WHERE    
	1=1
       -- with a procedure appointment date in that month                                  
       AND Der_Activity_Month = @report_period
       AND opa.Der_Financial_Year = @index_value      
	   AND ODS.Region_Code = 'Y59'
		AND OPA.[Appointment_Date] IS NOT NULL
       -- which has been recorded as attended
--Method to identify patients who attended                                    
       AND Der_Attendance_Type = 'Attend'               
	   AND OPA.Der_Provider_Code in ('RPC','RHM','RWF','RYR','RTH','RHW','RXQ','RXC','RTP','RPA','RN5','RHU','RN7','R1F','RVV','RDU','RTK','RA2')
       -- Method used to exclude overseas patients, private patients and patients from Wales, Scotland, Northern Ireland and Isle of Man (i.e. responsibility of devolved administration)                              
       AND Responsible_Purchaser_Assignment_Method NOT IN ('Reciprocal OSVs', 'Non-reciprocal OSVs', 'Private Patient', 'Devolved Administration')
                                    
       -- Method to exclude maternity pathway activity procedure                                    
       AND [Attend_Core_HRG] NOT LIKE 'NZ%'
                                    
       -- Method to exclude mental health TFCs and Maternity TFCs                                
       AND OPA.Treatment_Function_Code NOT IN ('501','560', '700', '710', '711', '712', '713', '715', '720', '721', '722', '723', '724', '725', '726', '727', '199', '499')       
                             
       -- To Exclude TOPs HRGs                                  
       AND Cost.[HRG_Code_OPP] NOT IN ('MA50Z','MA51Z','MA52A','MA52B','MA53Z','MA54Z','MA55A','MA55B','MA56A','MA56B')
                                    
       --Method to include priced OP procedures only, if marked as local priced will still be included                                
       AND Cost.[HRG_Code_OPP] <> 'NULL'         
                      
       -- Method to exclude 'UZ%' HRG where 'Data Invalid for Grouping'                                  
       AND Cost.[HRG_Code_OPP] NOT LIKE 'UZ%'           
                      
       -- which group to a HRG with a price as contained in the 2023/24 national tariff publication (those with  0 as a price are excluded).
-- Exclude zero priced activity                  
       AND Prices2324.OP_Procedure_Tariff > 0    
	   
	   --AND CASE WHEN Responsible_Purchaser_Assignment_Method IN ('Sub-ICB (Host Mapped)', 'Sub-ICB (Practice Mapped)', 'Sub-ICB (Postcode Mapped)','Sub-ICB (Provider Supplied)') THEN 'ICB Commissioned'                                     
    --   WHEN Responsible_Purchaser_Assignment_Method IN ('NHSE (Contracted Specialised)', 'NHSE (NCA Specialised)') Then 'Spec Comm'                               
    --   WHEN Responsible_Purchaser_Assignment_Method IN ('Sub-ICB (Host Mapped) (Delegated Sec Dent)', 'Sub-ICB (Practice Mapped) (Delegated Sec Dent)', 'Sub-ICB (Postcode Mapped) (Delegated Sec Dent)') Then 'Delegated Sec Dent'         
    --   WHEN Responsible_Purchaser_Assignment_Method = 'NHSE (Secondary Dental)' Then 'Secondary Dental'                                  
    --   Else 'Other NHSE' End IN ('Delegated Sec Dent','ICB Commissioned','Secondary Dental')

GROUP BY
	ODS.STP_Code 
	,CASE
		WHEN RIGHT(OPA.Der_Provider_Code,2) = '00' THEN LEFT(der_provider_code,3) 
		WHEN LEFT(der_provider_code,3) = 'RXH' THEN 'RYR'
		WHEN LEFT(der_provider_code,3) = 'RD7' THEN 'RDU'
		ELSE LEFT(OPA.Der_Provider_Code,3)
		END 
	,CASE WHEN OPA.[Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','420','421') THEN 'Paeds'
		WHEN OPA.[Treatment_Function_Code] IN ('110','111','115') THEN 'T&O'
		WHEN OPA.[Treatment_Function_Code] IN ('100','102','104','105','106') THEN 'General Surgery'
		ELSE OPA.[Treatment_Function_Code] 
		END ) as BM4
			   
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

/*XXX OP Capacity Use Metric XXX*/

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'ERF_NOT_FUP' AS Metric_Name
	,SUM([metric_value]) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_4]

WHERE 
	activity_type <> 'ERF_FUP'

GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'ERF_NOT_FUP' AS Metric_Name
	,SUM([metric_value]) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_4]

WHERE 
	activity_type <> 'ERF_FUP'

GROUP BY
	[STP_Code]
	,Der_Provider_Code

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]
	,'ERF_Total' AS Metric_Name
	,SUM([metric_value]) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_4]

GROUP BY
	[STP_Code]
	,Der_Provider_Code
	,[Treatment_Function_Code]

UNION ALL

SELECT
	[STP_Code]
	,Der_Provider_Code
 	,'Total' AS [Treatment_Function_Code]
	,'ERF_Total' AS Metric_Name
	,SUM([metric_value]) AS Metric_Value

FROM [NHSE_Sandbox_South].[dbo].[OP_Benchmarking_Staging_4]

GROUP BY
	[STP_Code]
	,Der_Provider_Code