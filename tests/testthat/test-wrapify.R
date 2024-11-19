test_that("Wrapper construction", {
  example <- wrapper(example_url())
  expect_equal(example$auth$type, "none")
  expect_equal(example$default_headers$`content-type`, "application/json")
})

test_that("Example iris requestor", {
  example <- wrapper(example_url())

  iris <- requestor(
    example,
    "iris",
    query_args = function_args(
      page = ,
      limit = 1
    )
  )

  expect_equal(length(iris(1)$data), 1)
  expect_equal(length(iris(1, 2)$data), 2)

  custom_extractor <- function(resp) {
    l <- resp |>
      httr2::resp_body_json()
    l$count
  }

  expect_equal(iris(1, 2, .extractor = custom_extractor), 150)

})

test_that("Example openai wrapper", {
  openai <- wrapper(
    "https://api.openai.com/v1",
    auth = auth_spec("bearer")
  )

  list_models <- requestor(
    openai,
    "models"
  )

  expect_error(list_models(.perform = FALSE), "Wrapper has no default environment variable name")
  expect_equal(resp_status(list_models(.credentials = Sys.getenv("OPENAI_KEY"), .extract = FALSE)),
               200)
})

test_that("Example Anthropic wrapper", {
  anth <- wrapper(
    "https://api.anthropic.com/v1",
    auth = auth_type("header", header = "x-api-key"),
    env_var_name = "ANTHROPIC_API_KEY"
  )

  message <- requestor(
    anth,
    "messages",
    body_args = function_args(
      messages =,
      max_tokens = 1024,
      model = "claude-3-5-sonnet-20241022"
    ),
    header_args = function_args(
      "anthropic-version" = "2023-06-01"
    ),
    method = "post"
  )

  message(list(list(role = "user", content = "Hello there")), .perform = FALSE)
}
)
