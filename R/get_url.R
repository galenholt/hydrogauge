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
get_url <- function(portal, test = TRUE) {
  portal <- tolower(portal)

  baseURL <- dplyr::case_when(
    grepl("http", portal) ~ portal,
    portal %in% c("vic", "victoria") ~ "https://data.water.vic.gov.au/cgi/webservice.exe?",
    portal %in% c("nsw", "new south wales", "newsouthwales") ~ "https://realtimedata.waternsw.com.au/cgi/webservice.exe?",
    portal %in% c("qld", "queensland") ~ "https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?",
    # portal %in% c('wa', 'westernaustralia', 'western australia') ~ "https://wir.water.wa.gov.au/cgi/webservice.exe?",
    # portal %in% c('sa', 'southaustralia', 'south australia') ~ "http://www.bom.gov.au/waterdata/services",
    portal %in% c("bom", "bureau") ~ "http://www.bom.gov.au/waterdata/services"
  )

  if (test) {
    url_fail <- httr2::request(baseURL) |>
      httr2::req_perform() |>
      httr2::resp_is_error()

    if (url_fail) {
      rlang::abort(glue::glue("URL not responding correctly. Check {baseURL} is the correct URL and is live."))
    }
  }


  return(baseURL)
}
