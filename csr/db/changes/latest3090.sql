-- Please update version.sql too -- this keeps clean builds in sync
define version=3090
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.customer_options
ADD prevent_relationship_loops NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.chain_customer_options
ADD prevent_relationship_loops NUMBER(1) NOT NULL;

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
@../chain/chain_pkg
@../chain/company_body
@../chain/test_chain_utils_body
@../schema_body
@../csrimp/imp_body

@update_tail
