-- Please update version.sql too -- this keeps clean builds in sync
define version=3156
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.ftp_profile ADD PRESERVE_TIMESTAMP	NUMBER(1)	DEFAULT 0 NOT NULL;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS
BEGIN
	UPDATE csr.ftp_profile
	SET preserve_timestamp = 1;
END;
/
-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_import_pkg

@../automated_export_import_body
@../automated_export_body

@update_tail
