# Merge GOSA subgroup and grade data

The grade data has multiple rows per entity (one per grade level), while
subgroup data has one row per entity. Merging would cause row explosion.
For now, we pivot grade data to wide format to add grade-level
enrollment columns to the subgroup data.

## Usage

``` r
merge_gosa_data(subgroup_df, grade_df)
```

## Arguments

- subgroup_df:

  Subgroup enrollment data

- grade_df:

  Grade-level enrollment data

## Value

Merged data frame with grade-level enrollment counts
