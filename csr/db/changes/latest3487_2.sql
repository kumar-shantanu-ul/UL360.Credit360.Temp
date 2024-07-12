-- Please update version.sql too -- this keeps clean builds in sync
define version=3487
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.internal_audit_listener_last_update ADD correlation_id VARCHAR2(64);
ALTER TABLE csrimp.internal_audit_listener_last_update ADD correlation_id VARCHAR2(64);
ALTER TABLE chain.integration_request ADD correlation_id VARCHAR2(64);
-- there is no corresponding csrimp version of integration request

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
@../chain/integration_pkg
@../internal_audit_listener_pkg
@../schema_body
@../csrimp/imp_body
@../internal_audit_listener_body
@../chain/integration_body

@update_tail
