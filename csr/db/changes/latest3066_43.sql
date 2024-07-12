-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD SHOW_ADDITIONAL_AUDIT_INFO NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CHK_SHOW_ADDITIONAL_AUDIT_INFO CHECK (SHOW_ADDITIONAL_AUDIT_INFO IN (0,1));

ALTER TABLE CSRIMP.CUSTOMER ADD SHOW_ADDITIONAL_AUDIT_INFO NUMBER(1) NOT NULL;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD SHOW_AUDIT_COORDINATOR NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD CONSTRAINT CHK_SHOW_AUDIT_COORDINATOR CHECK (SHOW_AUDIT_COORDINATOR IN (0,1));

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS ADD SHOW_AUDIT_COORDINATOR NUMBER(1) NOT NULL;


-- *** Grants ***
GRANT EXECUTE ON csr.T_USER_FILTER_ROW TO chain;
GRANT EXECUTE ON csr.T_USER_FILTER_TABLE TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../chain/company_user_pkg

@../chain/company_user_body
@../audit_body
@../customer_body
@../audit_report_body
@../schema_body
@../csrimp/imp_body
@../chain/setup_body
@../chain/helper_body
@../chain/supplier_audit_body

@update_tail
