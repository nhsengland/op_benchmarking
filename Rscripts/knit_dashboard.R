## Load libraries
source('Rscripts\\libraries.R')

##load local_functions
source('Rscripts\\local_functions.R')

##load local_colours
source('Rscripts\\local_colours.R')


rmarkdown::render(input = 'parent_main_v4.Rmd',
                  output_file = paste0('SE_OP_Benchmarking_Tool',today(),'.html'),
                  output_dir = 'outputs')


