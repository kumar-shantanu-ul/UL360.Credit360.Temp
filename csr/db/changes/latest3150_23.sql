-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'MAP_PLUGIN_TYPE';
	
	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csrimp.map_plugin_type CASCADE CONSTRAINTS';
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
@../chain/chain_body
@../../../aspen2/cms/db/tab_body

@../csrimp/imp_body

@update_tail
