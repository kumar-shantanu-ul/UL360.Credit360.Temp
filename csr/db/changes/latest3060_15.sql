-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


DECLARE
	v_count NUMBER(10);
BEGIN
		
	SELECT COUNT(*)
	  INTO v_count
	  FROM ALL_TAB_COLUMNS
	 WHERE table_name = 'SCORE_THRESHOLD'
	   AND COLUMN_NAME = 'LOOKUP_KEY';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.score_threshold ADD lookup_key VARCHAR2(255)';

		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.score_threshold ADD lookup_key VARCHAR2(255)';
		
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CSR.UK_SCORE_THRESH_LOOKUP_KEY ON CSR.SCORE_THRESHOLD(APP_SID, SCORE_TYPE_ID, NVL(UPPER(LOOKUP_KEY),TO_CHAR(SCORE_THRESHOLD_ID)))';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@ ../schema_body
@ ../csrimp/imp_body
@ ../quick_survey_pkg
@ ../quick_survey_body

@update_tail
