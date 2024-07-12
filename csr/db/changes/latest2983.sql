define version=2983
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE CHAIN.HIGG (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FTP_FOLDER				VARCHAR2(1000) NOT NULL,
	FTP_PROFILE_LABEL		VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_HIGG PRIMARY KEY (APP_SID)
);
CREATE TABLE CSRIMP.CHAIN_HIGG (
	CSRIMP_SESSION_ID       NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FTP_FOLDER				VARCHAR2(1000),
	FTP_PROFILE_LABEL		VARCHAR2(255),
    CONSTRAINT PK_HIGG PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_HIGG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.property_mandatory_roles (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	role_sid						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_mandatory_roles PRIMARY KEY (app_sid, role_sid),
	CONSTRAINT fk_property_mandatory_roles
		FOREIGN KEY (app_sid, role_sid) 
		REFERENCES csr.role(app_sid, role_sid)
);
CREATE TABLE csrimp.property_mandatory_roles (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	role_sid						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_mandatory_roles PRIMARY KEY (csrimp_session_id, role_sid),
    CONSTRAINT fk_property_mandatory_roles
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csr.doc_type
(
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	doc_type_id						NUMBER(10,0) NOT NULL,
	doc_library_sid					NUMBER(10,0) NOT NULL,
	name							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_doc_type			PRIMARY KEY (app_sid, doc_type_id),
    CONSTRAINT uk_doc_type_name		UNIQUE (app_sid, doc_library_sid, name)
);
CREATE TABLE csrimp.doc_type
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	doc_type_id						NUMBER(10,0) NOT NULL,
	doc_library_sid					NUMBER(10,0) NOT NULL,
	name							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_doc_type			PRIMARY KEY (csrimp_session_id, doc_type_id),
    CONSTRAINT fk_doc_type_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.map_doc_type (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_type_id					NUMBER(10)	NOT NULL,
	new_doc_type_id					NUMBER(10)	NOT NULL,
    CONSTRAINT fk_map_doc_type_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
CREATE SEQUENCE csr.doc_type_id_seq;
CREATE TABLE CSRIMP.CMS_DATA_HELPER (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOOKUP_KEY 						VARCHAR2(255) NOT NULL,
    HELPER_PROCEDURE 				VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_DATA_HELPER PRIMARY KEY (CSRIMP_SESSION_ID, LOOKUP_KEY),
	CONSTRAINT FK_CMS_DATA_HELPER_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE SEQUENCE csr.qs_filter_condition_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE SEQUENCE csr.qs_filter_condition_gen_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE GLOBAL TEMPORARY TABLE csr.temp_filter_conditions (
	survey_sid						NUMBER(10) NOT NULL,
	qs_campaign_sid					NUMBER(10)
) ON COMMIT DELETE ROWS;
CREATE SEQUENCE csr.auto_imp_zip_settings_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
CREATE TABLE csr.auto_imp_zip_settings(
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_zip_settings_id		NUMBER(10) NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	step_number						NUMBER(10) NOT NULL,
	sort_by							VARCHAR2(10),
	sort_by_direction				VARCHAR2(10),
	CONSTRAINT pk_auto_imp_zip_settings PRIMARY KEY (app_sid, auto_imp_zip_settings_id),
	CONSTRAINT fk_auto_imp_zip_set_step FOREIGN KEY (app_sid, automated_import_class_sid, step_number) REFERENCES csr.automated_import_class_step(app_sid, automated_import_class_sid, step_number),
	CONSTRAINT uk_auto_imp_zip_set_step UNIQUE (app_sid, automated_import_class_sid, step_number),
	CONSTRAINT ck_auto_imp_zip_set_sort_by CHECK (SORT_BY IN ('DATE','FILENAME') OR SORT_BY IS NULL),
	CONSTRAINT ck_auto_imp_zip_set_sort_dir CHECK (SORT_BY_DIRECTION IN ('ASC','DESC') OR SORT_BY_DIRECTION IS NULL)
);
CREATE TABLE csr.auto_imp_zip_filter(
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_zip_settings_id		NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	wildcard_match					VARCHAR2(1024),
	regex_match						VARCHAR2(1024),
	matched_import_class_sid		NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_imp_zip_filter PRIMARY KEY (app_sid, auto_imp_zip_settings_id, pos),
	CONSTRAINT fk_auto_imp_zip_filter_cls FOREIGN KEY (app_sid, matched_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid)
);


ALTER TABLE CSR.REGION_SURVEY_RESPONSE DROP CONSTRAINT PK_REGION_SURVEY_RESPONSE DROP INDEX;
ALTER TABLE CSR.REGION_SURVEY_RESPONSE DROP CONSTRAINT UQ_REG_SUR_RESP_RESP_ID DROP INDEX;
ALTER TABLE CSR.REGION_SURVEY_RESPONSE ADD (
	CONSTRAINT PK_REGION_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID)
);
ALTER TABLE CSRIMP.REGION_SURVEY_RESPONSE DROP CONSTRAINT PK_REGION_SURVEY_RESPONSE DROP INDEX;
ALTER TABLE CSRIMP.REGION_SURVEY_RESPONSE DROP CONSTRAINT UQ_REG_SUR_RESP_RESP_ID DROP INDEX; 
ALTER TABLE CSRIMP.REGION_SURVEY_RESPONSE ADD (
	CONSTRAINT PK_REGION_SURVEY_RESPONSE PRIMARY KEY (CSRIMP_SESSION_ID, SURVEY_RESPONSE_ID)
);
ALTER TABLE csr.metering_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_meter_show_inherited_roles CHECK(show_inherited_roles IN (1, 0))
);
ALTER TABLE csr.property_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_prop_show_inherited_roles CHECK(show_inherited_roles IN (1, 0))
);
ALTER TABLE csrimp.metering_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.property_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.doc_version ADD doc_type_id NUMBER(10,0) NULL;
ALTER TABLE csr.doc_version ADD 
(
	doc_type_id NUMBER(10,0) NULL,
	CONSTRAINT fk_doc_version_doc_type 
		FOREIGN KEY (app_sid, doc_type_id) 
		REFERENCES csr.doc_type (app_sid, doc_type_id)
);
ALTER TABLE csr.doc_type ADD 
(
	CONSTRAINT fk_doc_type_doc_lib
		FOREIGN KEY (app_sid, doc_library_sid)
		REFERENCES csr.doc_library (app_sid, doc_library_sid)
);
CREATE INDEX csr.ix_doc_version_doc_type ON csr.doc_version (app_sid, doc_type_id);
COMMENT ON COLUMN CHAIN.HIGG_MODULE_SUB_SECTION.HIGG_SECTION_ID IS 'DESC="Section",SEARCH_ENUM,ENUM_DESC_COL=SECTION_NAME';
COMMENT ON COLUMN CHAIN.HIGG_QUESTION.PARENT_QUESTION_ID IS 'DESC="Parent question",SEARCH_ENUM,ENUM_DESC_COL=QUESTION_TEXT';
COMMENT ON COLUMN CHAIN.HIGG_QUESTION.HIGG_SUB_SECTION_ID IS 'DESC="Sub-section",SEARCH_ENUM,ENUM_DESC_COL=SUB_SECTION_NAME';
COMMENT ON COLUMN CHAIN.HIGG_QUESTION_OPTION.HIGG_QUESTION_ID IS 'desc="Question",SEARCH_ENUM,ENUM_DESC_COL=QUESTION_TEXT';
ALTER TABLE csrimp.region MODIFY geo_latitude NUMBER;
ALTER TABLE csrimp.region MODIFY geo_longitude NUMBER;
DECLARE
	v_require_fix	NUMBER(1);
BEGIN
	SELECT CASE WHEN data_scale IS NULL THEN 0 ELSE 1 END 
	  INTO v_require_fix
	  FROM all_tab_columns 
	 WHERE table_name = 'REGION'  and OWNER = 'CSR' and COLUMN_NAME = 'GEO_LATITUDE';	-- check for latitude, it will apply to longitude as well
	 
	 IF v_require_fix = 1 THEN 
		execute immediate('ALTER TABLE csr.region MODIFY geo_latitude NUMBER');
		execute immediate('ALTER TABLE csr.region MODIFY geo_longitude NUMBER');
	 END IF;
END;
/
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) NOT NULL;
ALTER TABLE csr.initiative_user DROP CONSTRAINT fk_init_init_user;

BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT iu.app_sid, iu.initiative_sid, iu.project_sid old_project_sid, i.project_sid new_project_sid
		  FROM csr.initiative_user iu
		  JOIN csr.initiative i ON iu.app_sid = i.app_sid AND iu.initiative_sid = i.initiative_sid
		 WHERE (iu.app_sid, iu.initiative_sid, iu.project_sid) NOT IN (
			SELECT app_sid, initiative_sid, project_sid 
			  FROM csr.initiative
		 )
	) LOOP
		UPDATE csr.initiative_user
		   SET project_sid = r.new_project_sid
		 WHERE app_sid = r.app_sid
		   AND initiative_sid = r.initiative_sid
		   AND project_sid = r.old_project_sid;
	END LOOP;
END;
/

ALTER TABLE csr.initiative_user ADD CONSTRAINT fk_init_init_user
    FOREIGN KEY (app_sid, initiative_sid, project_sid)
    REFERENCES csr.initiative(app_sid, initiative_sid, project_sid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
;
ALTER TABLE CHAIN.TT_QUESTIONNAIRE_ORGANIZER MODIFY QUESTIONNAIRE_ID NUMBER(10) NULL;
ALTER TABLE CHAIN.TT_QUESTIONNAIRE_ORGANIZER ADD COMPANY_SID NUMBER(10) NOT NULL;
ALTER TABLE CHAIN.TT_QUESTIONNAIRE_ORGANIZER ADD QUESTIONNAIRE_TYPE_ID NUMBER(10) NOT NULL;
ALTER TABLE csrimp.customer
  ADD tear_off_deleg_header NUMBER(1) NOT NULL;
ALTER TABLE csrimp.customer
  ADD deleg_dropdown_threshold NUMBER(10) NOT NULL;
ALTER TABLE csr.customer
  ADD user_picker_extra_fields VARCHAR2(255);
ALTER TABLE csrimp.customer
  ADD user_picker_extra_fields VARCHAR2(255);
ALTER TABLE csr.qs_filter_condition ADD (
	qs_campaign_sid					NUMBER(10),
	CONSTRAINT fk_qs_filter_conditn_campaign FOREIGN KEY (app_sid, qs_campaign_sid)
		REFERENCES csr.qs_campaign (app_sid, qs_campaign_sid)
);
ALTER TABLE csr.qs_filter_condition_general ADD (
	qs_campaign_sid					NUMBER(10),
	CONSTRAINT fk_qs_fltr_condtn_gen_campaign FOREIGN KEY (app_sid, qs_campaign_sid)
		REFERENCES csr.qs_campaign (app_sid, qs_campaign_sid)
);
ALTER TABLE csr.qs_filter_condition RENAME COLUMN qs_filter_condition_id TO pos;
ALTER TABLE csr.qs_filter_condition ADD (
	qs_filter_condition_id			NUMBER(10),
	survey_sid						NUMBER(10),
	CONSTRAINT fk_qs_filter_condition_survey FOREIGN KEY (app_sid, survey_sid)
		REFERENCES csr.quick_survey (app_sid, survey_sid)
);
UPDATE csr.qs_filter_condition
   SET qs_filter_condition_id = csr.qs_filter_condition_id_seq.NEXTVAL
 WHERE qs_filter_condition_id IS NULL;
 
ALTER TABLE csr.qs_filter_condition MODIFY qs_filter_condition_id NOT NULL;
UPDATE csr.qs_filter_condition qfc
   SET survey_sid = (
	SELECT survey_sid
	  FROM csr.quick_survey_question qsq
	 WHERE qsq.app_sid = qfc.app_sid
	   AND qsq.question_id = qfc.question_id
	   AND qsq.survey_version = qfc.survey_version
	)
 WHERE survey_sid IS NULL; 
 
ALTER TABLE csr.qs_filter_condition MODIFY survey_sid NOT NULL;
ALTER TABLE csr.qs_filter_condition DROP CONSTRAINT pk_qs_filter_condition DROP INDEX;
ALTER TABLE csr.qs_filter_condition ADD CONSTRAINT pk_qs_filter_condition PRIMARY KEY (app_sid, qs_filter_condition_id);
CREATE UNIQUE INDEX csr.uk_qs_filter_condition ON csr.qs_filter_condition (app_sid, filter_id, pos, NVL(qs_campaign_sid, survey_sid));
ALTER TABLE csr.qs_filter_condition_general RENAME COLUMN qs_filter_condition_general_id TO pos;
ALTER TABLE csr.qs_filter_condition_general ADD (
	qs_filter_condition_general_id	NUMBER(10)
);
UPDATE csr.qs_filter_condition_general
   SET qs_filter_condition_general_id = csr.qs_filter_condition_gen_id_seq.NEXTVAL
 WHERE qs_filter_condition_general_id IS NULL;
 
ALTER TABLE csr.qs_filter_condition_general MODIFY qs_filter_condition_general_id NOT NULL;
ALTER TABLE csr.qs_filter_condition_general DROP CONSTRAINT pk_qs_filter_condition_general DROP INDEX;
ALTER TABLE csr.qs_filter_condition_general ADD CONSTRAINT pk_qs_filter_condition_general PRIMARY KEY (app_sid, qs_filter_condition_general_id);
CREATE UNIQUE INDEX csr.uk_qs_filter_condition_general ON csr.qs_filter_condition_general (app_sid, filter_id, pos, NVL(qs_campaign_sid, survey_sid));
ALTER TABLE csrimp.qs_filter_condition RENAME COLUMN qs_filter_condition_id TO pos;
ALTER TABLE csrimp.qs_filter_condition ADD (
	qs_filter_condition_id			NUMBER(10),
	survey_sid						NUMBER(10),
	qs_campaign_sid					NUMBER(10)
);
UPDATE csrimp.qs_filter_condition
   SET qs_filter_condition_id = csr.qs_filter_condition_id_seq.NEXTVAL
 WHERE qs_filter_condition_id IS NULL;
 
ALTER TABLE csrimp.qs_filter_condition MODIFY qs_filter_condition_id NOT NULL;
UPDATE csrimp.qs_filter_condition qfc
   SET survey_sid = (
	SELECT survey_sid
	  FROM csrimp.quick_survey_question qsq
	 WHERE qsq.csrimp_session_id = qfc.csrimp_session_id
	   AND qsq.question_id = qfc.question_id
	   AND qsq.survey_version = qfc.survey_version
	)
 WHERE survey_sid IS NULL; 
 
ALTER TABLE csrimp.qs_filter_condition MODIFY survey_sid NOT NULL;
ALTER TABLE csrimp.qs_filter_condition DROP CONSTRAINT pk_qs_filter_condition DROP INDEX;
ALTER TABLE csrimp.qs_filter_condition ADD CONSTRAINT pk_qs_filter_condition PRIMARY KEY (csrimp_session_id, qs_filter_condition_id);
CREATE UNIQUE INDEX csrimp.uk_qs_filter_condition ON csrimp.qs_filter_condition (csrimp_session_id, filter_id, pos, NVL(qs_campaign_sid, survey_sid));
ALTER TABLE csrimp.qs_filter_condition_general RENAME COLUMN qs_filter_condition_general_id TO pos;
ALTER TABLE csrimp.qs_filter_condition_general ADD (
	qs_filter_condition_general_id	NUMBER(10),	
	qs_campaign_sid					NUMBER(10)
);
UPDATE csrimp.qs_filter_condition_general
   SET qs_filter_condition_general_id = csr.qs_filter_condition_gen_id_seq.NEXTVAL
 WHERE qs_filter_condition_general_id IS NULL;
 
ALTER TABLE csrimp.qs_filter_condition_general MODIFY qs_filter_condition_general_id NOT NULL;
ALTER TABLE csrimp.qs_filter_condition_general DROP CONSTRAINT pk_qs_filter_condition_general DROP INDEX;
ALTER TABLE csrimp.qs_filter_condition_general ADD CONSTRAINT pk_qs_filter_condition_general PRIMARY KEY (csrimp_session_id, qs_filter_condition_general_id);
CREATE UNIQUE INDEX csrimp.uk_qs_filter_condition_general ON csrimp.qs_filter_condition_general (csrimp_session_id, filter_id, pos, NVL(qs_campaign_sid, survey_sid));
create index csr.ix_qs_filter_con_survey_sid on csr.qs_filter_condition (app_sid, survey_sid);
create index csr.ix_qs_filter_con_qs_campaign_s on csr.qs_filter_condition (app_sid, qs_campaign_sid);
create index csr.ix_qs_filter_con_gen_campaign on csr.qs_filter_condition_general (app_sid, qs_campaign_sid);
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE
ADD parent_instance_id NUMBER(10);
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE
ADD CONSTRAINT auto_instance_parent_instance FOREIGN KEY (app_sid, parent_instance_id) REFERENCES CSR.AUTOMATED_IMPORT_INSTANCE(app_sid, automated_import_instance_id);
DECLARE
	v_column_exists NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_column_exists
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='DELEG_PLAN' AND column_name='INTERVAL';
   
	IF v_column_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEG_PLAN DROP COLUMN INTERVAL';
	END IF;
END;
/


create or replace package chain.higg_setup_pkg as
procedure dummy;
end;
/
create or replace package body chain.higg_setup_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT SELECT, INSERT ON chain.higg TO csr;
GRANT SELECT ON csr.audit_closure_type TO chain;
GRANT SELECT, INSERT, UPDATE ON chain.higg TO csrimp;
GRANT SELECT, INSERT ON chain.higg TO csr;
GRANT INSERT ON chain.higg_module_tag_group TO csr;
GRANT EXECUTE ON chain.higg_setup_pkg TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.doc_type TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.map_doc_type TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.doc_type TO csrimp;
GRANT SELECT ON csr.doc_type_id_seq TO csrimp;
GRANT SELECT, UPDATE ON cms.form_version TO csrimp;
GRANT INSERT ON cms.data_helper TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.cms_data_helper TO tool_user;
GRANT SELECT ON csr.qs_filter_condition_id_seq TO CSRIMP;
GRANT SELECT ON csr.qs_filter_condition_gen_id_seq TO CSRIMP;




CREATE OR REPLACE VIEW csr.v$doc_current AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   df.lifespan,
		   dv.version, dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm,
		   dd.doc_data_id, dd.data, dd.sha1, dd.mime_type, dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id;
CREATE OR REPLACE VIEW csr.v$doc_approved AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   dc.version,
		   df.lifespan,
		   dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm,
		   dd.sha1, dd.mime_type, dd.data, dd.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status,
		   dd.app_sid, dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id
		-- don't return stuff that's added but never approved
	   WHERE dc.version IS NOT NULL;
CREATE OR REPLACE VIEW csr.v$doc_current_status AS
	SELECT parent_sid, doc_id, locked_by_sid, pending_version,
		version, lifespan,
		filename, description, change_description, changed_by_sid, changed_dtm,
		sha1, mime_type, data, doc_data_id,
		locked_by_me, expiry_status, doc_type_id, doc_type_name
	  FROM v$doc_approved
	   WHERE NVL(locked_by_sid,-1) != SYS_CONTEXT('SECURITY','SID') OR pending_version IS NULL
	   UNION ALL
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
			-- if it's the approver then show them the right version, otherwise pass through null (i.e. dc.version) to other users so they can't fiddle
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL THEN dc.pending_version ELSE dc.version END version,
		   df.lifespan,
		   dvp.filename, dvp.description, dvp.change_description, dvp.changed_by_sid, dvp.changed_dtm,
		   ddp.sha1, ddp.mime_type, ddp.data, ddp.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status, 
		   dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dvp ON dc.doc_id = dvp.doc_id AND dc.pending_version = dvp.version
		LEFT JOIN doc_data ddp ON dvp.doc_data_id = ddp.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dvp.doc_type_id
	   WHERE (NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL) OR dc.version IS null;
CREATE OR REPLACE VIEW csr.v$audit_validity AS 
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	CASE (atct.re_audit_due_after_type)
		WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
		WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
		WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
		WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
		ELSE ia.ovw_validity_dtm
	END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
	act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
	  FROM csr.internal_audit ia
	  LEFT JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  LEFT JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	 WHERE ia.deleted = 0
	   AND (ia.audit_closure_type_id IS NOT NULL OR ia.ovw_validity_dtm IS NOT NULL);
CREATE OR REPLACE VIEW chain.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,                  -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title, csru.user_ref,  -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								              -- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled, csru.send_alerts
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0;
CREATE OR REPLACE VIEW CHAIN.v$company_user AS
	SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name,
		   vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,
		   vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		   vcu.account_enabled, vcu.user_ref
	  FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
	 WHERE cug.app_sid = vcu.app_sid
	   AND cug.user_group_sid = gm.group_sid_id
	   AND vcu.user_sid = gm.member_sid_id;
	 




BEGIN
    security.user_pkg.logonAdmin();
    UPDATE csr.tab_user
       SET is_hidden = 0
     WHERE (tab_id, user_sid) IN (
        SELECT tu.tab_id, tu.user_sid
          FROM csr.tab t
          JOIN csr.tab_user tu
            ON t.tab_id = tu.tab_id
         WHERE t.is_hideable = 0
           AND tu.is_hidden = 1
     );
    
    security.user_pkg.LogOff(SYS_CONTEXT('SECURITY','ACT'));
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT DISTINCT hc.app_sid, fp.label, ftp.payload_path
		  FROM chain.higg_config hc
		  JOIN csr.auto_imp_fileread_ftp ftp ON ftp.app_sid = hc.app_sid
		  JOIN csr.ftp_profile fp ON fp.ftp_profile_id = ftp.ftp_profile_id
	)
	LOOP
		INSERT INTO chain.higg (app_sid, ftp_profile_label, ftp_folder)
		VALUES (r.app_sid, r.label, r.payload_path);
	END LOOP;
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (88, 'Higg', 'EnableHigg', 'Enables Higg integration');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (88, 'in_ftp_profile', 0, 'The FTP profile to use. If this does not already exist, this will be set up to connect to cyanoxantha');
	  
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	  VALUES (88, 'in_ftp_folder', 1, 'The folder on the FTP server containing Higg responses');
END;
/
UPDATE csr.role
   SET is_property_manager = 1
 WHERE is_metering = 1;
