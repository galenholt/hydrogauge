#' Gets timeseries for sites and variables
#'
#' Takes a list of sites and variables and fetches the timeseries. Variables may
#' include derived and base. This is very similar to the underlying API call,
#' and does not do very much automation of finding variables, checking times,
#' etc. If variables are not available for a site or for given times it just
#' silently does not return them. For a more automated (but currently slower)
#' approach, see [fetch_hydstra_timeseries()], which also allows a
#' `.errorhandling` argument.
#'
#' Timezone note: Data is returned from the API in local time, but the default
#' here is to output UTC for consistency. Note, however that the `start_time`
#' and `end_time` *must* be in database-local time. Thus, when using
#' programatically, it can be easiest to use `'raw'` or `'db_default'`. Further,
#' the API returns 0 for data outside the range if a request spans across the
#' boundary. Check your data with [get_variable_list()] or use
#' [fetch_hydstra_timeseries()], which does the check automatically.
#'
#'
#' @param portal character for the data portal (case insensitive). Default
#'   'victoria'
#' @param site_list character site code, either a single site code
#'   `"sitenumber"`, comma-separated codes in a single string `"sitenumber1,
#'   sitenumber2`, or a vector of site codes `c("sitenumber1", "sitenumber2")`
#' @param datasource character for datasource code. To my knowledge, options are
#'   `"A"`, `"TELEM"`, `"TELEMCOPY"`. Passing multiple not currently supported.
#' @param var_list character vector of variable codes. Needs to be either single
#'   code or vector (`c("code1", "code2")`), *not* a comma-separated string
#' @param start_time character, numeric, or date giving the start time. API
#'   expects a 14-digit character `"YYYYMMDDHHIIEE"`, but this will turn numeric
#'   or dates into that, and pad zeros if given less than 14 digits, e.g.
#'   `20200101` would be padded to give midnight on 1 Jan 2020.
#' @param end_time character, numeric, or date giving the end time. API expects
#'   a 14-digit character `"YYYYMMDDHHIIEE"`, but this will turn numeric or
#'   dates into that, and pad zeros if given less than 14 digits, e.g.
#'   `20200101` would be padded to give midnight on 1 Jan 2020.
#' @param interval character, period to report. I don't think capitalisation
#'   matters.
#'  * Options: `"year"`, `"month"`, `"day"`, `"hour"`, `"minute"`, `"second"`.
#' @param data_type character, the statistic to apply. *Warning:* only takes one
#'   value, which is applied to all variables. This may not be appropriate. If
#'   variables should have different statistics, run `get_ts_traces` multiple
#'   times.
#'  * Options: `"mean"`, `"max"`, `"min"`, `"start"`, `"end"`, `"first"`, `"last"`, `"tot"`, `"maxmin"`, `"point"`, `"cum"`. Not all are currently tested.
#' @param multiplier character, interval multiplier. I *think* this allows
#'   intervals like 5 days, by passing `interval = 'day'` and `multiplier = 5`.
#'   Not tested other than 1 at present.
#' @param returnformat character, one of
#'  * `"df"` returns a tibble
#'  * `"varlist"` returns a list with an separate tibble for each variable (may have multiple sites per tibble)
#'  * `"sitelist"` returns a list with an separate tibble for each site (may have multiple variables per tibble)
#' @param return_timezone character in [OlsonNames()] or one of three special
#'   cases: `'db_default'`, `'char'` or `'raw'`. Default 'UTC'. If 'db_default',
#'   uses the API default. If `'char'`, returns a string in the format
#'   `'YYYY-MM-DDTHH:MM:SS+TZ'`, having all needed info (and matching Kiwis
#'   returns). If `'raw'`, returns the time column as-is from the API (a
#'   14-digit string of numbers 'YYYMMDDHHMMSS')
#'  * `"sxvlist"` returns a list with an separate tibble for each site x variable combination
#' @param .errorhandling as in [foreach::foreach()] (but handled in
#'   [api_error_catch()]) Default 'stop'. Made available here primarily to use
#'   'pass' so big requests don't die due to API errors. **Be careful**- those
#'   errors then just get passed and so the data will be missing.

