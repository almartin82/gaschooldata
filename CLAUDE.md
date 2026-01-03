## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---


# Claude Code Instructions

### GIT COMMIT POLICY
- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pygaschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pygaschooldata && pytest tests/test_pygaschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pygaschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.

---

## Georgia Data Source Documentation

### Primary Data Source: GOSA (Governor's Office of Student Achievement)

**Base URL:** https://download.gosa.ga.gov/

**Available Years:** 2011-2024 (2010-11 through 2023-24 school years)

### File Naming Patterns (IMPORTANT)

GOSA files have **timestamps** appended to their names. The package scrapes directory listings to find the correct URLs.

**Enrollment by Subgroup (Demographics):**
- 2023+: `Enrollment_by_Subgroup_Metrics_YYYY-YY_TIMESTAMP.csv`
  - Example: `Enrollment_by_Subgroup_Metrics_2023-24_2025-06-17_15_15_26.csv`
- 2015-2022: `Enrollment_by_Subgroups_Programs_YYYY_TIMESTAMP.csv`
  - Example: `Enrollment_by_Subgroups_Programs_2022_Dec072022.csv`

**Enrollment by Grade:**
- 2023+: `Enrollment_by_Grade_YYYY-YY_TIMESTAMP.csv`
- Not available for 2015-2022

### Data Structure

**Subgroup file columns:**
- `LONG_SCHOOL_YEAR` - e.g., "2023-24"
- `DETAIL_LVL_DESC` - "State", "District", or "School"
- `SCHOOL_DSTRCT_CD`, `SCHOOL_DSTRCT_NM` - District identifiers
- `INSTN_NUMBER`, `INSTN_NAME` - School identifiers
- `ENROLL_PCT_*` - Demographics (Asian, Black, White, Hispanic, etc.)
- `ENROLL_PCT_MALE`, `ENROLL_PCT_FEMALE` - Gender
- Various program enrollment counts (EIP, ESOL, Special Ed, etc.)

**Grade file columns:**
- `GRADE_LEVEL` - K, 1st, 2nd, etc.
- `ENROLLMENT_COUNT` - Count for that grade
- `ENROLLMENT_PERIOD` - "Fall" or "Spring"

### Row Counts (Expected for 2024)

| Level | Count |
|-------|-------|
| State | 1 |
| District | ~218 |
| School | ~2304 |
| **Total** | **~2523** |

### Known Data Characteristics

1. **"TFS" values**: "Too Few Students" - converted to NA when parsing to numeric
2. **Grade data only available 2023+**: Older years have only subgroup data
3. **Multiple timestamps**: GOSA updates files periodically; we use the most recent

### Verified Working URLs (as of 2025-01)

```
https://download.gosa.ga.gov/2024/Enrollment_by_Subgroup_Metrics_2023-24_*.csv
https://download.gosa.ga.gov/2024/Enrollment_by_Grade_2023-24_*.csv
https://download.gosa.ga.gov/2023/Enrollment_by_Subgroup_Metrics_2022-23_*.csv
https://download.gosa.ga.gov/2022/Enrollment_by_Subgroups_Programs_2022_Dec072022.csv
```

### When URLs Fail

If URLs start failing:
1. Check if https://download.gosa.ga.gov/ is accessible
2. Browse the year directory to find new file patterns
3. Update `find_gosa_subgroup_url()` patterns if naming changed
4. File issues may indicate GOSA restructured their data repository

