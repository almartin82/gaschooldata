# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from GOSA
# (Governor's Office of Student Achievement).
#
# Data comes from GOSA's downloadable data repository:
# - Enrollment by Subgroup: Demographics, special populations (2011-present)
# - Enrollment by Grade: Grade-level enrollment (2011-present)
#
# GOSA data is available from 2010-11 onward. For earlier years, data must be
# requested directly from GOSA.
#
# URL Pattern: https://download.gosa.ga.gov/{YEAR}/Enrollment_by_Subgroup_Metrics_{YYYY-YY}_{timestamp}.csv
#
# ==============================================================================

#' Download raw enrollment data from GOSA
#'
#' Downloads enrollment data from GOSA's downloadable data repository.
#' Uses Enrollment by Subgroup Metrics for demographics and special populations.
#'
#' @param end_year School year end (2023-24 = 2024). Valid range: 2011-2024
#' @return List with enrollment data frame
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year - GOSA data available from 2011 onward
  if (end_year < 2011 || end_year > 2024) {
    stop("end_year must be between 2011 and 2024. GOSA downloadable data is only available from 2010-11 onward.")
  }

  message(paste("Downloading GOSA enrollment data for", end_year, "..."))

  # Download subgroup data (demographics, special populations)
  message("  Downloading enrollment by subgroup data...")
  subgroup_data <- download_gosa_subgroup(end_year)

  # Download grade-level data
  message("  Downloading enrollment by grade data...")
  grade_data <- download_gosa_grade(end_year)

  # Merge subgroup and grade data
  if (!is.null(grade_data) && nrow(grade_data) > 0) {
    # Merge by school identifiers
    merged_data <- merge_gosa_data(subgroup_data, grade_data)
  } else {
    merged_data <- subgroup_data
  }

  # Add end_year column
  merged_data$end_year <- end_year

  list(
    enrollment = merged_data
  )
}


#' Download GOSA Enrollment by Subgroup data
#'
#' Downloads the Enrollment_by_Subgroup_Metrics CSV from GOSA.
#' This file contains demographic breakdowns and special population counts.
#'
#' @param end_year School year end
#' @return Data frame with subgroup enrollment data
#' @keywords internal
download_gosa_subgroup <- function(end_year) {

  # Build the school year string (e.g., "2023-24" for end_year 2024)
  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  # GOSA uses calendar year folders
  # For 2023-24 data, look in /2024/ folder
  folder_year <- end_year

  # Try to find the file - GOSA uses timestamps in filenames
  # We'll try the direct download approach first
  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  # Create temp file
  temp_file <- tempfile(fileext = ".csv")

  # Try known filename patterns
  # Pattern: Enrollment_by_Subgroup_Metrics_{YYYY-YY}_{timestamp}.csv
  # We need to discover the exact filename

  # First, try to get the file listing or use a known pattern
 url <- find_gosa_subgroup_url(end_year)

  if (is.null(url)) {
    stop(paste("Could not find Enrollment by Subgroup data for year", end_year))
  }

  # Download the file
  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("gaschooldata R package")
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

  }, error = function(e) {
    stop(paste("Failed to download subgroup data for year", end_year,
               "\nError:", e$message))
  })

  # Read the CSV
  df <- readr::read_csv(
    temp_file,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  # Clean up
  unlink(temp_file)

  # Filter to the correct school year (data files sometimes contain multiple years)
  if ("SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$SCHOOL_YEAR == school_year, ]
  } else if ("LONG_SCHOOL_YEAR" %in% names(df)) {
    # Handle different column name variations
    df <- df[grepl(as.character(end_year), df$LONG_SCHOOL_YEAR), ]
  }

  df
}


