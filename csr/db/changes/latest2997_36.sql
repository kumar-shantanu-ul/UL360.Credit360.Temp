-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=36
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.automated_import_class
  ADD process_all_pending_files NUMBER (1) DEFAULT 0 NOT NULL;
 
ALTER TABLE csr.automated_import_class
  ADD CONSTRAINT ck_auto_imp_cls_process_all CHECK (process_all_pending_files IN (0, 1));

ALTER TABLE csr.automated_import_class_step
  ADD on_failure_sp VARCHAR2(255);

CREATE UNIQUE INDEX CSR.UK_CMS_IMP_CLASS_LABEL ON CSR.AUTOMATED_IMPORT_CLASS(APP_SID, UPPER(LABEL));
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.automated_import_class_step
	   SET on_failure_sp = on_completion_sp
	 WHERE on_completion_sp IS NOT NULL
	   AND on_failure_sp IS NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../automated_export_import_pkg

@../automated_import_body
@../automated_export_import_body

@update_tail
