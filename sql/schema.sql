-- Well Integrity Database: schema
-- Portable SQL. Runs here on SQLite; for SQL Server change DATE arithmetic (see query comments).

CREATE TABLE field (
  field_id        INTEGER      PRIMARY KEY,
  field_name      VARCHAR(40)  NOT NULL UNIQUE,
  location_type   VARCHAR(10)  NOT NULL CHECK (location_type IN ('Onshore', 'Offshore'))
);

CREATE TABLE well (
  well_id         INTEGER      PRIMARY KEY,
  field_id        INTEGER      NOT NULL REFERENCES field (field_id),
  well_name       VARCHAR(20)  NOT NULL UNIQUE,
  well_type       VARCHAR(20)  NOT NULL CHECK (well_type IN ('Oil producer', 'Gas producer', 'Water injector')),
  well_status     VARCHAR(12)  NOT NULL CHECK (well_status IN ('Active', 'Shut-in', 'Suspended')),
  spud_date       DATE         NOT NULL,
  completion_date DATE
);

CREATE TABLE casing_string (
  casing_id       INTEGER      PRIMARY KEY,
  well_id         INTEGER      NOT NULL REFERENCES well (well_id),
  string_type     VARCHAR(15)  NOT NULL CHECK (string_type IN ('Conductor', 'Surface', 'Intermediate', 'Production', 'Liner')),
  od_in           DECIMAL(6,3) NOT NULL,
  grade           VARCHAR(6)   NOT NULL,
  shoe_depth_m    DECIMAL(7,1) NOT NULL,
  cement_top_m    DECIMAL(7,1),
  CHECK (cement_top_m IS NULL OR cement_top_m <= shoe_depth_m)
);

CREATE TABLE annulus (
  annulus_id      INTEGER      PRIMARY KEY,
  well_id         INTEGER      NOT NULL REFERENCES well (well_id),
  annulus_name    CHAR(1)      NOT NULL CHECK (annulus_name IN ('A', 'B', 'C')),
  maasp_bar       DECIMAL(6,1) NOT NULL CHECK (maasp_bar > 0),
  UNIQUE (well_id, annulus_name)
);

CREATE TABLE annulus_reading (
  reading_id      INTEGER      PRIMARY KEY,
  annulus_id      INTEGER      NOT NULL REFERENCES annulus (annulus_id),
  reading_date    DATE         NOT NULL,
  pressure_bar    DECIMAL(6,1),               -- NULL = gauge not read
  UNIQUE (annulus_id, reading_date)
);

CREATE TABLE element_type (
  element_type_id      INTEGER     PRIMARY KEY,
  element_name         VARCHAR(40) NOT NULL UNIQUE,
  test_interval_months INTEGER     NOT NULL CHECK (test_interval_months > 0)
);

CREATE TABLE barrier_element (
  element_id      INTEGER      PRIMARY KEY,
  well_id         INTEGER      NOT NULL REFERENCES well (well_id),
  element_type_id INTEGER      NOT NULL REFERENCES element_type (element_type_id),
  envelope        VARCHAR(9)   NOT NULL CHECK (envelope IN ('Primary', 'Secondary')),
  install_date    DATE         NOT NULL,
  UNIQUE (well_id, element_type_id)
);

CREATE TABLE integrity_test (
  test_id           INTEGER      PRIMARY KEY,
  element_id        INTEGER      NOT NULL REFERENCES barrier_element (element_id),
  test_date         DATE         NOT NULL,
  test_type         VARCHAR(30)  NOT NULL,
  test_pressure_bar DECIMAL(6,1),
  result            CHAR(4)      NOT NULL CHECK (result IN ('PASS', 'FAIL')),
  remarks           VARCHAR(200)
);

CREATE TABLE integrity_issue (
  issue_id        INTEGER      PRIMARY KEY,
  well_id         INTEGER      NOT NULL REFERENCES well (well_id),
  element_id      INTEGER      REFERENCES barrier_element (element_id),
  annulus_id      INTEGER      REFERENCES annulus (annulus_id),
  detected_date   DATE         NOT NULL,
  category        VARCHAR(30)  NOT NULL,
  severity        VARCHAR(6)   NOT NULL CHECK (severity IN ('High', 'Medium', 'Low')),
  issue_status    VARCHAR(6)   NOT NULL CHECK (issue_status IN ('Open', 'Closed')),
  closed_date     DATE,
  description     VARCHAR(250) NOT NULL,
  CHECK ((issue_status = 'Open' AND closed_date IS NULL)
      OR (issue_status = 'Closed' AND closed_date IS NOT NULL))
);

CREATE TABLE intervention (
  intervention_id   INTEGER      PRIMARY KEY,
  well_id           INTEGER      NOT NULL REFERENCES well (well_id),
  issue_id          INTEGER      REFERENCES integrity_issue (issue_id),
  start_date        DATE         NOT NULL,
  end_date          DATE,
  intervention_type VARCHAR(40)  NOT NULL,
  description       VARCHAR(250),
  outcome           VARCHAR(12)  CHECK (outcome IN ('Successful', 'Partial', 'Unsuccessful')),
  rig_days          DECIMAL(5,1),
  CHECK (end_date IS NULL OR end_date >= start_date)
);

-- One-row table holding the reporting date, so every query uses the same "today".
CREATE TABLE report_settings (
  as_of_date      DATE         NOT NULL
);

CREATE INDEX ix_reading_annulus_date ON annulus_reading (annulus_id, reading_date);
CREATE INDEX ix_test_element_date    ON integrity_test (element_id, test_date);
CREATE INDEX ix_issue_well_status    ON integrity_issue (well_id, issue_status);
