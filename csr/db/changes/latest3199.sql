define version=3199
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
CREATE SEQUENCE chain.geotag_batch_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE chain.geotag_batch(
	app_sid 			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	geotag_batch_id		NUMBER(10, 0) NOT NULL,
	batch_job_id		NUMBER(10, 0) NOT NULL,
	source				NUMBER(1) NOT NULL,
	CONSTRAINT pk_geotag_batch PRIMARY KEY (app_sid, geotag_batch_id),
	CONSTRAINT fk_geotag_batch_job FOREIGN KEY (app_sid, batch_job_id) REFERENCES csr.batch_job (app_sid, batch_job_id),
	-- cross schema constraint
	CONSTRAINT chk_geotag_batch_trigger CHECK (source IN (0,1,2,3))
);
CREATE TABLE chain.geotag_batch_company_queue(
	app_sid 			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	geotag_batch_id		NUMBER(10, 0) NOT NULL,
	company_sid			NUMBER(10, 0) NOT NULL,
	processed_dtm		DATE,
	longitude			NUMBER,
	latitude			NUMBER,
	CONSTRAINT pk_geotag_batch_company_queue PRIMARY KEY (app_sid, geotag_batch_id, company_sid),
	CONSTRAINT fk_geotag_batch_company FOREIGN KEY (app_sid, company_sid) REFERENCES chain.company (app_sid, company_sid),
	CONSTRAINT fk_geotag_batch FOREIGN KEY (app_sid, geotag_batch_id) REFERENCES chain.geotag_batch (app_sid, geotag_batch_id)
);
CREATE INDEX chain.ix_geotag_batch_batch_job_id ON chain.geotag_batch (app_sid, batch_job_id);
CREATE INDEX chain.ix_geotag_batch_queue_comp ON chain.geotag_batch_company_queue (app_sid, company_sid);
CREATE INDEX chain.ix_geotag_batch_queue_batch ON chain.geotag_batch_company_queue (app_sid, geotag_batch_id);
CREATE TABLE csr.tpl_report_variant(
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	master_template_sid				NUMBER(10, 0)	NOT NULL,
	language_code					VARCHAR2(10)	NOT NULL,
	filename						VARCHAR2(256)	NOT NULL,
	word_doc						BLOB			NOT NULL,
	CONSTRAINT pk_tpl_report_variant PRIMARY KEY (app_sid, master_template_sid, language_code)
)
;
ALTER TABLE csr.tpl_report_variant ADD CONSTRAINT fk_tpl_rep_variant_tpl_rep
	FOREIGN KEY (app_sid, master_template_sid)
	REFERENCES csr.tpl_report(app_sid, tpl_report_sid) ON DELETE CASCADE
;
ALTER TABLE csr.tpl_report_variant ADD CONSTRAINT fk_tpl_rep_variant_lang
	FOREIGN KEY (language_code)
	REFERENCES aspen2.lang(lang)
