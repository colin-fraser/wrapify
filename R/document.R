#' Generate a Roxygen comment
#'
#' Generates a roxygen comment for a function for documentation.
#'
#' @param func The function to document
#' @param title The title of the function documentation (default: deparse(substitute(func)))
#' @param description The description of the function being documented (default: "\[Add a description here\]")
#' @param param_descriptions Description of the parameters of the function, in a named list (default: list())
#' @param return_description Description of the return value (default: "\[Describe the return value here\]")
#' @param examples Do you want to include examples? (default: FALSE)
#' @param export Do you want the function to be exported? (default: TRUE)
#' @param cat if TRUE, this will print the output on screen and return invisibly (default: TRUE)
#'
#' @return A string containing the generated Roxygen comment
#' @export
generate_roxygen_comment <- function(func,
                                     title = deparse(substitute(func)),
                                     description = "[Add a description here]",
                                     param_descriptions = list(),
                                     return_description = "[Describe the return value here]",
                                     examples = FALSE, export = TRUE, cat = TRUE) {
  func_name <- deparse(substitute(func))
  func_params <- formals(func)

  roxygen_comment <- c(
    generate_title_section(title),
    generate_description_section(description),
    generate_params_section(func_params, param_descriptions),
    generate_return_section(return_description)
  )

  if (examples) {
    roxygen_comment <- c(roxygen_comment, generate_examples_section(func_name, func_params))
  }

  if (export) {
    roxygen_comment <- c(roxygen_comment, generate_export_section())
  }

  roxygen_comment <- paste(roxygen_comment, collapse = "\n")

  if (cat) {
    cat(roxygen_comment)
    invisible(roxygen_comment)
  } else {
    roxygen_comment
  }
}


generate_title_section <- function(title) {
  generate_section(content = title, line_breaks = c(0, 0))
}

generate_description_section <- function(description) {
  generate_section(content = description)
}

generate_return_section <- function(return_description) {
  generate_section(tag = "return", content = return_description, line_breaks = c(1, 0))
}

generate_params_section <- function(func_params, param_descriptions) {
  builtin_descriptions <- c(
    ".credentials" = "Credentials to use, e.g. an API key",
    ".perform" = "Perform the request? If FALSE, an httr2 request object is returned.",
    ".extract" = "Extract the data? If FALSE, an httr2::response object is returned",
    ".extractor" = "A function which takes an httr2::response object and returns the desired data"
  )
  params_section <- unlist(lapply(names(func_params), function(param) {
    param_desc <- if (param %in% names(param_descriptions)) {
      param_descriptions[[param]]
    } else if (param %in% c('.credentials', '.perform', '.extract', '.extractor')) {
      builtin_descriptions[param]
    }

    else {
      paste0("[Description of ", param, "]")
    }
    generate_section(tag = "param", content = paste(param, param_desc), line_breaks = c(0, 0))
  }))
  params_section
}

generate_examples_section <- function(func_name, func_params) {
  examples_section <- c(
    generate_section(tag = "examples"),
    generate_section(content = "\\dontrun{"),
    generate_section(content = paste0(func_name, "(")),
    generate_section(content = if (length(func_params) > 0) paste(names(func_params), collapse = ", ") else ")"),
    generate_section(content = "}")
  )
  examples_section
}

generate_export_section <- function() {
  generate_section(tag = "export", line_breaks = c(0, 0))
}

generate_section <- function(tag = NULL, content = NULL, line_breaks = c(1, 1), prefix = "#' ") {
  if (is.null(tag) && is.null(content)) {
    stop("Both 'tag' and 'content' cannot be NULL.")
  }

  section <- c()

  if (!is.null(tag)) {
    if (!is.null(content)) {
      section <- c(section, paste0(prefix, "@", tag, " ", content))
    } else {
      section <- c(section, paste0(prefix, "@", tag))
    }
  } else {
    section <- c(section, paste0(prefix, content))
  }

  section <- c(rep(paste0(prefix), line_breaks[1]), section, rep(paste0(prefix), line_breaks[2]))

  section
}