UPDATE csr.module 
   SET module_name = 'Properties - GRESB',
	   description = 'Enables GRESB integration for property module. See <a href="http://emu.helpdocsonline.com/GRESB">http://emu.helpdocsonline.com/GRESB</a> for instructions.'
 WHERE module_id = 65;
UPDATE csr.module 
   SET module_name = 'Properties - Energy Star',
	   description = 'Enables Energy Star integration for property module.'
 WHERE module_id = 66;
INSERT INTO csr.property_mandatory_roles (app_sid, role_sid)
	SELECT app_sid, role_sid 
	  FROM csr.role 
	 WHERE is_property_manager = 1;
GRANT SELECT, INSERT, UPDATE ON csr.property_mandatory_roles TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.property_mandatory_roles TO tool_user;
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (87, 'Document library - document types', 'EnableDocLibDocTypes', 'Enables document types in the document library.', 0);
UPDATE csr.module
   SET module_name = 'Properties - GRESB',
       description = 'Enables GRESB integration for property module. See http://emu.helpdocsonline.com/GRESB for instructions.'
 WHERE module_id = 65;
 
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_menu_sas_sid					security.security_pkg.T_SID_ID;
	v_sa_sid						security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT c.app_sid, w.website_name
		  FROM csr.customer c, security.website w
		 WHERE c.app_sid = w.application_sid_id
	) LOOP
		security.user_pkg.logonadmin(r.website_name);
		v_app_sid := security.security_pkg.getApp;
		v_act_id := security.security_pkg.getACT;
		-- add menu item
		BEGIN
		v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
			  v_menu_sid := NULL;
		END;
		
		IF v_menu_sid IS NOT NULL THEN
			BEGIN
				security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'csr_site_admin_SuperAdmin_setup', 'SuperAdmin Setup', '/csr/site/admin/superadmin/setup.acds', 2, null, v_menu_sas_sid);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_menu_sas_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_site_admin_SuperAdmin_setup');
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_menu_sas_sid, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sas_sid));
			-- Add SA permission
			v_sa_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sas_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			-- remove links to pages that now exist in the new Super Admin page.
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/cms_admin_forms');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/cms_admin_doctemplates');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_admin_factor_sets');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin/csr_site_admin_emissionFactors_manage');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_admin_enable');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_admin_utilscripts');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
		END IF;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (85, 'Emission Factors Profiling', 'EnableEmFactorsProfileTool', 'Enables/Disables the Emission Factors Profile tool');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (85, 'Enable/Disable', 0, '0=disable, 1=enable');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (85, 'Menu Position', 1, '-1=end, or 1 based position');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (86, 'Emission Factors Classic', 'EnableEmFactorsClassicTool', 'Enables/Disables the Emission Factors Classic tool');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (86, 'Enable/Disable', 1, '0=disable, 1=enable');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (86, 'Menu Position', 2, '-1=end, or 1 based position, ignored if disabling');
