#' Interface to the getParameterList function
#'
#' It is unclear why this exists, it returns a subset of [getStationList()].
#'
#' @inheritParams getStationList
#'
#' @return a tibble
#' @export
#'
getParameterList <- function(portal,
                             station_no = NULL, returnfields = 'all',
                             extra_list = list(NULL)) {
  baseURL <- parse_url(portal)

  # station_no and returnfields need to be a comma separated length-1 vector. Ensure
  station_no <- paste(station_no, sep = ', ', collapse = ', ')

  if (length(returnfields) == 1 && returnfields == 'all') {
    returnfields <- c('')
  }

  returnfields <- paste(returnfields, sep = ', ', collapse = ', ')


  # bom has different requirements, and they go into the `query`, not the `body`

  api_query_list <- list(service = "kisters",
                         datasource = 0, # presumably there are others, but this is in all the documentation.
                         type = "queryServices",
                         request = "getParameterList",
                         kvp = 'true',
                         format = "json",
                         returnfields = returnfields)

  # I seem to assume that there is always a station_no. I guess if not I should
  # bypass? There are other things I could add to the list here, e.g.
  # station_name, station_id. I don't for the states, so keep it consistent for
  # now? That lack of flexibility in other packages though is a reason I'm
  # writing this myself, so maybe I should do better?
  api_query_list$station_no <- station_no

  api_query_list <- utils::modifyList(api_query_list, extra_list)


  # hit the api
  response_body <- get_response(baseURL, api_query_list = api_query_list)

  # Bom structure is simpler
  tibnames <- unlist(response_body[1])

  bodytib <- response_body[-1] |>
    tibble::tibble() |>
    tidyr::unnest_wider(col = 1, names_sep = '_') |>
    stats::setNames(tibnames)

  return(bodytib)
}
