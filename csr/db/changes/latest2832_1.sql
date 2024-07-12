-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_wrong_default		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_wrong_default
	  FROM all_tab_columns 
	 WHERE owner = 'CMS' 
	   AND table_name = 'TAB_COLUMN' 
	   AND column_name = 'SHOW_IN_BREAKDOWN' 
	   AND data_default IS NULL;
	   
	IF v_wrong_default = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.tab_column MODIFY show_in_breakdown DEFAULT 1';
	END IF;
END;
/

-- *** Data changes ***
-- RLS
-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