#' @return tibble(s) with requested variables at requested sites (where they
#'   exist). See `returnformat`, either a tibble or list of tibbles
#' @export
#'
#'
#' @examples
#' simpletrace <- get_ts_traces(
#'   portal = 'vic',
#'   site_list = "233217",
#'   datasource = "A",
#'   var_list = c("100", "141"),
#'   start_time = "20200101", end_time = "20200105",
#'   interval = "day", data_type = "mean",
#'   multiplier = 1, returnformat = "df"
#' )
get_ts_traces <- function(portal,
                          site_list,
                          datasource = "A",
                          var_list = c("100", "141"),
                          start_time,
                          end_time,
                          interval = "day",
                          data_type = "mean",
                          multiplier = 1,
                          return_timezone = "UTC",
                          returnformat = "df",
                          .errorhandling = "stop") {
  # If this gets a NA portal return NULL (which happens sometimes with
  # auto-finding from get_variable_list) and the variable doesn't exist
  if (is.na(portal) | length(portal) == 0 | is.null(portal)) {
    return(NULL)
  }
  baseURL <- parse_url(portal)

  # clean up the start and end times.
  start_time <- fix_times(start_time)
  end_time <- fix_times(end_time)

  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ", ", collapse = ", ")

  # this takes a var_list, but can't get derived variables that way. I could use
  # var_list where possible, otherwise varfrom-varto. or just loop over each var
  # as varfrom/to. I think that might have overhead to communicate with the API,
  # but splitting up means creating additional api_body_lists

  derived <- c("140", "141", "140.00", "141.00")

  # very tempting to just foreach over all values. will need to benchmark

  # clean list without derived
  noderiv_list <- var_list[!(var_list %in% derived)]
  # needs to be a comma separated length-1 vector
  noderiv_list <- paste(noderiv_list, sep = ", ", collapse = ", ")

  # derived list
  deriv_list <- var_list[(var_list %in% derived)]
  # needs to NOT be comma separated, because need to feed one at a time.

  # if only asking for derived, bypass
  if (noderiv_list != "") {
    # build the list for the non-derived
    api_body_list <- list(
      "function" = "get_ts_traces",
      "version" = "2",
      "params" = list(
        "site_list" = site_list,
        "start_time" = start_time,
        "var_list" = noderiv_list,
        "interval" = interval,
        "datasource" = datasource,
        "end_time" = end_time,
        "data_type" = data_type,
        "multiplier" = multiplier
      )
    )

    # hit the api
    response_body <- get_response(baseURL, api_body_list,
      .errorhandling = .errorhandling
    )

    # clean up with a function because so ugly
    bodytib <- clean_trace_list(
      responsebody = response_body,
      data_type = data_type,
      return_timezone = return_timezone,
      .errorhandling = .errorhandling
    )
  } else {
    bodytib <- tibble::tibble(.rows = 0)
  }


  # foreach for the derived. Very straightforward to do it for everything. And
  # could package the list-making, responsing, and unpacking in a function and
  # furrr it instead of foreach.

  # make CMD CHECK happy
  v <- NULL
  btd <- foreach::foreach(
    v = deriv_list,
    .combine = dplyr::bind_rows
  ) %do% {
    pl <- list(
      "function" = "get_ts_traces",
      "version" = "2",
      "params" = list(
        "site_list" = site_list,
        "start_time" = start_time,
        "varfrom" = "100",
        "varto" = v,
        "interval" = interval,
        "datasource" = datasource,
        "end_time" = end_time,
        "data_type" = data_type,
        "multiplier" = multiplier
      )
    )


    # hit the api
    rb <- get_response(baseURL, pl,
      .errorhandling = .errorhandling
    )

    # clean up with a function because so ugly
    bt <- clean_trace_list(
      responsebody = rb,
      data_type = data_type,
      return_timezone = return_timezone,
      .errorhandling = .errorhandling
    )
    bt # be explict that this is what each iteration returns
  }

  # glue on the derived vars and sort sites together
  bodytib <- dplyr::bind_rows(bodytib, btd) |>
    dplyr::arrange(.data$site, .data$variable)

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


