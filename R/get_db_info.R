#' Access to the get_db_info API call.
#'
#' In development, do not use. turn off the internal keyword once it works.
#'
#' @param portal url as elsewhere
#' @param table_name which table
#' @param station_filter a query somehow
#' @param return_type format of return?
#'
#' @return a dataframe
#' @keywords internal
get_db_info <- function(portal,
                        table_name = "site",
                        station_filter,
                        return_type = "hash") {

  baseURL <- parse_url(portal)

  # The json request needs an api_body_list
  api_body_list <- list("function" = 'get_db_info',
                    "version" = "3",
                    "params" = list("table_name" = table_name,
                                    "return_type" = return_type,
                                    "filter_values" = list("station" = station_filter)))

  # hit the api
  response_body <- get_response(baseURL, api_body_list)

  #unpack
  a <- 1

}