END;
/
BEGIN
	UPDATE csr.module 
	   SET module_name = 'Emission Factor Start Date'
	 WHERE module_id = 50;
	 
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (50, 'Enable/Disable', 0, '0=disable, 1=enable');
	
	-- Remove "Emission Factor Start Date OFF"
	DELETE FROM csr.module 
	 WHERE module_id = 51;
END;
/
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Enable Dataview Bar Variance Options', 0);
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Null out values in val and region_metric_val for region metrics that have a text measure
	UPDATE csr.val
	   SET val_number = null,
		   entry_val_number = null
	 WHERE val_number = 0
	   AND source_type_id = 14
	   AND (app_sid, ind_sid, region_sid) IN (
		SELECT app_sid, ind_sid, region_sid
		  FROM csr.region_metric_val
		 WHERE val = 0
		   AND (app_sid, measure_sid) IN (
			SELECT app_sid, measure_sid
			  FROM csr.measure
			 WHERE custom_field = '|'
		)
	);
	UPDATE csr.region_metric_val
	   SET val = null,
		   entry_val = null
	 WHERE val = 0
	   AND (app_sid, measure_sid) IN (
		SELECT app_sid, measure_sid
		  FROM csr.measure
		 WHERE custom_field = '|'
	);
END;
/
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28213, 30, 'Kelvin', 1, 1, 0, 0);
BEGIN
	INSERT INTO csr.util_script (
	  util_script_id, util_script_name, description, util_script_sp, wiki_article
	) VALUES (
	  25, 'Set extra fields for user picker', 'Set the extra fields (email, user_name, user_ref) to be displayed in user picker.', 'SetUserPickerExtraFields', NULL
	);
	INSERT INTO csr.util_script_param (
	  util_script_id, param_name, param_hint, pos, param_value, param_hidden
	) VALUES (
	  25, 'Extra fields', 'Comma separated list of fields. Allowed fields are email, user_name and user_ref. Enter space to clear the extra fields.', 0, NULL, 0
	);
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.customer
	   SET user_picker_extra_fields = 'email'
	 WHERE user_picker_extra_fields IS NULL;
	 
	 security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/
