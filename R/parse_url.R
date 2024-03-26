#' Returns the base of the request URL given state name
#'
#' All the functions have been tested most with Victoria- the other states work
#' though, so I've built this to allow querying them too.
#'
#' @param portal character, URL or name of data portal for some Australian
#'   portals. Currently accepts names for 'vic', 'nsw', 'qld', and 'bom' (case
#'   insensitive).
#'
#' @return character URL for the API request
#' @export
#'
parse_url <- function(portal, test = TRUE, type = FALSE,
                      .errorhandling = 'stop') {

  # Short-circuit if portal isn't there.
  if (is.na(portal)) {
    baseURL <- NA
    portal_type <- NA
    if (type) {
      return(tibble::tibble(baseURL = baseURL, portal_type = portal_type))
    } else {
      return(baseURL)
    }
  }

  # manage HTTP errors, which can kill the `req_perform` itself
  errorfun <- function(resp) {
    if (.errorhandling == 'stop') {httr2::resp_is_error(resp)} else {FALSE}
  }

  portal <- tolower(portal)

  baseURL <- dplyr::case_when(
    # Allow passing in addresses directly
    grepl("http", portal) ~ portal,
    # Some known Australian portals
    portal %in% c("vic", "victoria") ~ "https://data.water.vic.gov.au/cgi/webservice.exe?",
    portal %in% c("nsw", "new south wales", "newsouthwales") ~ "https://realtimedata.waternsw.com.au/cgi/webservice.exe?",
    portal %in% c("qld", "queensland") ~ "https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?",
    # portal %in% c('wa', 'westernaustralia', 'western australia') ~ "https://wir.water.wa.gov.au/cgi/webservice.exe?",
    # portal %in% c('sa', 'southaustralia', 'south australia') ~ "http://www.bom.gov.au/waterdata/services",
    portal %in% c("bom", "bureau") ~ "http://www.bom.gov.au/waterdata/services"
  )

  if (test | type) {
    url_ping <- httr2::request(baseURL) |>
      httr2::req_error(is_error = errorfun) |>
      httr2::req_retry(is_transient = \(resp) httr2::resp_status(resp) %in% c(429, 408, 503),
                       max_tries = 5) |>
      httr2::req_perform()

    url_fail <- url_ping |>
      httr2::resp_is_error()

    if (url_fail) {
      rlang::abort(glue::glue("URL not responding correctly. Check {baseURL} is the correct URL and is live."))
    }

    url_resp <- url_ping |>
      httr2::resp_body_string()

    portal_type <- ifelse(grepl('KiWIS', url_resp, ignore.case = TRUE), 'kiwis',
                          # I don't like this, but hydstra just returns an error about a missing request.
                          ifelse(grepl('missing top-level', url_resp, ignore.case = TRUE), 'hydstra',
                                 NA))
  }


  # more HTTP error management- we only get here with an error if .errorhandling
  # != 'stop' see 'clean_trace_list' for implementation of parsing this in the
  # ds functions. Need to integrate that everywhere
  if (httr2::resp_is_error(url_ping)) {
    if (.errorhandling == 'pass') {
      return(paste0('HTTP error number: ',
                    httr2::resp_status(url_ping),
                    ' ',
                    httr2::resp_status_desc(url_ping)))
    }

    # not well tested how downstream functions take this- it might need to change
    if (.errorhandling == 'remove') {
      return(NULL)
    }
  }

  if (type) {
    return(tibble::tibble(baseURL = baseURL, portal_type = portal_type))
  } else {
    return(baseURL)
  }

}
