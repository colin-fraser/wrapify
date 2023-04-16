todoist <- wrapify::wrapper(
  "api.todoist.com",
  "/rest/v2",
  auth_type = wrapify::bearer_auth_type(),
  key_management = "env",
  env_var_name = "TODOIST_API_KEY"
)

set_todoist_key <- \(x) Sys.setenv(TODOIST_API_KEY = x)

get_projects <- requestor(todoist, "projects")
get_project <- requestor(todoist, 'projects/{project_id}', resource_args = function_args(project_id = ))

create_task <- requestor(todoist, "tasks", method = "post",
                         body_args = function_args(
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
