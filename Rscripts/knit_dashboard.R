## Load libraries
source('Rscripts\\libraries.R')

##load local_functions
source('Rscripts\\local_functions.R')

##load local_colours
source('Rscripts\\local_colours.R')


rmarkdown::render(input = 'parent_main_v4.Rmd',
                  output_file = 'SE_OP_Benchmarking_Tool_2023_10_24.html',
                  output_dir = 'outputs')


