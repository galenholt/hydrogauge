#' Creates 14-digit character string needed for times in the API
#'
#' @param usertime time value from user. may be date, numeric, or character
#'
#' @return 14-digit character vector

fix_times <- function(usertime, type = 'hydllp') {

  # accept a few formats for the start_time and end_time
  # it wants a 14-character long string, e.g. '19750510000000'

  # let's work with characters. this should turn numeric or date objects into
  # strings and just pass strings around
  timestring <- as.character(usertime)
  collapsetime <- timestring |>
    stringr::str_extract_all(pattern = '[0-9]', simplify = TRUE) |>
    stringr::str_flatten()
  # why do this, and not not flatten? because it works to pad character input
  startlen <- nchar(collapsetime)
  if (startlen < 8) {rlang::warn("time specified is not long enough to give a day. Padding with zeros, but may not work.")}
  if (startlen > 14) {rlang::abort("Time specified has too many digits, check for typos.")}

  pad <- rep('0', 14-startlen) |> stringr::str_flatten()

  clean_time <- paste0(collapsetime, pad)

  # if type is 'hydllp', that's all we need.
  # if type is 'kiwis', we need dashes and colons.
  if (type == 'kiwis') {
    # This is annoying, since we could use lubridate directly, but that turns it
    # into UTC, and we want to be consistent that the times stay in local time a
    # la the API
    clean_time <- format_chartimes(clean_time)
  }

  return(clean_time)

}

format_chartimes <- function(t14) {

  if (is.numeric(t14)) {
    t14 <- format(t14, digits = 14, scientific = FALSE)
  }

  y <- substr(t14, start = 1, stop = 4)
  mo <- substr(t14, start = 5, stop = 6)
  d <- substr(t14, start = 7, stop = 8)
  h <- substr(t14, start = 9, stop = 10)
  m <- substr(t14, start = 11, stop = 12)
  s <- substr(t14, start = 13, stop = 14)
  t14 <- paste0(y, '-', mo, '-', d, 'T', h, ':', m, ':', s)

  return(t14)

}
