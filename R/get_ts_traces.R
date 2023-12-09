#' Gets timeseries for sites and variables
#'
#' Takes a list of sites and variables and fetches them. Variables may include
#' derived and base. This is very similar to the underlying API call, and does
#' not do very much automation of finding variables, checking times, etc. If
#' variables are not available for a site or for given times it just silently
#' does not return them. For a more automated (but currently slower) approach,
#' see [get_ts_traces2], which also allows a `.errorhandling` argument.
#'
#'
#' @param state character for the state (partial matching accepted). Assumes Victoria, but other states may work as well, though are untested. Used to get the API URL
#' @param site_list character site code, either a single site code `"sitenumber"`, comma-separated codes in a single string `"sitenumber1, sitenumber2`, or a vector of site codes `c("sitenumber1", "sitenumber2")`
#' @param datasource character for datasource code. To my knowledge, options are `"A"`, `"TELEM"`, `"TELEMCOPY"`. Passing multiple not currently supported.
#' @param var_list character vector of variable codes. Needs to be either single code or vector (`c("code1", "code2")`), *not* a comma-separated string
#' @param start_time character, numeric, or date giving the start time. API expects a 14-digit character `"YYYYMMDDHHIIEE"`, but this will turn numeric or dates into that, and pad zeros if given less than 14 digits, e.g. `20200101` would be padded to give midnight on 1 Jan 2020.
#' @param end_time character, numeric, or date giving the end time. API expects a 14-digit character `"YYYYMMDDHHIIEE"`, but this will turn numeric or dates into that, and pad zeros if given less than 14 digits, e.g. `20200101` would be padded to give midnight on 1 Jan 2020.
#' @param interval character, period to report.
#'  * Options: `"year"`, `"month"`, `"day"`, `"hour"`, `"minute"`, `"second"`. I don't think capitalisation matters.
#' @param data_type character, the statistic to apply. *Warning:* only takes one value, which is applied to all variables. This may not be appropriate. If variables should have different statistics, run `get_ts_traces` multiple times.
#'  * Options: `"mean"`, `"max"`, `"min"`, `"start"`, `"end"`, `"first"`, `"last"`, `"tot"`, `"maxmin"`, `"point"`, `"cum"`. Not all are currently tested.
#' @param multiplier character, interval multiplier. I *think* this allows intervals like 5 days, by passing `interval = 'day'` and `multiplier = 5`. Not tested other than 1 at present.
#' @param returnformat character, one of
#'  * `"df"` returns a tibble
#'  * `"varlist"` returns a list with an separate tibble for each variable (may have multiple sites per tibble)
#'  * `"sitelist"` returns a list with an separate tibble for each site (may have multiple variables per tibble)
#'  * `"sxvlist"` returns a list with an separate tibble for each site x variable combination

#' @return tibble(s) with requested variables at requested sites (where they exist). See `returnformat`, either a tibble or list of tibbles
#' @export
#'
#'
#' @examples
#' simpletrace <- get_ts_traces(site_list = "233217",
#' datasource = 'A',
#' var_list = c('100', '140'),
#' start_time = '20200101', end_time = '20200105',
#' interval = 'day', data_type = 'mean',
#' multiplier = 1, returnformat = 'df')


