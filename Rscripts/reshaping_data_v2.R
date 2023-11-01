
source('Rscripts\\data_import.R')


#delete this later it's just for prepping data
#unique(combined_data$Metric_Name)

#Creating a list of the specialities people are interested in

specialities <- as.list(c('100','101','110','120','130','301','302','303','320',
                          '330','340','400','410','502','Paeds','Total'))

#limiting the data to just that list

trimmed_data <- combined_data %>% 
  filter(Treatment_Function_Code %in% specialities)

## creating all_metrics dataframe 

## step 1: basic dataframe with a single metric (SA per 100 in this case)
all_metrics <- trimmed_data %>% 
  calculate_metric('SA_Processed','OPFA_Count','SA per 100 OPFA',100)

## step 2: bind in the next metric
all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       calculate_metric('SA_Diversions','SA_Total','SA Diversion Rate',100))

## step 3: repeat until complete 
all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       filter(Metric_Name == 'Mean_weeks_to_first') %>% 
                       mutate(Metric_Name = 'Mean weeks to first'))

all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       calculate_metric('OPFA_noProc_disch','OPFA_noProc','Discharge after OPFA'))

all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       calculate_metric('OPFU_Count','OPFA_Count','New FU Ratio'))

all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       calculate_metric('Moved_or_Discharged','OP_All_Count','Moved Discharged PIFU'))

all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       calculate_metric('DNA_Count','OP_All_Count','Missed Appointments'))

all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       calculate_metric('validated_pathways','open_pathways','validated last 12 weeks'))

all_metrics <- rbind(all_metrics,
                     trimmed_data %>% 
                       filter(Metric_Name == 'OPFU_Reduction') %>% 
                       mutate(Metric_Name = 'OPFU Reduction'))

all_metrics <- all_metrics %>% 
  ungroup()


all_metrics <- left_join(x = all_metrics,
                         y = provider_names,
                         by = c('Der_Provider_Code' = 'Provider_Code')) %>% 
  select(!c(stp_code,
            acute_full_name,
            Der_Provider_Code,
            STP_Code)) %>% 
  rename(c(provider = Provider_Short_Name,
           system = stp_short_name))


all_metrics <- left_join(x = all_metrics,
                         y = tfc_list,
                         by = c("Treatment_Function_Code" = "tfc")) %>% 
  select(system,
         provider,
         Treatment_Function_Code,
         tfc_short_name,
         Metric_Name,
         Metric_Value) %>% 
  rename(c(speciality = tfc_short_name,
           value = Metric_Value,
           metric_name = Metric_Name))
  


