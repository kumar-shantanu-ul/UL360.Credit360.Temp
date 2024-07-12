-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.role ADD is_system_managed number(1) DEFAULT 0;
UPDATE csr.role SET is_system_managed = 0;
ALTER TABLE csr.role MODIFY is_system_managed NOT NULL;
ALTER TABLE csr.role ADD CONSTRAINT chk_is_system_managed_1_0 CHECK (is_system_managed IN (1, 0));

ALTER TABLE csrimp.role ADD(
	IS_USER_CREATOR   NUMBER(1),
	IS_HIDDEN         NUMBER(1),
	IS_SYSTEM_MANAGED NUMBER(1)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../csr_data_pkg
@../role_pkg

@../role_body
@../chain/company_user_body
@../chain/company_type_body
@../chain/scheduled_alert_body
@../schema_body
@../csrimp/imp_body

@update_tail
