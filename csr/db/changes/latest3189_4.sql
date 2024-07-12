-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.FTP_PROFILE ADD ENABLE_DEBUG_LOG NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.FTP_PROFILE ADD CONSTRAINT CK_FTP_PROFILE_ENABLE_DEBG_LOG CHECK (ENABLE_DEBUG_LOG IN (0, 1)) ENABLE;
ALTER TABLE CSR.FTP_PROFILE ADD CONSTRAINT CK_FTP_PROFILE_PRESV_TIMESTAMP CHECK (PRESERVE_TIMESTAMP IN (0, 1)) ENABLE;

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

@../automated_export_import_pkg

@../automated_export_import_body

@update_tail
