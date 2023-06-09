% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrapper.R
\name{chat_completion}
\alias{chat_completion}
\title{Chat Completion}
\usage{
chat_completion(
  messages,
  model = "gpt-3.5-turbo",
  temperature = NULL,
  n = 1,
  stop = NULL,
  max_tokens = NULL,
  presence_penalty = NULL,
  frequency_penalty = NULL,
  logit_bias = NULL,
  user = NULL,
  ...,
  credentials = default_credentials(wrapper),
  action = default_action,
  decode_if_success = decode_if_success_default_value
)
}
\arguments{
\item{messages}{A list of messages. Create using \code{chat_message}}

\item{model}{The model}

\item{temperature}{The temperature}

\item{n}{The number of responses to request}

\item{stop}{sequences to end the completion}

\item{max_tokens}{Largest number of tokens to return}

\item{presence_penalty}{presence_penalty}

\item{frequency_penalty}{frequency penalty}

\item{logit_bias}{Modify the likelihood of specific tokens}

\item{user}{The unique identifier of the requesting user}

\item{...}{Arguments passed to the request runction}

\item{credentials}{API Token}

\item{action}{perform or dry run}

\item{decode_if_success}{decode if success?}
}
\value{
A list of chat completion objects
}
\description{
Generate a chat completion
}
