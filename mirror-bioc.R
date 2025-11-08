
# https://github.com/r-universe-org/sync/blob/6511d1b279ecf50fe013ee48744e549246907578/R/monorepos.R#L868-L880

metabioc_dummy_registry <- function () {
    nomirror <- c ('SwathXtend', 'h5vc') # large git files
    skiplist <- c ('IntOMICS') # package was renamed bc trademarks
    yml <- yaml::read_yaml ("https://bioconductor.org/config.yaml")
    bioc_version <- yml$devel_version
    bioc <- jsonlite::read_json (sprintf ('https://bioconductor.org/packages/json/%s/bioc/packages.json', bioc_version))
    stopifnot (length (bioc) > 2100)
    bioc <- Filter (function (x) !identical (x$PackageStatus, 'Deprecated') || identical (x$Package, 'zlibbioc'), bioc)
    lapply (setdiff (names (bioc), skiplist), function (x) {
        baseurl <- ifelse (x %in% nomirror, "https://git.bioconductor.org/packages/", "https://github.com/bioc/")
        list (package = x, url = paste0 (baseurl, x ))
    })
}
pkgs <- metabioc_dummy_registry ()
jsonlite::write_json (pkgs, "bioc-packages.json", auto_unbox = TRUE, pretty = TRUE)