UPDATE csr.module
   SET description = 'Enable GRESB property integration. Once enabled, the client''s site has to be added to the cr360 GRESB account, '||
       'by adding a new application under account settings, with the callback URL ''https://CLIENT_NAME.credit360.com/csr/site/property/gresb/authorise.acds''. '
 WHERE module_id = 65;
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (65, 'in_use_sandbox', 0, 'Use sandbox GRESB enviornment instead of live? (y|n default=n)');
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.Filters.CompanyRelationshipFilter
	v_desc := 'Survey Campaign Filter';
	v_class := 'Credit360.Chain.Cards.Filters.SurveyCampaign';
	v_js_path := '/csr/site/chain/cards/filters/surveyCampaign.js';
	v_js_class := 'Chain.Cards.Filters.SurveyCampaign';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
		
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.SurveyCampaign');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Survey Campaign Filter',
			'csr.quick_survey_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Basic Company Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/
/* US3032 */
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.Filters.CompanyRelationshipFilter
	v_desc := 'Survey Response Filter';
	v_class := 'Credit360.Audit.Cards.SurveyResponse';
	v_js_path := '/csr/site/audit/surveyResponse.js';
	v_js_class := 'Credit360.Audit.Filters.SurveyResponse';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
		
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Credit360.Audit.Filters.SurveyResponse');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Survey Response Filter',
			'csr.quick_survey_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Internal Audit Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Internal Audit Filter');
	END;	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	UPDATE chain.higg_question
	   SET measure_divisibility = 1 /*csr.csr_data_pkg.DIVISIBILITY_DIVISIBLE*/
	 WHERE higg_question_id IN (1136, 1138, 1224, 1445, 1541, 1726, 1729, 1732);