#' Cleans ts_trace API list body into tibble
#'
#' @inheritParams get_ts_traces
#'
#' @param responsebody response body from the API call to get_ts_traces
#' @param data_type the data_type used to calculate the statistic over the
#'   `interval`, glued on for record
#' @param gauge character gauge name- allows building an informative
#'   error-handled output
#'
#' @return a tibble with the rectangled response
#' @keywords internal
clean_trace_list <- function(responsebody,
                             data_type,
                             gauge = NA,
                             return_timezone = "UTC",
                             .errorhandling = "stop") {
  # Some error handling
  if (is.character(responsebody) && grepl("error number", responsebody)) {
    errortib <- tibble::tibble(
      error_num = as.numeric(stringr::str_extract(responsebody, "[0-9]+")),
      error_msg = responsebody,
      site = gauge,
      variable = NA
    )
    return(errortib)
  }

  if (is.null(responsebody)) {
    return(responsebody)
  }

  # unpack the list
  bodytib <- tibble::as_tibble(responsebody$return) |> # just get the return value (drop error col and disclaimer, etc)
    # tidyr::unnest_longer(col = tidyselect::where(is.list)) |> # a `return` list, not needed with $ indexing
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # complex set of lists
    tidyr::unnest_wider(col = "site_details") |> # columns of info about the site
    dplyr::rename(site_name = "name", site_short_name = "short_name") |>
    # there are name conflicts between site and varfrom and varto.
    # and we can drop varfrom
    dplyr::select(-"varfrom_details") |>
    tidyr::unnest_wider(col = "varto_details") |>
    dplyr::rename_with(
      ~ (paste0("variable_", .)),
      c("short_name", "name")
    )

  # parse errors, as defined by .errorhandling
  errorparser <- ts_error_catch(bodytib, .errorhandling = .errorhandling)

  # if there were errors and errorhandling was pass or remove, send those back
  # out.
  if ((!is.logical(errorparser)) &
      (.errorhandling == "pass" | .errorhandling == "remove")) {
    return(errorparser |>
      dplyr::mutate(dplyr::across(c(.data$longitude, .data$latitude), as.numeric)))
  }

  # break in here to get the quality codes to match
  qc <- bodytib |>
    dplyr::select("quality_codes", "site", "variable") |>
    tidyr::unnest_longer(col = "quality_codes") |>
    dplyr::mutate(quality_codes_id = as.integer(.data$quality_codes_id))

  # finish unpacking
  bodytib <- bodytib |>
    dplyr::select(-"quality_codes") |>
    tidyr::unnest_longer(col = "trace") |>
    tidyr::unnest_wider(col = "trace")

  # clean up
  bodytib <- bodytib |>
    dplyr::rename(value = "v", time = "t", quality_codes_id = "q")

  # Get the db timezone no matter what
  tz <- purrr::map_chr(bodytib$timezone, extract_timezone)

  # if the tz aren't all the same, going to need to bail out
  if (return_timezone == "db_default") {
    # This gives either the database timezone tz or UTC if there are multiple
    return_timezone <- multi_tz_check(tz)
  }


  # handle different sorts of time-parsing
  bodytib <- bodytib |>
    dplyr::mutate(
      database_timezone = tz,
      time = parse_state_times(.data$time,
        tz_name = .data$database_timezone,
        tz_offset = .data$timezone,
        timetype = return_timezone
      )
    ) |>
    dplyr::select(-"timezone") # Remove the tz as-returned, it can get confusing

  bodytib <- bodytib |>
    dplyr::left_join(qc, by = c("quality_codes_id", "site", "variable")) |>
    dplyr::mutate(dplyr::across(c("longitude", "latitude", "value"), as.numeric)) |> # leaving some others because they either are names (gauges, variable) or display better (precision)
    dplyr::mutate(data_type = data_type) # record the statistic

  return(bodytib)
}
