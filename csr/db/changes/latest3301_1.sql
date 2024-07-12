-- Please update version.sql too -- this keeps clean builds in sync
define version=3301
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.form_response_answer_file
ADD (
	remote_file_id VARCHAR2(255),
	file_name VARCHAR2(255) NOT NULL,
	mime_type VARCHAR2(255) NOT NULL
);


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
@../../../aspen2/cms/db/form_response_import_pkg
@../../../aspen2/cms/db/form_response_import_body

@update_tail
