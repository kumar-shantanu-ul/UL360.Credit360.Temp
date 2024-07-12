-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_exp_filecreate_dsv
ADD secondary_delimiter_id NUMBER(10);

ALTER TABLE csr.auto_exp_filecreate_dsv
ADD CONSTRAINT fk_auto_exp_second_delimiter FOREIGN KEY (secondary_delimiter_id) REFERENCES csr.auto_exp_imp_dsv_delimiters(delimiter_id);

ALTER TABLE csr.automated_export_class
MODIFY period_span_pattern_id NUMBER(10) NULL;

CREATE TABLE CSRIMP.SECURABLE_OBJECT_DESCRIPTION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SID_ID              NUMBER(10)          NOT NULL,
	LANG                VARCHAR2(10)        NOT NULL,
	DESCRIPTION         VARCHAR2(1023)      NOT NULL,
	CONSTRAINT pk_securable_object_desc PRIMARY KEY (CSRIMP_SESSION_ID, SID_ID, LANG),
	CONSTRAINT fk_so_desc_sid FOREIGN KEY (CSRIMP_SESSION_ID, SID_ID) REFERENCES csrimp.securable_object (CSRIMP_SESSION_ID, SID_ID) ON DELETE CASCADE,
	CONSTRAINT FK_SEC_OBJECT_DESC_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- *** Grants ***
GRANT EXECUTE ON csr.automated_import_pkg TO security;
GRANT EXECUTE ON csr.automated_export_pkg TO security;
grant insert on security.securable_object_description to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (5, 'User exporter (dsv)',		'Credit360.AutomatedExportImport.Export.Exporters.Users.UserExporter', 'Credit360.AutomatedExportImport.Export.Exporters.Users.UserDsvOutputter');

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (6, 'Groups and roles exporter (dsv)',		'Credit360.AutomatedExportImport.Export.Exporters.GroupsAndRoles.GroupsAndRolesExporter', 'Credit360.AutomatedExportImport.Export.Exporters.GroupsAndRoles.GroupsAndRolesDsvOutputter');

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (7, 'User exporter (dsv, Deutsche Bank)',		'Credit360.AutomatedExportImport.Export.Exporters.Users.UserExporter', 'Credit360.AutomatedExportImport.Export.Exporters.Gatekeeper.DeutscheBankUsersDsvOutputter');

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (8, 'Groups and roles exporter (dsv, Deutsche Bank)', 'Credit360.AutomatedExportImport.Export.Exporters.GroupsAndRoles.GroupsAndRolesExporter', 'Credit360.AutomatedExportImport.Export.Exporters.Gatekeeper.DeutscheBankEntitlementsDsvOutputter');


UPDATE csr.capability
   SET name = 'Manually import automated import instances'
 WHERE name = 'Manually import CMS data import instances';

-- ** New package grants **

-- *** Packages ***
@..\csr_user_pkg
@..\csr_user_body
@..\role_body
@..\automated_export_pkg
@..\automated_export_body
@..\csrimp\imp_body
@..\schema_pkg
@..\schema_body

@update_tail
