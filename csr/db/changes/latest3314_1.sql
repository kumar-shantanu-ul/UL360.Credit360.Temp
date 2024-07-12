-- Please update version.sql too -- this keeps clean builds in sync
define version=3314
define minor_version=1
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
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1070,'Indicator Map (Beta)', 'Credit360.Portlets.IndicatorMapNoFlash', EMPTY_CLOB(), '/csr/site/portal/portlets/IndicatorMapNoFlash.js');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
