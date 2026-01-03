# Find the correct GOSA subgroup URL for a given year

GOSA files have timestamps in their names. This function scrapes the
directory listing to discover the correct URL.

## Usage

``` r
find_gosa_subgroup_url(end_year)
```

## Arguments

- end_year:

  School year end

## Value

URL string or NULL if not found
