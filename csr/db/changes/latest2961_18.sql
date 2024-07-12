-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.BSCI_SUPPLIER MODIFY POSTCODE NULL;
ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER MODIFY POSTCODE NULL;

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
@../chain/bsci_pkg
@../chain/bsci_body

@../enable_body

@update_tail
