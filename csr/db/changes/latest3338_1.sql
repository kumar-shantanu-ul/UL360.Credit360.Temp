-- Please update version.sql too -- this keeps clean builds in sync
define version=3338
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.EXTERNAL_TARGET_PROFILE_TYPE (
	PROFILE_TYPE_ID			NUMBER(10,0) NOT NULL,
	LABEL					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_EXT_TARGET_PROF_TYPE PRIMARY KEY (PROFILE_TYPE_ID)
)
;

CREATE SEQUENCE CSR.EXTERNAL_TARGET_PROFILE_SEQ;

CREATE TABLE CSR.EXTERNAL_TARGET_PROFILE (
	APP_SID					NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	LABEL 					VARCHAR2(255) NOT NULL,
	TARGET_PROFILE_ID		NUMBER(10,0) NOT NULL,
	PROFILE_TYPE_ID			NUMBER(10,0) NOT NULL,
	SHAREPOINT_SITE			VARCHAR2(255),
	GRAPH_API_URL			VARCHAR2(255),
	SHAREPOINT_FOLDER		VARCHAR2(255),
	SHAREPOINT_TENANT_ID	VARCHAR2(255),
	CREDENTIAL_PROFILE_ID	NUMBER(10,0),
	CONSTRAINT PK_EXT_TARGET_PROF PRIMARY KEY (APP_SID, TARGET_PROFILE_ID),
	CONSTRAINT FK_EXT_TARGET_PROF_TYPE FOREIGN KEY (PROFILE_TYPE_ID) REFERENCES CSR.EXTERNAL_TARGET_PROFILE_TYPE (PROFILE_TYPE_ID)
)
;

/* No CSRIMP tables */

-- Alter tables
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD (
  AUTO_EXP_EXTERN_TARGET_PROFILE_ID   NUMBER(10,0)
);

ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD CONSTRAINT FK_AUTO_EXP_CLASS_EXT_TARGET 
FOREIGN KEY (APP_SID, AUTO_EXP_EXTERN_TARGET_PROFILE_ID) REFERENCES CSR.EXTERNAL_TARGET_PROFILE (APP_SID, TARGET_PROFILE_ID);

create index csr.ix_automated_exp_auto_exp_exte on csr.automated_export_class (app_sid, auto_exp_extern_target_profile_id);
create index csr.ix_external_targ_profile_type_ on csr.external_target_profile (profile_type_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.auto_exp_file_wrtr_plugin_type (plugin_type_id, label)
VALUES (4, 'External Target');

INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly, plugin_type_id)
VALUES (8, 'External Target', 'Credit360.ExportImport.Automated.Export.FileWrite.ExternalTargetWriter', 4);

INSERT INTO csr.external_target_profile_type (profile_type_id, label)
VALUES (1, 'SharePoint Folder (Online)');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_import_pkg
@../automated_export_import_body
@../automated_export_pkg
@../automated_export_body
@../csr_app_body

@update_tail
