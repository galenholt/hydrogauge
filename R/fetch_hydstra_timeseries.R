#' Wrapper for Hydstra/hydllp to find and return desired timeseries
#'
#' This wraps [get_variable_list()] and [get_ts_traces()], allowing a bit more
#' automation and a bit more flexibility than [get_ts_traces()], but is
#' currently slower due to more API network overhead. It loops over each
#' distinct site and variable we're asking for, which allows us to tailor the
#' requests a bit more. This approach allows us to do some useful things, though
#' not always at the same time. We can ask for "all" in `var_type`,
#' `start_time`, and `end_time`, and it will query the available data and get
#' what's there. We can also ask for different `data_type` (`statistic` in this
#' function for clarity) for different variables in `var_type`, which is very
#' important, though this cannot happen along with `var_type = "all"`. There are
#' likely speedups we can do to combine some requests, and there is the
#' possibility of future development allowing feeding this a pre-prepared table
#' of arguments.
#'
#' @inheritParams get_ts_traces
#' @inheritParams clean_trace_list
#'
#' @param gauge character vector of gauge numbers, as `site_list` for Hydstra
#'   functions (`station_no` for Kiwis functions)
#' @param var_list as in [get_ts_traces()], but can also take `"all"` to get all
#'   available variables at each site in `site_list`. If 'all', overrides
#'   `variable` and `units`, though using `var_list` with those is always
#'   dangerous.
#' @param variable allows searching by variable name, e.g. 'discharge' with
#'   grepl as in [fetch_kiwis_timeseries()]
#' @param units allows searching by the units of the variable, e.g. 'ML/d' with
#'   grepl as in [fetch_kiwis_timeseries()]
#' @param timeunit same as `interval` in [get_ts_traces()]. Name changed for
#'   consistency and interpretation.
#' @param statistic same as `data_type` in [get_ts_traces()]. Name changed for
#'   consistency and interpretation. Can be a single character or a vector the
#'   same length as `var_list`. If single value, behaves as in
#'   [get_ts_traces()], applying that function to all variables. If a vector, it
#'   applies the given function to the variable in the matching position of
#'   `var_list`. This allows us to ask for many variables that might need
#'   different statistics. *Note*- if `var_list = "all"`, there is no way to
#'   match since the variables are unknown and may change between sits, and so
#'   `statistic` should be a single function.
#' @param start_time as in [get_ts_traces()], but can also take `"all"` to start
#'   at the first timepoint for each variable in `var_list` at each site in
#'   `site_list`
#' @param end_time as in [get_ts_traces()], but can also take `"all"` to end at
#'   the last timepoint for each variable in `var_list` at each site in
#'   `site_list`
#' @param ignore_fromderived logical, default TRUE. Sometimes a derived variable
#'   (140, 141) is *also* available as a var_from, seemingly usually with a
#'   longer historical record. TRUE (the default) ignores that, and uses just
#'   the e.g. var_from = 100, var_to = 140. FALSE returns both sets, e.g. all
#'   records with the derived variable as var_to. If FALSE, *look at the output
#'   carefully, it's often very strange*
#' @param request_timezone ignored if start_time and end_time are time objects,
#'   otherwise a timezone from [OlsonNames()] or 'db_default'
#'
#' @return a tibble of the requested timeseries
#' @export
#'
fetch_hydstra_timeseries <- function(portal,
                                     gauge,
                                     datasource = "A",
                                     var_list = NULL,
                                     variable = NULL,
                                     units = NULL,
                                     timeunit = "day", # point is raw
                                     statistic = "mean",
                                     start_time,
                                     end_time,
                                     multiplier = 1,
                                     ignore_fromderived = TRUE,
                                     returnformat = "df",
                                     request_timezone = "db_default",
                                     return_timezone = "UTC",
                                     .errorhandling = "pass") {
  # get the dataframe of request options In theory we could loop over a vector
  # of portals here, but we'd need to know which gauges belonged to which. That
  # level of logic I think needs to be in an outer wrapper function
  possibles <- find_hydstra_request(
    portal = portal,
    gauge = gauge,
    datasource = datasource,
    var_list = var_list,
    variable = variable,
    units = units,
    statistic = statistic,
    timeunit = timeunit,
    multiplier = multiplier,
    ignore_fromderived = ignore_fromderived
  )

  # bubble the null up
  if (is.null(possibles) || nrow(possibles) == 0) {
    return(NULL)
  }

  # we need to know the timezone of the database
  gaugetz <- lubridate::tz(possibles$period_start)

  # times
  if (is.character(start_time) && start_time == "all") {
    possibles$start_time <- possibles$period_start
  } else {
    possibles$start_time <- request_to_gaugetime(start_time,
                                                 gaugetz, request_timezone)
  }

  if (is.character(end_time) && end_time == "all") {
    possibles$end_time <- possibles$period_end
  } else {
    possibles$end_time <- request_to_gaugetime(end_time,
                                               gaugetz, request_timezone)
  }

  # deal with asking for times across the boundary- clip to the available data.
  possibles <- possibles |>
    dplyr::mutate(
      start_time = dplyr::if_else(.data$start_time < .data$period_start,
                                  .data$period_start, .data$start_time),
      end_time = dplyr::if_else(.data$end_time > .data$period_end,
                                .data$period_end, .data$end_time)
    )

  # If we miss the dates on a single call, it errors. Mimic the silent deletion
  # of the API itself and just throw those out
  record_begins_after_end <- possibles$period_start > possibles$end_time
  record_ends_before_start <- possibles$period_end < possibles$start_time
  misstimes <- record_begins_after_end | record_ends_before_start

  possibles <- possibles[!misstimes, ]

  # This should work to furrr::future_pmap or purrr::pmap, but isn't.
  # # To make the arguments correct
  # p2 <- possibles |>
  #   dplyr::rename(var_list = varto,
  #                 site_list = site) |>
  #   dplyr::mutate(return_timezone = 'UTC',
  #                 returnformat = 'df',
  #                 .errorhandling = .errorhandling) |>
  #   dplyr::select(portal, site_list, datasource,
  #                 var_list, start_time, end_time,
  #                 interval, data_type, multiplier,
  #                 return_timezone,
  #                 returnformat,
  #                 .errorhandling)
  #
  # outtib <- purrr::pmap(p2, get_ts_traces)

  # This is ideally suited to `furrr::pmap` over, but I already depend on
  # foreach, so I guess stick with that.
  # There's obvious space here to do a better job identifying common things that
  # can hit the API together, e.g. a bunch of gauges all asking for the same
  # thing.

  # If there's nothing here, just return NULL. otherwise the loop is messed up
  # because 1:0 is 1,0. Another reason to furrr.
  if (nrow(possibles) == 0) {
    bodytib <- NULL
  } else {
    # CMD CHECK happy
    i <- NULL
    bodytib <- foreach::foreach(
      i = 1:nrow(possibles),
      .combine = dplyr::bind_rows,
      .options.future = list(seed = TRUE)
    ) %dofuture% {
      thisreq <- get_ts_traces(
        portal = possibles$portal[i],
        site_list = possibles$site[i],
        datasource = possibles$datasource[i],
        # This works, but will be double the API calls if we also want the
        # var_from
        var_list = possibles$varto[i],
        start_time = possibles$start_time[i],
        end_time = possibles$end_time[i],
        interval = possibles$interval[i],
        data_type = possibles$data_type[i],
        multiplier = possibles$multiplier[i],
        return_timezone = "UTC",
        returnformat = "df",
        .errorhandling = .errorhandling
      )
      thisreq # make it clear what gets returned each iteration
    }
  }

  if (is.null(bodytib)) {
    rlang::inform("NULL return- likely everything errored and was 'removed' with .errorhandling")
    return(bodytib)
  }


  # sort and rename
  bodytib <- bodytib |>
    dplyr::arrange(.data$site, .data$variable) |>
    dplyr::rename(statistic = "data_type")

  # return
  if (returnformat == "df") {
    return(bodytib)
  }
  if (returnformat == "varlist") {
    return(split(bodytib, bodytib$variable))
  }
  if (returnformat == "sitelist") {
    return(split(bodytib, bodytib$site))
  }
  if (returnformat == "sxvlist") {
    return(split(
      bodytib,
      interaction(bodytib$site, bodytib$variable)
    ))
  }
}
