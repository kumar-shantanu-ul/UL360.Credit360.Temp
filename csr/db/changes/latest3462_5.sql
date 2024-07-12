-- Please update version.sql too -- this keeps clean builds in sync
define version=3462
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD SHOW_DATA_APPROVE_CONFIRM NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_SHOW_DATA_APPROVE_CONFIRM CHECK (SHOW_DATA_APPROVE_CONFIRM IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD SHOW_DATA_APPROVE_CONFIRM NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (SHOW_DATA_APPROVE_CONFIRM DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_SHOW_DATA_APPROVE_CONFIRM CHECK (SHOW_DATA_APPROVE_CONFIRM IN (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_data_pkg

@..\csr_data_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
