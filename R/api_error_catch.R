api_error_catch <- function(bodylist, call = rlang::caller_env()) {
  e_value <- bodylist[1]

  if (e_value != 0) {
    ermessage = paste0("API error number ", e_value, ". Message: ", bodylist$error_msg)
    rlang::abort(message = ermessage, call = call)
  }
}

ts_error_catch <- function(bodytib, call = rlang::caller_env()) {

  # if no errors, return
  if (all(bodytib$error_num == 0)) {return()}

  bodytib |>
    dplyr::filter(error_num != 0) |>
    dplyr::select(error_num, error_msg, site, variable) |>
    dplyr::distinct()

  ermessage = paste0("API error number ", bodytib$error_num,
                     ". Message: ", bodytib$error_msg)
  ermessage = stringr::str_flatten(ermessage, collapse = "\n")

  rlang::abort(message = ermessage, call = call)


}
