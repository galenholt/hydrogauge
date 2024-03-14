#' Get timeseries from Kiwis (BOM)
#'
#' This expects a `ts_id` or `ts_path` (but not both) to identify the timeseries (>= 1) to pull. `ts_path` can be generated on the fly with wildcards, but isn't straightforward to parse- see the output of [getTimeseriesList()]. Though `ts_id` would need to be extracted from [getTimeseriesList()], and so may not be any easier to get programatically.
#' The equivalent state (hydllp) function is [get_ts_traces()] (to a close approximation).
#' If `period` is used, only one (or none) of `start_time` and `end_time` can be used. If neither is used, it gets the most recent period.
#'
#' @inheritParams getStationList
#'
#' @param ts_id timeseries id, typically found from [getTimeseriesList()]
#' @param ts_path timeseries path, which can be constructed, including wildcards, e.g. `ts_path = '*/A4260505/Water*/*DailyMean'` Gets the daily means for all 'Water' variables at gauge A4260505, which might include Level, Discharge, Temperature, etc..
#' @param start_time character or date or date time for the start. Default NULL.
#' @param end_time character or date or date time for the end. Default NULL.
#' @param period character, beginning with 'P', followed by numbers and characers indicating timespan, e.g. 'P2W'. See [documentation](https://timeseriesdoc.sepa.org.uk/api-documentation/api-function-reference/specifying-date-and-time/)
#' @param returnfields return fields for the data itself. Default is `c('Timestamp', 'Value', 'Quality Code')`. Full list from [Kisters](from [Kisters docs](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo))
#' @param meta_returnfields return fields about the variable and site. seems to be able to access most of what [getTimeseriesList()] has in its `returnfields`. Full list from [Kisters](from [Kisters docs](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo))
#'
#' @return a tibble of the timeseries values. Times are in UTC.
#' @export
#'
getTimeseriesValues <- function(portal,
                                ts_id = NULL,
                                ts_path = NULL,
                                start_time = NULL,
                                end_time = NULL,
                                period = NULL,
                                returnfields = 'all',
                                meta_returnfields = 'all',
                                extra_list = list(NULL)) {

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


  # SHOULD THE START AND END BE IN UTC OR other? I think but am not positive
  # that they are local, but then I return UTC. need to clean that up. Specify
  # start and end as in get_ts_traces for consistency

  baseURL <- get_url(portal)

  # Set defaults. For some reason getting the API default differs between returnfields and meta_returnfields
  if (length(returnfields) == 1 && returnfields == 'all') {
    returnfields <- c('Timestamp', 'Value', 'Quality Code')
  }

  if (length(meta_returnfields) == 1 && meta_returnfields == 'all') {
    meta_returnfields <- ''
  }

  # ts_id and returnfields need to be a comma separated length-1 vector. Ensure
  ts_id <- paste(ts_id, sep = ', ', collapse = ', ')

  returnfields <- paste(returnfields, sep = ',', collapse = ',')
  meta_returnfields <- paste(meta_returnfields, sep = ',', collapse = ',')


  # This is a bit roundabout, but it lets us be consistent across the kiwis and
  # hydllp functions. hydllp needs a 14 digit character vector, this needs
  # dashes and such in the right places, but will take date objects. So create
  # the 14 string, and then make it a date since the formatting works here
  if (!is.null(start_time)) {
    start_time <- fix_times(start_time) |>
      lubridate::ymd_hms()
  }
  if (!is.null(end_time)) {
    end_time <- fix_times(end_time) |>
      lubridate::ymd_hms()
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
  bodytib <- purrr::map(response_body, clean_bom_timeseries) |>
    purrr::list_rbind()

  bodytib

  return(bodytib)

}

#' Clean the raw output from the BOM getTimeseriesValue call
#'
#' This takes a single list, and so if multiple ts_ids have been extracted, should be looped over, e.g. with [purrr::map()].
#'
#' @param x the response list
#'
#' @return a tibble
#' @export
#'
clean_bom_timeseries <- function(x) {
  response_names <- names(x)

  data_names <- x$columns |>
    stringr::str_split_1(",")

  # Getting the col names is annoying
  data_df <- tibble::tibble(variable = response_names, value = x) |>
    tidyr::pivot_wider(names_from = variable, values_from = value) |>
    tidyr::unnest(cols = tidyselect::everything()) |>
    tidyr::unnest_wider(col = data, names_sep = '.')

    names(data_df)[grepl('data.', names(data_df))] <- data_names

  # return UTC in keeping with getStationList
  data_df <- data_df |>
    dplyr::mutate(Timestamp = lubridate::ymd_hms(Timestamp)) |>
    dplyr::select(-rows, -columns)

  # I'm trying to be as consistent as possible with the underlying API, but some of the column names are causing issues
  names(data_df) <- names(data_df) |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(' ', '_')

  # get_ts_traces() keeps these long, so will do the same here.
  # do I want these to be long (as they come in) or
  # tidyr::pivot_wider(names_from = ts_name, values_from = Value)

  return(data_df)
}
