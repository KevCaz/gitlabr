#' List projects in Gitlab
#' 
#' @param ... passed on to \code{\link{gitlab}}
#' @export
list_projects <- function(...) {
  gitlab("projects", ...)
}

#' Access to repository functions in Gitlab API
#' 
#' @param project name or id of project (not repository!)
#' @param req request to perform on repository (everything after '/repository/'
#' in gitlab API, as vector or part of URL)
#' @param ... passed on to \code{\link{gitlab}} API call, may include \code{path} argument for path
#' @export
repository <- function(project  
                     , req = c("tree")
                     , ...) {
  gitlab(c("projects", to_project_id(project, ...), "repository", req), ...)
}

#' @rdname repository
#' @import functional
#' @export
list_files <- functional::Curry(repository, req = "tree") ## should have a recursive option

#' Get a project id by name
#' @param project_name project name
#' @param ... passed on to \code{\link{gitlab}}
#' @export
get_project_id <- function(project_name, ...) {
  gitlab("projects", ...) %>%
    filter(name == project_name) %>%
    getElement("id") %>%
    as.integer()
}

to_project_id <- function(x, ...) {
  if (is.numeric(x)) {
    x
  } else
    get_project_id(x, ...)
}

#' Get a file from a gitlab repository
#' 
#' @param project name or id of project
#' @param file_path path to file
#' @param ref name of ref (commit branch or tag)
#' @param to_char flag if output should be converted to char; otherwise it is of class raw
#' @param ... passed on to \code{\link{gitlab}}
#' @export
#' @importFrom base64enc base64decode
get_file <- function(project
                   , file_path
                   , ref = "master"
                   , to_char = TRUE
                   , ...) {
  
  repository(project = project
           , req = "files"
           , file_path = file_path
           , ref = ref
           , verb = httr::GET
           , ...)$content %>% 
    base64decode() %>%
    iff(to_char, rawToChar)
  
}

#' Get zip archive of a specific repository
#' 
#' @param project Project name or id
#' @param save_to_file path where to save archive; if this is NULL, the archive
#' itself is returned as a raw vector
#' @param ... further parameters passed on to \code{\link{gitlab API}},
#' may include parameter \code{sha} for specifying a commit hash
#' @return if save_to_file is NULL, a raw vector of the archive, else the path
#' to the saved archived file 
archive <- function(project
                  , save_to_file = tempfile(fileext = ".zip")
                  , ...) {
  
  raw_archive <- repository(project = project, req = "archive", ...)
  if (!is.null(save_to_file)) {
    writeBin(raw_archive, save_to_file)
    return(save_to_file)
  } else {
    return(raw_archives)
  }
  
}

#' Compare to refs from a project repository
#' 
#' @noRd
#' 
#' This function is currently not exported since its output's format is rather ugly
#' 
#' @param project project name or id
#' @param from commit hash or ref/branch/tag name to compare from
#' @param tp commit hash or ref/branch/tag name to compare to
#' @param ... further parameters passed on to \code{\link{gitlab}}
compare_refs <- function(project
                  , from
                  , to
                  , ...) {
  repository(project = project
           , req = "compare"
           , from = from
           , to = to
           , ...)
}

#' Get commits and diff from a project repository
#' 
#' @param project project name or id
#' @param commit_sha if not null, get only the commit with the specific hash; for
#' \code{get_diff} this must be specified
#' @param ... passed on to \code{\link{gitlab}} API call, may contain
#' \code{ref_name} for specifying a branch or tag to list commits of
#' @export
get_commits <- function(project
                      , commit_sha = c()
                      , ...) {
  
  project <- to_project_id(project, ...)
  
  repository(project = project
           , req = c("commits", commit_sha)
           , auto_format = is.null(commit_sha)
           , ...)
}

#' @rdname get_commits
#' @export
get_diff <-  function(project
                     , commit_sha
                     , ...) {
  
  repository(project = project
           , req = c("commits", commit_sha, "diff")
           , ...)
}