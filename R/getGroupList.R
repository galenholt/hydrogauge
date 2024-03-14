#' Gets groups in the database
#'
#' Closest hydllp is [get_groups()], neither seem particularly useful.
#' Might make [getStationList()], [getTimeseriesList()] and [getTimeseriesValues()] easier, though not obviously by much.
#' Note that 'the group identifiers are returned as group_id but specified in getStationList, getTimeseriesList, getTimeseriesValues, and getTimeseriesValueLayer as stationgroup_id, parametergroup_id or timeseriesgroup_id' per [docs](https://timeseriesdoc.sepa.org.uk/api-documentation/api-function-reference/principal-query-functions#getGroupList)
#'
#' @inheritParams getStationList
#'
#' @return a tibble
#' @export
#'
getGroupList <- function(portal) {
  baseURL <- parse_url(portal)

  api_query_list <- list(service = "kisters",
                         datasource = 0, # presumably there are others, but this is in all the documentation.
                         type = "queryServices",
                         request = "getGroupList",
                         kvp = 'true',
                         format = "json")

  # hit the api
  response_body <- get_response(baseURL, api_query_list = api_query_list)

  # Bom structure is simpler
  tibnames <- unlist(response_body[1])

  bodytib <- response_body[-1] |>
    tibble::tibble() |>
    tidyr::unnest_wider(col = 1, names_sep = '_') |>
    setNames(tibnames)

  return(bodytib)
}
