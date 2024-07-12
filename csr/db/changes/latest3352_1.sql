-- Please update version.sql too -- this keeps clean builds in sync
define version=3352
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE
MODIFY (
	SHAREPOINT_SITE VARCHAR2(400),
	SHAREPOINT_FOLDER VARCHAR2(400)
);

ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE ADD (
  ONEDRIVE_FOLDER VARCHAR2(400)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.EXTERNAL_TARGET_PROFILE_TYPE (PROFILE_TYPE_ID, LABEL)
VALUES (2, 'OneDrive');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_body
@../target_profile_pkg
@../target_profile_body

@update_tail
