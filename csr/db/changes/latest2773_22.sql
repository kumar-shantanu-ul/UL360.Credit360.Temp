-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD (
	USER_ADMIN_HELPER_PKG	VARCHAR2(255) NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\csr_user_pkg
@..\csr_user_body

@update_tail
