#' Creates 14-digit character string needed for times in the API
#'
#' @param usertime time value from user. may be date, numeric, or character
#'
#' @return 14-digit character vector

fix_times <- function(usertime) {

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

  pad <- rep('0', 14-startlen) |> stringr::str_flatten()

  clean_time <- paste0(collapsetime, pad)
}
