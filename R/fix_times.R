#' Creates 14-digit character string needed for times in the API
#'
#' @param usertime time value from user. may be date, numeric, or character
#'
#' @return 14-digit character vector

fix_times <- function(usertime, type = 'hydstra') {

  # short-circuit NULL
  if (is.null(usertime)) {return(NULL)}

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

  # if type is 'hydstra', that's all we need.
  # if type is 'kiwis', we need dashes and colons.
  if (type == 'kiwis') {
    # This is annoying, since we could use lubridate directly, but that turns it
    # into UTC, and we want to be consistent that the times stay in local time a
    # la the API
    clean_time <- format_chartimes(clean_time)
  }

  return(clean_time)

}

#' turns 14-character time string into 'YYYY-MM-DDTHH:MM:SS'
#'
#' @param t14
#'
#' @return
format_chartimes <- function(t14) {

  # NA get turned into characters here, we dont want that.
  incoming_na <- which(is.na(t14))

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

  # make the NA NA
  t14[incoming_na] <- NA

  return(t14)

}

#' Get timezones from various formats
#'
#' @param x vector with tz info, either times with it included or tz
#'
#' @return vector of OlsonName timezones if possible
#'
extract_timezone <- function(x) {

  # we don't want to check that this is a single tz, since we could just return as a character to preserve that.

  # NA get turned into characters here, we dont want that.
  incoming_na <- which(is.na(x) | x == '')
  incoming_good <- which(!is.na(x) & x != '')

  # just return NA if there's nothing else
  if (length(incoming_good) == 0) {return(NA)}

  # This bit is mostly to handle the states, which have numeric e.g. 10.0
  if (is.numeric(x)) {
    if (x > 0) {
      sign <- '+'
    } else {
      sign <- '' # - gets retained in as.character
    }
    x <- paste0(sign, as.character(x))
  }

  if (is.character(x)) {

    # the API uses 'Z' to denote UTC
    if (any(grepl('Z$', x))) {
      timezone <- 'UTC'
    }

    # This bit is mostly to handle the states, e.g. "10.0"
    if (all(nchar(x[incoming_good]) %in% c(4,5))) {
      # make numeric to find the direction
      x <- as.numeric(x)
      if (x > 0) {
        sign <- '+'
      } else {
        sign <- '' # - gets retained in as.character
      }
      x <- paste0(sign, as.character(x))
    }

    time_offset <- stringr::str_extract(x, '(\\+|-)[0-9][0-9](:[0-9][0-9])*$')
    if (any(grepl(':[1-9]|\\.[1-9]', time_offset))) {
      rlang::warn(c("Gauge timezone has partial-hour offset, does not abide by OlsonNames()",
                    "Returning the offset as-is, which will require manual work to convert to date objects"))
      timezone <- time_offset
    } else {
      time_offset <- substr(time_offset, 1,3)
      time_offsetdir <- substr(time_offset, 1, 1)
      # have to switch the direction for the tz
      time_offsetdir <- ifelse(time_offsetdir == '+', '-', '+')
      timezone = paste0('Etc/GMT', time_offsetdir, substr(time_offset, 2, 3))
    }

  }

  if (inherits(x, 'POSIXt')) {
    timezone <- lubridate::tz(x)
  }

  # reset NAs
  timezone[incoming_na] <- NA

  return(timezone)
}

#' returns single tz from vector, with check for equality
#'
#' @param tzvec
#'
#' @return
multi_tz_check <- function(tzvec) {
  # ignore na- all of them
  if (all(is.na(tzvec))) {return(NA)}
  # when some, we don't care which, we just want everything else to be the same.
  tzvec <- tzvec[!is.na(tzvec)]

  if (!all(tzvec == tzvec[1])) {
    rlang::warn(c("Multiple timezones returned, cannot be used to make a single time vector.",
                  "i" = "Setting timezone returned to 'UTC' (original will be preserved)"))
    timezone = 'UTC'
  } else {
    timezone <- tzvec[1]
  }
  return(timezone)
}
