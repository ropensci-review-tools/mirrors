# ------ Update pkgstats from archive

library (pkgstats)
path <- "/ua/cran-pkgstats/tarballs/"
results_path <- "/ua/cran-pkgstats/pkgstats/"
archive <- FALSE
results_file <- file.path (results_path, "pkgstats-CRAN-all.Rds")
prev_results <- results_file
chunk_size <- 10L
save_full <- FALSE
results_path <- "./junk"
save_ex_calls <- FALSE
num_cores <- 25L
x <- pkgstats_from_archive (path = path,
                            archive = archive,
                            results_file = results_file,
                            prev_results = prev_results,
                            chunk_size = chunk_size,
                            num_cores = num_cores,
                            save_full = save_full,
                            results_path = results_path)

library (piggyback)
files <- c (
    "pkgstats-CRAN-all.Rds",
    "pkgstats-CRAN-current.Rds",
    "pkgstats-fn-names.Rds"
)
for (f in files) {
    path <- pb_download (file = f, dest = tempdir (), tag = "v0.1.1")
    path <- path [[1]]$request$output$path
    pb_upload (file = path, tag = "v0.1.2")
}
