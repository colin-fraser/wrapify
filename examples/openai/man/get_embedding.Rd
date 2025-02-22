% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrapper.R
\name{get_embedding}
\alias{get_embedding}
\title{Get Embeddings}
\usage{
get_embedding(
  input,
  model = "text-embedding-3-small",
  dimensions = NULL,
  user = NULL,
  .credentials = get_credentials_from_wrapper(wrapper),
  .perform = perform_by_default,
  .extract = extract_body_by_default,
  .extractor = extractor
)
}
\arguments{
\item{input}{The input text}

\item{model}{Which embedding model to use}

\item{dimensions}{How many dimensions to return}

\item{user}{A user ID}

\item{...}{Arguments passed to the request function}

\item{credentials}{Credentials}

\item{action}{perform or dry run}

\item{decode_if_success}{decode if success?}
}
\value{
an embedding object
}
\description{
Gets embeddings from openai
}
