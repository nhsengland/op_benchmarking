DECLARE @latest as date
SET @latest = (
SELECT MAX([ReportingDate])
FROM [dbo].[MHSCubeData] as a
	Left outer join [dbo].[provider] as b on a.orgcode=b.code
	left outer join [dbo].[NHSIRegion] as c on b.RegionID = c.ID
	left outer join [dbo].[Measure] as d on a.InternalID = d.InternalID
	left outer join [dbo].MeasureFrequency as e on d.Frequency = e.ID

WHERE 
	(c.Description like 'South East' or a.OrgName = 'South East Region')
	AND d.[Description] LIKE '%Day case and outpatient /% of total procedures (%' ESCAPE '/'
	AND d.[Description] LIKE 'BADS%'
	AND a.[InternalID] LIKE 'BD%'
	AND OrganisationType <> 'Site'
	AND b.STPCode IS NOT NULL
	AND a.Compartment = 'Day cases and outpatient procedures'
	AND a.SubCompartment = 'BADS Overview'
	)


SELECT 
b.STPCode as STP_Code
,a.[OrgCode] as Der_Provider_Code
,'Day Case Rate' AS Metric_Name
,SUBSTRING(a.MetricName,6,CHARINDEX(':',SUBSTRING(a.MetricName,6,len(a.MetricName)))-1) AS BADS_Grouping
,Value AS Metric_Value
,ReportingDate as ReportingDate

FROM [dbo].[MHSCubeData] as a
	Left outer join [dbo].[provider] as b on a.orgcode=b.code
	left outer join [dbo].[NHSIRegion] as c on b.RegionID = c.ID
	left outer join [dbo].[Measure] as d on a.InternalID = d.InternalID
	left outer join [dbo].MeasureFrequency as e on d.Frequency = e.ID

WHERE 
	(c.Description like 'South East' or a.OrgName = 'South East Region')
	AND d.[Description] LIKE '%Day case and outpatient /% of total procedures (%' ESCAPE '/'
	AND d.[Description] LIKE 'BADS%'
	AND a.[InternalID] LIKE 'BD%'
	AND OrganisationType <> 'Site'
	AND b.STPCode IS NOT NULL
	AND a.Compartment = 'Day cases and outpatient procedures'
	AND a.SubCompartment = 'BADS Overview'
	AND ReportingDate = @latest


ORDER BY 
	OrgCode
	,SubCompartment
	,Domain