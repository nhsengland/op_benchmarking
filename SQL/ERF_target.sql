declare @report_period as varchar(6)
set @report_period = '202402'

declare @index_value as varchar(7)
set @index_value = '2023/24'

--drop table NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_4
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


--INTO NHSE_Sandbox_South.dbo.OP_Benchmarking_Staging_4

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
                      
       -- which group to a HRG with a price as contained in the 2023/24 national tariff publication (those with £0 as a price are excluded).
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
		