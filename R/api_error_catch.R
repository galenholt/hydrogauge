api_error_catch <- function(bodylist, call = rlang::caller_env(), .errorhandling = 'stop') {
  e_value <- bodylist[1]

  if (e_value != 0) {
    ermessage = paste0("API error number ", e_value, ". Message: ", bodylist$error_msg)
    if (.errorhandling == 'stop') {
      rlang::abort(message = ermessage, call = call)
    }
    if (.errorhandling == 'remove') {
      return(NULL)
    }
    if (.errorhandling == 'pass') {
      return(ermessage)
    }
  }

  return(bodylist)
}

ts_error_catch <- function(bodytib, call = rlang::caller_env(), .errorhandling = 'stop') {

  # if no errors, return
  if (all(bodytib$error_num == 0)) {return(FALSE)}

  if (.errorhandling == 'remove') {
    errorframe <- bodytib |>
      tibble::tibble(.rows = 0) |>
      dplyr::select(-trace)
    return(errorframe)
  }

  if (.errorhandling == 'pass') {
    errorframe <- bodytib |>
        dplyr::filter(error_num != 0) |>
        dplyr::distinct() |>
      dplyr::select(-trace)
    return(errorframe)
  }
  # Not sure why I had this here
  # bodytib |>
  #   dplyr::filter(error_num != 0) |>
  #   dplyr::select(error_num, error_msg, site, variable) |>
  #   dplyr::distinct()

  if (.errorhandling == 'stop') {
    ermessage = paste0("API error number ", bodytib$error_num,
                       ". Message: ", bodytib$error_msg)
    ermessage = stringr::str_flatten(ermessage, collapse = "\n")

    rlang::abort(message = ermessage, call = call)
  }





}
