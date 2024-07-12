-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.section ADD (
	disable_general_attachments	NUMBER(1, 0)	DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.section ADD (
	disable_general_attachments	NUMBER(1, 0)	NULL
);

UPDATE csrimp.section SET disable_general_attachments = 0;

ALTER TABLE csrimp.section MODIFY disable_general_attachments NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../section_pkg
@../section_body
@../csrimp/imp_body
@../schema_body

@update_tail