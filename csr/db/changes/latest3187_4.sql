-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUDIT_LOG
ADD ORIGINAL_USER_SID NUMBER(10, 0);

-- Add the default separately.
ALTER TABLE CSR.AUDIT_LOG
MODIFY ORIGINAL_USER_SID DEFAULT SYS_CONTEXT('SECURITY', 'ORIGINAL_LOGIN_SID');

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
@../csr_data_pkg
@../csr_data_body
@../csr_user_body


@update_tail
