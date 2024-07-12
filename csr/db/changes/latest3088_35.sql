-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=35
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

INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES (1067, 'Active permit applications', 'Credit360.Portlets.Compliance.ActivePermitApplications', '/csr/site/portal/portlets/compliance/ActivePermitApplications.js');

INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES (1068, 'Applications summary', 'Credit360.Portlets.Compliance.PermitApplicationSummary', '/csr/site/portal/portlets/compliance/PermitApplicationSummary.js');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg

@../enable_body
@../permit_body

@update_tail
