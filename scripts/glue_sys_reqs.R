glue_sys_reqs <- function(pkgs) {
  rlang::check_installed("curl")
  rspm = Sys.getenv("RSPM_ROOT", "https://packagemanager.rstudio.com")
  rspm_repo_id = Sys.getenv("RSPM_REPO_ID", 1)
  rspm_repo_url = glue::glue("{rspm}/__api__/repos/{rspm_repo_id}")

  pkgnames = glue::glue_collapse(unique(pkgs), sep = "&pkgname=")

  req_url = glue::glue(
    "{rspm_repo_url}/sysreqs?all=false",
    "&pkgname={pkgnames}&distribution=ubuntu&release=22.04"
  )
  res = curl::curl_fetch_memory(req_url)
  sys_reqs = jsonlite::fromJSON(rawToChar(res$content), simplifyVector = FALSE)
  if (!is.null(sys_reqs$error)) rlang::abort(sys_reqs$error)

  sys_reqs = purrr::map(sys_reqs$requirements, purrr::pluck, "requirements", "packages")
  sys_reqs = sort(unique(unlist(sys_reqs)))
  sys_reqs = glue::glue_collapse(sys_reqs, sep = " \\\n    ")
  glue::glue(
    "RUN apt-get update -qq && \\ \n",
    "  apt-get install -y --no-install-recommends \\\n    ",
    sys_reqs,
    "\ && \\\n",
    "  apt-get clean && \\ \n",
    "  rm -rf /var/lib/apt/lists/*",
    .trim = FALSE
  )
}

# glue_sys_reqs(c("shiny", "dplyr"))
# #> RUN apt-get update -qq && \
# #>   apt-get install -y --no-install-recommends \
# #>     make \
# #>     zlib1g-dev && \
# #>   apt-get clean && \
# #>   rm -rf /var/lib/apt/lists/*

# appdir = "app/"
# pkgs = renv::dependencies(appdir)$Package
# sys_reqs = glue_sys_reqs(pkgs)
# https://www.jumpingrivers.com/blog/shiny-auto-docker/
