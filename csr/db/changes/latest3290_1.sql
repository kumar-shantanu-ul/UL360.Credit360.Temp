-- Please update version.sql too -- this keeps clean builds in sync
define version=3290
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.issue_custom_field
ADD restrict_to_group_sid NUMBER(10);

ALTER TABLE csrimp.issue_custom_field
ADD restrict_to_group_sid NUMBER(10);

CREATE INDEX csr.ix_issue_custom_field_group ON csr.issue_custom_field (restrict_to_group_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

ALTER TABLE csr.issue_custom_field ADD CONSTRAINT fk_iss_cus_field_group
	FOREIGN KEY (restrict_to_group_sid)
	REFERENCES security.group_table (sid_id);

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../issue_pkg

@../issue_body
@../schema_body
@../csrimp/imp_body

@update_tail
