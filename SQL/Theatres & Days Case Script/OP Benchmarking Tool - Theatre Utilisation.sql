DECLARE @latest as date
SET @latest = (
SELECT MAX([ReportingDate])
FROM [dbo].[MHSCubeData] as a
	Left outer join [dbo].[provider] as b on a.orgcode=b.code
	left outer join [dbo].[NHSIRegion] as c on b.RegionID = c.ID
	left outer join [dbo].[Measure] as d on a.InternalID = d.InternalID

WHERE 
    (c.description LIKE 'South East%' OR OrgName = 'South East Region')
    AND a.Compartment LIKE '%theatre%' 
	AND MetricName LIKE 'Capped elective%'
	AND Organisationtype <> 'Site'
    AND b.STPCode IS NOT NULL)

SELECT 
	b.STPCode as STP_Code
	,a.[OrgCode] as Der_Provider_Code
	,'Elective theatre utilisation' AS Metric_Name
	,CASE 
		WHEN CHARINDEX('%',a.MetricName) = len(a.metricname) THEN 'All'
		ELSE SUBSTRING(a.MetricName,41,len(a.MetricName))
		END AS Grouping
	,Value AS Metric_Value
	,ReportingDate as ReportingDate

FROM 
    [dbo].[MHSCubeData] a
	LEFT JOIN [dbo].[Provider] b ON a.OrgCode = b.Code
	LEFT JOIN [dbo].[NHSIRegion] c ON b.RegionID = c.ID
	LEFT JOIN [dbo].[Measure] d ON a.InternalID = d.InternalID

WHERE 
    (c.description LIKE 'South East%' OR OrgName = 'South East Region')
    AND a.Compartment LIKE '%theatre%' 
	AND MetricName LIKE 'Capped elective%'
	AND a.[ReportingDate] = @latest
	AND Organisationtype <> 'Site'
    AND b.STPCode IS NOT NULL
	
ORDER BY 
    STP_Code, 
	a.OrgCode

