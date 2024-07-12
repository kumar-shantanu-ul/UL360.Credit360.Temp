-- Please update version.sql too -- this keeps clean builds in sync
define version=3331
define minor_version=4
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
UPDATE CSR.CUSTOMER_PORTLET
   SET portlet_id = 1070
 WHERE portlet_id = 923;

DELETE FROM CSR.PORTLET
 WHERE portlet_id = 923;

UPDATE CSR.PORTLET
   SET type = 'Credit360.Portlets.IndicatorMap', script_path = '/csr/site/portal/portlets/IndicatorMap.js'
 WHERE portlet_id = 1070;

DELETE FROM CSR.UTIL_SCRIPT_RUN_LOG
 WHERE util_script_id IN (65,66);

DELETE FROM CSR.UTIL_SCRIPT
 WHERE util_script_id IN (65,66);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail
