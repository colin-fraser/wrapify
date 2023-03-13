#' @export
auth_type <- function(type, ...) {
  list2(type = type, ...)
}

#' @export
query_auth_type <- function(param_names) {
  auth_type("query", param_names = param_names)
}

query_auth_type_to_params <- function(x, params) {
  stopifnot(length(params) == length(x$param_names))
  set_names(list2(!!!params), x$param_names)
}

#' @export
bearer_auth_type <- function() {
  auth_type('bearer')
}
