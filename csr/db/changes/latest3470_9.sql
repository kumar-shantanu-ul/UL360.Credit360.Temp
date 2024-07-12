-- Please update version.sql too -- this keeps clean builds in sync
define version=3470
define minor_version=9
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
-- remove dangling records where site has been deleted.
DELETE from csr.ftp_profile
 WHERE app_sid IN (
    SELECT fp.app_sid
      FROM csr.ftp_profile fp
      LEFT JOIN csr.customer c ON c.app_sid = fp.app_sid
     WHERE c.app_sid IS NULL
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_import_body
@../csr_app_body

@update_tail
