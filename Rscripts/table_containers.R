#to do - add in the provider set of table rows, finish spec container, do metric container
# source: https://rstudio.github.io/DT/

htmltools::withTags(
  table(
    class = 'display',
    thead(
      tr(
        th(rowspan = 2, 'Speciality'),
        th(colspan = 3, 'BOB'),
        th(colspan = 1, 'Frimley'),
        th(colspan = 4, 'HIOW'),
        th(colspan = 4, 'K&M'),
        th(colspan = 3, 'Surrey'),
        th(colspan = 3, 'Sussex')
      ),
      tr()
    )
  )
)



