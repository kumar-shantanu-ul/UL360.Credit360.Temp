-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.prop_type_prop_tab (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	property_type_id	NUMBER(10) NOT NULL,
	plugin_id			NUMBER(10) NOT NULL,
	CONSTRAINT PK_PROP_TYPE_PROP_TAB PRIMARY KEY (app_sid, property_Type_id, plugin_id),
	CONSTRAINT FK_PROP_TYPE_PROP_TAB FOREIGN KEY (app_sid, property_type_id) REFERENCES csr.property_type(app_sid, property_type_id),
	CONSTRAINT FK_PLUGIN_PROP_TAB FOREIGN KEY (plugin_id) REFERENCES csr.plugin(plugin_id)
);

CREATE TABLE csrimp.prop_type_prop_tab (
	csrimp_session_id	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	property_type_id	NUMBER(10) NOT NULL,
	plugin_id			NUMBER(10) NOT NULL,
	CONSTRAINT PK_PROP_TYPE_PROP_TAB PRIMARY KEY (csrimp_session_id, property_Type_id, plugin_id),
	CONSTRAINT FK_PROP_TYPE_PROP_TAB_IS FOREIGN KEY (csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables
-- Throw away errors as will only affect new builds (schema was not updated).
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.issue_log MODIFY message NULL';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

-- This one was completely forgotten about.
ALTER TABLE csrimp.issue_log MODIFY message NULL;

create index csr.ix_prop_type_pro_plugin_id on csr.prop_type_prop_tab (plugin_id);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.prop_type_prop_tab to CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.PROP_TYPE_PROP_TAB TO TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\property_pkg
@@..\schema_pkg

@@..\property_body
@@..\schema_body
@@..\csrimp\imp_body

@update_tail
