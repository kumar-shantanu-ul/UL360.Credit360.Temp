-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.TAG_DESCRIPTION(
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAG_ID				NUMBER(10, 0)		NOT NULL,
	LANG				VARCHAR2(10)		NOT NULL,
	TAG					VARCHAR2(255)		NOT NULL,
	EXPLANATION			VARCHAR2(1024),
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_DESCRIPTION PRIMARY KEY (APP_SID, TAG_ID, LANG)
);

CREATE TABLE CSR.TAG_GROUP_DESCRIPTION(
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAG_GROUP_ID		NUMBER(10, 0)		NOT NULL,
	LANG				VARCHAR2(10)		NOT NULL,
	NAME				VARCHAR2(255)		NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_GROUP_DESCRIPTION PRIMARY KEY (APP_SID, TAG_GROUP_ID, LANG)
);


CREATE TABLE CSRIMP.TAG_DESCRIPTION(
	CSRIMP_SESSION_ID	NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAG_ID				NUMBER(10, 0)		NOT NULL,
	LANG				VARCHAR2(10)		NOT NULL,
	TAG					VARCHAR2(255)		NOT NULL,
	EXPLANATION			VARCHAR2(1024),
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAG_ID, LANG),
	CONSTRAINT FK_TAG_DESCRIPTION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.TAG_GROUP_DESCRIPTION(
	CSRIMP_SESSION_ID	NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAG_GROUP_ID		NUMBER(10, 0)		NOT NULL,
	LANG 				VARCHAR2(10)		NOT NULL,
	NAME				VARCHAR2(255)		NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_GROUP_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAG_GROUP_ID, LANG),
	CONSTRAINT FK_TAG_GROUP_DESCRIPTION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

DROP INDEX csr.UK_TAG_GROUP_NAME;

-- Alter tables

-- *** Grants ***
GRANT INSERT ON CSR.TAG_DESCRIPTION TO CSRIMP;
GRANT INSERT ON CSR.TAG_GROUP_DESCRIPTION TO CSRIMP;
GRANT INSERT, SELECT, UPDATE, DELETE ON CSRIMP.TAG_DESCRIPTION TO TOOL_USER;
GRANT INSERT, SELECT, UPDATE, DELETE ON CSRIMP.TAG_GROUP_DESCRIPTION TO TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

CREATE OR REPLACE VIEW CSR.V$TAG_GROUP AS
	SELECT tg.app_sid, tg.tag_group_id, NVL(tgd.name, tgden.name) name,
		tg.multi_select, tg.mandatory, tg.applies_to_inds,
		tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
		tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
		tg.applies_to_chain_product_types, tg.applies_to_quick_survey, tg.applies_to_audits,
		tg.applies_to_compliances, tg.lookup_key
	  FROM csr.tag_group tg
	LEFT JOIN csr.tag_group_description tgd ON tgd.app_sid = tg.app_sid AND tgd.tag_group_id = tg.tag_group_id AND tgd.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_group_description tgden ON tgden.app_sid = tg.app_sid AND tgden.tag_group_id = tg.tag_group_id AND tgden.lang = 'en';

CREATE OR REPLACE VIEW CSR.V$TAG AS
	SELECT t.app_sid, t.tag_id, NVL(td.tag, tden.tag) tag, NVL(td.explanation, tden.explanation) explanation,
		t.lookup_key, t.exclude_from_dataview_grouping
	  FROM csr.tag t
	LEFT JOIN csr.tag_description td ON td.app_sid = t.app_sid AND td.tag_id = t.tag_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_description tden ON tden.app_sid = t.app_sid AND tden.tag_id = t.tag_id AND tden.lang = 'en';


CREATE OR REPLACE VIEW csr.tag_group_ir_member AS
  -- get region tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, region_sid, null ind_sid, null non_compliance_id
    FROM tag_group_member tgm, v$tag t, region_tag rt
   WHERE tgm.tag_id = t.tag_id
     AND rt.tag_id = t.tag_id
  UNION ALL
  -- get indicator tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id,t.tag, null region_sid, it.ind_sid ind_sid, null non_compliance_id
    FROM tag_group_member tgm, v$tag t, ind_tag it
   WHERE tgm.tag_id = t.tag_id
     AND it.tag_id = t.tag_id
  UNION ALL
 -- get non compliance tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, null region_sid, null ind_sid, nct.non_compliance_id
    FROM tag_group_member tgm, v$tag t, non_compliance_tag nct
   WHERE tgm.tag_id = t.tag_id
     AND nct.tag_id = t.tag_id;

-- c:\cvs\csr\db\create_views.sql

GRANT SELECT ON csr.v$tag TO chain WITH GRANT OPTION;
GRANT SELECT ON csr.v$tag_group TO chain WITH GRANT OPTION;
GRANT SELECT, REFERENCES ON csr.v$tag_group TO donations;
GRANT SELECT, REFERENCES ON csr.v$tag TO donations;
GRANT SELECT, REFERENCES ON csr.v$tag_group TO surveys;
GRANT SELECT, REFERENCES ON csr.v$tag TO surveys;



CREATE OR REPLACE VIEW CHAIN.v$company_tag AS
	SELECT c.app_sid, c.company_sid, c.name company_name, ct.source, tg.name tag_group_name, t.tag, tg.tag_group_id, t.tag_id, t.lookup_key tag_lookup_key, c.active
	  FROM company c
	  JOIN (
		SELECT s.app_sid, s.company_sid, rt.tag_id, 'Supplier region tag' source
		  FROM csr.supplier s
		  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
		 UNION
		SELECT cpt.app_sid, cpt.company_sid, ptt.tag_id, 'Product type tag' source
		  FROM company_product_type cpt
		  JOIN product_type_tag ptt ON cpt.product_type_id = ptt.product_type_id AND cpt.app_sid = ptt.app_sid
	  ) ct ON c.company_sid = ct.company_sid AND c.app_sid = ct.app_sid
	  JOIN csr.v$tag t ON ct.tag_id = t.tag_id AND ct.app_sid = t.app_sid
	  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
	  JOIN csr.v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
