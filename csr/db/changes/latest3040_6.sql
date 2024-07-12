-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select, insert, update on chain.product_type_tr to csr;
grant select, insert, update on chain.product_type_tr to csrimp;
grant select, insert, update, delete on csrimp.chain_product_type_tr to tool_user;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body

@update_tail
