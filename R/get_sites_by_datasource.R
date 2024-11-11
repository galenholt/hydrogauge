#' Gets sites that have a given datasource
#'
#' Useful for getting lists of most sites
#'
#' @inheritParams get_ts_traces
#' @param datasources as in [get_ts_traces()], but can be a vector. As far as I can tell, options are `'A'`, `'TELEM'`, `'TELEMCOPY'`. If multiple, `c('A', 'TELEM')`
#'
#' @return a tibble with sites and datasources
#' @export
#'
#' @examples
#' sxd <- get_sites_by_datasource(portal = 'vic', datasources = c('A', 'TELEM'))
get_sites_by_datasource <- function(portal,
                                    datasources) {

  baseURL <- parse_url(portal)

  # The json request needs a api_body_list
  api_body_list <- list("function" = 'get_sites_by_datasource',
                        "version" = "1",
                        "params" = list("datasources" = datasources))

  # hit the api
  response_body <- get_response(baseURL, api_body_list)


  # unpack the list
  bodytib <- tibble::as_tibble(response_body$return) |> # the [2] drops the error column
    # tidyr::unnest_longer(col = tidyselect::where(is.list)) |> #  `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # site, and a `datasources` list
    tidyr::unnest_longer(col = tidyselect::where(is.list)) # fully unpacked into a long df

  # rename- the plurals are weird and cause issues with datasource x site
  names(bodytib)[names(bodytib) == 'sites'] <- 'site'

  return(bodytib)

}
