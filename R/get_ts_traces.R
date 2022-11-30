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
    list("site_list" = site_list,
         "start_time" = start_time,
         "var_list" = noderiv_list,
         "interval" = interval,
         "datasource" = datasource,
         "end_time" = end_time,
         "data_type" = data_type,
         "multiplier" = multiplier)

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
  bodytib <- tibble::as_tibble(responsebody[2]) %>% # the [2] drops the error column
    tidyr::unnest_longer(col = tidyselect::where(is.list)) %>% # a `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) %>% # complex set of lists
    tidyr::unnest_wider(col = site_details) %>% # columns of info about the site
    dplyr::rename(site_name = name, site_short_name = short_name) %>%
    # there are name conflicts between site and varfrom and varto.
    # and we can drop varfrom
    dplyr::select(-varfrom_details) %>%
    tidyr::unnest_wider(col = varto_details) %>%
    dplyr::rename_with(~(paste0('variable_', .)),
                c(short_name, name))

  # break in here to get the quality codes to match
  qc <- bodytib %>%
    dplyr::select(quality_codes, site, variable) %>%
    tidyr::unnest_longer(col = quality_codes) %>%
    dplyr::mutate(quality_codes_id = as.integer(quality_codes_id))

  # finish unpacking
  bodytib <- bodytib %>%
    dplyr::select(-quality_codes) %>%
    tidyr::unnest_longer(col = trace) %>%
    tidyr::unnest_wider(col = trace)

  # clean up
  bodytib <- bodytib %>%
    dplyr::rename(value = v, time = t, quality_codes_id = q) %>%
    dplyr::mutate(time = lubridate::ymd_hms(time)) %>%
    dplyr::left_join(qc, by = c('quality_codes_id', 'site', 'variable')) %>%
    dplyr::mutate(across(c(longitude, latitude, value), as.numeric)) # leaving some others because they either are names (gauges, variable) or display better (precision)

  return(bodytib)
}
