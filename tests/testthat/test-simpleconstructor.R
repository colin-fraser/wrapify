test_that("super_simple_constructor creates a constructor function with the specified arguments", {
  my_constructor <- super_simple_constructor(a = , b = , .class = "my_custom_class")
  result <- my_constructor(a = 1, b = 2)

  expect_named(result, c("a", "b"))
  expect_equal(result$a, 1)
  expect_equal(result$b, 2)
})

test_that("super_simple_constructor assigns the specified custom class", {
  my_constructor <- super_simple_constructor(a = , b = , .class = "my_custom_class")
  result <- my_constructor(a = 1, b = 2)

  expect_s3_class(result, "my_custom_class")
})

test_that("super_simple_constructor prunes NULL values by default", {
  my_constructor <- super_simple_constructor(a = , b = , .class = "my_custom_class")
  result <- my_constructor(a = 1, b = NULL)

  expect_named(result, "a")
  expect_equal(result$a, 1)
  expect_false("b" %in% names(result))
})

test_that("super_simple_constructor does not prune NULL values when .prune is FALSE", {
  my_constructor <- super_simple_constructor(a = , b = , .class = "my_custom_class", .prune = FALSE)
  result <- my_constructor(a = 1, b = NULL)

  expect_named(result, c("a", "b"))
  expect_equal(result$a, 1)
  expect_equal(result$b, NULL)
})
