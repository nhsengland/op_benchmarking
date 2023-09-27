## Load libraries
source('Rscripts\\libraries.R')

rmarkdown::render(input = 'parent_main.Rmd',
                  output_file = 'draft_benchmarking.html',
                  output_dir = 'outputs')


