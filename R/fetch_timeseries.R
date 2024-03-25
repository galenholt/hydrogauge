#' Fetch timeseries across formats
#'
#' Experimental, accepts single variable for now (one type of timeseries).
#' Handles gauges and portals in different ways, which are not fully developed.
#' Mostly a lot of translating between hydstra and kiwis to allow symmetric specification.
#'
#' @inheritParams fetch_kiwis_timeseries
#'
#' @param datatype as in [fetch_kiwis_timeseries()], or the `datasource` argument for hydstra, e.g. [fetch_hydstra_timeseries()]
#' @param portal_type I want to either be able to pass this a vector of length `portal` or 'auto'
#' @param gauge_portal I want to either be able to pass this a named list of length `portal` or a tibble with `portal` and `gauge` columns, or 'auto' to do our best at auto-detecting.
#' @param check_output logical, default TRUE- inform if there are duplicated gauges across portals or missing gauges
#' @return timeseries dataframe
#' @export
#'
fetch_timeseries <- function(portal,
                 gauge,
                 start_time,
                 end_time,
                 variable,
                 units,
                 timeunit,
                 statistic,
                 datatype,
                 portal_type = 'auto',
                 gauge_portal = 'auto',
                 request_timezone = 'db_default',
                 return_timezone = 'UTC',
                 robustness = 'robust',
                 check_output = TRUE) {



  # I'm not actually convinced this is that good of a plan. It's a lot of API calls and such to get here. But maybe.
  portal_tib <- build_request_table(portal = portal,
                                    gauge = gauge,
                                    start_time = start_time,
                                    end_time = end_time,
                                    variable = variable,
                                    units = units,
                                    timeunit = timeunit,
                                    statistic = statistic,
                                    datatype = datatype,
                                    portal_type = portal_type,
                                    gauge_portal = gauge_portal,
                                    robustness = 'robust')
  # however this goes, the above needs to be a 'find_call_table' or something

  all_out <- fetch_from_table(portal_tib)

  if (check_output) {

    # handle all empty
    if (nrow(all_out) > 0) {
      gaugedoubles <- all_out |>
        dplyr::reframe(n_sources = dplyr::n_distinct(source),
                       which_sources = unique(source),
                       .by = gauge) |>
        dplyr::filter(n_sources > 1) |>
        dplyr::summarise(which_sources = paste0(unique(which_sources), collapse = ', '),
                         .by = gauge) |>
        dplyr::mutate(gluer = paste(gauge, which_sources, sep = ': '))

      if (nrow(gaugedoubles) > 0) {
        rlang::warn(c("Multiple sources returned the same gauges:",
                      glue::glue("{gaugedoubles$gluer}")))
      }

      # need this for the check
      gauges_returned <- unique(all_out$gauge)

    } else {
      gauges_returned <- NULL
    }


    gauges_wanted <- unique(portal_tib$gauge)

    not_returned <- gauges_wanted[!(gauges_wanted %in% gauges_returned)]

    if (length(not_returned) > 0) {
      rlang::warn(c("Requested gauge(s) not returned:",
                    glue::glue("{paste0(not_returned, collapse = ', ')}")))
    }

  }


  return(all_out)


}
