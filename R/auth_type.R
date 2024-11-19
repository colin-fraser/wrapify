#' Auth types
#'
#' Functions for declaring different kinds of authorization for a wrapper.
#'
#' @param type the authorization type
#' @param ... other values to attach to the authorization type.
#'
#' @returns a simple named list
#' @export
auth_type <- function(type, ...) {
  list2(type = type, ...)
}

#' @export
#' @param param_names the parameter names to include in the query
#' @describeIn auth_type Authorization in the request query
query_auth_type <- function(param_names) {
  auth_type("query", param_names = param_names)
}

#' @export
#' @describeIn auth_type Bearer token
bearer_auth_type <- function() {
  auth_type('bearer')
}

#' @export
#' @describeIn auth_type authorization in header
#' @param header the name of the header where the credential goes
header_auth_type <- function(header) {
  auth_type("header", header = header)
}
