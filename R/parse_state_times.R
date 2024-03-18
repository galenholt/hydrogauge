#' Deal with parsing the hydllp timestamps into UTC or local time
#'
#' Very similar to [parse_bom_times()] but has to deal with tz differently, and return character versions differently
#'
#' @param timevec the output of the `t` column from hydllp, typically a 14-digit double
#' @param tz a timezone vector, also returned from hydllp
#' @param timetype character, one of 'char' (default), 'raw', 'UTC', or 'local'. 'char' returns a character in the format `YYYY-MM-DDTHH:MM:SS+TZ` matching BOM-style (and so containing all necessary info). `'raw'` simply returns the unmodified numeric, which does not.
#'
#' @return a vector, either character, numeric, or POSIX
#' @export
#'
parse_state_times <- function(timevec, tz, timetype) {

  # Doing this with a vector because that makes it easy to do for different dfs with different column names.
  # Both UTC and local need to know the tz, since unlike BOM its not encoded
  # We could just create a bom-style character vector and then get that function to do the work, but it's a bit roundabout.
  if (grepl('utc|local|char', timetype, ignore.case = TRUE)) {
    # none of the local stuff works with other than whole hours
    timeoffset <- as.numeric(tz)
    if (any(timeoffset %% 1 != 0)) {
      rlang::abort(c("Cannot use partial-hour timezones.",
                     "i" = "Try using `timetype = 'char'` and post-hoc manually parsing."))
    }
    timeoffset <- as.integer(timeoffset)
  }

  if (grepl('utc|local', timetype, ignore.case = TRUE)) {
    # needed for utc and local with lubridate
    timedir <- ifelse(timeoffset > 0, '-', '+') # This is backwards to if we return it as char
    tz_name <- paste0('Etc/GMT', timedir, timeoffset)

    state_df <- tibble::tibble(time = timevec, tz_name = tz_name) |>
      dplyr::group_by(tz_name) |>
      dplyr::mutate(time_local = lubridate::ymd_hms(time, tz = unique(tz_name)),
                    time_utc = lubridate::with_tz(time_local, tz = 'UTC')) |>
      dplyr::ungroup()

    if (grepl('utc', timetype, ignore.case = TRUE)) {
      timevec <- state_df$time_utc
    }
    if (grepl('local', timetype, ignore.case = TRUE)) {
      timevec <- state_df$time_local
    }
  }


  if (grepl('char', timetype, ignore.case = TRUE)) {

    timedir <- ifelse(timeoffset > 0, '+', '')

    timevec <- format_chartimes(timevec)

    timevec <- paste0(timevec, timedir, timeoffset)
  }

  if (!grepl('raw', timetype, ignore.case = TRUE)) {
    timevec <- timevec
  }


  return(timevec)
}
