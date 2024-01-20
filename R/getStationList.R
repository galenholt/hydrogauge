#' getStationList API call to Kisters KiWIS API
#'
#' This is the API used by Australian Bureau of Meteorology and many others. For
#' consistency with similar state functions using Kisters hydllp, I have kept
#' the site_list argument with the same name. Any of the return fields can be
#' searched though, using extra_list. The equivalent state (hydllp) function is
#' [get_db_info()] (to a close approximation).
#'
#' @param baseURL URL to Kisters KiWIS database. Default is Australian BOM,
#'   www.bom.gov.au/waterdata/services, but likely works for other KiWIS
#' @param site_list gauge numbers, as in all other functions. Converted to
#'   `station_no` internally, since that is what BOM uses.
#' @param returnfields default 'all', otherwise comma-separated string of fields
#'   to return
#' @param extra_list a named list of other fields to select on. Names should be
#'   in `returnfields` (or returned when `returnfields = 'all'`), values should
#'   be comma-separated characters, and can contain grep wildcards e.g.
#'   `extra_list = list(station_name = 'RIVER MURRAY*)`
#'
#' @return
#' @export
#'
#' @examples
getStationList <- function(portal,
                           site_list = NULL, returnfields = 'all',
                           extra_list = list(NULL)) {

  baseURL <- get_url(portal)

  # site_list and returnfields need to be a comma separated length-1 vector. Ensure
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  returnfields <- paste(returnfields, sep = ', ', collapse = ', ')


  # bom has different requirements, and they go into the `query`, not the `body`

  api_query_list <- list(service = "kisters",
                         datasource = 0, # presumably there are others, but this is in all the documentation.
                         type = "queryServices", request = "getStationList",
                         kvp = 'true',
                         format = "json",
                         returnfields = returnfields)

  # I seem to assume that there is always a site_list. I guess if not I should
  # bypass? There are other things I could add to the list here, e.g.
  # station_name, station_id. I don't for the states, so keep it consistent for
  # now? That lack of flexibility in other packages though is a reason I'm
  # writing this myself, so maybe I should do better?
  api_query_list$station_no <- site_list

  api_query_list <- modifyList(api_query_list, extra_list)


  # hit the api
  response_body <- get_response(baseURL, api_query_list = api_query_list)

  # Bom structure is simpler
  tibnames <- unlist(response_body[1])

  bodytib <- response_body[-1] |>
    tibble::tibble() |>
    tidyr::unnest_wider(col = 1, names_sep = '_') |>
    setNames(tibnames)

}
