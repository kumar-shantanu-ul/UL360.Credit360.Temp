-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer_saml_sso ADD show_sso_option_login NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer_saml_sso ADD CONSTRAINT chk_show_sso_option_log CHECK (show_sso_option_login IN (0,1));

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
@../saml_pkg
@../saml_body

@update_tail
