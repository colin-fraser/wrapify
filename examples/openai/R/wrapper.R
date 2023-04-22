#' @import wrapify
openai <- wrapper(
  hostname = "api.openai.com",
  base_path = "/v1",
  auth_type = bearer_auth_type(),
  key_management = "env",
  env_var_name = "OPENAI_KEY"
)

#' List models
#'
#' Lists available models from OpenAI
#'
#' @param ... arguments passed to the perform function
#' @param credentials API token
#' @param action either "perform" or "dryrun"
#' @param decode_if_success should decode if success?
#'
#' @return A list of available models
#' @export
list_models <- requestor(openai, "models")

#' Retrieve model
#'
#' Retrieve a model from the id
#'
#' @param model Model ID
#' @param ... arguments passed to the request performer
#' @param credentials API key
#' @param action perform or dry run
#' @param decode_if_success decode the result?
#'
#' @return List of information about a model instance.
#' @export
retrieve_model <- requestor(
  openai,
  resource = "models/{model}",
  resource_args = function_args(model = )
)

#' Chat Completion
#'
#' Generate a chat completion
#'
#' @param messages A list of messages. Create using `chat_message`
#' @param model The model
#' @param temperature The temperature
#' @param n The number of responses to request
#' @param stop sequences to end the completion
#' @param max_tokens Largest number of tokens to return
#' @param presence_penalty presence_penalty
#' @param frequency_penalty frequency penalty
#' @param logit_bias Modify the likelihood of specific tokens
#' @param user The unique identifier of the requesting user
#' @param ... Arguments passed to the request runction
#' @param credentials API Token
#' @param action perform or dry run
#' @param decode_if_success decode if success?
#'
#' @return A list of chat completion objects
#' @export
chat_completion <- requestor(
  openai,
  "chat/completions",
  method = "post",
  body_args = function_args(
    messages = ,
    model = "gpt-3.5-turbo",
    temperature = NULL,
    n = 1,
    stop = NULL,
    max_tokens = NULL,
    presence_penalty = NULL,
    frequency_penalty = NULL,
    logit_bias = NULL,
    user = NULL
  )
)

#' Quick chat completion
#'
#' Generates a quick chat completion
#'
#' @param user_message User message
#' @param system_message System message
#' @param ... arguments passed to chat_completion
#'
#' @return The returned completion from OpenAI
#' @export
quick_chat_completion <- function(user_message, system_message = NULL, ...) {
  if (!is.null(system_message)) {
    system_message <- list(chat_message(system_message, "system"))
  }
  chat_completion(c(system_message, list(chat_message(user_message))), ...)
}

#' Generate a message object
#'
#' Generates a chat_message object. This is used in the chat_completion functions.
#'
#' @param role role of the message
#' @param content content of the message
#' @param name name of the message sender
#'
#' @return A chat_message object, which is just a named list with content, role, and name.
#' @export
chat_message <- super_simple_constructor(content =, role = "user", name = NULL)

#' Save an API key to an environment variable
#'
#' Saves the key
#'
#' @param credentials the value of the key to save. Asks the user by default.
#'
#' @return A logical vector as per Sys.setenv
#' @export
set_api_key <- credential_setter(openai)
