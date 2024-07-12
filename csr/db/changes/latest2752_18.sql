-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT DELETE on csr.region_role_member TO chain;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../chain/company_body

@update_tail
