#' Deal with parsing the kiwis timestamps into UTC or local time
#'
#' Local time can be fraught, if there are issues, use one of the others and do the local time parsing manually based on your particular situation.
#'
#' @param timevec output with a Timestamp column with format as BOM, e.g. `'2020-01-01T00:00:00.000+10:00'`
#' @param timetype character, one of 'char' (default), 'raw', 'UTC', or 'local'. 'char' and 'raw' both return the Timestamp as it comes from BOM, the others parse into dates.
#'
#' @return a df with requested time columns
#' @export
#'
parse_bom_times <- function(timevec, timetype = 'char') {

  # Doing this with a vector because that makes it easy to do for different dfs with different column names.
  # lubridate does utc by default
  if (grepl('utc', timetype, ignore.case = TRUE)) {
    timevec <- lubridate::ymd_hms(timevec)
  }


  # Getting local time is a surprising amount of hassle. We need to extract the tz and pass it as an argument. And for some reason 'Etc/GMT-10' gives tz +10, etc.
  if (grepl('local', timetype, ignore.case = TRUE)) {
    time_offset <- stringr::str_extract(timevec, '(\\+|-)[0-9][0-9](:00)*$')
    time_offsetdir <- substr(time_offset, 1, 1)
    # have to switch the direction for the tz
    time_offsetdir <- ifelse(time_offsetdir == '+', '-', '+')
    tz = paste0('Etc/GMT', time_offsetdir, substr(time_offset, 2, 3))

    # There's probably a cleverer way to do this with base::aggregate, but I'm
    # just going to do this because we can only have one tz for lubridate, but
    # may have > 1 in thedata
    bom_df <- tibble::tibble(time = timevec, tz = tz) |>
      dplyr::group_by(tz) |>
      dplyr::mutate(time_local = lubridate::ymd_hms(time, tz = unique(tz))) |>
      dplyr::ungroup()

    timevec <- bom_df$time_local
  }

  if (!grepl('char|raw', timetype, ignore.case = TRUE)) {
    timevec <- timevec
  }

  return(timevec)


}