get_ts_traces <- function(state = "victoria",
                          site_list,
                          datasource = 'A',
                          var_list = c('100', '140'),
                          start_time,
                          end_time,
                          interval = 'day',
                          data_type = 'mean',
                          multiplier = 1,
                          returnformat = 'df') {

  baseURL <- get_url(state)

  # clean up the start and end times.
  start_time <- fix_times(start_time)
  end_time <- fix_times(end_time)

  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  # this takes a var_list, but can't get derived variables that way. I could use
  # var_list where possible, otherwise varfrom-varto. or just loop over each var
  # as varfrom/to. I think that might have overhead to communicate with the API,
  # but splitting up means creating additional api_body_lists

  derived <- c('140', '141')

  # very tempting to just foreach over all values. will need to benchmark

  # clean list without derived
  noderiv_list <- var_list[!(var_list %in% derived)]
  # needs to be a comma separated length-1 vector
  noderiv_list <- paste(noderiv_list, sep = ', ', collapse = ', ')

  # derived list
  deriv_list <- var_list[(var_list %in% derived)]
  # needs to NOT be comma separated, because need to feed one at a time.

  # if only asking for derived, bypass
  if (noderiv_list != "") {
    # build the list for the non-derived
    api_body_list = list("function" = 'get_ts_traces',
                     "version" = "2",
                     "params" = list("site_list" = site_list,
                                     "start_time" = start_time,
                                     "var_list" = noderiv_list,
                                     "interval" = interval,
                                     "datasource" = datasource,
                                     "end_time" = end_time,
                                     "data_type" = data_type,
                                     "multiplier" = multiplier))

    # hit the api
    response_body <- get_response(baseURL, api_body_list)

    # clean up with a function because so ugly
    bodytib <- clean_trace_list(response_body, data_type)

  } else {
    bodytib <- tibble::tibble(.rows = 0)
  }


  # foreach for the derived. Very straightforward to do it for everything. And
  # could package the list-making, responsing, and unpacking in a function and
  # furrr it instead of foreach.
  btd <- foreach::foreach(v = deriv_list,
                 .combine = dplyr::bind_rows) %dopar% {
                   pl = list("function" = 'get_ts_traces',
                             "version" = "2",
                             "params" = list("site_list" = site_list,
                                             "start_time" = start_time,
                                             "varfrom" = "100",
                                             "varto" = v,
                                             "interval" = interval,
                                             "datasource" = datasource,
                                             "end_time" = end_time,
                                             "data_type" = data_type,
                                             "multiplier" = multiplier))


                   # hit the api
                   rb <- get_response(baseURL, pl)

                   # clean up with a function because so ugly
                   bt <- clean_trace_list(rb, data_type)

                 }

  # glue on the derived vars and sort sites together
  bodytib <- dplyr::bind_rows(bodytib, btd) |>
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


#' Cleans ts_trace API list body into tibble
#'
#' @param responsebody response body from the API call to get_ts_traces
#' @param data_type the data_type used to calculate the statistic over the
#'   `interval`, glued on for record
#' @param .errorhandling as in [foreach::foreach()] (but handled in
#'   [api_error_catch()]) Default 'stop'. Made available here primarily to use
#'   'pass' so big requests don't die due to API errors. **Be careful**- those
#'   errors then just get passed and so the data will be missing. Only currently
#'   implemented and working in [get_ts_traces2()]
#' @param gauge character gauge name- allows building an informative error-handled output
#'
#' @return a tibble with the rectangled response
#' @export
#'
clean_trace_list <- function(responsebody, data_type, gauge = NA, .errorhandling = 'stop') {

  # Some error handling
  if (is.character(responsebody) && grepl("error number", responsebody)) {
    errortib <- tibble::tibble(error_num = as.numeric(stringr::str_extract(responsebody, '[0-9]+')),
                               error_msg = responsebody,
                               site = gauge,
                               variable = NA)
    return(errortib)
  }

  if (is.null(responsebody)) {return(responsebody)}

  # unpack the list
  bodytib <- tibble::as_tibble(responsebody[2]) |> # the [2] drops the error column
    tidyr::unnest_longer(col = tidyselect::where(is.list)) |> # a `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # complex set of lists
    tidyr::unnest_wider(col = site_details) |> # columns of info about the site
    dplyr::rename(site_name = name, site_short_name = short_name) |>
    # there are name conflicts between site and varfrom and varto.
    # and we can drop varfrom
    dplyr::select(-varfrom_details) |>
    tidyr::unnest_wider(col = varto_details) |>
    dplyr::rename_with(~(paste0('variable_', .)),
                c(short_name, name))

  # parse errors, as defined by .errorhandling
  errorparser <- ts_error_catch(bodytib, .errorhandling = .errorhandling)

  # if there were errors and errorhandling was pass or remove, send those back
  # out.
  if ((!is.logical(errorparser)) & (.errorhandling == 'pass' | .errorhandling == 'remove')) {
    return(errorparser |>
             dplyr::mutate(across(c(longitude, latitude), as.numeric)))
  }

  # break in here to get the quality codes to match
  qc <- bodytib |>
    dplyr::select(quality_codes, site, variable) |>
    tidyr::unnest_longer(col = quality_codes) |>
    dplyr::mutate(quality_codes_id = as.integer(quality_codes_id))

  # finish unpacking
  bodytib <- bodytib |>
    dplyr::select(-quality_codes) |>
    tidyr::unnest_longer(col = trace) |>
    tidyr::unnest_wider(col = trace)

  # clean up
  bodytib <- bodytib |>
    dplyr::rename(value = v, time = t, quality_codes_id = q) |>
    dplyr::mutate(time = lubridate::ymd_hms(time)) |>
    dplyr::left_join(qc, by = c('quality_codes_id', 'site', 'variable')) |>
    dplyr::mutate(across(c(longitude, latitude, value), as.numeric)) |>   # leaving some others because they either are names (gauges, variable) or display better (precision)
    dplyr::mutate(data_type = data_type) # record the statistic

  return(bodytib)
}

#' Gets timeseries for sites and variables with more automation than
#' `get_ts_traces`
#'
#' This is under development, and offers both a bit more automation and a bit
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


#' @inherit get_ts_traces return
#' @export
#'
#' @examples

get_ts_traces2 <- function(state = "victoria",
                           site_list,
                           datasource = 'A',
                           var_list = c('100', '140'),
                           start_time,
                           end_time,
                           interval = 'day',
                           data_type = 'mean',
                           multiplier = 1,
                           returnformat = 'df',
                           .errorhandling = 'stop') {
  baseURL <- get_url(state)

  if ("all" %in% var_list) {rlang::warn("`var_list = 'all'` is *very* dangerous, since it applies the same `data_type` to all variables, which is rarely appropriate. Check the variables available for your sites and make sure you want to do this.")}

  # Available variables, start and end times, and sites
  possibles <- get_variable_list(baseURL, site_list, datasource) |>
    dplyr::select(site, short_name, variable, var_name, datasource,
                  period_start, period_end) |>
    dplyr::mutate(varfrom = variable, varto = variable)

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
  if (start_time != 'all') {
    possibles$start_time <- fix_times(start_time)
  } else {
    possibles$start_time <- possibles$period_start
  }

  if (end_time != 'all') {
    possibles$end_time <- fix_times(end_time)
  } else {
    possibles$end_time <- possibles$period_end
  }

  # If we miss the dates on a single call, it errors. Mimic the silent deletion
  # of the API itself and just throw those out
  record_begins_after_end <- as.numeric(possibles$period_start) > as.numeric(possibles$end_time)
  record_ends_before_start <- as.numeric(possibles$period_end) < as.numeric(possibles$start_time)
  misstimes <- record_begins_after_end | record_ends_before_start

  possibles <- possibles[!misstimes, ]



  # functions
  if (length(data_type) == 1) {
    possibles$data_type <- data_type
  } else if (length(data_type) == length(var_list) & length(var_list) != 1) {
    varfun <- tibble::tibble(varto = var_list, data_type)
    possibles <- dplyr::left_join(possibles, varfun, by = 'varto')
  } else {
    rlang::abort("data_type is wrong length. Need to either use one or match the var_list")
  }

  # I'm going to write this as loops and then see if I can flatten/function
  bodytib <- foreach::foreach(i = 1:nrow(possibles),
                     .combine = dplyr::bind_rows) %dopar% {

                       pl = list("function" = 'get_ts_traces',
                                 "version" = "2",
                                 "params" = list("site_list" = possibles$site[i],
                                                 "start_time" = possibles$start_time[i],
                                                 "varfrom" = possibles$varfrom[i],
                                                 "varto" = possibles$varto[i],
                                                 "interval" = interval,
                                                 "datasource" = datasource,
                                                 "end_time" = possibles$end_time[i],
                                                 "data_type" = possibles$data_type[i],
                                                 "multiplier" = multiplier))


                       # hit the api
                       rb <- get_response(baseURL, pl, .errorhandling = .errorhandling)

                       # clean up with a function because so ugly
                       bt <- clean_trace_list(rb,
                                              data_type = possibles$data_type[i],
                                              gauge = possibles$site,
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
