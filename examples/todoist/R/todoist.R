todoist <- wrapify::wrapper(
  "https://api.todoist.com/rest/v2",
  auth = bearer_auth_type(),
  env_var_name = "TODOIST_API_KEY"
)

#' Get projects
#'
#' Get a list of projects
#'
#' @param ... Arguments passed to the requestor function
#' @param credentials Credential
#' @param action dryrun or perform
#' @param decode_if_success Decode if success?
#'
#' @importFrom wrapify requestor
#'
#' @return a list of projects
#' @export
get_projects <- wrapify::requestor(
  todoist,
  "projects",
  extractor = \(x) {
    httr2::resp_body_json(x) |>
      purrr::map_depth(2, \(x) if (is.null(x)) NA else x) |>
      purrr::map(tibble::as_tibble) |>
      purrr::list_rbind()
  })

#' @export
get_project <- wrapify::requestor(
  todoist,
  'projects/{project_id}',
  resource_args = wrapify::function_args(project_id = )
  )

#' @export
create_task <- wrapify::requestor(todoist, "tasks", method = "post",
                         body_args = wrapify::function_args(
                           content = ,
                           description = NULL,
                           project_id = NULL,
                           section_id = NULL,
                           parent_id = NULL,
                           order = NULL,
                           labels = NULL,
                           priority = NULL,
                           due_string = NULL,
                           due_date = NULL,
                           due_datetime = NULL,
                           due_lang = NULL,
                           assignee_id = NULL
                         ))
