#' The actual API call
#'
#' The other functions build the param list and process output. This always goes
#' in the middle to actually hit the API. Exposing it for ad-hoc testing, etc.
#'
#'
#' @param baseURL character URL that the request gets appended to
#' @param api_body_list a list with arguments for a particular call
#' @param .errorhandling intended to allow passing or removing errors. Currently
#'   only implemented in some places.
#'
#' @return the response body as a list
#' @keywords internal
get_response <- function(baseURL, api_body_list = NULL,
                         api_query_list = list(nullquery = NULL),
                         .errorhandling = 'stop') {

  # manage HTTP errors, which can kill the `req_perform` itself
  errorfun <- function(resp) {
    if (.errorhandling == 'stop') {httr2::resp_is_error(resp)} else {FALSE}
  }


  # make the request and response. Hydstra rate-limit refusals come back as
  # HTTP 200 with an API error in the JSON, so status codes alone don't catch
  # them- see [rate_limit_msg()]
  response_body <- httr2::request(baseURL) |>
    httr2::req_url_query(!!!api_query_list) |>
    httr2::req_body_json(api_body_list) |>
    httr2::req_error(is_error = errorfun) |>
    httr2::req_retry(is_transient = \(resp) httr2::resp_status(resp) %in% c(429, 408, 503) ||
                       !is.null(rate_limit_msg(resp)),
                     after = rate_limit_after,
                     max_tries = 5) |>
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


#' Detect a Hydstra download-rate refusal
#'
#' Hydstra portals refuse requests over the download-rate limit with API error
#' 221 inside an HTTP 200, e.g. `"You have downloaded 0.116845 MBytes in the
#' last 2.0 seconds, effective rate = 210.321 / hour, which is over your limit
#' of 150.0"`. I've only seen 221 used for this, so other rate-limit codes (if
#' they exist) won't get caught.
#'
#' @param resp an httr2 response
#'
#' @return the error message if `resp` is a rate-limit refusal, otherwise `NULL`
#' @keywords internal
rate_limit_msg <- function(resp) {
  # Refusals are a few hundred bytes. Checking size first means we don't parse
  # every multi-MB trace twice.
  if (!httr2::resp_has_body(resp) || length(httr2::resp_body_raw(resp)) > 2000) {
    return(NULL)
  }

  body <- tryCatch(httr2::resp_body_json(resp, check_type = FALSE),
                   error = function(e) NULL)

  # BOM/KiWIS bodies can be unnamed lists, so `$error_num` is just NULL there
  if (!is.list(body) || !identical(as.numeric(body$error_num), 221)) {
    return(NULL)
  }

  return(body$error_msg)
}

#' Seconds to wait before retrying, for [httr2::req_retry()]
#'
#' For a rate-limit refusal, this waits until the downloaded volume reported in
#' the message falls under the limit. Anything else falls back to the
#' `Retry-After` header, and to httr2's exponential backoff if there isn't one.
#'
#' @inheritParams rate_limit_msg
#'
#' @return numeric seconds, or `NA` to use httr2's backoff
#' @keywords internal
rate_limit_after <- function(resp) {
  msg <- rate_limit_msg(resp)
  if (is.null(msg)) {
    return(httr2::resp_retry_after(resp))
  }

  mb <- as.numeric(stringr::str_match(msg, "([0-9.]+)\\s*MBytes")[, 2])
  window <- as.numeric(stringr::str_match(msg, "last\\s+([0-9.]+)\\s*seconds")[, 2])
  limit <- as.numeric(stringr::str_match(msg, "limit of\\s+([0-9.]+)")[, 2])

  # If the message wording changes, let httr2 back off
  if (any(is.na(c(mb, window, limit))) || limit <= 0) {
    return(NA)
  }

  # `mb` over `mb * 3600 / limit` seconds is exactly the limit (MB/hour), and
  # `window` of those seconds have already passed. I *think* the server uses a
  # sliding window, so this should be enough; if it isn't, the next refusal
  # gives updated numbers and we wait again. The 10% and 1 s are headroom.
  wait <- (mb * 3600 / limit) - window
  return(max(wait, 0) * 1.1 + 1)
}
