-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select on csr.calc_tag_dependency to chain;
grant execute on csr.calc_pkg to chain;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../chain/company_pkg
@../chain/company_body

@update_tail
