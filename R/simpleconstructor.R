#' @export
simpleconstructor <- function(..., .prune = TRUE) {
  argg <- c(as.list(environment()), list(...))
  arg_names <- names(argg)
  required_args <- names(Filter(\(x) x$required, argg))
  enum_args <- names(Filter(\(x) !is.null(x$enum), argg))
  f <- function(...) {
    for (arg in required_args) {
      if (is.null(env_get(nm = arg))) {
        abort(glue::glue("`{arg}` is a required argument"))
      }
    }
    for (arg in enum_args) {
      env_poke(nm = arg, value = arg_match0(env_get(nm = arg), argg[[arg]][['enum']], arg_nm = arg))
    }
    out <- env_get_list(nms = arg_names)
    if (.prune) {
      out <- purrr::compact(out)
    }
    out
  }
  formals(f) <- map(argg, "enum")
  f
}

#' @export
property <- function(type = "string", enum = NULL, description = NULL, required = FALSE) {
  structure(as.list(environment()), class = 'property')
}

#' @export
super_simple_constructor <- function(..., .class = 'supersimpleconstruct', .prune = TRUE) {
  args <- function_args(...)
  f <- function(..., .prune = .prune) {
    out <- env_get_list(nms = names(args))
    if (.prune) {
      out <- purrr::compact(out)
    }

    out
  }
  formals(f) <- args
  f
}


