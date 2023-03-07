#' Returns the base of the request URL given state name
#'
#' All the functions have been tested most with Victoria- the other states work
#' though, so I've built this to allow querying them too.
#'
#' @param state character, name of state. Currently only accepts Victoria, New
#'   South Wales, and Queensland (and various abbreviations, e.g. NSW, QLD, Vic)
#'
#' @return character URL for the API request
#' @export
#'
#' @examples
get_url <- function(state) {
 if (grepl('vic', state, ignore.case = TRUE)) {
   baseURL <- "https://data.water.vic.gov.au/cgi/webservice.exe?"
 }

  if (grepl('nsw', state, ignore.case = TRUE) |
      grepl('new', state, ignore.case = TRUE) |
      grepl('wales', state, ignore.case = TRUE)) {
    baseURL <- "https://realtimedata.waternsw.com.au/cgi/webservice.exe?"
  }

  if (grepl('q', state, ignore.case = TRUE)) {
    baseURL <- "https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?"
  }

  return(baseURL)
}
