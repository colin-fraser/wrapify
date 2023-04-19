
<!-- README.md is generated from README.Rmd. Please edit that file -->

# OpenAI API wrapper

<!-- badges: start -->
<!-- badges: end -->

This is an example package to demonstrate the use of `wrapify` for
constructing simple API wrappers. Install with `devtools::install_github("colin-fraser/wrapify/examples/openai/")`.

``` r
library(openaiwrapper)
quick_chat_completion("What is 20 squared?", token = getPass::getPass("OpenAI API Key"))
#> $id
#> [1] "chatcmpl-76uJfR0gqQn3qyKwZa6WyC3n5i5bZ"
#> 
#> $object
#> [1] "chat.completion"
#> 
#> $created
#> [1] 1681880803
#> 
#> $model
#> [1] "gpt-3.5-turbo-0301"
#> 
#> $usage
#> $usage$prompt_tokens
#> [1] 14
#> 
#> $usage$completion_tokens
#> [1] 6
#> 
#> $usage$total_tokens
#> [1] 20
#> 
#> 
#> $choices
#> $choices[[1]]
#> $choices[[1]]$message
#> $choices[[1]]$message$role
#> [1] "assistant"
#> 
#> $choices[[1]]$message$content
#> [1] "20 squared is 400."
#> 
#> 
#> $choices[[1]]$finish_reason
#> [1] "stop"
#> 
#> $choices[[1]]$index
#> [1] 0
```

See [wrapper.R](R/wrapper.R) to see how this package is created using `wrapify`.
