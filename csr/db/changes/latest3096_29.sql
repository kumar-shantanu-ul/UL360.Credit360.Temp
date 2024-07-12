-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_permit_condition ADD (
	copied_from_id					NUMBER(10) NULL,
	CONSTRAINT fk_cpc_copied_from 
		FOREIGN KEY (app_sid, copied_from_id) 
		REFERENCES csr.compliance_permit_condition (app_sid, compliance_item_id)
);

ALTER TABLE csr.issue ADD (
	copied_from_id					NUMBER(10) NULL,
	CONSTRAINT fk_issue_copied_from
		FOREIGN KEY (app_sid, issue_id)
		REFERENCES csr.issue (app_sid, issue_id)
);

ALTER TABLE csr.issue_scheduled_task ADD (
	copied_from_id					NUMBER(10) NULL,
	CONSTRAINT fk_issue_st_copied_from
		FOREIGN KEY (app_sid, copied_from_id)
		REFERENCES csr.issue_scheduled_task (app_sid, issue_scheduled_task_id)
);

ALTER TABLE csrimp.compliance_permit_condition ADD (
	copied_from_id					NUMBER(10) NULL
);

ALTER TABLE csrimp.issue ADD (
	copied_from_id					NUMBER(10) NULL
);

ALTER TABLE csrimp.issue_scheduled_task ADD (
	copied_from_id					NUMBER(10) NULL
);

CREATE INDEX csr.ix_cpc_copied_from ON csr.compliance_permit_condition(app_sid, copied_from_id);
CREATE INDEX csr.ix_issue_copied_from ON csr.issue (app_sid, copied_from_id);
CREATE INDEX csr.ix_issue_st_copied_from ON csr.issue_scheduled_task (app_sid, copied_from_id);

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
@../permit_pkg
@../schema_pkg

@../csrimp/imp_body
@../issue_body
@../permit_body
@../schema_body
@../csr_app_body

@update_tail
