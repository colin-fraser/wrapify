#' @export
#' @import rlang
#' @import httr2
wrapper <- function(hostname, base_path, auth_type = "none",
                    key_management = c('none', 'environment', 'ask'),
                    scheme = "https", user_agent = "wrapify",
                    default_content_type = "application/json",
                    default_query_args = NULL,
                    env_var_name = NULL,
                    ...) {
  key_management <- match.arg(key_management)
  if (key_management == 'environment' && is.null(env_var_name)) {
    abort("If key_management is set to \"environment\" then env_var_name must be supplied")
  }

  if (is.character(auth_type)) {
    auth_type <- auth_type(auth_type)
  }

  list(
    url = list(
      hostname = hostname,
      path = base_path,
      scheme = scheme
    ),
    user_agent = user_agent,
    default_content_type = default_content_type,
    auth_type = auth_type,
    key_management = key_management,
    default_query_args = default_query_args,
    env_var_name = env_var_name,
    ...
  )
}

wrapper_auth_type <- function(wrapper) wrapper$auth_type$type


#' @export
ask_for_credentials <- function(wrapper) {
  if (wrapper_auth_type(wrapper) == 'query') {
    set_names(lapply(wrapper$auth_type$param_names, \(x) getPass::getPass(x)),
              wrapper$auth_type$param_names)
  } else if (wrapper_auth_type(wrapper) == 'bearer') {
    getPass::getPass("API Key")
  }
}

default_content_type <- function(wrapper) wrapper$default_content_type

default_credentials <- function(wrapper) {
  switch(wrapper$key_management,
         "none" = NULL,
         "environment" = get_credential_from_environment(wrapper),
         "ask" = ask_for_credentials(wrapper))
}

get_credential_from_environment <- function(wrapper) {
  credential <- Sys.getenv(wrapper$env_var_name)
  if (is.null(credential) || credential == "") {
    abort("Credentials not found in environment variable ", wrapper$env_var_name)
  }
  credential
}

base_url <- function(wrapper) {
  httr2::url_build(wrapper$url)
}

request_from_wrapper <- function(wrapper) {
  req <- request(base_url(wrapper)) |>
    req_user_agent(wrapper$user_agent)

  req
}

#' @export
requestor <- function(wrapper,
                      resource,
                      resource_args = NULL,
                      resource_constants = NULL,
                      query_args = NULL,
                      query_constants = NULL,
                      body_args = NULL,
                      body_constants = NULL,
                      method = "get",
                      default_action = c("perform", "dryrun"),
                      content_type = NULL,
                      body_type = 'json',
                      additional_request_args = NULL) {
  default_action <- match.arg(default_action)
  content_type <- content_type %||% default_content_type(wrapper)
  args <- c(resource_args,
            query_args,
            wrapper$default_query_args,
            body_args)
  f <- function(..., credentials = default_credentials(wrapper),
                action = default_action,
                decode_if_success = TRUE) {
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
    out <- request_from_wrapper(wrapper) |>
      req_method(method) |>
      req_url_path_append(glue_url(resource, resource_arg_values)) |>
      req_url_query(!!!query_payload) |>
      authorize(wrapper, credentials)

    if (length(body_args) > 0) {
      out <- out |>
        req_body_json(purrr::compact(body_args))
    }

    if (action == "perform") {
      out <- req_perform(out)

      if (decode_if_success && !resp_is_error(out)) {
        out <- decoder(content_type)(out)
      }
    } else if (action == "dryrun") {
      out <- req_dry_run(out)
    }

    out
  }
  formals(f) <- c(args, formals(f))
  f
}

glue_url <- function(url, values) {
  for (nm in names(values)) {
    url <- gsub(paste0("\\{", nm, "\\}"), urltools::url_encode(values[[nm]]), url)
  }
  url
}

authorize <- function(req, wrapper, credentials) {
  switch(wrapper_auth_type(wrapper),
         "none" = req,
         "bearer" = req_auth_bearer_token(req, credentials),
         "query" = req_url_query(req, !!!credentials)
  )
}

decoder <- function(content_type) {
  switch(content_type,
    "application/json" = resp_body_json
  )
}

#' @export
function_args <- function(...) {
  rlang::pairlist2(...)
}
