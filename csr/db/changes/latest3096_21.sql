-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_imp_user_imp_settings ADD set_line_mngmnt_frm_mngr_key NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.auto_imp_user_imp_settings ADD CONSTRAINT ck_auto_imp_usr_set_lin_mngmnt CHECK (set_line_mngmnt_frm_mngr_key IN (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../user_profile_pkg
@../automated_import_pkg

@../user_profile_body
@../automated_import_body

@update_tail