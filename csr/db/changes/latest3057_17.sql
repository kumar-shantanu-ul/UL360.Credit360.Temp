-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.compliance_permit_application ADD (
	flow_item_id			NUMBER(10,0) NOT NULL
);

ALTER TABLE csrimp.compliance_permit_application ADD (
	flow_item_id			NUMBER(10,0) NOT NULL
);

ALTER TABLE csr.compliance_options ADD (
	permit_flow_sid			NUMBER(10,0) NULL,
	application_flow_sid	NUMBER(10,0) NULL
);

ALTER TABLE csrimp.compliance_options ADD (
	permit_flow_sid			NUMBER(10,0) NULL,
	application_flow_sid	NUMBER(10,0) NULL
);

ALTER TABLE csrimp.compliance_options MODIFY (
	requirement_flow_sid	NUMBER(10,0) NULL
);

ALTER TABLE csrimp.compliance_options MODIFY (
	regulation_flow_sid		NUMBER(10,0) NULL
);

ALTER TABLE csr.compliance_permit ADD CONSTRAINT fk_compl_perm_flow_item_id
	FOREIGN KEY (app_sid, flow_item_id)
	REFERENCES csr.flow_item (app_sid, flow_item_id);

ALTER TABLE csr.compliance_permit_application ADD CONSTRAINT fk_perm_appl_flow_item_id
	FOREIGN KEY (app_sid, flow_item_id)
	REFERENCES csr.flow_item (app_sid, flow_item_id);

ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_co_per_flow 
	FOREIGN KEY (app_sid, permit_flow_sid) 
	REFERENCES csr.flow (app_sid, flow_sid);

ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_co_app_flow 
	FOREIGN KEY (app_sid, application_flow_sid) 
	REFERENCES csr.flow (app_sid, flow_sid);

CREATE INDEX csr.ix_comp_permit_flow_item_id ON csr.compliance_permit (app_sid, flow_item_id);
CREATE INDEX csr.ix_cpa_flow_item_id ON csr.compliance_permit_application (app_sid, flow_item_id);
CREATE INDEX csr.ix_compliance_op_permit_f ON csr.compliance_options (app_sid, permit_flow_sid);
CREATE INDEX csr.ix_compliance_op_application_f ON csr.compliance_options (app_sid, application_flow_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('permit', 'Permit', 'csr.permit_pkg');
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('application', 'Application', 'csr.permit_pkg');

INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (17, 'permit', 'Not created');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (18, 'permit', 'Application');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (19, 'permit', 'Active');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (20, 'permit', 'Surrendered');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (21, 'application', 'Not created');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (22, 'application', 'Pre-application');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (23, 'application', 'Initial checks');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (24, 'application', 'Determination');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (25, 'application', 'Determined');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
CREATE OR REPLACE PACKAGE csr.permit_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.permit_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/

GRANT EXECUTE ON csr.permit_pkg TO web_user;


@@../compliance_setup_pkg
@@../compliance_pkg
@@../permit_pkg

@@../compliance_setup_body
@@../compliance_body
@@../permit_body

@@../schema_body
@@../enable_body
@@../csrimp/imp_body

@update_tail
