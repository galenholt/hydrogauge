#' Deal with parsing the kiwis timestamps into UTC or local time
#'
#' Local time can be fraught, if there are issues, use one of the others and do the local time parsing manually based on your particular situation.
#'
#' @param timevec output with a Timestamp column with format as BOM, e.g. `'2020-01-01T00:00:00.000+10:00'`
#' @param timetype character, one of 'char' (default), 'raw', 'UTC', or 'local'. 'char' and 'raw' both return the Timestamp as it comes from BOM, the others parse into dates.
#'
#' @return a vector, either character or POSIX
#' @export
#'
parse_bom_times <- function(timevec, timetype = 'char') {

  if (!grepl('char|raw', timetype, ignore.case = TRUE)) {
    timevec <- timevec
  }

  if (timetype %in% OlsonNames()) {
    timevec <- lubridate::ymd_hms(timevec) |>
      lubridate::with_tz(timetype)
  }

  return(timevec)


}
