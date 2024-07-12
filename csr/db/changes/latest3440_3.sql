-- Please update version.sql too -- this keeps clean builds in sync
define version=3440
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM csr.util_script
	 WHERE util_script_id = 74;
	 
	IF v_exists = 0 THEN  
		INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
		VALUES (74, 'Trigger logistics recalculation', 'Trigger a recalculation by logistics service for a given transport mode', 'RecalcLogistics');
		INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
		VALUES (74, 'Transport mode', '(1 Air, 2 Sea, 3 Road, 4 Barge, 5 Rail)', 0);
	END IF;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
