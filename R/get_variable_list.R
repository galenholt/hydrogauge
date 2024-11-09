#' Gets the variables available for sites and datasources
#'
#'
#' @inheritParams get_ts_traces
#' @param datasource as in [get_ts_traces()], but can be a vector. As far as I
#'   can tell, options are `'A'`, `'TELEM'`, `'TELEMCOPY'`. If multiple, `c('A',
#'   'TELEM')`
#'
#' @return a tibble of the variables for each site and datasource.
#' @export
#'
#' @examples
#' v2 <- get_variable_list(
#'   site_list = "233217, 405328, 405331, 405837",
#'   datasource = c("A", "TELEM")
#' )
get_variable_list <- function(portal,
                              site_list,
                              datasource,
                              return_timezone = "UTC") {
  baseURL <- parse_url(portal)

  # site_list needs to be a comma separated length-1 vector. Ensure
  site_list <- paste(site_list, sep = ", ", collapse = ", ")

  api_body_list <- list(
    "function" = "get_variable_list",
    "version" = "1",
    "params" = list(
      "site_list" = site_list,
      "datasource" = datasource[1]
    )
  ) # have to loop datasources


  # hit the api
  response_body <- get_response(baseURL, api_body_list)


  # Sometimes we get gauges with no variables (seems to happen mostly across
  # state lines). If there are other good gauges, the bad ones get auto-filled
  # with NA in the dplyr. But if not, we have to be explicit. And I think for
  # safety I'll just be explicit
  dummyvarlist <- list(list(
    period_end = NA, period_start = NA,
    subdesc = NA, variable = NA, units = NA,
    name = NA
  ))


  #
  findmissing <- function(x) {
    length(x$variables) == 0
  }
  response_body$return$sites <- response_body$return$sites |>
    purrr::map_if(
      findmissing,
      \(x) {
        x$variables <- dummyvarlist
        x
      }
    )
  # unpack
  bodytib <- tibble::as_tibble(response_body$return) |> # use $return instead of [2] to drops the error column because qld has a 'disclaimer' in 2
    # tidyr::unnest_longer(col = tidyselect::where(is.list)) |> # a `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # sites, and a `datasource` list
    tidyr::unnest_wider(col = "site_details") |> # site details in new cols
    tidyr::unnest_longer(col = "variables") |> # one line per variable, details of variables in a list
    dplyr::rename(long_name = "name") |> # variables have names too, avoid conflicts
    tidyr::unnest_wider(col = "variables") |> # columns for each attribute of the variables
    dplyr::rename(var_name = "name") |> # clarify name
    dplyr::mutate(datasource = datasource[1]) |> # add a datasource column so we can cross-ref
    dplyr::select("site", "short_name", "long_name", "variable", "units",
                  "var_name", "period_start", "period_end", "subdesc",
                  "datasource", "timezone")

  # deal with the times

  # Get the db timezone no matter what
  tz <- purrr::map_chr(bodytib$timezone, extract_timezone)

  # if the tz aren't all the same, going to need to bail out
  if (return_timezone == "db_default") {
    # This gives either the database timezone tz or UTC if there are multiple
    return_timezone <- multi_tz_check(tz)
  }

  bodytib <- bodytib |>
    dplyr::mutate(
      database_timezone = tz,
      period_start = parse_state_times(.data$period_start,
        tz_name = .data$database_timezone,
        tz_offset = .data$timezone,
        timetype = return_timezone
      ),
      period_end = parse_state_times(.data$period_end,
        tz_name = .data$database_timezone,
        tz_offset = .data$timezone,
        timetype = return_timezone
      )
    ) |>
    dplyr::select(-"timezone")

  # would be good to preallocate, but no idea how big it'll be. I guess just
  # recurse and bind_rows? Could fairly easily just to a purrr::map or
  # furrr::map across datasources? Then at least we'd hit the api in parallel.
  # Leave this for now but it's ugly
  if (length(datasource) > 1) {
    datasource <- datasource[-1]
    bodytib <- dplyr::bind_rows(
      bodytib,
      get_variable_list(
        portal = portal,
        site_list = site_list,
        datasource = datasource,
        return_timezone = return_timezone
      )
    )
  }

  return(bodytib)
}
