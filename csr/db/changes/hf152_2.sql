-- Please update version.sql too -- this keeps clean builds in sync
define version=0
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUDIT_LOG MODIFY REMOTE_ADDR DEFAULT SYS_CONTEXT('SECURITY', 'REMOTE_ADDR');
ALTER TABLE CSR.AUDIT_LOG MODIFY ORIGINAL_USER_SID DEFAULT SYS_CONTEXT('SECURITY', 'ORIGINAL_LOGIN_SID');
ALTER TABLE CSR.AUDIT_LOG MODIFY AUDIT_DATE DEFAULT SYSDATE;
ALTER TABLE CSR.AUDIT_LOG MODIFY APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');

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

@update_tail
