## TO DO: 
# 1) add the values column to the remaining metric_n dataframes
# 2) rbind the metric_n dataframes into a master dataframe
# 3) create the tables for the flexdashboard



## Load libraries
source('Rscripts\\libraries.R')

set.seed(1) #this is just to ensure the random numbers are replicable as the come from the same seed

system <- c(rep('BOB',3),'Frimley',rep('HIOW',4),rep('KM',4),rep('Surrey',3),rep('Sussex',3))
provider <- c('RBH','OUH','BHT','Frimley','IOW','UHS','PHU','HHFT',
              'DGT','MFT','EKH','MTW','RSCH','ASP','SASH','QVH','ESH','UHSX')

metric <- c('Advice & Guidance - (21%)','Diversion rate (pre & post )','Average wait to 1st (weeks)',
            'D/C after 1st (%)','New:FU ratio','PIFU (5%)','Missed Appointments (DNA/WNB)',
            'Performance against OPFU 25% target', '% of RTT pathways validated in last 12 weeks')

metric_id <- seq(1:9)

speciality <- c('Cardiology','Dermatology','Gastroenterology','Gynaecology','Neurology','Urology',
                'ENT','Endocrinology','Haematology','Respiratory','Rheumatology','Paediatrics',
                'Total')

sys_prov <- tibble(system,provider)
speciality <- tibble(speciality)
sys_prov_spec <- cross_join(sys_prov,speciality)
metrics <- tibble(metric_id,metric)

rm(metric,system,provider)

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

metric_1$value <- sample(40,size = nrow(metric_1),replace=T)