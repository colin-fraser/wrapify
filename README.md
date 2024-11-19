
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
implementation of this is found in the directory. This is the full code
for a minimal wrapper that hits the [`models`
resource](https://platform.openai.com/docs/api-reference/models/list),
which lists the available models.

``` r
library(wrapify)
openai_wrapper <- wrapper(
  base_url = "https://api.openai.com/v1",
  auth = bearer_auth_type(),
  env_var_name = "OPENAI_KEY"
)

list_models <- requestor(openai_wrapper, "models")

list_models()$data[[1]]  # there are a lot of models. Let's just look at the first one.
#> $id
#> [1] "gpt-4-1106-preview"
#> 
#> $object
#> [1] "model"
#> 
#> $created
#> [1] 1698957206
#> 
#> $owned_by
#> [1] "system"
```

One can also provide a custom `extractor` function which takes the
retrieved `response` object and outputs data in a desired format.

``` r
list_models <- requestor(
  openai_wrapper, 
  "models",
  extractor = \(x) {
    # takes an httr2 response x and returns a data.frame
    data.frame(do.call(cbind, httr2::resp_body_json(x, simplifyVector = TRUE)$data))
  }
)
list_models()
#>                                    id object    created        owned_by
#> 1                  gpt-4-1106-preview  model 1698957206          system
#> 2                          o1-preview  model 1725648897          system
#> 3                               gpt-4  model 1687882411          openai
#> 4               o1-preview-2024-09-12  model 1725648865          system
#> 5                   gpt-4o-2024-08-06  model 1722814719          system
#> 6                  o1-mini-2024-09-12  model 1725648979          system
#> 7                             o1-mini  model 1725649008          system
#> 8                            dall-e-2  model 1698798177          system
#> 9                              gpt-4o  model 1715367049          system
#> 10                        gpt-4o-mini  model 1721172741          system
#> 11             gpt-4o-mini-2024-07-18  model 1721172717          system
#> 12             gpt-3.5-turbo-instruct  model 1692901427          system
#> 13                      gpt-3.5-turbo  model 1677610602          openai
#> 14                 gpt-3.5-turbo-0125  model 1706048358          system
#> 15                        babbage-002  model 1692634615          system
#> 16                        davinci-002  model 1692634301          system
#> 17                           dall-e-3  model 1698785189          system
#> 18                  chatgpt-4o-latest  model 1723515131          system
#> 19             gpt-3.5-turbo-16k-0613  model 1685474247          openai
#> 20             text-embedding-3-large  model 1705953180          system
#> 21                  gpt-3.5-turbo-16k  model 1683758102 openai-internal
#> 22                 gpt-3.5-turbo-0301  model 1677649963          openai
#> 23                      tts-1-hd-1106  model 1699053533          system
#> 24                gpt-4-turbo-preview  model 1706037777          system
#> 25             text-embedding-ada-002  model 1671217299 openai-internal
#> 26                         gpt-4-0613  model 1686588896          openai
#> 27             text-embedding-3-small  model 1705948997          system
#> 28                           tts-1-hd  model 1699046015          system
#> 29                          whisper-1  model 1677532384 openai-internal
#> 30                 gpt-3.5-turbo-1106  model 1698959748          system
#> 31                        gpt-4-turbo  model 1712361441          system
#> 32               gpt-4o-audio-preview  model 1727460443          system
#> 33                 gpt-3.5-turbo-0613  model 1686587434          openai
#> 34    gpt-4o-audio-preview-2024-10-01  model 1727389042          system
#> 35                 gpt-4-0125-preview  model 1706037612          system
#> 36            gpt-4o-realtime-preview  model 1727659998          system
#> 37                              tts-1  model 1681940951 openai-internal
#> 38                         tts-1-1106  model 1699053241          system
#> 39        gpt-3.5-turbo-instruct-0914  model 1694122472          system
#> 40             gpt-4-turbo-2024-04-09  model 1712601677          system
#> 41                  gpt-4o-2024-05-13  model 1715368132          system
#> 42 gpt-4o-realtime-preview-2024-10-01  model 1727131766          system
```

### Wrappers

We start by creating a wrapper, which stores some baseline properties of
the API.

``` r
library(wrapify)
openai_wrapper <- wrapper(
  base_url = "https://api.openai.com/v1",
  auth = bearer_auth_type(),
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

#' @export
chat_completion <- requestor(
  wrapper = openai_wrapper,
  resource = "chat/completions",
  method = "post",
  body_args = function_args(
    messages = , # specifying an empty value forces the argument to be required
    model = "gpt-3.5-turbo", # setting a default value for an argument
    temperature = NULL, # making an argument optional
    n = 1,
    stop = NULL,
    max_tokens = NULL,
    presence_penalty = NULL,
    frequency_penalty = NULL,
    logit_bias = NULL,
    user = NULL
  ),
  extractor = \(x) {
    httr2::resp_body_json(x)$choices[[1]]$message$content
  }
)

chat_completion(list(list(role = "user", content = "hi there")))
#> [1] "Hello! How can I assist you today?"
```

This creates a requestor function called *chat_completion* which makes
the specified API call, and extracts the text of the response. The
resulting function has arguments specified by the `body_args` argument
above.

``` r
str(chat_completion)
#> function (messages, model = "gpt-3.5-turbo", temperature = NULL, n = 1, 
#>     stop = NULL, max_tokens = NULL, presence_penalty = NULL, frequency_penalty = NULL, 
#>     logit_bias = NULL, user = NULL, ..., .credentials = get_credentials_from_wrapper(wrapper), 
#>     .perform = perform_by_default, .extract = extract_body_by_default, 
#>     .extractor = extractor)
```

Calling this function sends the specified request to the API. We can
check how this works without actually sending the request by setting
`.perform = FALSE`. This will return the `httr2` `request` object that
has been created.

``` r
chat_completion("hello there!", credentials = "[API KEY]", .perform = FALSE)
#> <httr2_request>
#> POST https://api.openai.com/v1/chat/completions
#> Headers:
#> • content-type: 'application/json'
#> • Authorization: '<REDACTED>'
#> Body: json encoded data
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
#> [1] "Hello! I'm just a computer program, so I don't have feelings, but I'm here to help you. How can I assist you today?"
```

To make this easier, the super_simple_constructor function creates
constructors of named lists.

``` r
chat_message <- super_simple_constructor(content = , role = "user")
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
#> [1] "Hello! How can I assist you today?"
```

To make this even easier for the user, you might implement even more of
this boilerplate for them.

``` r
quick_chat_completion <- function(user_message, ...) {
  messages <- list(chat_message(user_message))
  chat_completion(messages, ...)
}

quick_chat_completion("What is the square root of 100?")
#> [1] "The square root of 100 is 10."
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
#> #' @param messages [Description of messages]
#> #' @param model [Description of model]
#> #' @param temperature [Description of temperature]
#> #' @param n [Description of n]
#> #' @param stop [Description of stop]
#> #' @param max_tokens [Description of max_tokens]
#> #' @param presence_penalty [Description of presence_penalty]
#> #' @param frequency_penalty [Description of frequency_penalty]
#> #' @param logit_bias [Description of logit_bias]
#> #' @param user [Description of user]
#> #' @param ... [Description of ...]
#> #' @param .credentials [Description of .credentials]
#> #' @param .perform [Description of .perform]
#> #' @param .extract [Description of .extract]
#> #' @param .extractor [Description of .extractor]
#> #' 
#> #' @return [Describe the return value here]
#> #' @export
```
