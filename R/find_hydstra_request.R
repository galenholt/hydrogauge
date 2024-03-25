#' Get a set of requests to make from hydstra
#'
#' Similar to [find_ts_id()] for Kiwis in spirit
#'
#' @inheritParams fetch_hydstra_timeseries
#' @param warnmissing warns if a gauge is missing. TRUE by default, but able to be silenced for programmatic use.
#'
#' @return a tibble, each row of which has the information needed for a Hydstra request
#' @export
find_hydstra_request <- function(portal,
                                 gauge,
                                 datasource = 'A',
                                 var_list = NULL,
                                 variable = NULL,
                                 units = NULL,
                                 statistic = 'mean',
                                 timeunit = 'day', #point is raw
                                 multiplier = 1,
                                 warnmissing = TRUE) {

  if ("all" %in% var_list) {rlang::warn("`var_list = 'all'` is *very* dangerous, since it applies the same `data_type` (that is, aggregation function) to all variables, which is rarely appropriate. Check the variables available for your sites and make sure you want to do this.")}

  if (is.null(var_list) & is.null(variable) & is.null(units)) {
    rlang::abort('no selections have been made. All of `var_list`, `variable` and `units` are NULL.')
  }

  if ((!is.null(variable) | !is.null(units)) & !is.null(var_list)) {
    rlang::warn('Attempting to request data with both `var_list` and the `variable`, `units` combination can yield unexpected results')
  }

  # Available variables, start and end times, and sites
  # use 'db_default' return_timezone since this passes times around in the state format
  hyd_req_tib <- get_variable_list(portal = portal,
                                 site_list = gauge,
                                 datasource = datasource,
                                 return_timezone = 'db_default') |> # make it less likely to stuff up times when we ask for them in the same tz
    dplyr::select(site, short_name, variable, var_name, datasource,
                  period_start, period_end) |>
    dplyr::mutate(varfrom = variable, varto = variable)

  # if null, bail out
  if (nrow(hyd_req_tib) == 0 | all(is.na(hyd_req_tib$varto))) {
    rlang::warn(glue::glue("Gauge(s) {paste0(gauge, collapse = ', ')} do not exist in portal {portal}"))
    return(NULL)
  }

  # If variable is NA, we won't be able to request it, and it's likely because we asked for a gauge that doesn't exist in this portal.
  # I'm tempted to throw a warning, but that will get messy if I rely on this later to toss extra gauges.
  hyd_req_tib <- hyd_req_tib |>
    dplyr::filter(!is.na(variable))

  # add derived if they exist
  poss140 <- hyd_req_tib[hyd_req_tib$variable == '100.00', ]
  poss141 <- poss140
  poss140$varto <- '140.00'
  poss140$var_name <- 'Discharge (cumec)'
  poss141$varto <- '141.00'
  poss141$var_name <- 'Discharge (Ml/d)'
  hyd_req_tib <- dplyr::bind_rows(hyd_req_tib, poss140, poss141)

  # make a units column just like kiwis
  hyd_req_tib <- hyd_req_tib |>
    dplyr::mutate(parametertype_name = stringr::str_remove_all(var_name, ' \\(.*'),
                  ts_unitsymbol = stringr::str_remove_all(var_name, '.*\\(|\\)'))

  # select variables

  # let 'all' trump everything
  if ('all' %in% var_list) {
    # just check the length, otherwise leave alone
    if (length(var_list) > 1) {rlang::warn("var_list has more than one entry but contains 'all'. Using 'all'.")}

    if (!is.null(variable) | !is.null(units)) {
      variable <- NULL
      units <- NULL
      rlang::warn("`'all'` in `var_list`, ignoring `variable` and `units`")
    }
  } else if (!is.null(var_list)) {
    # hyd_req_tib has variables with .00 on the end, var_list might or might not. make it consistent
    var_list <- var_list |>
      stringr::str_remove_all("\\.00") |>
      stringr::str_c(".00")
  }

  # do a variable and unit hunt
  if (!is.null(variable)) {
    # there's a 'variable' column in hyd_req_tib
    variable_search <- paste0(variable, collapse = '|')
    hyd_req_tib <- hyd_req_tib |>
      dplyr::filter(grepl(variable_search, parametertype_name, ignore.case = TRUE))
  }

  if (!is.null(units)) {
    units <- paste0(units, collapse = '|')
    hyd_req_tib <- hyd_req_tib |>
      dplyr::filter(grepl(units, ts_unitsymbol, ignore.case = TRUE))
  }

  if (!is.null(var_list)) {
    hyd_req_tib <- hyd_req_tib[hyd_req_tib$varto %in% var_list, ]
  }



  # functions. If we have an explicit var_list (i.e. types of data to pull, we can have length-matched data_type, i.e aggregation function) If var_list == 'all', we can't match because we don't know the length or order.
  if (length(statistic) == 1) {
    hyd_req_tib$data_type <- statistic
  } else if (length(statistic) == length(var_list) & length(var_list) != 1) {
    varfun <- tibble::tibble(varto = var_list, statistic)
    hyd_req_tib <- dplyr::left_join(hyd_req_tib, varfun, by = 'varto')
  } else {
    rlang::abort("statistic is wrong length. Need to either use one or match the var_list")
  }

  if (nrow(hyd_req_tib) == 0) {
    rlang::warn(c("Filters do not match any timeseries.",
                  "i" = glue::glue("Run `hyd_req_tib <- get_timeseries_list(portal = {portal}, site_list = {gauge}, datasource = {datasource})`"),
                  "and check output manually to find the error."))
  }

  # add the portal on, this allows for looping over portals
  hyd_req_tib$portal <- portal
  # Add some constants on (which may gain length at some point, but are not included above because not part of the searching). Including them here though as this produces the full set of info we need for a request
  hyd_req_tib$interval <- timeunit
  hyd_req_tib$multiplier <- multiplier


  if (warnmissing) {
    missing_gauges <- gauge[!gauge %in% hyd_req_tib$site]

    if (length(missing_gauges > 0)) {
      rlang::warn(c("Not all gauges selected.",
                    glue::glue("missing {paste0(missing_gauges, collapse = '.')}."),
                    "If expected, check arguments."))
    }
  }

  return(hyd_req_tib)


}
