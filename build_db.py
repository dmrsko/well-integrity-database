"""Build the Well Integrity Database as a SQLite file and run the saved reports.

Usage:
    python build_db.py              # builds well_integrity.db and runs every report
    python build_db.py 03_maasp     # builds the database and runs one report
"""
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).parent
SQL_DIR = ROOT / "sql"
DB_PATH = ROOT / "well_integrity.db"


def build_database(db_path=DB_PATH):
    """Create the tables from schema.sql and load the sample data from seed.sql."""
    if db_path != ":memory:" and Path(db_path).exists():
        Path(db_path).unlink()
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript((SQL_DIR / "schema.sql").read_text(encoding="utf-8"))
    conn.executescript((SQL_DIR / "seed.sql").read_text(encoding="utf-8"))
    conn.commit()
    return conn


def run_report(conn, query_file):
    """Run one saved report and return its column names and rows."""
    cursor = conn.execute(query_file.read_text(encoding="utf-8"))
    columns = [c[0] for c in cursor.description]
    return columns, cursor.fetchall()


def print_table(columns, rows):
    widths = [max(len(str(x)) for x in [col] + [r[i] for r in rows]) for i, col in enumerate(columns)]
    print("  ".join(c.ljust(w) for c, w in zip(columns, widths)))
    print("  ".join("-" * w for w in widths))
    for r in rows:
        print("  ".join(str(v).ljust(w) for v, w in zip(r, widths)))


def main():
    conn = build_database()
    print(f"Built {DB_PATH.name}")
    wanted = sys.argv[1] if len(sys.argv) > 1 else ""
    for query_file in sorted((SQL_DIR / "queries").glob(f"{wanted}*.sql")):
        title = query_file.read_text(encoding="utf-8").splitlines()[0].lstrip("- ")
        print(f"\n=== {title} ({query_file.name}) ===")
        print_table(*run_report(conn, query_file))
    conn.close()


if __name__ == "__main__":
    main()
