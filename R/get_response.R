#' The actual API call
#'
#' The other functions build the param list and process output. This always goes
#' in the middle to actually hit the API. Exposing it for ad-hoc testing, etc.
#'
#' @param baseURL character URL that the request gets appended to
#' @param api_body_list a list with arguments for a particular call
#' @param .errorhandling intended to allow passing or removing errors. Currently
#'   only implemented in a way that works for [get_ts_traces2()]; see
#'   documentation there.
#'
#' @return the response body as a list
#' @export
#'
get_response <- function(baseURL, api_body_list = NULL,
                         api_query_list = list(nullquery = NULL),
                         .errorhandling = 'stop') {

  # manage HTTP errors, which can kill the `req_perform` itself
  errorfun <- function(resp) {
    if (.errorhandling == 'stop') {httr2::resp_is_error(resp)} else {FALSE}
  }


  # make the request and response
  response_body <- httr2::request(baseURL) |>
    httr2::req_url_query(!!!api_query_list) |>
    httr2::req_body_json(api_body_list) |>
    httr2::req_error(is_error = errorfun) |>
    # httr2::req_retry(is_transient = \(resp) resp_status(resp) %in% c(429, 408, 503)) |>
    httr2::req_perform()

  # more HTTP error management- we only get here with an error if .errorhandling
  # != 'stop' see 'clean_trace_list' for implementation of parsing this in the
  # ds functions. Need to integrate that everywhere
  if (httr2::resp_is_error(response_body)) {
    if (.errorhandling == 'pass') {
      return(paste0('HTTP error number: ',
                    httr2::resp_status(response_body),
                    ' ',
                    httr2::resp_status_desc(response_body)))
    }

    # not well tested how downstream functions take this- it might need to change
    if (.errorhandling == 'remove') {
      return(NULL)
    }
  }


  # The no-HTTP error case gets parsed and checked for API errors
 response_body <- response_body |>
    httr2::resp_body_json(check_type = FALSE)

 # The states (Hydstra) use api_body_list, and return some API errors in the JSON, but BOM
 # has a different JSON structure, so skip if BOM (which uses api_query_list)
 if (!is.null(api_body_list)) {
   response_body <- api_error_catch(response_body, .errorhandling = .errorhandling)
 }

  return(response_body)
}
