test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})

test_that("request builder", {
  faker_person <- request_builder(
    base_path = "https://fakerapi.it/api/v1",
    request_path = "persons",
    query_args = params(
      param("gender", required = FALSE),
      param("birthday_start", required = FALSE),
      param("birthday_end", required = FALSE),
      param("seed", required = FALSE)
    ),
    query_constants = list(
      "_quantity" = 1,
      "_locale" = "en_US"
    )
  )
  r <- faker_person("male")
})
