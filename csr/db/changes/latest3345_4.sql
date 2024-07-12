-- Please update version.sql too -- this keeps clean builds in sync
define version=3345
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.msal_user_consent_flow
DROP CONSTRAINT UK_MSAL_USR_CF_ACT_RED;

DELETE FROM csr.msal_user_consent_flow;

ALTER TABLE csr.msal_user_consent_flow
ADD CONSTRAINT UK_MSAL_USR_CF_ACT UNIQUE (ACT_ID);

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
