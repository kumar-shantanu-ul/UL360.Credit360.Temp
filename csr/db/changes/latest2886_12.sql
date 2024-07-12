-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer 
  ADD copy_forward_allow_na NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer 
  ADD CONSTRAINT ck_customer_copy_for_allow_na CHECK (copy_forward_allow_na IN (0,1));

ALTER TABLE csrimp.customer 
  ADD copy_forward_allow_na number(1) not null;
ALTER TABLE csrimp.customer 
  ADD CONSTRAINT ck_customer_copy_for_allow_na CHECK (copy_forward_allow_na IN (0,1));

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
@..\sheet_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
