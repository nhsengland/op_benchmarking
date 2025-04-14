SELECT DISTINCT
    b.STPCode AS STP_Code,
    a.OrgCode AS Der_Provider_Code,
	b.OrganisationType,
    a.[InternalID] AS Treatment_Function_Code,
    [MetricName] AS Metric_Name,
    a.Compartment AS Compartment,  
    --SUM([Value]) AS Metric_Value 
	Value
FROM 
    [dbo].[MHSCubeData] a 
LEFT JOIN 
    [dbo].[Provider] b ON a.OrgCode = b.Code
LEFT JOIN 
    [dbo].[NHSIRegion] c ON b.RegionID = c.ID
LEFT JOIN 
    [dbo].[Measure] d ON a.InternalID = d.InternalID
LEFT JOIN 
    [dbo].[MeasureFrequency] e ON d.Frequency = e.ID
WHERE 
    (c.description LIKE 'South East%' OR a.OrgName = 'South East Region')
    AND d.[Description] LIKE '%Day case and outpatient /% of total procedures (%'ESCAPE'/'
  AND d.[Description] LIKE 'BADS%'
  AND a.[InternalID] LIKE 'BD%'
  AND Organisationtype <> 'Site'
    AND 
    a.[ReportingDate] = EOMONTH(GETDATE(), -4)  
		AND 
	b.STPCode IS NOT NULL
	AND
	a.Compartment = 'Day cases and outpatient procedures'
--GROUP BY	
--    b.STPCode, 
--    a.OrgCode,
--    a.[InternalID],
--    [MetricName],
--    a.Compartment,
--	b.Organisationtype
ORDER BY 
    STP_Code, 
	a.OrgCode,
    Treatment_Function_Code ASC;

	