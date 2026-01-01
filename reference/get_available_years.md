# Get available years for Georgia enrollment data

Returns the range of years available from GOSA (Governor's Office of
Student Achievement). GOSA provides enrollment data from the 2010-11
school year (end_year = 2011) through 2024-25 (end_year = 2025).

## Usage

``` r
get_available_years()
```

## Value

A list with components:

- min_year:

  Integer. The earliest available year (2011).

- max_year:

  Integer. The most recent available year (2025).

- description:

  Character. A description of the data availability.

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2011
#> 
#> $max_year
#> [1] 2025
#> 
#> $description
#> [1] "GOSA enrollment data (2010-11 through 2024-25 school years)"
#> 
# Returns list(min_year = 2011, max_year = 2025, description = "...")
```
