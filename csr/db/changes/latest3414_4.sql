-- Please update version.sql too -- this keeps clean builds in sync
define version=3414
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select, references, insert, update, delete on chain.supplier_relationship to CSR;
grant select, references, insert, update, delete on chain.company_type to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../supplier_pkg

@../supplier_body

@update_tail
