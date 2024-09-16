#' Get Hydstra groups sites belong to.
#'
#' This is not particularly useful, as far as I can tell, but it in theory lets
#' us use various `filter`s in `get_db_info`. The problem is the groups don't
#' seem very useful in practice and it takes forever.
#'
#' @inheritParams get_ts_traces
#'
#' @return a tibble of the sites and datasources present
#' @export
#'
get_groups <- function(portal,
                       site_list) {

  baseURL <- parse_url(portal)
  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  # The json request needs a api_body_list
  api_body_list <- list("function" = 'get_groups',
                    "version" = "1",
                    "params" = list("site_list" = site_list))

  # hit the api
  response_body <- get_response(baseURL, api_body_list)

  # This list structure is strange, and we can't just call $return because the names are sometimes names and sometimes list items.
  returnid <- which(names(response_body) == 'return')
  body_tib <- tibble::as_tibble(response_body[returnid])  |>  # the [2] drops the error column
    tidyr::unnest_wider(col = where(is.list))  |>  # a `return` list
    tidyr::unnest_longer(col = where(is.list))

  return(body_tib)
}
