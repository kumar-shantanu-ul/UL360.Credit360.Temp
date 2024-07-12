-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.gresb_indicator_mapping MODIFY ind_sid NULL;
ALTER TABLE csrimp.compliance_item MODIFY title VARCHAR2(1024);
ALTER TABLE csrimp.compliance_item MODIFY summary VARCHAR2(4000);
ALTER TABLE csrimp.compliance_permit MODIFY permit_sub_type_id NULL;
ALTER TABLE csrimp.compliance_permit_condition MODIFY condition_sub_type_id NULL;

CREATE TABLE csrimp.compliance_permit_history (
	CSRIMP_SESSION_ID				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	prev_permit_id					NUMBER(10,0) NOT NULL,
	next_permit_id					NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_permit_history PRIMARY KEY (CSRIMP_SESSION_ID, prev_permit_id, next_permit_id),
	CONSTRAINT fk_compliance_permit_hist_is FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);


-- *** Grants ***
grant select, insert, update, delete on csrimp.compliance_permit_history to tool_user;
grant select, insert, update on csr.compliance_permit_history to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body
@../schema_body

@update_tail
