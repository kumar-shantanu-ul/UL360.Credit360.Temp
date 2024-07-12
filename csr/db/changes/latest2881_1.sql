-- Please update version.sql too -- this keeps clean builds in sync
define version=2881
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer
  ADD rstrct_multiprd_frm_edit_to_yr NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.customer
  ADD allow_multiperiod_forms NUMBER(1) NOT NULL;

ALTER TABLE csrimp.customer
  ADD rstrct_multiprd_frm_edit_to_yr NUMBER(1) NOT NULL;

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
@..\customer_body
@..\delegation_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
