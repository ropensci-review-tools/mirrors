
# https://github.com/r-universe-org/sync/blob/6511d1b279ecf50fe013ee48744e549246907578/R/monorepos.R#L868-L880

metabioc_dummy_registry <- function () {
    nomirror <- c ('SwathXtend', 'h5vc') # large git files
    skiplist <- c ('IntOMICS') # package was renamed bc trademarks
    skiplist <- c (skiplist, "Anaquin") # removed from github
    yml <- yaml::read_yaml ("https://bioconductor.org/config.yaml")
    bioc_version <- yml$devel_version
    bioc <- jsonlite::read_json (sprintf ('https://bioconductor.org/packages/json/%s/bioc/packages.json', bioc_version))
    stopifnot (length (bioc) > 2100)
    bioc <- Filter (function (x) !identical (x$PackageStatus, 'Deprecated') || identical (x$Package, 'zlibbioc'), bioc)
    out <- lapply (setdiff (names (bioc), skiplist), function (x) {
        baseurl <- ifelse (x %in% nomirror, "https://git.bioconductor.org/packages/", "https://github.com/bioc/")
        ghurls <- grep ("^https\\:\\/\\/github\\.com\\/", bioc[[x]], value = TRUE)
        if (length (ghurls) == 0L) {
            pkgurl <- paste0 (baseurl, x)
        } else {
            ghurls <- unlist (strsplit (ghurls, ",\\s*"))
            ghurls <- unique (gsub ("(\\/(issues|wiki).*|\\/|\\s.*)$", "", tolower (ghurls)))
            ghcom_url <- grep ("github\\.com", ghurls, value = TRUE)
            ghio_url <- grep ("github\\.io", ghurls, value = TRUE)
            if (length (ghcom_url) > 1L) {
                # Potentially multiple forks: resolve to latest
                gh_sp <- strsplit (ghcom_url, "\\/")
                org_repo <- lapply (gh_sp, function (i) tail (i, 2L))
                org_repo <- do.call (rbind, org_repo)
                commit_dates <- apply (org_repo, 1, function (i) {
                    x <- tryCatch (
                        gh::gh (
                            "/repos/:owner/:repo/commits",
                            owner = i [1],
                            repo = i [2],
                            .limit = 1L
                        ) [[1]],
                        error = function (e) NULL
                    )
                    ifelse (is.null (x), NA_character_, x$commit$committer$date)
                })
                i <- which.max (as.POSIXct (commit_dates))
                ghcom_url <- ghcom_url [i]
            }
            if (length (ghcom_url) == 1L) {
                pkgurl <- ghcom_url
            } else if (length (ghio_url) == 1L) {
                gh_org <- gsub ("^https\\:\\/\\/|\\..*$", "", ghio_url)
                gh_repo <- gsub ("^.*\\/", "", ghio_url)
                pkgurl <- paste0 ("https://github.com/", gh_org, "/", gh_repo)
            } else {
                stop ("More than 1 gh url for ", x)
            }
            pkgurl <- ghurls [1]
        }
        list (package = x, url = pkgurl)
    })
}
pkgs <- metabioc_dummy_registry ()
jsonlite::write_json (pkgs, "bioc-packages.json", auto_unbox = TRUE, pretty = TRUE)
