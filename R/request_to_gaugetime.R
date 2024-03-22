#' Transform requested times to the gauge timezones, whatever their tz and the tz of the gauge/database
#'
#' @param reqtime requested time. Character, numeric, or POSIXt
#' @param gaugetz database timezone
#' @param request_timezone declared timezone of `reqtime`, ignored if `reqtime` is `POSIXt`, in which case its tz is known.
#'
#' @return requested time in the timezone `gaugetz`
#'
request_to_gaugetime <- function(reqtime, gaugetz, request_timezone) {
  if (inherits(reqtime, 'POSIXt')) {

    req_time <- req_time |>
      lubridate::with_tz(tzone = gaugetz)

  } else {

    # If the incoming times should be treated as gauge-local, get the tz
    if (grepl('db_default', request_timezone, ignore.case = TRUE)) {
      # put those incoming times into the gauge times
      # because we used 'db_default' on the list, we can extract from here directly
      request_timezone <- gaugetz
    }

    reqtime <- reqtime |>
      fix_times() |>
      lubridate::ymd_hms(tz = request_timezone) |>
      lubridate::with_tz(tzone = gaugetz)
  }

  # catch NULLs, they end up as length-0 posix, but we want them to be NULL for other functions
  if (length(reqtime) == 0) {reqtime <- NULL}

  return(reqtime)
}
