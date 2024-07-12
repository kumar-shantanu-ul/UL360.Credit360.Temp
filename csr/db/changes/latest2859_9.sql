-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.PORTLET (
     PORTLET_ID, NAME, TYPE, SCRIPT_PATH
 ) VALUES (
     1057,
     'Role List',
     'Credit360.Portlets.RoleList',
     '/csr/site/portal/Portlets/RoleList.js'
 );

-- ** New package grants **

-- *** Packages ***

@../role_pkg

@../role_body

@update_tail
