-- Please update version.sql too -- this keeps clean builds in sync
define version=3412
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_DETAILS_ROW AS
  OBJECT (
  APP_SID					NUMBER(10),
  CSR_USER_SID				NUMBER(10),
  FULL_NAME					VARCHAR2(256),
  FRIENDLY_NAME				VARCHAR2(256),
  EMAIL						VARCHAR2(256),
  USER_NAME					VARCHAR2(256),
  SHEET_ID					NUMBER(10),
  SHEET_URL					VARCHAR2(400),
  DELEGATION_NAME			VARCHAR2(1023),
  PERIOD_SET_ID				NUMBER(10),
  PERIOD_INTERVAL_ID		NUMBER(10),
  DELEGATION_SID			NUMBER(10),
  SUBMISSION_DTM			DATE,
  REMINDER_DTM				DATE,
  START_DTM					DATE,
  END_DTM					DATE
  );
/

CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_DETAILS_TABLE AS 
  TABLE OF CSR.T_ALERT_BATCH_DETAILS_ROW;
/
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../alert_pkg
@../delegation_pkg
@../enable_pkg

@../alert_body
@../delegation_body
@../sheet_body

@update_tail
