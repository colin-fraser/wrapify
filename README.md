
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `wrapify`: A package for making API packages

<!-- badges: start -->
<!-- badges: end -->

`wrapify` is for quickly generating API wrappers in R. It abstracts a
lot of the boilerplate in creating these packages manually using `httr2`
(which already itself abstracts a lot of boilerplate).

## Installation

You can install the development version of wrapify from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("colin-fraser/wrapify")
```

## A simple example

Here’s how to construct a wrapper around the OpenAI API. A more complete
implementation of this is found in the
[`examples/openai`](examples/openai) directory. This is the full code
for a minimal package that hits the Chat Completion resource:

``` r
openai_wrapper <- wrapper(
  hostname = "api.openai.com",
  base_path = "/v1",
  auth_type = bearer_auth_type(),
  key_management = "env",
  env_var_name = "OPENAI_KEY"
)

#' @export
chat_message <- super_simple_constructor(content = , role = 'user')

#' @export
chat_completion <- requestor(
  wrapper = openai_wrapper,
  resource = "chat/completions",
  method = "post",
  body_args = function_args(
    messages = ,  # specifying an empty value forces the argument to be required
    model = "gpt-3.5-turbo",  # setting a default value for an argument
    temperature = NULL,  # making an argument optional
    n = 1,
    stop = NULL,
    max_tokens = NULL,
    presence_penalty = NULL,
    frequency_penalty = NULL,
    logit_bias = NULL,
    user = NULL
  )
)
```

This would create an R package with two exported functions,
`chat_completion` which hits the OpenAI API and `chat_message` which
constructs `message` objects as specified in the API documentation. See
below for more details.

### Wrappers

We start by creating a wrapper, which stores some baseline properties of
the API.

``` r
library(wrapify)
openai_wrapper <- wrapper(
  hostname = "api.openai.com",
  base_path = "/v1",
  auth_type = bearer_auth_type(),
  key_management = "env",
  env_var_name = "OPENAI_KEY"
)
```

This specifies that we will be building a wrapper for an API hosted at
`api.openai.com/v1`, that the API uses Bearer tokens, and that we expect
the user to store their API key in an environment variable called
`"OPENAI_KEY"`.

### Requestors

Now we can create requestors using the `requestor` function. Here’s one
that implements the [Chat
Complation](https://platform.openai.com/docs/guides/chat) request.

``` r
chat_completion <- requestor(
  wrapper = openai_wrapper,
  resource = "chat/completions",
  method = "post",
  body_args = function_args(
    messages = ,  # specifying an empty value forces the argument to be required
    model = "gpt-3.5-turbo",  # setting a default value for an argument
    temperature = NULL,  # making an argument optional
    n = 1,
    stop = NULL,
    max_tokens = NULL,
    presence_penalty = NULL,
    frequency_penalty = NULL,
    logit_bias = NULL,
    user = NULL
  )
)
```

This creates a requestor function called *chat_completion* which makes
the specified API call. The resulting function has arguments specified
by the `body_args` argument above.

``` r
str(chat_completion)
#> function (messages, model = "gpt-3.5-turbo", temperature = NULL, n = 1, 
#>     stop = NULL, max_tokens = NULL, presence_penalty = NULL, frequency_penalty = NULL, 
#>     logit_bias = NULL, user = NULL, ..., credentials = default_credentials(wrapper), 
#>     action = default_action, decode_if_success = decode_if_success_default_value)
```

Calling this function sends the specified request to the API. We can
check how this works without actually sending the request by setting
`action = 'dryrun'`.

``` r
chat_completion("hello there!", action = "dryrun", credentials = "[API KEY]")
#> POST /v1/chat/completions HTTP/1.1
#> Host: api.openai.com
#> User-Agent: wrapify
#> Accept: */*
#> Accept-Encoding: deflate, gzip
#> Authorization: <REDACTED>
#> Content-Type: application/json
#> Content-Length: 57
#> 
#> {"messages":"hello there!","model":"gpt-3.5-turbo","n":1}
#> $method
#> [1] "POST"
#> 
#> $path
#> [1] "/v1/chat/completions"
#> 
#> $headers
#> $headers$accept
#> [1] "*/*"
#> 
#> $headers$`accept-encoding`
#> [1] "deflate, gzip"
#> 
#> $headers$authorization
#> [1] "Bearer [API KEY]"
#> 
#> $headers$`content-length`
#> [1] "57"
#> 
#> $headers$`content-type`
#> [1] "application/json"
#> 
#> $headers$host
#> [1] "api.openai.com"
#> 
#> $headers$`user-agent`
#> [1] "wrapify"
```

### Simple Constructs

If I go ahead and run the function as specified above, I will run into a
problem. Referring to the [Chat completion
documentation](https://platform.openai.com/docs/guides/chat), it turns
out that the `messages` argument can’t just be a simple string; it needs
to be a list of specially formatted message objects. The documentation
gives the following example.

    curl https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d '{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Hello!"}]
      }'

We can relatively straightforwardly construct this input on the fly and
call the function but it’s a bit awkward.

``` r
chat_completion(list(list(role = "user", content = "hello, how are you?")))
#> $id
#> [1] "chatcmpl-776vTjZFXHUgqXY9Uu3EKFBbEnXl1"
#> 
#> $object
#> [1] "chat.completion"
#> 
#> $created
#> [1] 1681929275
#> 
#> $model
#> [1] "gpt-3.5-turbo-0301"
#> 
#> $usage
#> $usage$prompt_tokens
#> [1] 14
#> 
#> $usage$completion_tokens
#> [1] 31
#> 
#> $usage$total_tokens
#> [1] 45
#> 
#> 
#> $choices
#> $choices[[1]]
#> $choices[[1]]$message
#> $choices[[1]]$message$role
#> [1] "assistant"
#> 
#> $choices[[1]]$message$content
#> [1] "As an AI language model, I don't have feelings. However, I am functioning properly and ready to assist you. How may I help you today?"
#> 
#> 
#> $choices[[1]]$finish_reason
#> [1] "stop"
#> 
#> $choices[[1]]$index
#> [1] 0
```

To make this easier, the super_simple_constructor function creates
constructors of named lists.

``` r
chat_message <- super_simple_constructor(content = , role = 'user')
```

This creates a function called `chat_message` that returns a named list
in the right format.

``` r
chat_message("hello there!")
#> $content
#> [1] "hello there!"
#> 
#> $role
#> [1] "user"
#> 
#> attr(,"class")
#> [1] "supersimpleconstruct" "list"
```

This makes calling the API function more straightforward.

``` r
chat_completion(list(chat_message("hello there!")))
#> $id
#> [1] "chatcmpl-776vVeiO5kChtJB2PfDBLOfzVnQ5x"
#> 
#> $object
#> [1] "chat.completion"
#> 
#> $created
#> [1] 1681929277
#> 
#> $model
#> [1] "gpt-3.5-turbo-0301"
#> 
#> $usage
#> $usage$prompt_tokens
#> [1] 11
#> 
#> $usage$completion_tokens
#> [1] 8
#> 
#> $usage$total_tokens
#> [1] 19
#> 
#> 
#> $choices
#> $choices[[1]]
#> $choices[[1]]$message
#> $choices[[1]]$message$role
#> [1] "assistant"
#> 
#> $choices[[1]]$message$content
#> [1] "Hello! How may I assist you?"
#> 
#> 
#> $choices[[1]]$finish_reason
#> [1] "stop"
#> 
#> $choices[[1]]$index
#> [1] 0
```

To make this even easier for the user, you might implement even more of
this boilerplate for them.

``` r
quick_chat_completion <- function(user_message, ...) {
  messages <- list(chat_message(user_message))
  chat_completion(messages, ...)
}

