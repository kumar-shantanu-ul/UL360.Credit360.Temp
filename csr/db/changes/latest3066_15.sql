-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
v_util_script_id NUMBER(10);

BEGIN
  SELECT MAX(util_script_id) 
		INTO v_util_script_id
    FROM csr.util_script;
	
  v_util_script_id := v_util_script_id + 1;
  
  INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
			  VALUES (v_util_script_id,'Add US EGrid values','Add US EGrid values to a region and all its children','AddUSEGridValues',null);
	
  INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
			  VALUES (v_util_script_id, 'Region sid', 'The sid of the region to link e-grid references', 1);
	
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
