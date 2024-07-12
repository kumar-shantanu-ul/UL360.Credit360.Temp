-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON chain.company_reference_id_seq TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	 VALUES (75, 'in_bsci_id', 6, 'The BSCI ID for the client');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
