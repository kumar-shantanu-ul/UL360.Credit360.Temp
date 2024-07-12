-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.auto_exp_retrieval_sp (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_exp_retrieval_sp_id			NUMBER(10) NOT NULL,
	stored_procedure					VARCHAR2(255) NOT NULL,
	strip_underscores_from_headers		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_exp_retrieval_sp PRIMARY KEY (app_sid, auto_exp_retrieval_sp_id),
	CONSTRAINT ck_auto_exp_rtrvl_strip CHECK (strip_underscores_from_headers IN (0, 1))
);

CREATE SEQUENCE csr.auto_exp_rtrvl_sp_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

		
-- Alter tables

ALTER TABLE csr.automated_export_class
ADD auto_exp_retrieval_sp_id NUMBER(10);

--check constraint for auto_exp_retrieval_sp_id not null if plugin_id = blah? would need to fix setup stored procs as well


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (13, 'Stored Procedure - Dsv', 'Credit360.AutomatedExportImport.Export.Exporters.StoredProcedure.StoredProcedureExporter', 'Credit360.AutomatedExportImport.Export.Exporters.StoredProcedure.StoredProcedureDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (14, 'ABInBev - Mean Scores (dsv) ', 'Credit360.AutomatedExportImport.Export.Exporters.AbInBev.MeanScoresExporter', 'Credit360.AutomatedExportImport.Export.Exporters.AbInBev.MeanScoresDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (15, 'ABInBev - Suep Mean Scores (dsv) ', 'Credit360.AutomatedExportImport.Export.Exporters.AbInBev.SuepMeanScoresExporter', 'Credit360.AutomatedExportImport.Export.Exporters.AbInBev.SuepMeanScoresDsvOutputter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../automated_export_pkg
@../automated_export_body
@../csr_app_body

@update_tail
