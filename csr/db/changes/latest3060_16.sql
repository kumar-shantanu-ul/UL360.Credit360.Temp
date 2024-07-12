-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.internal_audit_locked_tag DROP CONSTRAINT pk_ia_locked_tag;

ALTER TABLE csr.internal_audit_locked_tag ADD CONSTRAINT uk_ia_locked_tag UNIQUE (app_sid, internal_audit_sid, tag_group_id, tag_id);

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

@../audit_body

@update_tail
