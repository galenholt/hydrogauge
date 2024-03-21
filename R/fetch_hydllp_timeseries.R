#' Wrapper for hydllp to find and return desired timeseries
#'
#' This wraps [get_variable_list()] and [get_ts_traces()], allowing a bit more automation and a bit
#' more flexibility than [get_ts_traces()], but is currently slower due to more
#' API network overhead. It loops over each distinct site and variable we're
#' asking for, which allows us to tailor the requests a bit more. This approach
#' allows us to do some useful things, though not always at the same time. We
#' can ask for "all" in `var_type`, `start_time`, and `end_time`, and it will
#' query the available data and get what's there. We can also ask for different
#' `data_type` statistics for different variables in `var_type`, which is very
#' important, though this cannot happen along with `var_type = "all"`. There are
#' likely speedups we can do to combine some requests, and there is the
#' possibility of future development allowing feeding this a pre-prepared table
#' of arguments.
#'
#' @inheritParams get_ts_traces
#' @inheritParams clean_trace_list
#' @param var_list as in [get_ts_traces()], but can also take `"all"` to get all
#'   available variables at each site in `site_list`
#' @param start_time as in [get_ts_traces()], but can also take `"all"` to start
#'   at the first timepoint for each variable in `var_list` at each site in
#'   `site_list`
#' @param end_time as in [get_ts_traces()], but can also take `"all"` to end at
#'   the last timepoint for each variable in `var_list` at each site in
#'   `site_list`
#' @param data_type single character or a vector the same length as `var_list`.
#'   If single value, behaves as in [get_ts_traces()], applying that function to
#'   all variables. If a vector, it applies the given function to the variable
#'   in the matching position of `var_list`. This is potentially the most
#'   important use of this function vs. [get_ts_traces()]- it allows us to ask for
#'   many variables that might need different statistics. *Note*- if `var_list =
#'   "all"`, there is no way to match since the variables are unknown and may
#'   change between sits, and so `data_type` should be a single function.
#' @param request_timezone ignored if start_time and end_time are time objects, otherwise a timezone from [OlsonNames()] or 'db_default'


fetch_hydllp_timeseries <- function(portal,
                                    gauge,
                                    datasource = 'A',
                                    var_list = c('100', '140'),
                                    start_time,
                                    end_time,
                                    interval = 'day',
                                    data_type = 'mean',
                                    multiplier = 1,
                                    returnformat = 'df',
                                    request_timezone = 'db_default',
                                    return_timezone = 'UTC',
                                    .errorhandling = 'pass') {
  baseURL <- parse_url(portal)

  if ("all" %in% var_list) {rlang::warn("`var_list = 'all'` is *very* dangerous, since it applies the same `data_type` (that is, aggregation function) to all variables, which is rarely appropriate. Check the variables available for your sites and make sure you want to do this.")}

  # Available variables, start and end times, and sites
  # use 'raw' return_timezone since this passes times around in the state format
  possibles <- get_variable_list(baseURL,
                                 gauge,
                                 datasource,
                                 return_timezone = 'db_default') |> # make it less likely to stuff up times when we ask for them in the same tz
    dplyr::select(site, short_name, variable, var_name, datasource,
                  period_start, period_end) |>
    dplyr::mutate(varfrom = variable, varto = variable)

  # we need to know the timezone of the database
  gaugetz <- lubridate::tz(possibles$period_start)

  # Now, let's use that to populate the params list in a loop over its rows.
  # we need to make some adjustments first though

  # add derived if they exist
  poss140 <- possibles[possibles$variable == '100.00', ]
  poss141 <- poss140
  poss140$varto <- '140.00'
  poss141$varto <- '141.00'
  possibles <- dplyr::bind_rows(possibles, poss140, poss141)


  # Variables
  # dangerous conditional- if all is there anywhere, it trumps everything
  if (!('all' %in% var_list)) {
    # possibles has variables with .00 on the end, var_list might or might not. make it
    var_list <- var_list |>
      stringr::str_remove_all("\\.00") |>
      stringr::str_c(".00")

    # cut to those asked for
    possibles <- possibles[possibles$varto %in% var_list, ]
  } else {
    # just check the length, otherwise leave alone
    if (length(var_list) > 1) {rlang::warn("var_list has more than one entry but contains 'all'. Using 'all'.")}
  }

  # times
  if (start_time == 'all') {
    possibles$start_time <- possibles$period_start
  } else {
    possibles$start_time <- request_to_gaugetime(start_time, gaugetz, request_timezone)
  }

  if (end_time == 'all') {
    possibles$end_time <- possibles$period_end
  } else {
    possibles$end_time <- request_to_gaugetime(end_time, gaugetz, request_timezone)
  }

  # deal with asking for times across the boundary- clip to the available data.
  possibles <- possibles |>
    dplyr::mutate(start_time = dplyr::if_else(start_time < period_start, period_start, start_time),
                  end_time = dplyr::if_else(end_time > period_end, period_end, end_time))

  # If we miss the dates on a single call, it errors. Mimic the silent deletion
  # of the API itself and just throw those out
  record_begins_after_end <- possibles$period_start > possibles$end_time
  record_ends_before_start <- possibles$period_end < possibles$start_time
  misstimes <- record_begins_after_end | record_ends_before_start

  possibles <- possibles[!misstimes, ]



  # functions. If we have an explicit var_list (i.e. types of data to pull, we can have length-matched data_type, i.e aggregation function) If var_list == 'all', we can't match because we don't know the length or order.
  if (length(data_type) == 1) {
    possibles$data_type <- data_type
  } else if (length(data_type) == length(var_list) & length(var_list) != 1) {
    varfun <- tibble::tibble(varto = var_list, data_type)
    possibles <- dplyr::left_join(possibles, varfun, by = 'varto')
  } else {
    rlang::abort("data_type is wrong length. Need to either use one or match the var_list")
  }

  # Add some constants on (which may become variables at some point
  possibles$portal <- portal
  possibles$interval <- interval
  possibles$multiplier <- multiplier

  # This is ideally suited to `furrr::imap` over, but I already depend on foreach, so I guess stick with that.
  # There's obvious space here to do a better job identifying common things that can hit the API together, e.g. a bunch of gauges all asking for the same thing.

  bodytib <- foreach::foreach(i = 1:nrow(possibles),
                              .combine = dplyr::bind_rows) %do% {

                                thisreq <- get_ts_traces(portal = possibles$portal[i],
                                                         site_list = possibles$site[i],
                                                         datasource = possibles$datasource[i],
                                                         var_list = possibles$varto[i], # I think this works, but will be double the API calls if we also want the var_from
                                                         start_time = possibles$start_time[i],
                                                         end_time = possibles$end_time[i],
                                                         interval = possibles$interval[i],
                                                         data_type = possibles$data_type[i],
                                                         multiplier = possibles$multiplier[i],
                                                         return_timezone = 'UTC',
                                                         returnformat = 'df',
                                                         .errorhandling = .errorhandling)

                              }

  if (is.null(bodytib)) {
    rlang::inform("NULL return- likely everything errored and was 'removed' with .errorhandling")
    return(bodytib)
  }


  # sort
  bodytib <- bodytib |>
    dplyr::arrange(site, variable)

  # return
  if (returnformat == 'df') {return(bodytib)}
  if (returnformat == 'varlist') {return(split(bodytib, bodytib$variable))}
  if (returnformat == 'sitelist') {return(split(bodytib, bodytib$site))}
  if (returnformat == 'sxvlist') {
    return(split(bodytib,
                 interaction(bodytib$site,bodytib$variable)))
  }


}

