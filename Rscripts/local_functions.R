calculate_metric <- function(data, metric1, metric2, new_name, multiplier = 1) {
  result <- data %>%
    filter(Metric_Name %in% c(metric1, metric2)) %>%
    pivot_wider(names_from = Metric_Name, 
                values_from = Metric_Value) %>%
    group_by(STP_Code, 
             Der_Provider_Code, 
             Treatment_Function_Code) %>%
    mutate(!!sym(new_name) := (!!sym(metric1) / !!sym(metric2))*multiplier) %>%
    select(!c(metric1, metric2)) %>%
    pivot_longer(cols = new_name,
                 names_to = 'Metric_Name',
                 values_to = 'Metric_Value')
  return(result)
}

#this is used to style the table if the metric is a RAG rated one

RAG_styler_up_good <- function(red_threshold,green_threshold) {formatter("span",
                      style = x ~ formattable::style(display = 'block',
                                                     'text-align' = 'right',
                                                     'border-radius' = '4px',
                                                     padding = "0 4px",
                                                     "background-color" = ifelse(x <= red_threshold, table_red,
                                                                                 ifelse(x >= green_threshold, table_green,
                                                                                        ifelse(is.na(x),"white",highlight))),
                                                     color = ifelse(x <= red_threshold, 'white','black')))}

RAG_styler_up_bad <-function(red_threshold,green_threshold) {formatter("span",
                                 style = x ~ formattable::style(display = 'block',
                                                                'border-radius' = '4px',
                                                                'text-align' = 'right',
                                                                padding = "0 4px",
                                                                "background-color" = ifelse(x >= red_threshold, table_red,
                                                                                            ifelse(x <= green_threshold, table_green,
                                                                                                   ifelse(is.na(x),"white",highlight))),
                                                                color = ifelse(x >= red_threshold, 'white','black')))}


# this takes the existing color_tile function from formatter and adds right alignment to the styling
color_tile_ralign <- function(...) {
  formatter("span",
            style = function(x) formattable::style(
              display = "block",
              padding = "0 4px",
              "text-shadow" = "0px 0px 3px #EEEEEE",
              "border-radius" = "4px",
              'text-align' = 'right',
              "background-color" = csscolor(gradient(as.numeric(x), ...))))
}


cat("local functions loaded")