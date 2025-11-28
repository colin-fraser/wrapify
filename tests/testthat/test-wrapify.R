test_that("Wrapper construction", {
  example <- wrapper("example.com")
  expect_equal(example$auth$type, "none")
  expect_equal(example$default_headers$`content-type`, "application/json")
})


test_that("Example openai wrapper", {
  # Mock OpenAI API
  app <- webfakes::new_app()
  app$use(\(req, res) {
    res$set_header("Authorization", req$headers$Authorization)
    "next"
  }, .first = TRUE)
  app$get("/models", function(req, res) {
    # Just return successful response - we'll verify auth in the request object
    res$
      send_json(list(
      data = list(
        list(id = "gpt-4", object = "model"),
        list(id = "gpt-3.5-turbo", object = "model")
      )
    ))
  })
  app <- webfakes::local_app_process(app)

  openai <- wrapper(
    app$url(),
    auth = bearer_auth_type()
  )

  list_models <- requestor(
    openai,
    "models"
  )

  expect_error(list_models(), "Wrapper has no default environment variable name")

  # Test with credentials provided
  resp <- list_models(.credentials = "test-api-key", .extract = FALSE)
  expect_equal(resp_status(resp), 200)

  # Verify the bearer token was sent correctly
  expect_equal(resp$headers$Authorization, "Bearer test-api-key")

})

test_that("Anthropic API wrapper with header auth", {
  # Test based on Anthropic API structure:
  # curl https://api.anthropic.com/v1/models \
  #   -H "X-Api-Key: $ANTHROPIC_API_KEY"
  app <- webfakes::new_app()
  app$get("/models", function(req, res) {
    res$send("claude-3.5")
  })
  app <- webfakes::local_app_process(app)
  url <- app$url()

  anth <- wrapper(
    url,
    auth = header_auth_type(header = "x-api-key")
  )

  # Test the models endpoint
  list_models <- requestor(
    anth,
    "models",
    header_constants = list("api-version" = "2025-01-01")
  )

  resp <- list_models(.credentials = "test-api-key-123")

  # Check URL is correct
  expect_match(resp$url, app$url("/models"))

  # Check that x-api-key header is set correctly
  expect_equal(req_get_headers(resp$request, redacted = 'reveal')$`x-api-key`, "test-api-key-123")
  expect_equal(req_get_headers(resp$request, redacted = 'reveal')$`api-version`, "2025-01-01")
})

test_that("Query auth - single parameter", {
  # Use httpbin which echoes back query parameters
  app <- webfakes::local_app_process(webfakes::httpbin_app())

  # Create wrapper with single-parameter query auth
  api <- wrapper(
    app$url(),
    auth = query_auth_type(param_names = "apikey")
  )

  # Create a simple requestor
  get_data <- requestor(
    api,
    "get"
  )

  # Test with plain string credential (not JSON)
  resp <- get_data(.credentials = list(apikey = "secret123"))

  # Verify the API key was sent in the query string
  expect_equal(resp$args$apikey, "secret123")
})

test_that("Query auth - multiple parameters", {
  # Use httpbin which echoes back query parameters
  app <- webfakes::local_app_process(webfakes::httpbin_app())

  # Create wrapper with multi-parameter query auth
  api <- wrapper(
    app$url(),
    auth = query_auth_type(param_names = c("api_key", "account_id"))
  )

  # Create a simple requestor
  get_data <- requestor(
    api,
    "get"
  )

  # Test with named list credentials
  creds <- list(api_key = "secret123", account_id = "acc456")
  resp <- get_data(.credentials = creds)

  # Verify both parameters were sent in the query string
  expect_equal(resp$args$api_key, "secret123")
  expect_equal(resp$args$account_id, "acc456")
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
