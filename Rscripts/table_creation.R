
#for speciality pages
spec_data <- all_metrics %>% 
  filter(speciality == 'Total') %>% 
  select(system,
         provider,
         metric_name,
         value) %>% 
  pivot_wider(names_from = metric_name,
              values_from = value)





#for metric pages
metric_data <- all_metrics %>% 
  filter(metric_id == 1) %>% 
  select(speciality,
         system,
         provider,
         value) %>% 
  pivot_wider(names_from = c(speciality),
              values_from = value)






datatable(ex2,
          class = 'cell-border stripe',
          rownames = FALSE,
          colnames = c('Provider','Cardio','Derm','Gastro','Gynae','Neuro','Urology',
            'ENT','Endocrinology','Haematology','Respiratory','Rheumatology','Paeds','Total'),
          options = list(pageLength = nrow(df),
                         paging = FALSE,
                         dom = 'ti')
          )%>% 
  formatRound(c(5,7,8,9),2)




datatable(spec_data,
          class = 'cell-border stripe',
          rownames = FALSE,
          options = list(pageLength = nrow(df),
                         paging = FALSE,
                         dom = 'ti')
) %>% 
  formatRound(c(5,7,8,9),2)


datatable(metric_data,
          class = 'cell-border stripe',
          rownames = FALSE,
          colnames = c('Provider','Cardio','Derm','Gastro','Gynae','Neuro','Urology',
                       'ENT','Endocrinology','Haematology','Respiratory','Rheumatology','Paeds','Total'),
          options = list(pageLength = nrow(df),
                         paging = FALSE,
                         dom = 'ti')
)



