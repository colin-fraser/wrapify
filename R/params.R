param <- function(name, required, default = NULL) {
  list(name = name, required = required, default = default)
}

params <- function(...) {
  list(...)
}

param_names <- function(params) {
  purrr::map_chr(params, "name")
}

required_params <- function(params) {
  Filter(\(x) x$required, params)
}

to_pairlist <- function(params) {
  out <- setNames(map(params, "default"), map(params, "name"))
  rlang::pairlist2(!!!out)
}
