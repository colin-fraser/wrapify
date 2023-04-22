#' Super Simple Constructor
#'
#' Generates a constructor function with the specified arguments, an optional custom class, and
#' a prune option. The constructor function returns a named list containing the values of the arguments.
#'
#' @param ... The arguments for the constructor function.
#' @param .class A character string representing the custom class for the constructor function's output (default: 'supersimpleconstruct').
#' @param .prune A logical value determining whether NULL values should be removed from the output named list (default: TRUE).
#'
#' @return A constructor function that takes the specified arguments and returns a named list with an associated class.
#' @export
#' @import rlang
#'
#' @examples
#' # Create a constructor function with 'a' and 'b' as arguments
#' my_constructor <- super_simple_constructor(a = , b = , .class = "my_custom_class")
#'
#' # Call the constructor function with values for 'a' and 'b'
#' result <- my_constructor(a = 1, b = 2)
#'
#' # Check the class of the 'result' variable
#' class(result) # Output: "my_custom_class"
super_simple_constructor <- function(..., .class = c('supersimpleconstruct', 'list'), .prune = TRUE) {
  args <- function_args(...)
  f <- function(..., .prune = .prune) {
    out <- env_get_list(nms = names(args), default = stop("All arguments must be supplied"))
    if (.prune) {
      out <- purrr::compact(out)
    }

    structure(out, class = .class)
  }
  formals(f) <- args
  f
}


