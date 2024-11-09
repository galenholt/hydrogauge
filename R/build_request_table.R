build_request_table <- function(portal,
                                gauge,
                                start_time,
                                end_time,
                                variable,
                                units,
                                timeunit,
                                statistic,
                                datatype,
                                portal_type,
                                gauge_portal,
                                robustness = "robust") {
  # So, we need to identify which function to use for each portal, and which
  # portal to request for each gauge

  # make CMD CHECK happy
  i <- NULL
  if (portal_type == "auto") {
    portal_tib <- foreach::foreach(
      i = 1:length(portal),
      .combine = dplyr::bind_rows
    ) %do% {
      parse_url(portal[i], type = TRUE)
    }
    portal_tib$portal <- portal
  } else {
    bu <- foreach::foreach(i = 1:length(portal), .combine = c) %do% {
      parse_url(portal[i])
    }
    # this works whether portal_type is 1 or length(portal)
    portal_tib <- tibble::tibble(portal = portal, baseURL = bu, portal_type = portal_type)
  }

  # For auto-gauging, we run the risk of duplicates. Missing gauges from a
  # portal just get dropped in the first steps of the fetch* functions, but
  # duplicates will be returned multiple times. Is that better or worse than
  # finding them a priori? I'm not sure, there are advantages either way.
  if (is.character(gauge_portal) & "auto" %in% gauge_portal) {
    if (length(portal > 1)) {
      rlang::inform(c(
        "`gauge_portal` set to auto. Gauges will be requested from all portals.",
        glue::glue("Duplicates returned, but attempt to detect for processing.")
      ))
    }
    gauge_portal <- tidyr::expand_grid(portal, gauge)
  }

  # handle the list
  if (is.list(gauge_portal) & !inherits(gauge_portal, "data.frame")) {
    # infer names if unnamed
    if (is.null(names(gauge_portal))) {
      if (length(gauge_portal) == length(portal)) {
        names(gauge_portal) <- portal
      } else {
        rlang::abort("Cannot infer portal from unnamed gauge list with different length than `portal`")
      }
    }

    # check names
    if (all(names(gauge_portal) %in% portal)) {
      gauge_portal <- tibble::enframe(gauge_portal) |>
        tidyr::unnest(cols = "value") |>
        dplyr::rename(portal = "name", gauge = "value")
    } else {
      rlang::abort("`gauge_portal` names do not match those in `portal`")
    }
  }

  # Then we should have a dataframe no matter what, and we can
  if (is.data.frame(gauge_portal)) {
    portal_tib <- dplyr::left_join(portal_tib, gauge_portal, by = "portal")
  }

  # The variable, units, and datatype
  if (length(variable) > 1 | length(units) > 1) {
    rlang::abort("`find_timeseries` only handles a single variable and unit. If you want more, use other functions that allow more manual setup.")
  }
  portal_tib$variable <- variable
  portal_tib$units <- units

  # We expect datatype might differ
  if (length(datatype) == 1 | length(datatype) == length(portal)) {
    dttib <- tibble::tibble(portal = portal, datatype = datatype)
    portal_tib <- dplyr::left_join(portal_tib, dttib, by = "portal")
  }

  # This is really getting very complex. I think I'll keep working on it, but I
  # think a better way to go is to jump ahead and assume I have put together a
  # tibble or a list and write the function to loop over that and just clean it
  # up a bit. part of that cleanup is translate some synonyms- should these be
  # held in a data object rather than created?

  # THere's got to be a cleaner method here with less dplyr and more logical
  # indexing. is this going to work with AsStored/point? we probably need a NULL
  # option if one of those is chosen.
  hydtimes <- c("year", "month", "day", "hour", "minute", "second")
  kitimes <- c("Yearly", "Monthly", "Daily", "Hourly", "Minute", "Second")
  timename <- tibble::tibble(
    hydstra = rep(hydtimes, 2),
    kiwis = rep(kitimes, 2),
    all_times = c(hydtimes, kitimes)
  )

  hydstat <- c("mean", "max", "min", "start", "end",
               "first", "last", "tot", "maxmin", "point", "cum")
  # Not super sure about these.
  kistat <- c("Mean", "Max", "Min", NA, NA, NA, NA, "Total", NA, "AsStored", NA)
  statname <- tibble::tibble(
    hydstra = rep(hydstat, 2),
    kiwis = rep(kistat, 2),
    all_stats = c(hydstat, kistat)
  )


  timesel <- timename |>
    dplyr::filter(.data$all_times == timeunit) |>
    dplyr::select(-"all_times") |>
    tidyr::pivot_longer(
      col = tidyselect::everything(),
      names_to = "portal_type",
      values_to = "timeunit"
    )
  statsel <- statname |>
    dplyr::filter(.data$all_stats == statistic) |>
    dplyr::select(-"all_stats") |>
    tidyr::pivot_longer(
      col = tidyselect::everything(),
      names_to = "portal_type",
      values_to = "statistic"
    )

  stattime <- statsel |>
    dplyr::left_join(timesel, by = "portal_type") |>
    dplyr::mutate(timeunit = ifelse(.data$statistic %in% c("AsStored", "point"),
                                    NULL, .data$timeunit))

  portal_tib <- portal_tib |>
    dplyr::left_join(stattime, by = "portal_type")
  # see the bomout_own method to get site owners to make a 'fetch_aussie_water'
  # function given gauges- feed them through that to assign a portal, then
  # create the tibble and loop as we're about to do here.

  # If we want speed at the cost of losing everything from a single failed
  # gauge, minimize the number of API calls.
  if (robustness == "speed") {
    # We only allow one variable, units, datatype, statistic, and timeunit here,
    # so that makes this easier.
    # I'm going to group_by those and not collapse them, and so it would work in
    # future to have multiple that are uniquely mapped to gauge.
    # .We could collapse them too with |, but then we'd get the factorial with
    # gauge, which may not be what we want.
    portal_tib <- portal_tib |>
      dplyr::summarise(
        gauge = paste0(unique(.data$gauge), collapse = ", "),
        .by = c("baseURL", "portal_type", "portal", "variable",
                "units", "datatype", "statistic", "timeunit")
      )
  }

  # add timecolumns
  portal_tib$start_time <- start_time
  portal_tib$end_time <- end_time

  return(portal_tib)
}
