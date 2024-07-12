-- Please update version.sql too -- this keeps clean builds in sync
define version=3202
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
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1069,'Period picker','Credit360.Portlets.PeriodPicker2','{"portletHeight":75}','/csr/site/portal/portlets/PeriodPicker2.js');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
