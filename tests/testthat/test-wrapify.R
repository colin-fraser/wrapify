test_wrapper <- wrapper(
  hostname = "api.example.com",
  base_path = "/v1",
  auth_type = "none",
  key_management = "none",
  scheme = "https",
  user_agent = "test_agent",
  default_content_type = "application/json"
)

test_that("wrapper function creates a valid wrapper object", {
  expect_named(test_wrapper, c("url", "user_agent", "default_content_type", "auth_type", "key_management", "default_query_args", "env_var_name"))
  expect_equal(test_wrapper$url$hostname, "api.example.com")
  expect_equal(test_wrapper$url$path, "/v1")
  expect_equal(test_wrapper$url$scheme, "https")
  expect_equal(test_wrapper$user_agent, "test_agent")
  expect_equal(test_wrapper$default_content_type, "application/json")
  expect_equal(test_wrapper$auth_type$type, "none")
  expect_equal(test_wrapper$key_management, "none")
  expect_null(test_wrapper$default_query_args)
  expect_null(test_wrapper$env_var_name)
})

# Create a test requestor function for the "/users" endpoint
test_requestor <- requestor(
  test_wrapper,
  "users",
  query_args = function_args(userid = , fields = "all")
)

test_that("requestor function creates a valid requestor function", {
  expect_type(test_requestor, "closure")
  expect_named(formals(test_requestor), c("userid", "fields", "...", "credentials", "action", "decode_if_success"))
  expect_equal(formals(test_requestor)$fields, "all")
})

# Test the requestor function with a dry run
test_that("requestor function performs a dry run correctly", {
  response <- test_requestor(userid = 1, action = "dryrun")
  expect_type(response, "list")
  expect_equal(response$method, "GET")
  expect_equal(response$headers$`user-agent`, "test_agent")
})

jsonplaceholder_wrapper <- wrapper(
  hostname = "jsonplaceholder.typicode.com",
  base_path = "",
  auth_type = "none",
  key_management = "none",
  scheme = "https",
  user_agent = "test_agent",
  default_content_type = "application/json"
)

users_requestor <- requestor(
  jsonplaceholder_wrapper,
  "users",
  query_args = function_args(id = )
)

test_that("requestor function retrieves a user from the JSONPlaceholder API", {
  # Make a request to the "/users" endpoint with a specific user ID
  response <- users_requestor(id = 1, action = "perform")

  # Check if the user object has the expected properties
  expect_named(response[[1]], c("id", "name", "username", "email", "address", "phone", "website", "company"))

  # Check if some properties have the expected values
  expect_equal(response[[1]]$id, 1)
})
