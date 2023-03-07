get_db_info <- function(state = "victoria",
                        table_name = "site",
                        station_filter,
                        return_type = "hash") {

  baseURL <- get_url(state)

  # The json request needs a paramlist
  paramlist <- list("function" = 'get_db_info',
                    "version" = "3",
                    "params" = list("table_name" = table_name,
                                    "return_type" = return_type,
                                    "filter_values" = list("station" = station_filter)))

  # hit the api
  response_body <- get_response(baseURL, paramlist)

  #unpack
  a <- 1

}