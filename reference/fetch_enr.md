# Fetch Georgia enrollment data

Downloads and returns enrollment data from the Governor's Office of
Student Achievement (GOSA).

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid range: 2011-2025.

- tidy:

  If TRUE (default), returns data in tidy format.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data
enr_2024 <- fetch_enr(2024)

# Force fresh download
enr_fresh <- fetch_enr(2024, use_cache = FALSE)
} # }
```
