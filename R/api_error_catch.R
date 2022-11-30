api_error_catch <- function(bodylist, call = rlang::caller_env()) {
  e_value <- bodylist[1]

  if (e_value != 0) {
    ermessage = paste0("API error number ", e_value, "\nMessage: ", bodylist$error_msg)
    rlang::abort(message = ermessage, call = call)
  }
}
