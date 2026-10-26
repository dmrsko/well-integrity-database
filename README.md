# Well Integrity Database

A relational database for well barrier elements, integrity tests, annulus pressures, integrity issues and interventions across onshore and offshore wells. This is the kind of data a Well Integrity Management System (WIMS) holds.

**Live dashboard:** https://well-integrity-example.netlify.app (the whole database runs as SQLite in the browser, with an editable SQL workbench)

## What is in the repository

| Path | Content |
|---|---|
| `sql/schema.sql` | 11 tables with primary and foreign keys, CHECK constraints and indexes |
| `sql/seed.sql` | Synthetic sample data: 2 fields, 13 wells, barrier tests since 2023, 12 months of annulus readings |
| `sql/queries/` | 8 reports a well integrity team uses every week |
| `build_db.py` | Builds `well_integrity.db` and prints the reports |
| `tests/test_reports.py` | Checks that the reports find the scenarios built into the data |
| `site/index.html` | The static dashboard published on Netlify |

## Reports

1. **Well integrity status**: red / amber / green per well
2. **Barrier elements needing action**: failed or overdue tests
3. **Annulus pressure against MAASP**
4. **Rising annulus pressure**: trend over the last months
5. **Open integrity issues**
6. **Intervention history**: from detected issue to repair
7. **Test compliance by field**
8. **Data quality checks**: e.g. a failed test with no issue logged

## Data model

Every test, issue and repair hangs off a physical thing in the well: a barrier element or an annulus. That keeps the history traceable from a failed test to the intervention that fixed it.

- Barrier elements are rows, so an onshore well without an SSSV and an offshore well with one fit the same model.
- The required test interval sits on `element_type`, so a policy change is one update.
- MAASP belongs to the annulus, and readings are compared with the limit of the annulus they were taken on.
- CHECK constraints reject bad records, for example a closed issue without a closing date or a top of cement below the casing shoe.

## Run it

Needs only Python (SQLite is built in).

```bash
python build_db.py               # build the database and print all reports
python build_db.py 03_maasp      # print one report
pip install -r requirements.txt
python -m pytest -q              # 4 tests
```

The SQL runs on SQLite; for SQL Server, change the date functions as noted in each query.

## How it was built

Written with an AI coding assistant (Claude). The data model, integrity rules and scenarios are mine, based on 16 years in drilling, workover and fishing operations.

## Data

All fields, wells and readings are synthetic. They do not describe any real field or operator.

Author: Damir Skoko · damir.skoko@gmail.com
