#' @export
auth_type <- function(type, ...) {
  list2(type = type, ...)
}

#' @export
query_auth_type <- function(param_names) {
  auth_type("query", param_names = param_names)
}

#' @export
bearer_auth_type <- function() {
  auth_type('bearer')
}
