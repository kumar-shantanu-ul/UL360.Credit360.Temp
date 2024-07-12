-- Please update version.sql too -- this keeps clean builds in sync
define version=2979
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
	v_column_exists NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_column_exists
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='DELEG_PLAN' AND column_name='INTERVAL';
   
	IF v_column_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEG_PLAN DROP COLUMN INTERVAL';
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

@update_tail
