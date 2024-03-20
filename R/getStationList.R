#' getStationList API call to Kisters KiWIS API
#'
#' This is the API used by Australian Bureau of Meteorology and many others. For
#' consistency with similar state functions using Kisters hydllp, I have kept
#' the station_no argument with the same name. Any of the return fields can be
#' searched though, using extra_list. The equivalent state (hydllp) function is
#' [get_db_info()] (to a close approximation).
#'
#' @param portal URL to Kisters KiWIS database. Default is Australian BOM,
#'   www.bom.gov.au/waterdata/services, but likely works for other KiWIS
#' @param station_no gauge numbers, as `site_list` in the hydllp functions. There are many other fields that can be used to filter and select records, but this seems to be most common and so we give it special treatment. For others, use see `extra_list`
#' @param returnfields default 'default', otherwise 'all' to get everything available, or comma-separated string of fields
#'   to return. Full list for each function available from [Kisters docs](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo)
#' @param extra_list a named list of other fields to select on. Names (usually) should be
#'   in `returnfields` (or returned when `returnfields = 'all'`), though not all work- see the queryfields in the [Kisters docs](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo).
#'   Values should be comma-separated characters, and can contain grep wildcards e.g.
#'   `extra_list = list(station_name = 'RIVER MURRAY*)`. Can also use groups from [getGroupList()], e.g. `extra_list = list(stationgroup_id = '20017550')` gets the MDB_WIP_Watercourse stations.
#'
#' @return a tibble
#' @export
#'
getStationList <- function(portal,
                           station_no = NULL,
                           returnfields = 'default',
                           extra_list = list(NULL)) {

  baseURL <- parse_url(portal)

  # station_no and returnfields need to be a comma separated length-1 vector. Ensure
  station_no <- paste(station_no, sep = ', ', collapse = ', ')

  if (length(returnfields) == 1 && returnfields == 'all') {
    returnfields <- c('station_no', 'station_id', 'station_uuid', 'station_name', 'catchment_no', 'catchment_id', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'site_no', 'site_id', 'site_uuid', 'site_name', 'parametertype_id', 'parametertype_name', 'parametertype_shortname', 'stationparameter_name', 'stationparameter_no', 'stationparameter_id', 'parametertype_longname', 'object_type', 'object_type_shortname', 'station_georefsystem', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'river_id', 'river_name', 'area_id', 'area_name', 'ca_site', 'ca_sta')
  }
  if (length(returnfields) == 1 && returnfields == 'default') {
    returnfields <- c('station_no', 'station_id', 'station_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'site_no', 'site_id', 'site_name', 'parametertype_id', 'parametertype_name', 'parametertype_shortname', 'stationparameter_name', 'stationparameter_no', 'stationparameter_id', 'parametertype_longname', 'object_type', 'object_type_shortname', 'station_georefsystem', 'station_longname')
  }

  returnfields <- paste(returnfields, sep = ', ', collapse = ', ')


  # bom has different requirements, and they go into the `query`, not the `body`

  api_query_list <- list(service = "kisters",
                         datasource = 0, # presumably there are others, but this is in all the documentation.
                         type = "queryServices",
                         request = "getStationList",
                         kvp = 'true',
                         format = "json",
                         returnfields = returnfields)

  # I seem to assume that there is always a station_no. I guess if not I should
  # bypass? There are other things I could add to the list here, e.g.
  # station_name, station_id. I don't for the states, so keep it consistent for
  # now? That lack of flexibility in other packages though is a reason I'm
  # writing this myself, so maybe I should do better?
  api_query_list$station_no <- station_no

  api_query_list <- modifyList(api_query_list, extra_list)


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
