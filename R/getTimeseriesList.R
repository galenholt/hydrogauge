#' Get the list of timeseries available
#'
#' This is the API used by Australian Bureau of Meteorology and many others. For
#' consistency with similar state functions using Kisters hydllp, I have kept
#' the station_no argument with the same name. Any of the return fields can be
#' searched though, using extra_list. The equivalent state (hydllp) function is
#' [get_variable_list()] (to a close approximation).
#' The available return fields (and thus factors that can be filtered) are
#' `'station_name', 'station_no', 'station_id', 'ts_id', 'ts_name', 'ts_path', 'parametertype_id', 'parametertype_name'`, where the `station_no` argument matches `station_no` for consistency across state functions.
#' There is an additional `returnfield` option, `coverage`, which returns the period of record.
#' There may be additional undocumented returnfield options; it appears that most of what is returned by `getStationList` is available, e.g. 'station_latitude'
#'
#'
#' @inheritParams getStationList
#' @param timetype character, one of 'char' (default), 'raw', 'UTC', or 'local'. 'char' and 'raw' both return the Timestamp as it comes from BOM, the others parse into dates.
#'
#' @return A tibble of information about available timeseries
#' @export
#'
getTimeseriesList <- function(portal,
                              station_no = NULL,
                              returnfields = 'default',
                              extra_list = list(NULL),
                              timetype = 'char') {
  baseURL <- parse_url(portal)

  # station_no and returnfields need to be a comma separated length-1 vector. Ensure
  station_no <- paste(station_no, sep = ', ', collapse = ', ')

  if (length(returnfields) == 1 && returnfields == 'all') {
    returnfields <- c('station_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'station_georefsystem', 'station_longname', 'ts_id', 'ts_name', 'ts_shortname', 'ts_path', 'ts_type_id', 'ts_type_name', 'parametertype_id', 'parametertype_name', 'stationparameter_name', 'stationparameter_no', 'stationparameter_longname', 'ts_unitname', 'ts_unitsymbol', 'ts_unitname_abs', 'ts_unitsymbol_abs', 'site_no', 'site_id', 'site_name', 'catchment_no', 'catchment_id', 'catchment_name', 'coverage', 'ts_density', 'ts_exchange', 'ts_spacing', 'ca_site', 'ca_sta', 'ca_par', 'ca_ts')
  }
  if (length(returnfields) == 1 && returnfields == 'default') {
    returnfields <- c('station_name', 'station_no', 'station_id', 'ts_id', 'ts_name', 'ts_unitname', 'ts_unitsymbol', 'ts_path', 'parametertype_id', 'parametertype_name', 'stationparameter_name', 'coverage')
  }

  returnfields <- paste(returnfields, sep = ', ', collapse = ', ')


  # bom has different requirements, and they go into the `query`, not the `body`

  api_query_list <- list(service = "kisters",
                         datasource = 0, # presumably there are others, but this is in all the documentation.
                         type = "queryServices",
                         request = "getTimeseriesList",
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

  # If we have times, parse them if desired
 if (grepl('coverage', returnfields)) {
   # Return the desired times
   # Don't allow more than 1, or it gets confusing
   if (length(timetype) > 1) {
     rlang::warn(c("getTimeseriesList() only accepts one `timetype`",
                   "i" = glue::glue("Defaulting to the first, {timetype[1]}."),
                   "i" = "if you want more, use `parse_bom_times` post-hoc, likely with `'char'` here to make tz parsing work."))
     timetype <- timetype[1]
   }

    bodytib <- bodytib |>
      dplyr::mutate(from = parse_bom_times(from, timetype),
                    to = parse_bom_times(to, timetype))
  }


  return(bodytib)
}
