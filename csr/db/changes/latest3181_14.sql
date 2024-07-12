-- Please update version.sql too -- this keeps clean builds in sync
define version=3181
define minor_version=14
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
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (55, 'Metering - Urjanet Renewable Energy Columns', 'Enable or disable the Urjanet renewable energy column mappings and associated meter inputs', 'EnableUrjanetRenewEnergy', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (55, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg

@../meter_monitor_body
@../util_script_body

@update_tail
