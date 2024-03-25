#' Fetches timeseries from a table of arguments
#'
#' @param request_table data.frame with columns c('portal', 'gauge', 'start_time', 'end_time', 'variable', 'units', 'timeunit', 'statistic', 'datatype')
#' @param clean whether to clean the output to a standard set of columns, or leave as-returned
#'
#' @return dataframe of timeseries
#' @export
#'
fetch_from_table <- function(request_table,
                             clean = TRUE) {

  if (!all(c('portal', 'gauge', 'start_time', 'end_time', 'variable', 'units', 'timeunit', 'statistic', 'datatype') %in% names(request_table))) {
    rlang::abort(c("Missing columns in `request_table`",
                   "i" = "Requires c('portal', 'gauge', 'start_time', 'end_time', 'variable', 'units', 'timeunit', 'statistic', 'datatype')"))
  }

  # Now we split the table up and call the appropriate function
  portsplit <- split(request_table, request_table$portal)


  # for (i in 1:length(portsplit)) {
  #   ot <- send_to_type(portsplit[[i]])
  # }
  outtib <- purrr::map(portsplit, send_to_type) |>
    purrr::list_rbind()

  return(outtib)

}


#' Make a common request format to either kiwis or hydstra
#'
#' @inheritParams fetch_from_table
#'
#' @return dataframe of timeseries
#' @export
#'
send_to_type <- function(request_table,
                    clean = TRUE) {

  if (all(request_table$portal_type == 'kiwis')) {

    # Still using foreach, though furrr would be better and would let us wrap it all up in a safely.
    # And somehow would be good to manage the parallelisation between here and
    # the inner Hydstra loops. I think here is probably the place to put most
    # of it, since if we're using this function, we only have one variable,
    # etc, and that's what the inner ones loop over.
    ts_out <- foreach::foreach(r = 1:nrow(request_table),
                      .combine = dplyr::bind_rows) %do% {
                        ts <- fetch_kiwis_timeseries(portal = request_table$portal[r],
                                               gauge = request_table$gauge[r],
                                               start_time = request_table$start_time[r],
                                               end_time = request_table$end_time[r],
                                               variable = request_table$variable[r],
                                               units = request_table$units[r],
                                               timeunit = request_table$timeunit[r],
                                               statistic = request_table$statistic[r],
                                               datatype = request_table$datatype[r],
                                               request_timezone = 'db_default',
                                               return_timezone = 'UTC')
                      }

    if (all(request_table$portal == request_table$portal[1])) {
      portal <- request_table$portal[1]
    }

    # Handle everything null too
    if (clean & ncol(ts_out) > 0) {
      ts_out <- ts_out |>
        dplyr::rename(gauge = station_no,
                      name = station_name,
                      variable_name = parametertype_name,
                      units = ts_unitsymbol) |>
        dplyr::mutate(source = portal) |>
        dplyr::select(gauge, name, variable_name, units, value, quality_code, time, database_timezone, source)
    }


  }

  if (all(request_table$portal_type == 'hydstra')) {

    # Still using foreach, though furrr would be better and would let us wrap it all up in a safely.
    # And somehow would be good to manage the parallelisation between here and
    # the inner Hydstra loops. I think here is probably the place to put most
    # of it, since if we're using this function, we only have one variable,
    # etc, and that's what the inner ones loop over.
    ts_out <- foreach::foreach(r = 1:nrow(request_table),
                      .combine = dplyr::bind_rows) %do% {
                       ts <- fetch_hydstra_timeseries(portal = request_table$portal[r],
                                                 gauge = request_table$gauge[r],
                                                 start_time = request_table$start_time[r],
                                                 end_time = request_table$end_time[r],
                                                 variable = request_table$variable[r],
                                                 units = request_table$units[r],
                                                 timeunit = request_table$timeunit[r],
                                                 statistic = request_table$statistic[r],
                                                 datasource = request_table$datatype[r],
                                                 request_timezone = 'db_default',
                                                 return_timezone = 'UTC')
                      }

    if (all(request_table$portal == request_table$portal[1])) {
      portal <- request_table$portal[1]
    }

    if (clean & ncol(ts_out) > 0) {
      ts_out <- ts_out |>
        dplyr::select(-variable_name) |>
        dplyr::rename(gauge = site,
                      name = site_name,
                      quality_code = quality_codes_id) |>
        dplyr::mutate(variable_name = stringr::str_remove_all(variable_short_name, ' \\(.*'),
                      units = stringr::str_remove_all(variable_short_name, '.*\\(|\\)'),
                      source = portal) |>
        dplyr::select(-variable_short_name) |>
        dplyr::select(gauge, name, variable_name, units, value, quality_code, time, database_timezone, source)
    }


  }

  return(ts_out)
}