END;
/
INSERT INTO CSR.AUTO_IMP_IMPORTER_PLUGIN
  (plugin_id, label, importer_assembly)
VALUES
  (5, 'Zip extractor', 'Credit360.ExportImport.Automated.Import.Importers.ZipExtractImporter.ZipExtractImporter');






@..\csr_user_pkg
@..\user_report_pkg
@..\enable_pkg
@..\schema_pkg
@..\chain\higg_setup_pkg
@..\role_pkg
@..\property_pkg
@..\meter_pkg
@..\doc_pkg
@..\doc_lib_pkg
@..\csrimp\imp_pkg
@..\delegation_pkg
@..\factor_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\dataview_pkg
@..\chain\company_pkg
@..\chain\company_user_pkg
@..\util_script_pkg
@..\flow_pkg
@..\teamroom_pkg
@..\quick_survey_pkg
@..\region_pkg
@..\automated_import_pkg


@..\portlet_body
@..\csr_user_body
@..\campaign_body
@..\quick_survey_body
@..\approval_dashboard_body
@..\user_report_body
@..\enable_body
@..\schema_body
@..\chain\higg_body
@..\chain\higg_setup_body
@..\csrimp\imp_body
@..\role_body
@..\property_body
@..\meter_body
@..\csr_app_body
@..\doc_body
@..\doc_lib_body
@..\initiative_doc_body
@..\section_body
@..\delegation_body
@..\factor_body
@..\issue_report_body
@..\supplier_body
@..\chain\company_user_body
@..\..\..\aspen2\cms\db\tab_body
@..\dataview_body
@..\chain\company_body
@..\..\..\aspen2\cms\db\filter_body
@..\meter_monitor_body
@..\initiative_body
@..\audit_report_body
@..\chain\questionnaire_body
@..\customer_body
@..\audit_body
@..\issue_body
@..\util_script_body
@..\flow_body
@..\teamroom_body
@..\chain\setup_body
@@..\audit_body
@..\region_body
@..\automated_import_body
@..\incident_body



@update_tail
