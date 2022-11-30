#' Title
#'
#' @param baseURL
#' @param site_list
#' @param datasource
#' @param var_list
#' @param start_time
#' @param end_time
#' @param interval
#' @param data_type
#' @param multiplier
#' @param returnformat
#'
#' @return
#' @export
#'
#' @importFrom foreach %dopar%
#'
#' @examples
get_ts_traces <- function(baseURL = "https://data.water.vic.gov.au/cgi/webservice.exe?",
                          site_list,
                          datasource = 'A',
                          var_list = c('100', '140'),
                          start_time,
                          end_time,
                          interval = 'day',
                          data_type = 'mean',
                          multiplier = 1,
                          returnformat = 'df') {

  # clean up the start and end times.
  start_time <- fix_times(start_time)
  end_time <- fix_times(end_time)

  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  # this takes a var_list, but can't get derived variables that way. I could use
  # var_list where possible, otherwise varfrom-varto. or just loop over each var
  # as varfrom/to. I think that might have overhead to communicate with the API,
  # but splitting up means creating additional paramlists

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
    paramlist = list("function" = 'get_ts_traces',
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
    response_body <- get_response(baseURL, paramlist)

    # clean up with a function because so ugly
    bodytib <- clean_trace_list(response_body)
  } else {
    bodytib <- tibble(.rows = 0)
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
                   bt <- clean_trace_list(rb)

                 }

  # glue on the derived vars
  bodytib <- bind_rows(bodytib, btd)

  # return
  if (returnformat == 'df') {return(bodytib)}
  if (returnformat == 'varlist') {return(split(bodytib, bodytib$variable))}
  if (returnformat == 'sitelist') {return(split(bodytib, bodytib$site))}
  if (returnformat == 'sxvlist') {
    return(split(bodytib,
                 interaction(bodytib$site,bodytib$variable)))
    }

}


clean_trace_list <- function(responsebody) {
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

  # I guess fail if any fail. I could pass, but do I want to? could remove,
  # warn, and if anything left, pass?
  ts_error_catch(bodytib)

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
    dplyr::mutate(across(c(longitude, latitude, value), as.numeric)) # leaving some others because they either are names (gauges, variable) or display better (precision)

  return(bodytib)
}

get_ts_traces2 <- function(baseURL = "https://data.water.vic.gov.au/cgi/webservice.exe?",
                           site_list,
                           datasource = 'A',
                           var_list = c('100', '140'),
                           start_time,
                           end_time,
                           interval = 'day',
                           data_type = 'mean',
                           multiplier = 1,
                           returnformat = 'df') {

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
                       rb <- get_response(baseURL, pl)

                       # clean up with a function because so ugly
                       bt <- clean_trace_list(rb)

                     }
  # return
  if (returnformat == 'df') {return(bodytib)}
  if (returnformat == 'varlist') {return(split(bodytib, bodytib$variable))}
  if (returnformat == 'sitelist') {return(split(bodytib, bodytib$site))}
  if (returnformat == 'sxvlist') {
    return(split(bodytib,
                 interaction(bodytib$site,bodytib$variable)))
  }


}
