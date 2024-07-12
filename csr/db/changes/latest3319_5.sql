-- Please update version.sql too -- this keeps clean builds in sync
define version=3319
define minor_version=5
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
DELETE FROM csr.tab_portlet
 WHERE customer_portlet_sid IN (
	SELECT customer_portlet_sid
	  FROM csr.customer_portlet
	 WHERE portlet_id = 1070
);

DELETE FROM csr.customer_portlet
 WHERE portlet_id = 1070;

UPDATE csr.portlet SET name = 'Indicator Map (deprecated)' WHERE portlet_id = 923;
UPDATE csr.portlet SET name = 'Indicator Map' WHERE portlet_id = 1070;
UPDATE csr.customer_portlet SET portlet_id = 1070 WHERE portlet_id = 923;

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE) 
VALUES (65, 'Indicator Map (Flash)', 'Switches non flash indicator map to the flash version', 'RevertToFlashIndicatorMap', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE) 
VALUES (66, 'Indicator Map (Non Flash)', 'Switches flash indicator map to the non flash version', 'SwitchToNonFlashIndicatorMap', NULL);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
