#' Deal with parsing the hydllp timestamps into UTC or local time
#'
#' Very similar to [parse_bom_times()] but has to deal with tz differently, and return character versions differently
#'
#' @param timevec the output of the `t` column from hydllp, typically a 14-digit double
#' @param timetype character, one of 'char' (default), 'raw', 'UTC', or 'local'. 'char' returns a character in the format `YYYY-MM-DDTHH:MM:SS+TZ` matching BOM-style (and so containing all necessary info). `'raw'` simply returns the unmodified numeric, which does not.
#' @param tz_name the name of the incoming timezone, as in OlsonNames, needed for lubridate
#' @param tz_offset the offset of the incoming timezone, easier to parse for 'char'
#'
#' @return a vector, either character, numeric, or POSIX
#' @export
#'
parse_state_times <- function(timevec, tz_name, tz_offset, timetype) {

  ### Need to re-figure this- we need a database_timezone column and a time column. Does that mean this needs to be two functions? Or return a 2-col tibble that then gets unpacked?
  if (grepl('char', timetype, ignore.case = TRUE)) {

    tzoffnum <- as.numeric(tz_offset)
    timedir  <- ifelse(tzoffnum > 0, '+', '') # '-' gets included with as.character

    timevec <- format_chartimes(timevec)

    timevec[!is.na(timevec)] <- paste0(timevec[!is.na(timevec)], timedir, tzoffnum)
  }


  if (!grepl('raw', timetype, ignore.case = TRUE)) {
    timevec <- timevec
  }

  if (timetype %in% OlsonNames()) {
    # get a single tz, but check it's not multiple
    tz_name <- multi_tz_check(tz_name)
    # Unlike BOM, the tz info isn't in the timevec, so it gets put directly into UTC with no shift unless we give it tz.
    timevec <- lubridate::ymd_hms(timevec, tz = tz_name) |>
      lubridate::with_tz(timetype)
  }


  return(timevec)
}



