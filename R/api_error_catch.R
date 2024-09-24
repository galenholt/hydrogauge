#' Handle and parse errors from the API calls
#'
#' @param bodylist list returned by API
#' @param call see [rlang::abort()]; passes calling environment for clearer
#'   messages
#' @param .errorhandling as in [foreach::foreach()]- passed in here to handle
#'   simply `abort`ing vs doing something with the error and continuing
#'
#' @return depends on presence of errors and value of `.errorhandling`
#' @keywords internal
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


#' Catch API errors that don't appear until the list is unpacked
#'
#' @param bodytib dataframe constructed from API list with `error_num` column
#' @inheritParams api_error_catch
#'
#' @return typically `bodytib`, unless there are errors, then determined by `.errorhandling`
#' @keywords internal
#'
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

  if (.errorhandling == 'stop') {
    ermessage = paste0("API error number ", bodytib$error_num,
                       ". Message: ", bodytib$error_msg)
    ermessage = stringr::str_flatten(ermessage, collapse = "\n")

    rlang::abort(message = ermessage, call = call)
  }

}
