-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.customer_options
  ADD create_one_flow_item_for_comp NUMBER(1, 0) DEFAULT (1) NOT NULL;

ALTER TABLE chain.customer_options
  ADD CONSTRAINT chk_create_one_flow_item CHECK(create_one_flow_item_for_comp IN (0, 1));

ALTER TABLE csrimp.chain_customer_options
  ADD create_one_flow_item_for_comp NUMBER(1, 0) NOT NULL;

ALTER TABLE csrimp.chain_customer_options
  ADD CONSTRAINT chk_create_one_flow_item CHECK(create_one_flow_item_for_comp IN (0, 1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE chain.customer_options
	   SET create_one_flow_item_for_comp = 0;

	security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/supplier_flow_pkg

@../schema_body
@../csrimp/imp_body
@../chain/supplier_flow_body

@update_tail
