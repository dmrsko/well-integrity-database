"""Checks that the database builds and the reports find the scenarios planted in the sample data."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from build_db import SQL_DIR, build_database, run_report  # noqa: E402


def report(name):
    conn = build_database(":memory:")
    columns, rows = run_report(conn, next((SQL_DIR / "queries").glob(f"{name}*.sql")))
    return [dict(zip(columns, r)) for r in rows]


def test_every_report_runs():
    conn = build_database(":memory:")
    for query_file in (SQL_DIR / "queries").glob("*.sql"):
        run_report(conn, query_file)


def test_thirteen_wells_loaded():
    conn = build_database(":memory:")
    assert conn.execute("SELECT COUNT(*) FROM well").fetchone()[0] == 13


def test_brv03_is_red():
    rows = {r["well_name"]: r for r in report("01_status")}
    assert rows["BRV-03"]["integrity_status"] == "RED"


def test_data_quality_finds_unlogged_failed_test_on_brv06():
    text = str(report("08_quality"))
    assert "BRV-06" in text
