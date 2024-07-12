-- Please update version.sql too -- this keeps clean builds in sync
define version=3048
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant execute on chain.product_type_pkg to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/product_type_pkg
@../chain/product_type_body
@../enable_body

@update_tail
