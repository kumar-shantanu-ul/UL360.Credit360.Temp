-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.tpl_report_schedule ADD (
	publish_to_prop_doc_lib NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_publish_to_prop_doc_lib CHECK (publish_to_prop_doc_lib IN (0, 1))
);

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
@../templated_report_schedule_pkg
@../templated_report_schedule_body

@update_tail
