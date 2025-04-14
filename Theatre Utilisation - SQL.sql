SELECT
    b.STPCode,
    CASE
        WHEN orgtype LIKE '%(Site)%' THEN 'Site'
        WHEN orgtype LIKE '%ICB%' THEN 'ICB'
        WHEN orgtype LIKE '%Region%' THEN 'Region'
        ELSE 'Provider'
    END AS Der_Provider_Code,
    a.[InternalID] AS Treatment_Function_Code,
    [MetricName] AS Metric_Name,
    SUM([Value]) AS Metric_Value
FROM [dbo].[MHSCubeData] a
LEFT JOIN [dbo].[Provider] b ON a.OrgCode = b.Code
LEFT JOIN [dbo].[NHSIRegion] c ON b.RegionID = c.ID
LEFT JOIN [dbo].[Measure] d ON a.InternalID = d.InternalID -- Join to measure table to get frequency code
LEFT JOIN [dbo].[MeasureFrequency] e ON d.Frequency = e.ID -- Map frequency codes to frequency descriptions
WHERE (
        (c.description LIKE 'South East%') 
        OR (OrgName = 'South East Region')
    )
    AND (
        (a.Compartment LIKE '%theatre%' 
            AND a.SubCompartment LIKE 'Theatre Util%' 
            AND a.[InternalID] = 'TH0158' 
            AND a.[ReportingDate] BETWEEN DATEADD(M, DATEDIFF(M, 0, GETDATE()) - 5, 0) AND GETDATE()
        ) 
        OR (
            a.[InternalID] = 'DC0001' 
            AND a.[ReportingDate] BETWEEN DATEADD(M, DATEDIFF(M, 0, GETDATE()) - 11, 0) AND GETDATE()
        )
    )
GROUP BY
    b.STPCode,
    CASE
        WHEN orgtype LIKE '%(Site)%' THEN 'Site'
        WHEN orgtype LIKE '%ICB%' THEN 'ICB'
        WHEN orgtype LIKE '%Region%' THEN 'Region'
        ELSE 'Provider'
    END,
    a.[InternalID],
    [MetricName]
ORDER BY 
    b.STPCode, 
    a.[InternalID] ASC;
