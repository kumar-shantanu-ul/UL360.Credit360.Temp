-- Please update version.sql too -- this keeps clean builds in sync
define version=2841
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.region_tree_pkg TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

--Update the capability

-- ** New package grants **

-- *** Packages ***
@../chain/company_type_body
@../chain/type_capability_body

@update_tail
