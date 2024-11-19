test_that("generate_roxygen_comment returns correct template with default values", {
  test_function <- function(x, y) {
    x + y
  }
  expected_output <- paste(
    "#' test_function",
    "#' ",
    "#' [Add a description here]",
    "#' ",
    "#' @param x [Description of x]",
    "#' @param y [Description of y]",
    "#' ",
    "#' @return [Describe the return value here]",
    "#' @export",
    sep = "\n"
  )

  expect_equal(generate_roxygen_comment(test_function), expected_output)
})

test_that("generate_roxygen_comment returns correct template with custom values", {
  test_function <- function(x, y) {
    x + y
  }
  expected_output <- paste(
    "#' Test Function",
    "#' ",
    "#' This function adds two numbers.",
    "#' ",
    "#' @param x The first number.",
    "#' @param y The second number.",
    "#' ",
    "#' @return The sum of the two input numbers.",
    "#' @export",
    sep = "\n"
  )

  roxygen_comment_string <- generate_roxygen_comment(
    test_function,
    title = "Test Function",
    description = "This function adds two numbers.",
    param_descriptions = list(
      x = "The first number.",
      y = "The second number."
    ),
    return_description = "The sum of the two input numbers."
  )

  expect_equal(roxygen_comment_string, expected_output)
})

test_that("generate_roxygen_comment returns correct template for a function without parameters", {
  test_function <- function() {
    42
  }
  expected_output <- paste(
    "#' test_function",
    "#' ",
    "#' [Add a description here]",
    "#' ",
    "#' ",
    "#' @return [Describe the return value here]",
    "#' @export",
    sep = "\n"
  )

  expect_equal(generate_roxygen_comment(test_function), expected_output)
})

test_that("generate_roxygen_comment returns correct template without examples", {
  test_function <- function(x, y) {
    x + y
  }
  expected_output <- paste(
    "#' Test Function",
    "#' ",
    "#' This function adds two numbers.",
    "#' ",
    "#' @param x The first number.",
    "#' @param y The second number.",
    "#' ",
    "#' @return The sum of the two input numbers.",
    "#' @export",
    sep = "\n"
  )

  roxygen_comment_string <- generate_roxygen_comment(
    test_function,
    title = "Test Function",
    description = "This function adds two numbers.",
    param_descriptions = list(
      x = "The first number.",
      y = "The second number."
    ),
    return_description = "The sum of the two input numbers.",
    examples = FALSE
  )

  expect_equal(roxygen_comment_string, expected_output)
})
