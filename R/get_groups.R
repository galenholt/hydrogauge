#' Get Hydstra groups sites belong to.
#'
#' This is not particularly useful, as far as I can tell, but it in theory lets
#' us use various `filter`s in `get_db_info`. The problem is the groups don't
#' seem very useful
#'
#' @inheritParams get_ts_traces
#'
#' @return a tibble of the sites and datasources present
#' @export
#'
#' @examples
get_groups <- function(baseURL = "https://data.water.vic.gov.au/cgi/webservice.exe?",
                       site_list) {
  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  # The json request needs a paramlist
  paramlist <- list("function" = 'get_groups',
                    "version" = "1",
                    "params" = list("site_list" = site_list))

  # hit the api
  response_body <- get_response(baseURL, paramlist)

  body_tib <- as_tibble(response_body[2]) %>% # the [2] drops the error column
    unnest_wider(col = where(is.list)) %>% # a `return` list
    unnest_longer(col = where(is.list))

  return(body_tib)
}
