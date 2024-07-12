-- Please update version.sql too -- this keeps clean builds in sync
define version=3383
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM sys.all_tab_columns
	 WHERE owner = 'CMS'
	   AND table_name = 'FORM_RESPONSE_IMPORT_OPTIONS'
	   AND column_name = 'USES_NEW_SP_SIGNATURE';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.form_response_import_options ADD uses_new_sp_signature NUMBER(1) DEFAULT 0';
		EXECUTE IMMEDIATE 'ALTER TABLE cms.form_response_import_options MODIFY uses_new_sp_signature NOT NULL';
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
@../../../aspen2/cms/db/form_response_import_pkg
@../../../aspen2/cms/db/form_response_import_body

@update_tail
