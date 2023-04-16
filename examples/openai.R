openai <- wrapper("api.openai.com", "/v1",
                  auth_type = bearer_auth_type(),
                  key_management = "env",
                  env_var_name = "OPENAI_KEY"
                  )

list_models <- requestor(openai, "models")

chat_completion <- requestor(openai,
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
                             ))
chatgpt_message <- super_simple_constructor(role = , content = , user = NULL)
simple_chat <- function(message, ...) {
  chat_completion(list(chatgpt_message("user", message)), ...)
}
extract_content <- function(chat_response) {
  purrr::map_chr(chat_response$choices, c("message", "content"))
}
