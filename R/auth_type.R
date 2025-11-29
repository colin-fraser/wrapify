#' Auth types
#'
#' Functions for declaring different kinds of authorization for a wrapper.
#'
#' @param type the authorization type
#' @param ... other values to attach to the authorization type.
#'
#' @returns a wrapify_auth object
#' @export
auth_type <- function(type, ...) {
  structure(
    list2(type = type, ...),
    class = c("wrapify_auth", "list")
  )
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
  auth_type("bearer")
}

#' @export
#' @describeIn auth_type authorization in header
#' @param header the name of the header where the credential goes
header_auth_type <- function(header) {
  auth_type("header", header = header)
}

#' Format a wrapify auth object
#'
#' @param x A wrapify_auth object
#' @param ... Additional arguments (unused)
#'
#' @return A character vector representing the auth type
#' @export
format.wrapify_auth <- function(x, ...) {
  if (x$type == "none") {
    return("<wrapify_auth: none>")
  }

  if (x$type == "bearer") {
    return("<wrapify_auth: bearer token>")
  }

  if (x$type == "header") {
    return(paste0("<wrapify_auth: header (", x$header, ")>"))
  }

  if (x$type == "query") {
    params <- paste(x$param_names, collapse = ", ")
    return(paste0("<wrapify_auth: query (", params, ")>"))
  }

  paste0("<wrapify_auth: ", x$type, ">")
}

#' Print a wrapify auth object
#'
#' @param x A wrapify_auth object
#' @param ... Additional arguments passed to format
#'
#' @return Invisibly returns the original object
#' @export
print.wrapify_auth <- function(x, ...) {
  cat(format(x, ...), "\n")
  invisible(x)
}
