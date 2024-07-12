-- Please update version.sql too -- this keeps clean builds in sync
define version=3479
define minor_version=3
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
-- Remove all orphaned auto_imp_fileread_ftp records
DELETE FROM csr.auto_imp_fileread_ftp
 WHERE auto_imp_fileread_ftp_id IN (
    SELECT f.auto_imp_fileread_ftp_id FROM csr.auto_imp_fileread_ftp f
      LEFT JOIN csr.automated_import_class_step s ON s.auto_imp_fileread_ftp_id = f.auto_imp_fileread_ftp_id
     WHERE s.auto_imp_fileread_ftp_id IS NULL
)
;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body
@../meter_monitor_body

@update_tail
