-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer
ADD REQUIRE_SA_LOGIN_REASON NUMBER(1) DEFAULT 1 NOT NULL;

ALTER TABLE csr.customer
ADD CONSTRAINT CK_REQUIRE_SA_LOGIN_REASON CHECK (REQUIRE_SA_LOGIN_REASON IN (0,1));

ALTER TABLE csrimp.customer
ADD REQUIRE_SA_LOGIN_REASON NUMBER(1) NOT NULL;

ALTER TABLE csrimp.customer
ADD CONSTRAINT CK_REQUIRE_SA_LOGIN_REASON CHECK (REQUIRE_SA_LOGIN_REASON IN (0,1));

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
@../customer_body
@../schema_body
@../csrimp/imp_body

@update_tail
