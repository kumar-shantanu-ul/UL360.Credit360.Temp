-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS (
	APP_SID							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUTOMATED_EXPORT_CLASS_SID		NUMBER(10)	NOT NULL,
	BATCHED_EXPORT_TYPE_ID			NUMBER(10)	NOT NULL,
	SETTINGS_XML					XMLTYPE		NOT NULL,
	CONVERT_TO_DSV					NUMBER(1) DEFAULT 0 NOT NULL,
	PRIMARY_DELIMITER				VARCHAR2(1) DEFAULT ',' NOT NULL,
	SECONDARY_DELIMITER				VARCHAR2(1) DEFAULT '|' NOT NULL,
	CONSTRAINT PK_AUTO_EXP_BATCH_EXP_SETTINGS PRIMARY KEY (APP_SID, AUTOMATED_EXPORT_CLASS_SID),
	CONSTRAINT CK_AUTO_EXP_BATCH_EXP_CONV_DSV CHECK (CONVERT_TO_DSV IN (0, 1))
);

ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS ADD CONSTRAINT FK_AUTO_EXP_BTCH_SET_CLS_SID
	FOREIGN KEY (APP_SID, AUTOMATED_EXPORT_CLASS_SID)
	REFERENCES CSR.AUTOMATED_EXPORT_CLASS(APP_SID, AUTOMATED_EXPORT_CLASS_SID)
;

ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS ADD CONSTRAINT FK_AUTO_EXP_BTCH_SET_EXPORTER
	FOREIGN KEY (BATCHED_EXPORT_TYPE_ID)
	REFERENCES CSR.BATCHED_EXPORT_TYPE(BATCH_JOB_TYPE_ID)
;

CREATE INDEX csr.ix_auto_exp_batc_batched_expor ON csr.auto_exp_batched_exp_settings (batched_export_type_id);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
	VALUES (19, 'Batched exporter',	'Credit360.ExportImport.Automated.Export.Exporters.Batched.AutomatedBatchedExporter', 'Credit360.ExportImport.Automated.Export.Exporters.Batched.AutomatedBatchedOutputter');

	-- Clear out unimplemented crap
	DELETE FROM CSR.AUTO_EXP_FILE_WRITER_PLUGIN
	 WHERE PLUGIN_ID IN (2, 3, 4);
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_exporter_pkg
@../automated_export_pkg

@../batch_exporter_body
@../automated_export_body


@update_tail
