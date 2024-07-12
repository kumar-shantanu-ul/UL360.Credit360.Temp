-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON chain.v$company_reference TO csr;
GRANT SELECT ON chain.reference TO csr;
GRANT SELECT, DELETE ON chain.company_reference TO csr;

GRANT EXECUTE ON chain.helper_pkg TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../integration_api_pkg
@../supplier_pkg
@../chain/company_pkg

@../integration_api_body
@../supplier_body
@../chain/company_body

@update_tail
