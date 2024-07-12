-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_permit_tab(
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    plugin_type_id    				NUMBER(10, 0)	NOT NULL,
    pos               				NUMBER(10, 0)	NOT NULL,
    tab_label         				VARCHAR2(50),
    CONSTRAINT pk_permit_tab PRIMARY KEY (app_sid, plugin_id),
    CONSTRAINT ck_permit_tab_plugin_type CHECK (plugin_type_id = 21)
);

CREATE INDEX ix_compliance_permit_tb_plugin ON csr.compliance_permit_tab (plugin_id, plugin_type_id);

ALTER TABLE csr.compliance_permit_tab ADD CONSTRAINT fk_compliance_permit_tb_plugin
    FOREIGN KEY (plugin_id, plugin_type_id)
    REFERENCES csr.plugin(plugin_id, plugin_type_id);

CREATE TABLE csr.compliance_permit_tab_group (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    group_sid						NUMBER(10, 0),
    role_sid						NUMBER(10, 0),
    CONSTRAINT pk_permit_tab_group PRIMARY KEY (app_sid, plugin_id, group_sid),
    CONSTRAINT ck_permit_tab_group_grp_role CHECK (
		(group_sid IS NULL AND role_sid IS NOT NULL) OR 
		(group_sid IS NOT NULL AND role_sid IS NULL)
	)
);

CREATE INDEX csr.ix_compliance_permit_tab_role ON csr.compliance_permit_tab_group (app_sid, role_sid);

ALTER TABLE csr.compliance_permit_tab_group ADD CONSTRAINT fk_compliance_permit_tab_group
    FOREIGN KEY (app_sid, plugin_id)
    REFERENCES csr.compliance_permit_tab (app_sid, plugin_id);

ALTER TABLE csr.compliance_permit_tab_group ADD CONSTRAINT fk_compliance_permit_tab_role
    FOREIGN KEY (app_sid, role_sid)
    REFERENCES csr.role (app_sid, role_sid);

CREATE TABLE csrimp.compliance_permit_tab(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    plugin_type_id    				NUMBER(10, 0)	NOT NULL,
    pos               				NUMBER(10, 0)	NOT NULL,
    tab_label         				VARCHAR2(50),
    CONSTRAINT pk_permit_tab PRIMARY KEY (csrimp_session_id, plugin_id),
    CONSTRAINT fk_permit_tab_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.compliance_permit_tab_group (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    group_sid						NUMBER(10, 0),
    role_sid						NUMBER(10, 0),
    CONSTRAINT pk_permit_tab_group PRIMARY KEY (csrimp_session_id, plugin_id, group_sid),
    CONSTRAINT fk_permit_tab_group_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.compliance_permit
ADD activity_details CLOB;

ALTER TABLE csr.compliance_permit_application
ADD title VARCHAR2(1024) NOT NULL;

ALTER TABLE csrimp.compliance_permit
ADD activity_details CLOB;

ALTER TABLE csrimp.compliance_permit_application
ADD title VARCHAR2(1024) NOT NULL;

-- *** Grants ***
grant select, insert, update, delete on csrimp.compliance_permit_tab to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_tab_group to tool_user;
grant select, insert, update on csr.compliance_permit_tab to csrimp;
grant select, insert, update on csr.compliance_permit_tab_group to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (21, 'Permit tab');

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (
	csr.plugin_id_seq.NEXTVAL, 21, 
	'Permit details tab', 
	'/csr/site/compliance/controls/PermitDetailsTab.js', 
	'Credit360.Compliance.Controls.PermitDetailsTab', 
	'Credit360.Compliance.Plugins.PermitDetailsTab', 
	'Shows basic permit details'
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../compliance_pkg
@@../csr_data_pkg
@@../schema_pkg

@@../compliance_body
@@../enable_body
@@../csr_app_body
@@../schema_body
@@../csrimp/imp_body
@@../role_body

@update_tail
