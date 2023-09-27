## TO DO: 
# 1) create the tables for the flexdashboard

set.seed(1) #this is just to ensure the random numbers are replicable as the come from the same seed

system <- c(rep('BOB',3),'Frimley',rep('HIOW',4),rep('KM',4),rep('Surrey',3),rep('Sussex',3))
provider <- c('RBH','OUH','BHT','Frimley','IOW','UHS','PHU','HHFT',
              'DGT','MFT','EKH','MTW','RSCH','ASP','SASH','QVH','ESH','UHSX')

metric <- c('SA per 100 OPFA','SA Diversion Rate','Average Wait to OPFA',
            'Discharge after OPFA','New:FU ratio','Moved or Discharged to PIFU','Missed Appointments',
            'OPFU Reduction', 'RTT Pathway Validation')

metric_id <- seq(1:9)

specialities <- c('Cardiology','Dermatology','Gastroenterology','Gynaecology','Neurology','Urology',
                'ENT','Endocrinology','Haematology','Respiratory','Rheumatology','Paediatrics',
                'Total')

sys_prov <- tibble(system,provider)
speciality <- tibble(specialities) %>% 
  rename(speciality = specialities)
sys_prov_spec <- cross_join(sys_prov,speciality)
metrics <- tibble(metric_id,metric)


for (id in metric_id) {
 x <- metrics %>% 
   filter(metric_id == id) %>% 
   select(metric) %>% 
   pull()
 df <- sys_prov_spec
 df$metric_id <- id
 df$metric_name <- x
 assign(paste0('metric_',id),df)
}

rm(df,x,id,metric_id)
#Met1 = Spec advice rate
metric_1$value <- sample(10:40,size = nrow(metric_1),replace=T)
#Met 2 = Spec advice diversion rate
metric_2$value <- sample(10:40,size = nrow(metric_2),replace=T)
#Met 3 = Mean time to 1st
metric_3$value <- runif(nrow(metric_3),5.2,13.0)
#Met 4 = Discharge after 1st
metric_4$value <- sample(14:40,size = nrow(metric_4),replace=T)
#Met 5 = New:FU ratio
metric_5$value <- runif(nrow(metric_5),0.85,3.79)
#Met 6 = PIFU 5%
metric_6$value <- runif(nrow(metric_6),0.013,0.09)
#Met 7 = Missed appts
metric_7$value <- runif(nrow(metric_7),0.03,0.08)
#Met 8 = Performance against 25% target
metric_8$value <- runif(nrow(metric_8),-0.15,0.25)
#Met 9 = % RTT pathways validated in last 12 weeks
metric_9$value <- runif(nrow(metric_9),0.139,0.485)

all_metrics <- rbind(metric_1,metric_2)
all_metrics <- rbind(all_metrics,metric_3)
all_metrics <- rbind(all_metrics,metric_4)
all_metrics <- rbind(all_metrics,metric_5)
all_metrics <- rbind(all_metrics,metric_6)
all_metrics <- rbind(all_metrics,metric_7)
all_metrics <- rbind(all_metrics,metric_8)
all_metrics <- rbind(all_metrics,metric_9)

rm(metric_1,
   metric_2,
   metric_3,
   metric_4,
   metric_5,
   metric_6,
   metric_7,
   metric_8,
   metric_9)


