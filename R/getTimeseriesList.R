#' Get the list of timeseries available
#'
#' This is the API used by Australian Bureau of Meteorology and many others. For
#' consistency with similar state functions using Kisters Hydstra, I have kept
#' the station_no argument with the same name. Any of the return fields can be
#' searched though, using extra_list. The equivalent state (Hydstra) function is
#' [get_variable_list()] (to a close approximation).
#' The available return fields (and thus factors that can be filtered) are
#' `'station_name', 'station_no', 'station_id', 'ts_id', 'ts_name', 'ts_path', 'parametertype_id', 'parametertype_name'`, where the `station_no` argument matches `station_no` for consistency across state functions.
#' *Important*- There is an additional `returnfield` option, `coverage`, which returns the period of record. It is included by default, but if you limit `returnfields`, you must include it to get the time period.
#' There may be additional undocumented returnfield options; it appears that most of what is returned by `getStationList` is available, e.g. 'station_latitude'
#'
#'
#' @inheritParams getStationList
#' @param extra_list a named list, see [getStationList()], with a special note that here we can include a 'timezone' argument that determines the timezone the API returns in. This is dangerous, since the API ingests dates in its own default timezone and that is inferred from the return in the absence of the ability to extract it. Thus, including a `timezone` in `extra_list` may yield unexpected outcomes when requesting dates. A better option is to use `return_timezone` to adjust the return values. That said, it may be that some databases return gauge-local tzs, which won't be allowed to be concatenated. A solution would be to just work in UTC with `timezone = 'UTC'` in extralist to make all outputs on the same tz.
#' @param return_timezone character in [OlsonNames()] or one of three special cases: `'db_default'`, `'char'` or `'raw'`. Default 'UTC'. If 'db_default', uses the API default. BOM defaults to +10. If `'char'` or `'raw'`, returns the time column as-is from the API (A string in the format `'YYYY-MM-DDTHH:MM:SS+TZ'`)
#'
#' @return A tibble of information about available timeseries.Times are POSIXct in UTC by default.
#' @export
#'
getTimeseriesList <- function(portal,
                              station_no = NULL,
                              returnfields = 'default',
                              extra_list = list(NULL),
                              return_timezone = 'UTC') {
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
                         returnfields = returnfields
                         # timezone = timezone # I had this capacity, but it's likely not needed and gets in the way of discovering the db default tz, which we need for requests.
                         )

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

  # If nothing there, drop it
  if (nrow(bodytib) == 0) {
    return(NULL)
  }

  # If we have times, parse them if desired
 if (grepl('coverage', returnfields)) {

    # Get the db timezone no matter what
   tz <- extract_timezone(bodytib$from)

   # if the tz aren't all the same, going to need to bail out
   if (return_timezone == 'db_default') {
     # This gives either the database timezone tz or UTC if there are multiple
     return_timezone <- multi_tz_check(tz)
   }

    bodytib <- bodytib |>
      dplyr::mutate(from = parse_bom_times(from, return_timezone),
                    to = parse_bom_times(to, return_timezone),
                    database_timezone = tz)
  }


  return(bodytib)
}
