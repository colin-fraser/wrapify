#' Initialize a wrapper for an API
#'
#' This function creates a wrapper object for an API with the given settings.
#' The created wrapper can be used with the requestor function to make API calls.
#'
#' @param base_url The base URL
#' @param default_headers The default headers for API requests
#' @param default_query_args A named list of default query arguments to include in all API requests.
#' @param auth The authentication type
#' @param ... Additional arguments passed to the wrapper object.
#'
#' @return A wrapper object with the provided settings.
#' @export
#' @import rlang
#' @import httr2
wrapper <- function(base_url,
                    default_headers = list(
                      "content-type" = "application/json"
                    ),
                    default_query_args = list(),
                    auth = auth_spec("none"),
                    ...) {
  list(
    base_url = base_url,
    default_headers = default_headers,
    default_query_args = default_query_args,
    auth = auth,
    ...
  )
}

#' Create an API requestor function
#'
#' This function generates a custom requestor function for the given wrapper
#' and API endpoint. The generated function can be used to make API calls with
#' specified parameters and configurations. The resource_args, query_args, and
#' other argument lists will be the arguments of the returned function. These
#' should be created using the `function_args` function.
#'
#' @param wrapper The wrapper object initialized using the `wrapper` function.
#' @param resource The API endpoint to be called (e.g., "/users/{user_id}").
#' @param resource_args A named list of arguments to be used as path parameters in the returned function. Create using `function_args()`.
#' @param resource_constants A named list of constants to be used as path parameters.
#' @param query_args A named list of arguments to be used as query parameters in the returned function. Create using `function_args()`.
#' @param query_constants A named list of constants to be used as query parameters.
#' @param body_args A named list of arguments to be used as request body parameters in the returned function. Create using `function_args()`.
#' @param body_constants A named list of constants to be used as request body parameters.
#' @param method The HTTP method to use for the API request (default: "get"). Accepts "get", "post", "put", "delete", etc.
#' @param default_action The default action to perform when the generated requestor function is called (default: "perform"). Accepts "perform" or "dryrun".
#' @param content_type The content type for the API request (default: determined by the wrapper's default_content_type).
#' @param body_type The type of request body to use for the API request (default: 'json').
#' @param additional_request_args Additional arguments to be passed to the request object.
#' @param decode_if_success_default_value A logical value indicating whether to decode the response if the request is successful (default: TRUE).
#' @param post_process_default_value A logical value indicating whether to apply the post_processor by default.
#' @param post_processor A function that is applied to the return value. You might want to use as_tibble or something.
#'   If NULL then the return value is returned unchanged.
#'
#' @return A custom requestor function for making API calls with the specified settings. The returned function will have the specified resource_args, query_args, and other arguments.
#' @export
#' @import rlang
requestor <- function(wrapper,
                      resource,
                      resource_args = NULL,
                      resource_constants = NULL,
                      query_args = NULL,
                      query_constants = NULL,
                      body_args = NULL,
                      body_constants = NULL,
                      method = "get",
                      content_type = NULL,
                      body_type = "json",
                      additional_request_args = NULL,
                      perform_by_default = TRUE,
                      extract_body_by_default = TRUE,
                      extractor = "infer") {
  args <- c(
    resource_args,
    query_args,
    wrapper$default_query_args,
    body_args
  )
  f <- function(..., .credentials = get_credentials_from_wrapper(wrapper), .perform = perform_by_default, .extract = extract_body_by_default,
                .extractor = extractor) {
    for (arg in fn_fmls_syms()) {
      # TODO: get required argument checking to work
      check_required(arg)
    }

    if (length(query_args) > 0 || length(wrapper$default_query_args) > 0) {
      query_args <- rlang::env_get_list(nms = c(names(query_args), names(wrapper$default_query_args)))
    }
    if (length(resource_args) > 0) {
      resource_args <- rlang::env_get_list(nms = names(resource_args))
    }
    if (length(body_args) > 0) {
      body_args <- rlang::env_get_list(nms = names(body_args))
    }
    query_payload <- c(query_args, query_constants)
    resource_arg_values <- c(resource_args, resource_constants)

    out <- request_from_wrapper(wrapper, .credentials) |>
      req_method(method) |>
      req_url_path_append(glue_url(resource, resource_arg_values)) |>
      req_url_query(!!!query_payload)

    if (length(body_args) > 0) {
      out <- out |>
        req_body_json(purrr::compact(body_args))
    }

    if (!.perform) {
      return (out)
    }

    out <- req_perform(out)

    if (.extract) {
      extractor <- get_extractor(.extractor)
      out <- extractor(out)
    }

    out
  }

  f_args <- c(args, formals(f))
  formals(f) <- f_args
  f
}

get_extractor <- function(x) {
  if (is.function(x)) {
    return(x)
  }
  if (x == "infer") {
    return(infer_extractor)
  }
  getFunction(x)
}

infer_extractor <- function(resp) {
  f <- switch(resp_content_type(resp),
    "application/json" = resp_body_json
  )
  f(resp)
}

request_from_wrapper <- function(wrapper, credentials) {
  r <- request(wrapper$base_url) |>
    req_headers(!!!wrapper$default_headers) |>
    req_url_query(!!!wrapper$default_query_args)

  authorize(r, wrapper, credentials)
}


glue_url <- function(template, params) {
  glue::glue_data(params, template)
}

authorize <- function(req, wrapper, credential) {
  if (wrapper$auth$type == "none") {
    return(req)
  }

  if (wrapper$auth$type == "bearer") {
    return(req_auth_bearer_token(req, credential))
  }

  if (wrapper$auth$type == "header") {
    h <- list2(`wrapper$auth$header` := credential)
    return(req_headers(req, !!! h))
  }
}



get_credentials_from_wrapper <- function(wrapper) {
  switch(wrapper$auth$type,
    "none" = NULL,
    "bearer" = get_env_var_from_wrapper(wrapper),
    "header" = get_env_var_from_wrapper(wrapper)
  )
}

get_env_var_from_wrapper <- function(wrapper) {
  if (is.null(wrapper$env_var_name)) {
    stop("Wrapper has no default environment variable name")
  }

  out <- Sys.getenv(wrapper$env_var_name)

  if (out == "") {
    abort(glue::glue("No API key found for environment variable {wrapper$env_var_name}"))
  }

  out
}

auth_spec <- function(type, header = NULL) {
  switch(type,
    "none" = list(type = "none"),
    "bearer" = list(type = "bearer"),
    "header" = list(type = "header", header = header)
  )
}


#' @export
function_args <- function(...) {
  rlang::pairlist2(...)
}
