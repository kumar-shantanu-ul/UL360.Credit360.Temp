-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=19
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
INSERT INTO csr.portlet (portlet_id,name,type,default_state,script_path) 
VALUES (
	1061,
	'Non-compliant items',
	'Credit360.Portlets.Compliance.NonCompliantItems', 
	EMPTY_CLOB(),
	'/csr/site/portal/portlets/compliance/NonCompliantItems.js'
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../compliance_pkg
@@../compliance_body
@@../enable_body

@update_tail
