/* Treatment function lookup */

SELECT 

CASE WHEN [Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Paeds'
	ELSE [Treatment_Function_Code] END AS [Treatment_Function_Code]
,CASE WHEN [Treatment_Function_Code] IN ('142','171','211','212','213','214','215','216','217','218','219','220',
												'221','222','223','230','240','241','242','250','251','252','253','254',
												'255','256','257','258','259','260','261','262','263','264','270','280',
												'290','291','321','421') THEN 'Combined Paediatric Specialities'
		ELSE SUBSTRING([Treatment_Function_Desc],5,LEN([Treatment_Function_Desc])) 
		END AS Treatment_Function

FROM [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_TreatmentFunction]



	