#' Find the correct GOSA subgroup URL for a given year
#'
#' GOSA files have timestamps in their names. This function attempts to
#' construct or discover the correct URL.
#'
#' @param end_year School year end
#' @return URL string or NULL if not found
#' @keywords internal
find_gosa_subgroup_url <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  # Known URLs based on research (these are examples - actual filenames have timestamps)
  # We'll try a few approaches:

  # Approach 1: Try the GOSA index to get current files
  # The downloadable data page links to current versions

  # Approach 2: Try common filename patterns
  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  # Try without timestamp (sometimes works for latest version)
  patterns <- c(
    paste0("Enrollment_by_Subgroup_Metrics_", school_year, ".csv"),
    paste0("Enrollment_by_Subgroup_", school_year, ".csv")
  )

  for (pattern in patterns) {
    test_url <- paste0(base_url, pattern)
    response <- try(httr::HEAD(test_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(test_url)
    }
  }

  # Approach 3: For recent years, try known good URLs
  # Based on research, construct likely URLs
  known_urls <- list(
    "2024" = "https://download.gosa.ga.gov/2024/Enrollment_by_Subgroup_Metrics_2023-24.csv",
    "2023" = "https://download.gosa.ga.gov/2023/Enrollment_by_Subgroup_Metrics_2022-23.csv",
    "2022" = "https://download.gosa.ga.gov/2022/Enrollment_by_Subgroup_Metrics_2021-22.csv",
    "2021" = "https://download.gosa.ga.gov/2021/Enrollment_by_Subgroup_Metrics_2020-21.csv",
    "2020" = "https://download.gosa.ga.gov/2020/Enrollment_by_Subgroup_Metrics_2019-20.csv",
    "2019" = "https://download.gosa.ga.gov/2019/Enrollment_by_Subgroup_Metrics_2018-19.csv",
    "2018" = "https://download.gosa.ga.gov/2018/Enrollment_by_Subgroup_Metrics_2017-18.csv",
    "2017" = "https://download.gosa.ga.gov/2017/Enrollment_by_Subgroup_Metrics_2016-17.csv",
    "2016" = "https://download.gosa.ga.gov/2016/Enrollment_by_Subgroup_Metrics_2015-16.csv",
    "2015" = "https://download.gosa.ga.gov/2015/Enrollment_by_Subgroup_Metrics_2014-15.csv",
    "2014" = "https://download.gosa.ga.gov/2014/Enrollment_by_Subgroup_Metrics_2013-14.csv",
    "2013" = "https://download.gosa.ga.gov/2013/Enrollment_by_Subgroup_Metrics_2012-13.csv",
    "2012" = "https://download.gosa.ga.gov/2012/Enrollment_by_Subgroup_Metrics_2011-12.csv",
    "2011" = "https://download.gosa.ga.gov/2011/Enrollment_by_Subgroup_Metrics_2010-11.csv"
  )

  year_str <- as.character(end_year)
  if (year_str %in% names(known_urls)) {
    test_url <- known_urls[[year_str]]
    response <- try(httr::HEAD(test_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(test_url)
    }
  }

  # Approach 4: Try alternate URL structure using GOSA's document download
  # Some files are served via the main GOSA site
  alt_url <- paste0(
    "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/document/",
    "Enrollment_by_Subgroup_Metrics_", school_year, ".csv"
  )

  response <- try(httr::HEAD(alt_url, httr::timeout(10)), silent = TRUE)
  if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
    return(alt_url)
  }

  NULL
}


#' Download GOSA Enrollment by Grade data
#'
#' Downloads the Enrollment_by_Grade CSV from GOSA.
#' This file contains grade-level enrollment counts.
#'
#' @param end_year School year end
#' @return Data frame with grade enrollment data, or NULL if not available
#' @keywords internal
download_gosa_grade <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  # Try to find the grade-level file
  url <- find_gosa_grade_url(end_year)

  if (is.null(url)) {
    message("    Note: Grade-level data not found separately; will use total enrollment only")
    return(NULL)
  }

  temp_file <- tempfile(fileext = ".csv")

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("gaschooldata R package")
    )

    if (httr::http_error(response)) {
      message("    Note: Grade-level data download failed; using total enrollment only")
      return(NULL)
    }

  }, error = function(e) {
    message("    Note: Grade-level data not available; using total enrollment only")
    return(NULL)
  })

  # Read the CSV
  df <- readr::read_csv(
    temp_file,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  unlink(temp_file)

  # Filter to correct school year
  if ("SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$SCHOOL_YEAR == school_year, ]
  }

  df
}


#' Find the correct GOSA grade-level URL for a given year
#'
#' @param end_year School year end
#' @return URL string or NULL if not found
#' @keywords internal
find_gosa_grade_url <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  # Try common patterns
  patterns <- c(
    paste0("Enrollment_by_Grade_", school_year, ".csv"),
    paste0("Enrollment_Grade_", school_year, ".csv")
  )

  for (pattern in patterns) {
    test_url <- paste0(base_url, pattern)
    response <- try(httr::HEAD(test_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(test_url)
    }
  }

  NULL
}


#' Merge GOSA subgroup and grade data
#'
#' Combines the subgroup demographics with grade-level enrollment.
#'
#' @param subgroup_df Subgroup enrollment data
#' @param grade_df Grade-level enrollment data
#' @return Merged data frame
#' @keywords internal
merge_gosa_data <- function(subgroup_df, grade_df) {

  # Identify common ID columns
  # GOSA uses SCHOOL_DSTRCT_CD + INSTN_NUMBER as the school identifier
  id_cols <- c("SCHOOL_DSTRCT_CD", "INSTN_NUMBER", "SCHOOL_YEAR")
  id_cols <- id_cols[id_cols %in% names(subgroup_df) & id_cols %in% names(grade_df)]

  if (length(id_cols) == 0) {
    # Can't merge, return subgroup data only
    return(subgroup_df)
  }

  # Select grade columns from grade_df
  grade_cols <- grep("^GRADE_|^GR_|_GRADE$", names(grade_df), value = TRUE)

  if (length(grade_cols) == 0) {
    return(subgroup_df)
  }

  # Merge
  grade_subset <- grade_df[, c(id_cols, grade_cols), drop = FALSE]
  merged <- dplyr::left_join(subgroup_df, grade_subset, by = id_cols)

  merged
}


#' Get available years for GOSA data
#'
#' Returns the range of years available from GOSA downloadable data.
#'
#' @return Integer vector of available years
#' @keywords internal
get_available_years <- function() {
  2011:2024
}
