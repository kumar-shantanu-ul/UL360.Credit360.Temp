-- Please update version.sql too -- this keeps clean builds in sync
define version=3202
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count	number(10);
BEGIN
	SELECT COUNT(*) 
	  INTO v_count 
	  FROM all_tab_cols 
	 WHERE owner = 'CSR' 
	   AND table_name = 'QS_CAMPAIGN' 
	   AND column_name = 'WRITE_ANSWERS_TO_INDICATORS';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.qs_campaign DROP COLUMN write_answers_to_indicators';
	END IF;
END;
/

DECLARE
	v_count	number(10);
BEGIN
	SELECT COUNT(*) 
	  INTO v_count 
	  FROM all_tab_cols 
	 WHERE owner = 'CSRIMP' 
	   AND table_name = 'QS_CAMPAIGN' 
	   AND column_name = 'WRITE_ANSWERS_TO_INDICATORS';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.qs_campaign DROP COLUMN write_answers_to_indicators';
	END IF;
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
@../campaign_pkg

@../campaign_body
@../enable_body
@../csrimp/imp_body
@../schema_body

@update_tail