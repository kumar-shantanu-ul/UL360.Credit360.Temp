-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=38
@update_header

-- *** DDL ***
-- Create tables
 
CREATE TABLE csr.compl_permit_app_status (
	compl_permit_app_status_id		NUMBER(10, 0)	NOT NULL,
	label							VARCHAR2(256)	NOT NULL,
	pos 							NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_compl_permit_app_status PRIMARY KEY (compl_permit_app_status_id)
);

INSERT INTO csr.compl_permit_app_status(compl_permit_app_status_id, label, pos) VALUES (0, 'In Progress', 0);
INSERT INTO csr.compl_permit_app_status(compl_permit_app_status_id, label, pos) VALUES (1, 'Granted', 1);
INSERT INTO csr.compl_permit_app_status(compl_permit_app_status_id, label, pos) VALUES (2, 'Refused', 2);

-- Alter tables

ALTER TABLE csr.compliance_permit_application ADD (
	compl_permit_app_status_id	NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT fk_compl_permit_app_status_id FOREIGN KEY (compl_permit_app_status_id) REFERENCES csr.compl_permit_app_status (compl_permit_app_status_id)
);

CREATE INDEX csr.ix_cpa_stat 
	ON csr.compliance_permit_application (compl_permit_app_status_id);

ALTER TABLE csrimp.compliance_permit_application ADD (
	compl_permit_app_status_id	NUMBER(1) NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (29, 'permit', 'Refused');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (30, 'application', 'Withdrawn');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../compliance_pkg
@../permit_pkg
@../training_pkg

@../compliance_body
@../compliance_register_report_body
@../compliance_setup_body
@../training_body
@../training_flow_helper_body
@../permit_body
@../flow_body

@../csrimp/imp_body
@../schema_body

@update_tail
