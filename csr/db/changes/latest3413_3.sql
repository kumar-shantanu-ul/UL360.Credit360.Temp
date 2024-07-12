-- Please update version.sql too -- this keeps clean builds in sync
define version=3413
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_ISSUES AS
	OBJECT (
		APP_SID							NUMBER(10),
		ISSUE_LOG_ID					NUMBER(10),
		CSR_USER_SID					NUMBER(10),
		FRIENDLY_NAME					VARCHAR2(255),
		FULL_NAME						VARCHAR2(256),
		EMAIL							VARCHAR2(256)
	);
/
CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_ISSUES_TABLE AS
	TABLE OF CSR.T_ALERT_BATCH_ISSUES;
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
@../enable_pkg

@../issue_body
@../region_body

@update_tail
