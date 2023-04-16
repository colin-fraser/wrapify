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
