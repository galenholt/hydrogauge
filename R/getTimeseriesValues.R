#' Get timeseries from Kiwis (BOM)
#'
#' This expects a `ts_id` or `ts_path` (but not both) to identify the timeseries (>= 1) to pull. `ts_path` can be generated on the fly with wildcards, but isn't straightforward to parse- see the output of [getTimeseriesList()]. Though `ts_id` would need to be extracted from [getTimeseriesList()], and so may not be any easier to get programatically.
#' The equivalent state (hydllp) function is [get_ts_traces()] (to a close approximation).
#' If `period` is used, only one (or none) of `start_time` and `end_time` can be used. If neither is used, it gets the most recent period.
#'
#' Timezone note: BOM documentation says data is returned in local time. This is true on the web interface, but not the API. The API defaults to +10, but we can choose, so here we default to `return_timezone = 'UTC'` for consistency.
#' Further, `start_time` and `end_time` *must* be in database-local time; setting a different return time, either here or directly to the API with a `timezone` argument in `extra_list`, does not affect the interpretation of these times. [getTimeseriesList()] returns the `database_timezone` to make this easier. [fetch_kiwiws_timeseries()] handles some of this work automatically.
#'
#' @inheritParams getTimeseriesList
#'
#' @param ts_id timeseries id, typically found from [getTimeseriesList()]
#' @param ts_path timeseries path, which can be constructed, including wildcards, e.g. `ts_path = '*/A4260505/Water*/*DailyMean'` Gets the daily means for all 'Water' variables at gauge A4260505, which might include Level, Discharge, Temperature, etc..
#' @param start_time character or date or date time for the start *in database default timezone*. Default NULL.
#' @param end_time character or date or date time for the end *in database default timezone*. Default NULL.
#' @param period character, default NULL. The special case 'complete' returns the full set of data. Otherwise, beginning with 'P', followed by numbers and characers indicating timespan, e.g. 'P2W'. See [documentation](https://timeseriesdoc.sepa.org.uk/api-documentation/api-function-reference/specifying-date-and-time/).
#' @param returnfields return fields for the data itself. Default is `c('Timestamp', 'Value', 'Quality Code')`. Full list from [Kisters](from [Kisters docs](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo))
#' @param meta_returnfields return fields about the variable and site. seems to be able to access most of what [getTimeseriesList()] has in its `returnfields`. Full list from [Kisters](from [Kisters docs](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo))
#'
#' @return a tibble of the timeseries values. Times are POSIXct in UTC by default.
#' @export
#'
getTimeseriesValues <- function(portal,
                                ts_id = NULL,
                                ts_path = NULL,
                                start_time = NULL,
                                end_time = NULL,
                                period = NULL,
                                returnfields = 'default',
                                meta_returnfields = 'default',
                                extra_list = list(NULL),
                                return_timezone = 'UTC') {

  # See scottish help- it looks like the ts_path can be constructed in-situ rather than needing to get ts_id from getTimeseriesList
  # though does it matter?

  # check multiple specifications
  # times
  if (!is.null(start_time) & !is.null(end_time) & !is.null(period)) {
    rlang::abort("only two of start_time, end_time, and period can be used.")
    # it does seem to work to just pass one in as null though.
  }

  # Timeseries
  if (!is.null(ts_id) & !is.null(ts_path)) {
    rlang::abort("ts_id and ts_path both specified. Choose one.")
  }

  baseURL <- parse_url(portal)

  # Set defaults. For some reason getting the API default differs between returnfields and meta_returnfields
  if (length(returnfields) == 1 && returnfields == 'default') {
    returnfields <- c('Timestamp', 'Value', 'Quality Code')
  }

  if (length(meta_returnfields) == 1 && meta_returnfields == 'default') {
    meta_returnfields <- ''
  }

  # ts_id and returnfields need to be a comma separated length-1 vector. Ensure
  ts_id <- paste(ts_id, sep = ', ', collapse = ', ')

  returnfields <- paste(returnfields, sep = ',', collapse = ',')
  meta_returnfields <- paste(meta_returnfields, sep = ',', collapse = ',')


  # These times should be character vectors in LOCAL time. hydllp needs a 14
  # digit character vector, this needs dashes and such in the right places, but
  # will take date objects. The problem is those date objects end up in UTC. So
  # instead, parse the 14 digits into the kiwis format
  if (!is.null(start_time)) {
    start_time <- fix_times(start_time, type = 'kiwis')
  }
  if (!is.null(end_time)) {
    end_time <- fix_times(end_time, type = 'kiwis')
  }

  # bom has different requirements, and they go into the `query`, not the `body`
  api_query_list <- list(service = "kisters",
                         datasource = 0, # presumably there are others, but this is in all the documentation.
                         type = "queryServices",
                         request = "getTimeseriesValues",
                         kvp = 'true',
                         format = "json",
                         ts_id = ts_id,
                         ts_path = ts_path,
                         from = start_time,
                         to = end_time,
                         period = period,
                         metadata = 'true',
                         md_returnfields = meta_returnfields,
                         returnfields = returnfields)

  api_query_list <- modifyList(api_query_list, extra_list)

  # hit the api
  response_body <- get_response(baseURL, api_query_list = api_query_list)

  # This has a different structure than the other responses
  # There is one list-item per ts_id. Within that, the metadata each gets one entry, and then the data is inside $data

  # extract the data
  # For a single ts_id, then purrr
  bodytib <- purrr::map(response_body, \(x) clean_bom_timeseries(x, return_timezone)) |>
    purrr::list_rbind()

  bodytib

  return(bodytib)

}

