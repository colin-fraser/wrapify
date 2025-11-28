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
    auth = bearer_auth_type()
  )

  list_models <- requestor(
    openai,
    "models"
  )

  expect_error(list_models(.perform = FALSE), "Wrapper has no default environment variable name")
  expect_equal(
    resp_status(list_models(.credentials = Sys.getenv("OPENAI_KEY"), .extract = FALSE)),
    200
  )
})

test_that("Anthropic API wrapper with header auth", {
  # Test based on Anthropic API structure:
  # curl https://api.anthropic.com/v1/models \
  #   -H "X-Api-Key: $ANTHROPIC_API_KEY"

  anth <- wrapper(
    "https://api.anthropic.com/v1",
    auth = header_auth_type(header = "x-api-key")
  )

  # Test the models endpoint
  list_models <- requestor(
    anth,
    "models"
  )

  # Verify request structure with explicit credentials
  req <- list_models(.credentials = "test-api-key-123", .perform = FALSE)

  # Check URL is correct
  expect_match(req$url, "https://api.anthropic.com/v1/models")

  # Check that x-api-key header is set correctly
  expect_equal(req$headers$`x-api-key`, "test-api-key-123")

  # Test the messages endpoint with custom headers
  message <- requestor(
    anth,
    "messages",
    body_args = function_args(
      messages = ,
      max_tokens = 1024,
      model = "claude-3-5-sonnet-20241022"
    ),
    header_args = function_args(
      "anthropic-version" = "2023-06-01"
    ),
    method = "post"
  )

  body <- list(list(role = "user", content = "Hello there"))

  req <- message(body, .credentials = "test-key", .perform = FALSE)

  # Verify body parameters
  expect_equal(req$body$data$messages, body)
  expect_equal(req$body$data$model, "claude-3-5-sonnet-20241022")

  # Verify headers
  expect_equal(req$headers$`anthropic-version`, "2023-06-01")
  expect_equal(req$headers$`x-api-key`, "test-key")

  # Test overriding header args at call time
  req2 <- message(body, .credentials = "test-key", .perform = FALSE, "anthropic-version" = "2024-01-01")
  expect_equal(req2$headers$`anthropic-version`, "2024-01-01")
})

test_that("Query auth - single parameter", {
  # Create wrapper with single-parameter query auth
  api <- wrapper(
    "https://api.example.com/v1",
    auth = query_auth_type(param_names = "apikey")
  )

  # Create a simple requestor
  get_data <- requestor(
    api,
    "data"
  )

  # Test with plain string credential (not JSON)
  req <- get_data(.credentials = list(apikey = "secret123"), .perform = FALSE)

  # Verify the API key is in the query string
  expect_match(req$url, "apikey=secret123")
  expect_match(req$url, "/v1/data")
})

test_that("Query auth - multiple parameters", {
  # Create wrapper with multi-parameter query auth
  api <- wrapper(
    "https://api.example.com/v1",
    auth = query_auth_type(param_names = c("api_key", "account_id"))
  )

  # Create a simple requestor
  get_data <- requestor(
    api,
    "data"
  )

  # Test with named list credentials
  creds <- list(api_key = "secret123", account_id = "acc456")
  req <- get_data(.credentials = creds, .perform = FALSE)

  # Verify both parameters are in the query string
  expect_match(req$url, "api_key=secret123")
  expect_match(req$url, "account_id=acc456")
})

test_that("Query auth - credential validation", {
  # Create wrapper with specific param names
  api <- wrapper(
    "https://api.example.com/v1",
    auth = query_auth_type(param_names = c("api_key", "secret"))
  )

  get_data <- requestor(api, "data")

  # Should error if credential names don't match
  expect_error(
    get_data(.credentials = list(wrong_name = "test"), .perform = FALSE),
    "credential must be a list with names: api_key, secret"
  )

  # Should error if missing a required parameter
  expect_error(
    get_data(.credentials = list(api_key = "test"), .perform = FALSE),
    "credential must be a list with names: api_key, secret"
  )
})

test_that("read_key_value_list - single parameter", {
  # Single parameter should accept plain string
  result <- read_key_value_list("my_secret_key", "apikey")
  expect_equal(result, list(apikey = "my_secret_key"))
})

test_that("read_key_value_list - multiple parameters", {
  # Multiple parameters should parse JSON
  json_str <- '{"api_key": "secret123", "account_id": "acc456"}'
  result <- read_key_value_list(json_str, c("api_key", "account_id"))

  expect_equal(result$api_key, "secret123")
  expect_equal(result$account_id, "acc456")
})

test_that("read_key_value_list - invalid JSON for multiple params", {
  # Should error with helpful message if JSON is invalid
  expect_error(
    read_key_value_list("not valid json", c("api_key", "secret")),
    "For multi-parameter query auth, credentials must be stored as JSON"
  )
})
