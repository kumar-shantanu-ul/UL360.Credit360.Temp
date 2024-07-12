-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.INTERNAL_AUDIT_LOCKED_TAG DROP CONSTRAINT PK_IA_LOCKED_TAG;
ALTER TABLE CSRIMP.INTERNAL_AUDIT_LOCKED_TAG DROP CONSTRAINT PK_IA_LOCKED_TAG;

ALTER TABLE CSR.INTERNAL_AUDIT_LOCKED_TAG ADD CONSTRAINT PK_IA_LOCKED_TAG
	PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, TAG_GROUP_ID, TAG_ID);

ALTER TABLE CSRIMP.INTERNAL_AUDIT_LOCKED_TAG ADD CONSTRAINT PK_IA_LOCKED_TAG
	PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, TAG_GROUP_ID, TAG_ID);

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

@update_tail
