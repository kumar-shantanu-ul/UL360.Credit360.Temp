-- Please update version.sql too -- this keeps clean builds in sync
define version=3324
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer_saml_sso
ADD use_basic_user_management NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.customer_saml_sso
ADD full_name_attribute VARCHAR2(255);

ALTER TABLE csr.customer_saml_sso
ADD email_attribute VARCHAR2(255);

ALTER TABLE csr.customer_saml_sso
ADD CONSTRAINT CHK_BASIC_USR_MGMT_ATTRS CHECK ((use_basic_user_management IS NULL OR use_basic_user_management = 0) OR (use_basic_user_management = 1 AND full_name_attribute IS NOT NULL AND email_attribute IS NOT NULL));

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
@../saml_pkg
@../saml_body

@update_tail