;
-- c:\cvs\csr\db\chain\create_views.sql

GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag_logging_form TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.approval_dashboard_tpl_tag TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag_dataview TO chain;


-- *** Data changes ***
-- RLS

-- Data

-- AUDIT_TYPE_TAG_DESC_CHANGED
INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
VALUES (112, 'Category description changed', 1);

-- insert translations of whatever text was in the base table
INSERT INTO csr.tag_description (app_sid, tag_id, lang, tag, explanation)
	SELECT t.app_sid, t.tag_id, ts.lang, NVL(trt.translated, t.tag) tag, NVL(tre.translated, t.explanation) explanation
	  FROM csr.tag t
	  JOIN aspen2.translation_set ts ON ts.application_sid = t.app_sid
	  LEFT JOIN (
		SELECT t.application_sid, t.original, trt.lang, trt.translated
		  FROM aspen2.translated trt, aspen2.translation t
		WHERE t.application_sid = trt.application_sid AND t.original_hash = trt.original_hash
	  ) trt ON trt.application_sid = ts.application_sid AND trt.lang = ts.lang AND t.tag = trt.original
	  LEFT JOIN (
		SELECT t.application_sid, t.original, tre.lang, tre.translated
		  FROM aspen2.translated tre, aspen2.translation t
		WHERE t.application_sid = tre.application_sid AND t.original_hash = tre.original_hash
	  ) tre ON tre.application_sid = ts.application_sid AND tre.lang = ts.lang AND t.explanation = tre.original
	  ORDER BY app_sid, tag_id, lang;

INSERT INTO csr.tag_group_description (app_sid, tag_group_id, lang, name)
	SELECT tg.app_sid, tg.tag_group_id, ts.lang, NVL(tr.translated, tg.name) name
	  FROM csr.tag_group tg
	  JOIN aspen2.translation_set ts ON ts.application_sid = tg.app_sid
	  LEFT JOIN (
		SELECT t.application_sid, t.original, tr.lang, tr.translated
		  FROM aspen2.translated tr, aspen2.translation t
		WHERE t.application_sid = tr.application_sid AND t.original_hash = tr.original_hash
	  ) tr ON tr.application_sid = ts.application_sid AND tr.lang = ts.lang AND tg.name = tr.original
	  ORDER BY app_sid, tag_group_id, lang;


/*
Note: Renaming these columns for now, we'll drop them later once the dust settles.
*/
ALTER TABLE CSR.TAG RENAME COLUMN TAG TO TAG_OLD;
ALTER TABLE CSR.TAG RENAME COLUMN EXPLANATION TO EXPLANATION_OLD;
ALTER TABLE CSR.TAG_GROUP RENAME COLUMN NAME TO NAME_OLD;

ALTER TABLE CSR.TAG MODIFY (TAG_OLD NULL);
ALTER TABLE CSR.TAG_GROUP MODIFY (NAME_OLD NULL);

ALTER TABLE CSRIMP.TAG DROP COLUMN TAG;
ALTER TABLE CSRIMP.TAG DROP COLUMN EXPLANATION;
ALTER TABLE CSRIMP.TAG_GROUP DROP COLUMN NAME;

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (69, 'Category translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (70, 'Tag translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (71, 'Category translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (72, 'Tag translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (73, 'Tag explanation translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (74, 'Tag explanation translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);


INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (69, 'Category translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.CategoryTranslationImporter');
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (70, 'Tag translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.TagTranslationImporter');
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (73, 'Tag explanation translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.TagExplanationTranslationImporter');

INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (71, 'Category translation export', 'Credit360.ExportImport.Export.Batched.Exporters.CategoryTranslationExporter');
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (72, 'Tag translation export', 'Credit360.ExportImport.Export.Batched.Exporters.TagTranslationExporter');
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (74, 'Tag explanation translation export', 'Credit360.ExportImport.Export.Batched.Exporters.TagExplanationTranslationExporter');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../schema_pkg
@../tag_pkg
@../role_pkg
@../question_library_pkg

@../schema_body
@../tag_body

@../meter_body
@../region_body
@../compliance_library_report_body
@../compliance_register_report_body
@../region_report_body
@../question_library_body
@../question_library_report_body
@../indicator_body
@../region_tree_body
@../role_body
@../csr_user_body
@../calc_body
@../benchmarking_dashboard_body
@../question_library_body
@../dataset_legacy_body
@../issue_body
@../snapshot_body
@../model_body
@../audit_body
@../audit_report_body
@../non_compliance_report_body
@../supplier_body
@../stored_calc_datasource_body
@../meter_list_body
@../property_body
@../property_report_body
@../initiative_metric_body
@../initiative_body
@../initiative_project_body
@../initiative_export_body
@../initiative_grid_body
@../initiative_report_body
@../enable_body
@../templated_report_schedule_body


@../chain/activity_body
@../chain/activity_report_body
@../chain/company_body
@../chain/company_tag_body
@../chain/company_filter_body
@../chain/component_body
@../chain/filter_body
@../chain/product_body
@../chain/bsci_body
@../chain/dedupe_admin_body
@../chain/company_dedupe_body
@../chain/dedupe_proc_record_report_body

@../chain/helper_body


@../csrimp/imp_body

--@../surveys/question_library_body
--@../surveys/question_library_report_body
@../donations/donation_body
@../donations/tag_body
@../integration_api_body

@update_tail