quick_chat_completion("What is the square root of 100?")
#> $id
#> [1] "chatcmpl-776vXzfJ5SIcOrqV473uOKgWwBJ3G"
#> 
#> $object
#> [1] "chat.completion"
#> 
#> $created
#> [1] 1681929279
#> 
#> $model
#> [1] "gpt-3.5-turbo-0301"
#> 
#> $usage
#> $usage$prompt_tokens
#> [1] 17
#> 
#> $usage$completion_tokens
#> [1] 10
#> 
#> $usage$total_tokens
#> [1] 27
#> 
#> 
#> $choices
#> $choices[[1]]
#> $choices[[1]]$message
#> $choices[[1]]$message$role
#> [1] "assistant"
#> 
#> $choices[[1]]$message$content
#> [1] "The square root of 100 is 10."
#> 
#> 
#> $choices[[1]]$finish_reason
#> [1] "stop"
#> 
#> $choices[[1]]$index
#> [1] 0
```

### Documenting the requestor functions

Since the main point of this package is to provide tools for building
packages, you’ll want to document the requestor functions. To help with
this, there is a function called `generate_roxygen_comment` that
constructs Roxygen2 comment templates for the functions that you create
with `requestor`.

``` r
generate_roxygen_comment(chat_completion)
#> #' chat_completion
#> #' 
#> #' [Add a description here]
#> #' 
#> #' @param messages Description of messages
#> #' @param model Description of model
#> #' @param temperature Description of temperature
#> #' @param n Description of n
#> #' @param stop Description of stop
#> #' @param max_tokens Description of max_tokens
#> #' @param presence_penalty Description of presence_penalty
#> #' @param frequency_penalty Description of frequency_penalty
#> #' @param logit_bias Description of logit_bias
#> #' @param user Description of user
#> #' @param ... Description of ...
#> #' @param credentials Description of credentials
#> #' @param action Description of action
#> #' @param decode_if_success Description of decode_if_success
#> #' 
#> #' @return [Describe the return value here]
#> #' @export
```