;
CREATE INDEX csr.ix_tpl_report_va_language_code ON csr.tpl_report_variant(language_code);
CREATE TABLE csrimp.tpl_report_variant(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	master_template_sid				NUMBER(10, 0)	NOT NULL,
	language_code					VARCHAR2(10)	NOT NULL,
	filename						VARCHAR2(256)	NOT NULL,
	word_doc						BLOB			NOT NULL,
	CONSTRAINT pk_tpl_report_variant PRIMARY KEY (csrimp_session_id, master_template_sid, language_code),
	CONSTRAINT fk_tpl_report_variant_is FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session(csrimp_session_id) ON DELETE CASCADE
)
;
CREATE TABLE CSR.OSHA_CONFIG(
	APP_SID					NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CMS_TAB_SID				NUMBER(10,0),
	DATE_CMS_COL_SID		NUMBER(10,0),
	REGION_CMS_COL_SID		NUMBER(10,0),
CONSTRAINT PK_OSHA_CONFIG PRIMARY KEY (APP_SID)
)
;
CREATE TABLE CSRIMP.OSHA_CONFIG(
	CSRIMP_SESSION_ID		NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CMS_TAB_SID				NUMBER(10,0),
	DATE_CMS_COL_SID		NUMBER(10,0),
	REGION_CMS_COL_SID		NUMBER(10,0),
	CONSTRAINT PK_OSHA_CONFIG PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_OSHA_CONFIG FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;
DROP TABLE CSRIMP.OSHA_MAPPING;
CREATE TABLE CSRIMP.OSHA_MAPPING(
	CSRIMP_SESSION_ID		NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OSHA_BASE_DATA_ID		NUMBER(10,0)	NOT NULL,
	IND_SID					NUMBER(10,0),
	CMS_COL_SID				NUMBER(10,0),
	REGION_DATA_MAP_ID		NUMBER(10,0),
	CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, OSHA_BASE_DATA_ID),
	CONSTRAINT FK_OSHA_MAPPING FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;
CREATE TABLE CSR.REGION_DATA_MAP(
	REGION_DATA_MAP_ID				NUMBER(10,0)	NOT NULL,
	DATA_ELEMENT					VARCHAR2(50)	NOT NULL,
	DESCRIPTION						VARCHAR2(4000)	NOT NULL,
	IS_PROPERTY						NUMBER(1)		DEFAULT 0 NOT NULL,
	IS_METER						NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_REGION_DATA_MAP 	PRIMARY KEY (REGION_DATA_MAP_ID)
)
;


DROP TRIGGER csr.batch_job_notify_trigger;
DROP MATERIALIZED VIEW LOG ON CSR.BATCH_JOB_NOTIFY;
DROP MATERIALIZED VIEW CSR.V$BATCH_JOB_NOTIFY;
DROP TABLE CSR.BATCH_JOB_NOTIFY;
ALTER TABLE chain.customer_options ADD company_geotag_enabled NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_company_geotag_enabled CHECK (company_geotag_enabled IN (1,0));
ALTER TABLE csrimp.chain_customer_options ADD company_geotag_enabled NUMBER(1,0) NOT NULL;
/*
ALTER TABLE chain.saved_filter DROP CONSTRAINT chk_hide_empty;
ALTER TABLE chain.saved_filter DROP COLUMN hide_empty;
ALTER TABLE csrimp.chain_saved_filter DROP COLUMN hide_empty;
*/
ALTER TABLE chain.saved_filter ADD (
	HIDE_EMPTY NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_HIDE_EMPTY CHECK (HIDE_EMPTY IN (0, 1))
);
ALTER TABLE csrimp.chain_saved_filter ADD (
	HIDE_EMPTY NUMBER(1,0) NULL
);
UPDATE csrimp.chain_saved_filter SET hide_empty = 0;
ALTER TABLE csrimp.chain_saved_filter MODIFY (hide_empty NUMBER(1,0) NOT NULL);
ALTER TABLE CSR.OSHA_MAPPING ADD(
	REGION_DATA_MAP_ID 				NUMBER(10,0)
);
ALTER TABLE CSR.OSHA_MAPPING ADD CONSTRAINT FK_OSHA_MAP_REGION_DATA
    FOREIGN KEY (REGION_DATA_MAP_ID)
    REFERENCES CSR.REGION_DATA_MAP(REGION_DATA_MAP_ID)
;
CREATE INDEX CSR.IX_OSHA_MAPPING_REGION_DATA ON CSR.OSHA_MAPPING(REGION_DATA_MAP_ID);


GRANT INSERT ON csr.tpl_report_variant TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.tpl_report_variant TO tool_user;


BEGIN
	UPDATE csr.portlet
	   SET name = 'Rainforest Alliance To Do List'
	 WHERE type = 'Credit360.Portlets.Chain.ToDoList';
END;
/
BEGIN
	INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15888, 'Fugitive Gas - R-436a', 1, 0, 11158);
	INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15889, 'Fugitive Gas - R-452a', 1, 0, 11158);
END;
/
BEGIN
	INSERT INTO cms.col_type (col_type, description) VALUES (43, 'Latitude');
	INSERT INTO cms.col_type (col_type, description) VALUES (44, 'Longitude');
	INSERT INTO cms.col_type (col_type, description) VALUES (45, 'Altitude');
	INSERT INTO cms.col_type (col_type, description) VALUES (46, 'Horizontal accuracy');
	INSERT INTO cms.col_type (col_type, description) VALUES (47, 'Vertical accuracy');
END;
/
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (1, 'SID', 'Region id', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (2, 'DESC', 'Region description', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (3, 'REF', 'Region reference', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (4, 'GEO_CITY', 'Region City', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (5, 'GEO_ST_CODE', 'Region State Code', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (6, 'GEO_ST_DESC', 'Region State', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (7, 'GEO_COUNTRY_DESC', 'Region Country', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (8, 'GEO_COUNTRY_CODE', 'Region Country Code', 0, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (9, 'MGNT_COMPANY', 'Management company', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (10, 'FUND', 'Fund', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (11, 'PROP_TYPE', 'Property type', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (12, 'PROP_SUB_TYPE', 'Property sub type', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (13, 'PROP_ADDR1', 'Property Address 1', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (14, 'PROP_ADDR2', 'Property Address 2', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (15, 'PROP_CITY', 'Property city', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (16, 'PROP_STATE', 'Property state', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (17, 'PROP_ZIP', 'Property zip', 1, 0);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (18, 'MET_NUM', 'Meter number', 0, 1);
INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (19, 'MET_TYPE', 'Meter type', 0, 1);






@..\batch_job_pkg
@..\chain\chain_pkg
@..\chain\helper_pkg
@..\chain\company_pkg
@..\chain\filter_pkg
@..\templated_report_pkg
@..\schema_pkg
@..\delegation_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\integration_api_pkg
@..\osha_pkg
@..\region_pkg


@..\batch_job_body
@..\csr_app_body
@..\chain\filter_body
@..\..\..\aspen2\cms\db\filter_body
@..\util_script_body
@..\schema_body
@..\chain\helper_body
@..\chain\company_body
@..\csrimp\imp_body
@..\quick_survey_report_body
@..\templated_report_body
@..\delegation_body
@..\sheet_body
@..\..\..\aspen2\cms\db\tab_body
@..\integration_api_body
@..\enable_body
@..\osha_body
@..\region_body



@update_tail
