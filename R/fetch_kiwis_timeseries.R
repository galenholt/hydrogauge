#' Wrapper for Kiwis to find and return desired timeseries
#'
#' Wraps [getTimeseriesList()] (via [find_ts_id()]) and [getTimeseriesValues()]
#' to find the `ts_id` that matches the sort of timeseries we want and go get it
#' (them) For help with the arguments, run `ts_list <- getTimeseriesList(portal
#' = portal, station_no = gauge)` to see the [getTimeseriesList()] output that
#' is parsed to give the `ts_id`. This can be very helpful if you're getting
#' incorrect records or too many or not enough. Each argument below says which
#' column it filters on, using [grepl()] with `ignore.case = TRUE`
#'
#' Note that while each of the filtering arguments `variable`, `units`,
#' `timeunit`, `statistic`, and `datatype` can be vectors, they are not
#' positionally matched. Each is just done as a simple OR, and so for example if
#' you have `variable = 'discharge'`, `units = c('ML/d', 'cumecs')`, and
#' `statistic = c('Mean', 'Min')`, you'll get the mean and min of *both* ML/d
#' and cumecs, not the mean of ML/d and min of cumecs. For more control, run
#' this multiple times with the desired subsets. Further, the use of [grepl()]
#' allows full regex parsing. For example, many gauges have daily values that
#' split at 09:00 or at midnight. Using `datatype = 'QaQc.*09'` gets just the
#' 09:00 versions.
#'
#' @inheritParams getTimeseriesValues
#'
#' @param gauge character vector of gauge numbers, as `station_no` for Kiwis
#'   functions (`site_list` for Hydstra)
#' @param variable character vector of variables we want to extract. Matches on
#'   `parametertype_name`
#' @param units units of the variable, used when there may be > 1 e.g. cumecs,
#'   ML/d for discharge. If NULL, gets all available. Matches to `ts_unitsymbol`
#' @param timeunit The time interval to request, e.g. "Daily", the default. Main
#'   values seem to be 'Daily', 'Monthly', 'Yearly', and 'AsStored' (the raw
#'   data). Matches to part of `ts_name`
#' @param statistic The aggregation statistic, e.g. "Mean", the default. Main
#'   values seem to be 'Mean', 'Max', 'Min', 'Total', though not all are
#'   available for each variable- rainfall tends to use Total, while discharge
#'   tends to use mean, max, min. Matches to part of `ts_name`
#' @param datatype The type of data to return, default 'QaQc'. Some other
#'   options seem to be 'Recieved', 'Harmonised', and 'Obs'. *Note*- 'QaQc'
#'   matches to both 'DMQaQc' and 'PR01QaQc'. In many cases only one is
#'   available, but if you get 2x too much data, check and specify which you
#'   want. Matches to part of `ts_name`
#' @param namefilters character vector giving the ability to match to other
#'   parts of `ts_name` in case those specified in timeunit, statistic, and
#'   datatype aren't sufficient to find the desired `ts_id`. One frequent
#'   occurrence is two Daily datasets that differ in whether they split at 9am
#'   or midnight, in which case you should use either `namefilters = '09HR` or
#'   `namefilters = '24HR`. In some situations, this can be easier than using
#'   regex, e.g.  `datatype = 'QaQc.*09'`
#' @param request_timezone ignored if start_time and end_time are time objects,
#'   otherwise a timezone from [OlsonNames()] or 'db_default'
#'
#' @return a tibble of the requested timeseries
#' @export
#'
fetch_kiwis_timeseries <- function(portal,
                                   gauge = NULL,
                                   start_time = NULL,
                                   end_time = NULL,
                                   period = NULL,
                                   variable = "discharge",
                                   units = "ML/d",
                                   timeunit = "Daily", # AsStored is raw data
                                   statistic = "Mean",
                                   datatype = "QaQc",
                                   namefilters = NULL,
                                   extra_list = list(NULL),
                                   returnfields = "default",
                                   meta_returnfields = "default",
                                   request_timezone = "db_default",
                                   return_timezone = "UTC") {
  if (is.null(gauge) && is.null(unlist(extra_list))) {
    rlang::abort("Need either `gauge` or `extra_list` to not be NULL")
  }

  # Get the ts_ids for the requested variables, gauges, etc
  ts_ids <- find_ts_id(
    portal = portal,
    gauge = gauge,
    variable = variable,
    units = units,
    timeunit = timeunit,
    statistic = statistic,
    datatype = datatype,
    namefilters = namefilters,
    extra_list = extra_list,
    return_timezone = "db_default"
  ) # make it less likely to stuff up times when we ask for them in the same tz

  # bubble the null up
  if (is.null(ts_ids) || nrow(ts_ids) == 0) {
    return(NULL)
  }
  # we need to know the timezone of the database
  gaugetz <- lubridate::tz(ts_ids$from)

  if (!is.null(period) && period == "complete") {
    start_time <- NULL
    end_time <- NULL
  } else {
    if (start_time == "all" & end_time == "all") {
      # can we do this if we have multiple variables with different start times?
      # Does that work for getTimeseriesValues?
      start_time <- NULL
      end_time <- NULL
      period <- "complete"
    } else if (end_time == "all" & start_time != "all") {
      # This can be beyond the end of some ts_ids, the others just get truncated
      end_time <- max(ts_ids$to)
      # ditto. and check get_ts_traces- do I do this there, or in 2? Does this
      # mean I need to loop?
    } else if (end_time != "all" & start_time == "all") {
      start_time <- min(ts_ids$from)
    }
  }


  # use a different set of defaults here than for deeper functions
  if (length(returnfields) == 1 && returnfields == "default") {
    returnfields <- c("Timestamp", "Value", "Quality Code")
  }

  if (length(meta_returnfields) == 1 && meta_returnfields == "default") {
    meta_returnfields <- c("station_no", "station_name", "ts_id", "ts_name",
                           "parametertype_name", "ts_unitsymbol")
  }



  # Put the request times on the gauge timezone
  start_req <- request_to_gaugetime(start_time, gaugetz, request_timezone)
  end_req <- request_to_gaugetime(end_time, gaugetz, request_timezone)

  # Can I check for duplication somehow?
  # We don't need to be as loopy here as with the hydstra, since each record has
  # a unique identifier
  # Though do we want to for safety?

  # Try to avoid over-call errors that say they're triggered at 250,000 records,
  # but actually seem like 120,000 ish
  ts_ids <- ts_ids |> dplyr::mutate(
    days = as.numeric(.data$to - .data$from) + 1,
    sumdays = cumsum(.data$days)
  )

  # This gives a lenght-1 list if the sum is < 120000, otherwise a list of bits
  # each of which is less than 120000
  ts_ids <- ts_ids |>
    dplyr::mutate(chunk = floor(.data$sumdays / 120000)) |>
    dplyr::group_by(.data$chunk) |>
    dplyr::group_split()

  # CMD CHECK happy
  i <- NULL
  timeseries <- foreach::foreach(
    i = ts_ids,
    .combine = dplyr::bind_rows,
    .options.future = list(seed = TRUE)
  ) %dofuture% {
    getTimeseriesValues(
      portal = portal,
      ts_id = i$ts_id,
      start_time = start_req,
      end_time = end_req,
      period = period,
      returnfields = returnfields,
      meta_returnfields = meta_returnfields,
      return_timezone = return_timezone
    )
  }

  # Move to this.
  # timeseries <- furrr::future_map(ts_ids,
  #                               \(x) getTimeseriesValues(portal = portal,
  #                               ts_id = x$ts_id,
  #                               start_time = start_req,
  #                               end_time = end_req,
  #                               period = period,
  #                               returnfields = returnfields,
  #                               meta_returnfields = meta_returnfields,
  #                               return_timezone = return_timezone))
  #
  #
  # timeseries <- dplyr::bind_rows(timeseries)

  return(timeseries)
}
