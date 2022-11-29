get_variable_list <- function(baseURL = "https://data.water.vic.gov.au/cgi/webservice.exe?",
                              site_list, datasource) {


  paramlist <- list("function" = 'get_variable_list',
                     "version" = "1",
                     "params" = list("site_list" = site_list,
                                     "datasource" = datasource[1])) # have to loop datasources


  # hit the api
  response_body <- get_response(baseURL, paramlist)

  # unpack
  bodytib <- tibble::as_tibble(response_body[2]) |> # the [2] drops the error column
    tidyr::unnest_longer(col = where(is.list)) |> # a `return` list
    tidyr::unnest_wider(col = where(is.list)) |> # sites, and a `datasource` list
    tidyr::unnest_wider(col = site_details) |> # site details in new cols
    tidyr::unnest_longer(col = variables) |> # one line per variable, details of variables in a list
    dplyr::rename(long_name = name) |> # variables have names too, avoid conflicts
    tidyr::unnest_wider(col = variables) |> # columns for each attribute of the variables
    rename(var_name = name) |> # clarify name
    mutate(datasource = datasource[1]) # add a datasource column so we can cross-ref

  # would be good to preallocate, but no idea how big it'll be. I guess just
  # recurse and bind_rows? Could fairly easily just to a purrr::map or furrr::map across datasources? Then at least we'd hit the api in parallel.
  # Leave this for now but it's ugly
  if (length(datasource) > 1) {
    datasource <- datasource[-1]
    bodytib <- dplyr::bind_rows(bodytib, get_variable_list(baseURL, site_list, datasource))
  }

  return(bodytib)
}
