-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.user_profile up
SET email_address = CONCAT(up.csr_user_sid, '@credit360.com')
WHERE EXISTS(
    SELECT 1
      FROM csr.csr_user cu
     WHERE up.csr_user_sid = cu.csr_user_sid
       AND cu.anonymised = 1
);

UPDATE csr.csr_user
SET email = CONCAT(csr_user_sid, '@credit360.com')
WHERE anonymised = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body

@update_tail