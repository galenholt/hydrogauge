#' The actual API call
#'
#' The other functions build the param list and process output. This always goes
#' in the middle to actually hit the API.
#'
#' @param baseURL character URL that the request gets appended to
#' @param params a list with arguments for a particular call
#'
#' @return
#' @export
#'
#' @examples
get_response <- function(baseURL, paramlist) {
  # make the request and response
  response_body <- httr2::request(baseURL) |>
    httr2::req_body_json(paramlist) |>
    httr2::req_perform() |>
    httr2::resp_body_json(check_type = FALSE)

  return(response_body)
}
