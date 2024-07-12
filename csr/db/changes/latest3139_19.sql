-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer MODIFY calc_start_dtm DEFAULT NULL;
ALTER TABLE csr.customer MODIFY calc_end_dtm DEFAULT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (41, 'Set calc start of time date', '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the earliest date to include for calculations', 'SetCalcStartDate', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (41, 'Calc start date (YYYY-MM-DD)', 'Date in YYYY-MM-DD format e.g.2010-01-01', 0, NULL, 0);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg

@..\csr_app_body
@..\util_script_body

@update_tail
