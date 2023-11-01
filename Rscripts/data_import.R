base_data_noRTT <- read_csv("data/base_data_noRTT.csv",
                                 show_col_types = FALSE)
base_data_RTT <- read_csv("data/base_data_RTT.csv",
                          show_col_types = FALSE)

combined_data <- rbind(base_data_noRTT,
                       base_data_RTT)

rm(base_data_noRTT,
   base_data_RTT)




tfc_list <- read_csv("lookups/tfc_list.csv", 
                     col_types = cols(tfc = col_character()))

provider_names <-read_csv("lookups/provider_short_names.csv",
                          show_col_types = FALSE)

system_names <-read_csv("lookups/system_names.csv",
                          show_col_types = FALSE)