#' Clean the raw output from the BOM getTimeseriesValue call
#'
#' This takes a single list, and so if multiple ts_ids have been extracted, should be looped over, e.g. with [purrr::map()].
#'
#' @param x the response list
#' @param return_timezone character in [OlsonNames()]. Default 'UTC'. If 'db_default', uses the API default. BOM defaults to +10
#'
#' @return a tibble
#' @export
#'
clean_bom_timeseries <- function(x, return_timezone = 'UTC') {
  response_names <- names(x)

  data_names <- x$columns |>
    stringr::str_split_1(",")

  # handle the situation of no data
  if (length(x$data) == 0) {
    numcols <- stringr::str_split(x$columns, ',', simplify = TRUE) |>
      length()

    x$data <- list(as.vector(rep(NA, numcols), mode = 'list'))
  }

  # Getting the col names is annoying
  data_df <- tibble::tibble(variable = response_names, value = x) |>
    tidyr::pivot_wider(names_from = variable, values_from = value) |>
    tidyr::unnest(cols = tidyselect::everything()) |>
    tidyr::unnest_wider(col = data, names_sep = '.')

    names(data_df)[grepl('data.', names(data_df))] <- data_names

  data_df <- data_df |>
    dplyr::select(-rows, -columns)

  # Return the desired times

  # Get the db timezone no matter what
  tz <- extract_timezone(data_df$Timestamp)

  # if the tz aren't all the same, going to need to bail out
  if (return_timezone == 'db_default') {
    # This gives either the database timezone tz or UTC if there are multiple
    return_timezone <- multi_tz_check(tz)
  }

  # do the time parse
  data_df <- data_df |>
    dplyr::mutate(time = parse_bom_times(Timestamp, return_timezone),
                  database_timezone = tz) |>
    dplyr::select(-Timestamp)

  # I'm trying to be as consistent as possible with the underlying API, but some of the column names are causing issues
  names(data_df) <- names(data_df) |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(' ', '_')

  # get_ts_traces() keeps these long, so will do the same here.
  # do I want these to be long (as they come in) or
  # tidyr::pivot_wider(names_from = ts_name, values_from = Value)

  return(data_df)
}
