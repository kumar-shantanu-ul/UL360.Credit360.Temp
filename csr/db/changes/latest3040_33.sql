-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.bsci_supplier MODIFY industry NULL;
ALTER TABLE csrimp.chain_bsci_supplier MODIFY industry NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
-- I don't believe alter -> NULL will invalidate but seen odder things happen
@../chain/bsci_pkg
@../chain/bsci_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
