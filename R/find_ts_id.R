#' Helper to extract ts_id for desired variables from [getTimeseriesList()]
#'
#' @inheritParams fetch_kiwis_timeseries
#'
#' @return a tibble of the matching ts_ids, along with other columns
#' @export
#'
find_ts_id <- function(portal,
                       gauge,
                       variable = "discharge",
                       units = "ML/d",
                       timeunit = "Daily", # AsStored is the raw data
                       statistic = "Mean",
                       datatype = "QaQc",
                       namefilters = NULL,
                       extra_list = list(NULL),
                       return_timezone = "char") {
  # Get the timeseries list
  ts_list <- getTimeseriesList(
    portal = portal,
    station_no = gauge,
    extra_list = extra_list,
    return_timezone = return_timezone
  )

  if (is.null(ts_list)) {
    rlang::warn(glue::glue("Gauge(s) {paste0(gauge, collapse = ', ')} do not exist in portal {portal}"))
    return(NULL)
  }

  # allow 'all' as shorthand for variable and units, where NULL means we don't
  # filter on those values here
  if ("all" %in% variable) {
    variable <- NULL
  }
  if ("all" %in% units) {
    units <- NULL
  }

  # Parse that to get the ts_id(s) we need for getTimeseriesValues

  if (!is.null(variable)) {
    variable <- paste0(variable, collapse = "|")
    ts_list <- ts_list |>
      dplyr::filter(grepl(variable, .data$parametertype_name, ignore.case = TRUE))
  }

  if (!is.null(units)) {
    units <- paste0(units, collapse = "|")
    ts_list <- ts_list |>
      dplyr::filter(grepl(units, .data$ts_unitsymbol, ignore.case = TRUE))
  }

  # We have to pull the datatype, time period, and calculation off out of the
  # name, since I can't find the key to the ts_path
  if (!is.null(datatype)) {
    datatype <- paste0(datatype, collapse = "|")
    ts_list <- ts_list |>
      dplyr::filter(grepl(datatype, .data$ts_name, ignore.case = TRUE))
  }

  if (!is.null(timeunit)) {
    timeunit <- paste0(timeunit, collapse = "|")
    ts_list <- ts_list |>
      dplyr::filter(grepl(timeunit, .data$ts_name, ignore.case = TRUE))
  }

  if (!is.null(statistic)) {
    statistic <- paste0(statistic, collapse = "|")
    ts_list <- ts_list |>
      dplyr::filter(grepl(statistic, .data$ts_name, ignore.case = TRUE))
  }

  # a catchall for other things that might want to filter
  if (!is.null(namefilters)) {
    namefilters <- paste0(namefilters, collapse = "|")
    ts_list <- ts_list |>
      dplyr::filter(grepl(namefilters, .data$ts_name, ignore.case = TRUE))
  }

  if (nrow(ts_list) == 0) {
    rlang::warn(c("Filters do not match any timeseries.",
      "i" = glue::glue("Run `ts_list <- getTimeseriesList(portal = '{portal}', station_no = '{gauge}')`"),
      "and check output manually to find the error.",
      "see argument description for columns filtered on, all done with `grepl(argument, column, ignore.case = TRUE)"
    ))
  }

  return(ts_list)
}
