test_that("Wrapper construction", {
  example <- wrapper("example.com")
  expect_equal(example$auth$type, "none")
  expect_equal(example$default_headers$`content-type`, "application/json")

  # Test S3 class structure
  expect_s3_class(example, "wrapify_wrapper")
  expect_s3_class(example, "list")
})

test_that("Wrapper print and format methods", {
  w <- wrapper("https://api.example.com", auth = bearer_auth_type())

  # Test format method returns character vector
  formatted <- format(w)
  expect_type(formatted, "character")
  expect_true(any(grepl("api.example.com", formatted)))
  expect_true(any(grepl("bearer", formatted)))

  # Test print method (capture output)
  output <- capture.output(print(w))
  expect_true(any(grepl("wrapify_wrapper", output)))
  expect_true(any(grepl("api.example.com", output)))
})

test_that("Auth type S3 classes", {
  # Test each auth type has proper class
  none_auth <- auth_type("none")
  expect_s3_class(none_auth, "wrapify_auth")
  expect_s3_class(none_auth, "list")

  bearer <- bearer_auth_type()
  expect_s3_class(bearer, "wrapify_auth")

  header <- header_auth_type("x-api-key")
  expect_s3_class(header, "wrapify_auth")

  query <- query_auth_type(c("api_key", "secret"))
  expect_s3_class(query, "wrapify_auth")
})

test_that("Auth type print and format methods", {
  # Test bearer auth format
  bearer <- bearer_auth_type()
  formatted <- format(bearer)
  expect_match(formatted, "bearer token")

  # Test header auth format
  header <- header_auth_type("x-api-key")
  formatted <- format(header)
  expect_match(formatted, "header")
  expect_match(formatted, "x-api-key")

  # Test query auth format
  query <- query_auth_type(c("api_key", "secret"))
  formatted <- format(query)
  expect_match(formatted, "query")
  expect_match(formatted, "api_key")

  # Test print methods work without error
  expect_output(print(bearer), "bearer")
  expect_output(print(header), "x-api-key")
  expect_output(print(query), "api_key")
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

test_that("content_type parameter overrides default", {
  # Create a simple wrapper
  api <- wrapper("https://api.example.com")

  # Create requestor with custom content_type
  post_data <- requestor(
    api,
    "data",
    method = "post",
    content_type = "application/xml",
    body_args = function_args(data = "test")
  )

  # Get request without performing it
  req <- post_data(data = "test", .credentials = NULL, .perform = FALSE)

  # Check that content-type header was set to XML, not JSON
  headers <- req$headers
  expect_equal(headers$`content-type`, "application/xml")
})

test_that("content_type NULL uses default", {
  # Create a wrapper with default content-type
  api <- wrapper("https://api.example.com")

  # Create requestor without specifying content_type
  post_data <- requestor(
    api,
    "data",
    method = "post",
    content_type = NULL,
    body_args = function_args(data = "test")
  )

  # Get request without performing it
  req <- post_data(data = "test", .credentials = NULL, .perform = FALSE)

  # Check that default content-type is used (from wrapper defaults)
  headers <- req$headers
  expect_equal(headers$`content-type`, "application/json")
})

test_that(".additional_request_args passes arguments to req_perform", {
  # Mock a simple API endpoint
  app <- webfakes::new_app()
  app$get("/data", function(req, res) {
    res$send_json(list(status = "ok"))
  })
  app <- webfakes::local_app_process(app)

  # Create wrapper and requestor
  api <- wrapper(app$url())
  get_data <- requestor(api, "data")

  # Test passing verbosity argument to req_perform
  # Capture output to verify verbosity was passed
  output <- capture.output({
    resp <- get_data(
      .credentials = NULL,
      .additional_request_args = list(verbosity = 1),
      .extract = FALSE
    )
  })

  # Verify the request succeeded
  expect_equal(resp_status(resp), 200)

  # Verify body content
  body <- resp_body_json(resp)
  expect_equal(body$status[[1]], "ok")

  # When verbosity = 1, httr2 outputs request info
  expect_true(any(grepl("GET", output)))
})

test_that(".additional_request_args with path for caching", {
  # Mock a simple API endpoint
  app <- webfakes::new_app()
  app$get("/data", function(req, res) {
    res$send_json(list(status = "ok", timestamp = as.numeric(Sys.time())))
  })
  app <- webfakes::local_app_process(app)

  # Create wrapper and requestor
  api <- wrapper(app$url())
  get_data <- requestor(api, "data")

  # Create a temp file for caching
  cache_path <- tempfile(fileext = ".rds")
  on.exit(unlink(cache_path), add = TRUE)

  # Make first request with caching enabled
  resp1 <- get_data(
    .credentials = NULL,
    .additional_request_args = list(path = cache_path),
    .extract = FALSE
  )

  # Verify cache file was created
  expect_true(file.exists(cache_path))

  # Make second request - should use cache
  resp2 <- get_data(
    .credentials = NULL,
    .additional_request_args = list(path = cache_path),
    .extract = FALSE
  )

  # Both responses should be identical (same timestamp proves it's cached)
  expect_equal(resp_body_json(resp1)$timestamp, resp_body_json(resp2)$timestamp)
})
