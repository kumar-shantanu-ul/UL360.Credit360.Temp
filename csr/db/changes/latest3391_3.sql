-- Please update version.sql too -- this keeps clean builds in sync
define version=3391
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	FOR r IN (SELECT null FROM all_tab_cols WHERE owner = 'CSR' AND TABLE_NAME = 'COMPLIANCE_PERMIT_SCORE' AND COLUMN_NAME = 'LAST_PERMIT_SCORE_LOG_ID')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE DROP COLUMN LAST_PERMIT_SCORE_LOG_ID';
	END LOOP;
	
	FOR r IN (SELECT null FROM all_tab_cols WHERE owner = 'CSRIMP' AND TABLE_NAME = 'COMPLIANCE_PERMIT_SCORE' AND COLUMN_NAME = 'LAST_PERMIT_SCORE_LOG_ID')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.COMPLIANCE_PERMIT_SCORE DROP COLUMN LAST_PERMIT_SCORE_LOG_ID';
	END LOOP;
END;
/

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

@update_tail
