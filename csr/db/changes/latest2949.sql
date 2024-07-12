define version=2949
define minor_version=0
define is_combined=1
@update_header

begin
	for r in (select * from all_constraints where owner = 'CSRIMP' and r_owner='CSRIMP' and r_constraint_name!='PK_CSRIMP_SESSION') loop
		execute immediate 'alter table csrimp.'||r.table_name||' drop constraint '||r.constraint_name;
	end loop;
end;
/

-- clean out junk in csrimp
begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

-- Shouldn't exist on live, but does
begin
	for r in (select 1 from all_tables where owner='CSRIMP' and table_name='GEO_MAP') loop
		execute immediate 'DROP TABLE CSRIMP.GEO_MAP';
	end loop;
end;
/

CREATE TABLE CSRIMP.GEO_MAP(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    GEO_MAP_SID             	    NUMBER(10, 0)    NOT NULL,
    LABEL                   	    VARCHAR2(255)    NOT NULL,
    REGION_SELECTION_TYPE_ID	    NUMBER(10, 0)    NOT NULL,
    INCLUDE_INACTIVE_REGIONS	    NUMBER(1, 0)     NOT NULL,
    START_DTM               	    DATE             NOT NULL,
    END_DTM                 	    DATE,
    INTERVAL                	    VARCHAR2(10)     NOT NULL,
	TAG_ID                          NUMBER(10),
    CONSTRAINT CHK_GEO_MAP_INCL_INACT CHECK (INCLUDE_INACTIVE_REGIONS IN (0,1)),
    CONSTRAINT CHK_GEO_MAP_INTERVAL CHECK (INTERVAL IN ('m','q','h','y')),
    CONSTRAINT PK_GEO_MAP PRIMARY KEY (CSRIMP_SESSION_ID, GEO_MAP_SID),
    CONSTRAINT FK_GEO_MAP
		FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) 
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.GEO_MAP_REGION(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    GEO_MAP_SID						NUMBER(10, 0)    NOT NULL,
    REGION_SID     					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GEO_MAP_REGION PRIMARY KEY (CSRIMP_SESSION_ID, GEO_MAP_SID, REGION_SID),
    CONSTRAINT FK_GEO_MAP_REGION 
		FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) 
		ON DELETE CASCADE
);
CREATE SEQUENCE CHAIN.DEDUPE_PROCESSED_RECORD_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE SEQUENCE CHAIN.DEDUPE_MATCH_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE CHAIN.DEDUPE_MATCH_TYPE(
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0) NOT NULL,
	LABEL						VARCHAR(32) NOT NULL,
	CONSTRAINT PK_DEDUPE_MATCH_TYPE PRIMARY KEY (DEDUPE_MATCH_TYPE_ID),
	CONSTRAINT UC_DEDUPE_MATCH_TYPE UNIQUE (LABEL)
);
CREATE TABLE CHAIN.DEDUPE_PROCESSED_RECORD(
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	IMPORT_SOURCE_ID			NUMBER(10, 0) NOT NULL,
	COMPANY_REF					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	PROCESSED_DTM				DATE DEFAULT SYSDATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	CONSTRAINT PK_DEDUPE_PROCESSED_RECORD PRIMARY KEY (APP_SID, DEDUPE_PROCESSED_RECORD_ID),
	CONSTRAINT UC_DEDUPE_PROCESSED_RECORD UNIQUE (APP_SID, IMPORT_SOURCE_ID, COMPANY_REF, ITERATION_NUM)
);
CREATE TABLE CHAIN.DEDUPE_MATCH(
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_MATCH_ID				NUMBER(10, 0) NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0) NOT NULL,
	DEDUPE_RULE_ID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_DEDUPE_MATCH PRIMARY KEY (APP_SID, DEDUPE_MATCH_ID),
	CONSTRAINT UC_DEDUPE_MATCH UNIQUE (APP_SID, DEDUPE_PROCESSED_RECORD_ID, MATCHED_TO_COMPANY_SID)
);
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW(
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	IMPORT_SOURCE_ID			NUMBER(10, 0) NOT NULL,
	COMPANY_REF					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	PROCESSED_DTM				DATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	MATCHED_TO_COMPANY_NAME		VARCHAR(512),
	IMPORT_SOURCE_NAME			VARCHAR(512) NOT NULL
) 
ON COMMIT DELETE ROWS; 
CREATE TABLE CSRIMP.CHAIN_DEDUP_PROCE_RECORD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID NUMBER(10,0) NOT NULL,
	COMPANY_REF VARCHAR2(512) NOT NULL,
	DEDUPE_MATCH_TYPE_ID NUMBER(10,0),
	IMPORT_SOURCE_ID NUMBER(10,0) NOT NULL,
	ITERATION_NUM NUMBER(10,0) NOT NULL,
	MATCHED_BY_USER_SID NUMBER(10,0),
	MATCHED_DTM DATE,
	MATCHED_TO_COMPANY_SID NUMBER(10,0),
	PROCESSED_DTM DATE NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUP_PROCE_RECORD PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_PROCESSED_RECORD_ID),
	CONSTRAINT FK_CHAIN_DEDUP_PROCE_RECORD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_MATCH (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_MATCH_ID NUMBER(10,0) NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID NUMBER(10,0) NOT NULL,
	DEDUPE_RULE_ID NUMBER(10,0) NOT NULL,
	MATCHED_TO_COMPANY_SID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_MATCH PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_MATCH_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_MATCH_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_PROC_RECO (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_PROCESSED_RECORD_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_PROCESSED_RECORD_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_PROC_RECO PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_PROCESSED_RECORD_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_PROC_RECO UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_PROCESSED_RECORD_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_PROC_RECO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_MATCH (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MATCH_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MATCH_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_MATCH PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MATCH_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_MATCH UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MATCH_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_MATCH_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.aggregation_period(
	app_sid					NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	aggregation_period_id	NUMBER(10)		NOT NULL,
	label					VARCHAR2(100) 	NOT NULL,
	no_of_months			NUMBER(2)		NOT NULL,
	CONSTRAINT PK_AGGREGATION_PERIOD PRIMARY KEY (app_sid, aggregation_period_id)
);
CREATE TABLE csrimp.aggregation_period (
	csrimp_session_id		NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	aggregation_period_id	NUMBER(10)		NOT NULL,
	label					VARCHAR2(100) 	NOT NULL,
	no_of_months			NUMBER(2)		NOT NULL,
	CONSTRAINT pk_aggregation_period PRIMARY KEY (csrimp_session_id, aggregation_period_id)
);
CREATE TABLE CHEM.CHEM_OPTIONS (
	APP_SID						NUMBER(10, 0)	DEFAULT sys_context('SECURITY', 'APP') NOT NULL,
	CHEM_HELPER_PKG				VARCHAR(255),
	CONSTRAINT PK_CHEM_OPTIONS PRIMARY KEY (APP_SID)
);
CREATE TABLE CSRIMP.CHEM_CHEM_OPTIONS (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CHEM_HELPER_PKG				VARCHAR(255),
	CONSTRAINT PK_CHEM_OPTIONS PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_CHEM_CHEM_OPTIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHEM_CAS (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CAS_CODE VARCHAR2(50)		NOT NULL,
	NAME VARCHAR2(4000)			NOT NULL,
	UNCONFIRMED NUMBER(1)		NOT NULL,
	IS_VOC NUMBER(1)			NOT NULL,
	CATEGORY VARCHAR2(20),
	CONSTRAINT PK_CAS PRIMARY KEY (CSRIMP_SESSION_ID, CAS_CODE),
	CONSTRAINT FK_CHEM_CAS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE OR REPLACE TYPE CHEM.T_CAS_COMP_ROW AS
	OBJECT (
		CAS_CODE				VARCHAR2(50),
		PCT_COMPOSITION 		NUMBER(5,4) 
	);
/
CREATE OR REPLACE TYPE CHEM.T_CAS_COMP_TABLE AS
	TABLE OF CHEM.T_CAS_COMP_ROW;
/
DROP TABLE chem.waiver;


alter table cms.tab_column add format_mask varchar2(200);
alter table csrimp.cms_tab_column add format_mask varchar2(200);
ALTER TABLE CSR.EST_METER ADD (
	INACTIVE_DTM		DATE,
	FIRST_BILL_DTM		DATE
);

ALTER TABLE csr.urjanet_service_type DROP CONSTRAINT PK_URJANET_SERVICE_TYPE DROP INDEX;
ALTER TABLE csr.urjanet_service_type ADD (
	raw_data_source_id NUMBER(10) DEFAULT 0
);

ALTER TABLE csr.urjanet_service_type ADD 
	CONSTRAINT PK_URJANET_SERVICE_TYPE PRIMARY KEY (app_sid, service_type, raw_data_source_id)
;

BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT app_sid, MAX(raw_data_source_id) raw_data_source_id
		  FROM csr.meter_raw_data_source
		 WHERE raw_data_source_type_id = 3 -- urjanet
		 GROUP BY app_sid
	) LOOP	
		UPDATE csr.urjanet_service_type 
		   SET raw_data_source_id = r.raw_data_source_id
		 WHERE raw_data_source_id = 0
		   AND app_sid = r.app_sid;
	END LOOP;
END;
/

ALTER TABLE csr.urjanet_service_type MODIFY raw_data_source_id NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csr.urjanet_service_type ADD CONSTRAINT srv_type_raw_data_src_id FOREIGN KEY (app_sid, raw_data_source_id) REFERENCES csr.meter_raw_data_source(app_sid, raw_data_source_id);
ALTER TABLE csr.meter_raw_data_source
   ADD (
		create_meters NUMBER(1),
		automated_import_class_sid NUMBER(10,0),
		holding_region_sid NUMBER(10,0)
	);
	
ALTER TABLE csrimp.meter_raw_data_source
   ADD (
		create_meters NUMBER(1),
		automated_import_class_sid NUMBER(10,0),
		holding_region_sid NUMBER(10,0)
	);
UPDATE csr.meter_raw_data_source
   SET create_meters = 0
 WHERE create_meters IS NULL;
   
ALTER TABLE csr.meter_raw_data_source MODIFY create_meters NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.meter_raw_data_source ADD CONSTRAINT raw_data_auto_imp FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid);
ALTER TABLE csr.meter_excel_mapping ADD (create_meters_map_column VARCHAR2(255));
ALTER TABLE csrimp.meter_excel_mapping ADD (create_meters_map_column VARCHAR2(255));
ALTER TABLE csr.meter_raw_data_source ADD meter_date_format VARCHAR2(255);
ALTER TABLE csrimp.meter_raw_data_source ADD meter_date_format VARCHAR2(255);
ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_COMPANY
	FOREIGN KEY (APP_SID, MATCHED_TO_COMPANY_SID)
	REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;
ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_SOURCE
	FOREIGN KEY (APP_SID, IMPORT_SOURCE_ID)
	REFERENCES CHAIN.IMPORT_SOURCE(APP_SID, IMPORT_SOURCE_ID)
;
ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_MATCH
	FOREIGN KEY (DEDUPE_MATCH_TYPE_ID)
	REFERENCES CHAIN.DEDUPE_MATCH_TYPE(DEDUPE_MATCH_TYPE_ID)
;
ALTER TABLE CHAIN.DEDUPE_MATCH ADD CONSTRAINT FK_DEDUPE_MATCH_PROC_REC
	FOREIGN KEY (APP_SID, DEDUPE_PROCESSED_RECORD_ID)
	REFERENCES CHAIN.DEDUPE_PROCESSED_RECORD(APP_SID, DEDUPE_PROCESSED_RECORD_ID)
;
ALTER TABLE CHAIN.DEDUPE_MATCH ADD CONSTRAINT FK_DEDUPE_MATCH_COMPANY
	FOREIGN KEY (APP_SID, MATCHED_TO_COMPANY_SID)
	REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;
ALTER TABLE CHAIN.DEDUPE_MATCH ADD CONSTRAINT FK_DEDUPE_MATCH_RULE
	FOREIGN KEY (APP_SID, DEDUPE_RULE_ID)
	REFERENCES CHAIN.DEDUPE_RULE(APP_SID, DEDUPE_RULE_ID)
;
ALTER TABLE chain.dedupe_mapping ADD REFERENCE_ID NUMBER(10);
ALTER TABLE chain.dedupe_mapping ADD TAG_GROUP_ID NUMBER(10);
ALTER TABLE chain.import_source ADD LOOKUP_KEY VARCHAR2(32);
ALTER TABLE chain.dedupe_field RENAME COLUMN ORACLE_TABLE TO ENTITY;
ALTER TABLE chain.dedupe_field RENAME COLUMN ORACLE_COLUMN TO FIELD;
BEGIN
	security.user_pkg.logonadmin;
	
	UPDATE chain.dedupe_mapping dm
	   SET reference_id = (
			SELECT reference_id
			   FROM chain.reference r
			  WHERE dm.reference_lookup = r.lookup_key
	);
	
	UPDATE chain.import_source
	   SET lookup_key = SUBSTR(name, 0, 28) || import_source_id;
END;
/
ALTER TABLE chain.import_source MODIFY LOOKUP_KEY NOT NULL;
ALTER TABLE chain.import_source ADD CONSTRAINT UC_IMPORT_SOURCE_LOOKUP UNIQUE (APP_SID, LOOKUP_KEY);
ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT chk_dedupe_field_or_ref;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_dedupe_field_or_ref_or_tag 
	CHECK ((dedupe_field_id IS NOT NULL AND reference_id IS NULL AND tag_group_id IS NULL) 
		OR (dedupe_field_id IS NULL AND reference_id IS NOT NULL AND tag_group_id IS NULL)
		OR (dedupe_field_id IS NULL AND reference_id IS NULL AND tag_group_id IS NOT NULL));
	
ALTER TABLE chain.dedupe_mapping DROP COLUMN REFERENCE_LOOKUP;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_MAPPING_REFERENCE
	FOREIGN KEY (app_sid, reference_id)
	REFERENCES chain.reference (app_sid, reference_id);
	
ALTER TABLE csrimp.chain_import_source ADD LOOKUP_KEY VARCHAR2(32);
ALTER TABLE csrimp.chain_dedupe_mapping ADD TAG_GROUP_ID NUMBER (10);
ALTER TABLE csrimp.chain_dedupe_mapping ADD REFERENCE_ID NUMBER (10);
ALTER TABLE csrimp.chain_dedupe_mapping DROP COLUMN REFERENCE_LOOKUP;
CREATE OR REPLACE TYPE CHAIN.T_DATES IS TABLE OF DATE;
/
ALTER TABLE csr.customer
  ADD show_aggregate_override NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.dataview
  ADD aggregation_period_id NUMBER(10);
ALTER TABLE csr.dataview_history
  ADD aggregation_period_id NUMBER(10);
ALTER TABLE csrimp.customer
  ADD show_aggregate_override NUMBER(1) NOT NULL;
ALTER TABLE csrimp.dataview
  ADD aggregation_period_id NUMBER(10);
ALTER TABLE csrimp.dataview_history
  ADD aggregation_period_id NUMBER(10);
  
ALTER TABLE csr.aggregation_period
  ADD CONSTRAINT fk_aggregation_period_customer FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid);
ALTER TABLE csrimp.aggregation_period
  ADD CONSTRAINT fk_aggregation_period_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
  
ALTER TABLE csr.dataview
  ADD CONSTRAINT fk_dataview_aggregation_period FOREIGN KEY (app_sid, aggregation_period_id) REFERENCES csr.aggregation_period (app_sid, aggregation_period_id);
ALTER TABLE CSR.TPL_REPORT_SCHEDULE
ADD scenario_run_sid NUMBER(10);
ALTER TABLE CSR.TPL_REPORT_SCHEDULE ADD CONSTRAINT FK_TPL_REP_SCHED_SCEN_RUN 
    FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
    REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID);
ALTER TABLE CSR.EST_OPTIONS ADD (
	TRASH_WHEN_SHARING		NUMBER(1)	DEFAULT 0 NOT NULL,
	TRASH_WHEN_POLLING		NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT CK_TRASH_WHEN_SHARING CHECK (TRASH_WHEN_SHARING IN (0, 1)),
	CONSTRAINT CK_TRASH_WHEN_POLLING CHECK (TRASH_WHEN_POLLING IN (0, 1))
);
ALTER TABLE chem.cas
ADD app_sid NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NULL;
ALTER TABLE chem.cas_restricted 
DROP CONSTRAINT fk_cas_cas_restr;
ALTER TABLE chem.substance_cas
DROP CONSTRAINT fk_cas_subst_cas;
ALTER TABLE chem.cas_group_member
DROP CONSTRAINT fk_cas_cas_grp_mbr;
ALTER TABLE chem.cas
DROP CONSTRAINT pk_cas DROP INDEX;
BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chem.substance_cas
		 UNION
		SELECT DISTINCT app_sid
		  FROM chem.cas_restricted	
		 UNION
		SELECT DISTINCT app_sid		  
		  FROM chem.cas_group_member		  
	)
	LOOP
		INSERT INTO chem.cas (app_sid, cas_code, name, unconfirmed, is_voc, category)
		     SELECT r.app_sid, cas_code, name, unconfirmed, is_voc, category
			   FROM chem.cas 
			  WHERE app_sid IS NULL;
	END LOOP;
	
	DELETE
	  FROM chem.cas
	 WHERE app_sid IS NULL;
	
END;
/
ALTER TABLE chem.cas
     MODIFY app_sid NOT NULL;
ALTER TABLE chem.cas
ADD CONSTRAINT pk_cas PRIMARY KEY (app_sid, cas_code);
ALTER TABLE chem.cas_restricted ADD CONSTRAINT fk_cas_cas_restr 
    FOREIGN KEY (app_sid, cas_code) REFERENCES chem.cas (app_sid, cas_code);
	
ALTER TABLE chem.substance_cas ADD CONSTRAINT fk_cas_subst_cas 
    FOREIGN KEY (app_sid, cas_code) REFERENCES chem.cas (app_sid, cas_code);
ALTER TABLE chem.cas_group_member ADD CONSTRAINT fk_cas_cas_grp_mbr 
    FOREIGN KEY (app_sid, cas_code) REFERENCES CHEM.CAS (app_sid, cas_code);	
alter table csrimp.delegation add (
	TAG_VISIBILITY_MATRIX_GROUP_ID	NUMBER(10),
	ALLOW_MULTI_PERIOD		 		NUMBER(1)		   NOT NULL
);
ALTER TABLE csr.like_for_like_slot
  DROP COLUMN is_locked;
ALTER TABLE csrimp.like_for_like_slot
  DROP COLUMN is_locked;
CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE AS 
 OBJECT ( 
	LIKE_FOR_LIKE_SID			NUMBER(10),
	NAME						VARCHAR2(255),
	IND_SID						NUMBER(10),
	REGION_SID					NUMBER(10),
	INCLUDE_INACTIVE_REGIONS	NUMBER(1),
	PERIOD_START_DTM			DATE,
	PERIOD_END_DTM				DATE,
	PERIOD_SET_ID				NUMBER(10),
	PERIOD_INTERVAL_ID			NUMBER(10),
	RULE_TYPE					NUMBER(1),
	SCENARIO_RUN_SID			NUMBER(10),
	CREATED_BY_USER_SID			NUMBER(10),
	CREATED_DTM					DATE,
	LAST_REFRESH_USER_SID		NUMBER(10),
	LAST_REFRESH_DTM			DATE,
	CONSTRUCTOR FUNCTION T_LIKE_FOR_LIKE(SID NUMBER)
		RETURN SELF AS RESULT
	);
/
CREATE OR REPLACE TYPE BODY CSR.T_LIKE_FOR_LIKE AS
	CONSTRUCTOR FUNCTION T_LIKE_FOR_LIKE(SID NUMBER)
	RETURN SELF AS RESULT
AS
	BEGIN
		SELECT LIKE_FOR_LIKE_SID, NAME, IND_SID, REGION_SID, INCLUDE_INACTIVE_REGIONS,
			PERIOD_START_DTM, PERIOD_END_DTM, PERIOD_SET_ID, PERIOD_INTERVAL_ID,
			RULE_TYPE, SCENARIO_RUN_SID, CREATED_BY_USER_SID, CREATED_DTM,
			LAST_REFRESH_DTM
		  INTO SELF.LIKE_FOR_LIKE_SID, SELF.NAME, SELF.IND_SID, SELF.REGION_SID,
			SELF.INCLUDE_INACTIVE_REGIONS, SELF.PERIOD_START_DTM, SELF.PERIOD_END_DTM,
			SELF.PERIOD_SET_ID, SELF.PERIOD_INTERVAL_ID, SELF.RULE_TYPE, SELF.SCENARIO_RUN_SID,
			SELF.CREATED_BY_USER_SID, SELF.CREATED_DTM, SELF.LAST_REFRESH_DTM
		  FROM CSR.LIKE_FOR_LIKE_SLOT
		 WHERE LIKE_FOR_LIKE_SID = SID;
		 RETURN;
	END;
END;
/

DROP TYPE CSR.T_LIKE_FOR_LIKE_VAL_TABLE;

CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_ROW AS 
	OBJECT (
	IND_SID				NUMBER(10),
	REGION_SID			NUMBER(10),
	PERIOD_START_DTM	DATE,
	PERIOD_END_DTM		DATE,
	VAL_NUMBER			NUMBER(24,10),
	SOURCE_TYPE_ID		NUMBER(10),
	SOURCE_ID			NUMBER(20)
	);
/

CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_TABLE AS 
	TABLE OF CSR.T_LIKE_FOR_LIKE_VAL_ROW;
/

grant select, insert, update on csr.geo_map to csrimp;
grant select, insert, update on csr.geo_map_region to csrimp;
grant select, insert, update, delete on csrimp.geo_map to web_user;
grant select, insert, update, delete on csrimp.geo_map_region to web_user;
grant SELECT on cms.item_id_seq to chain;
grant EXECUTE on cms.tab_pkg to chain;
GRANT EXECUTE ON csr.unit_test_pkg TO chain;
GRANT EXECUTE ON csr.T_VARCHAR2_TABLE TO chain;
GRANT EXECUTE ON csr.tag_pkg TO chain;
grant select, insert, update, delete on csrimp.chain_dedup_proce_record to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_match to web_user;
grant select, insert, update on chain.dedupe_processed_record to csrimp;
grant select, insert, update on chain.dedupe_match to csrimp;
grant select on chain.dedupe_processed_record_id_seq to csrimp;
grant select on chain.dedupe_processed_record_id_seq to CSR;
grant select on chain.dedupe_match_id_seq to csrimp;
grant select on chain.dedupe_match_id_seq to CSR;
grant select, insert, update on chain.dedupe_processed_record to CSR;
grant select, insert, update on chain.dedupe_match to CSR;
grant select on chain.dedupe_processed_record_id_seq to CSR;
grant select on chain.dedupe_match_id_seq to CSR;
GRANT SELECT, INSERT, UPDATE ON csr.aggregation_period TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.aggregation_period TO web_user;
grant select, insert, update, delete on csrimp.lookup_table to web_user;
grant select, insert, update, delete on csrimp.lookup_table_entry to web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chem.cas TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chem_cas TO web_user;
GRANT SELECT, INSERT, UPDATE ON chem.cas TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON chem.chem_options TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chem_chem_options TO web_user;
GRANT SELECT, INSERT, UPDATE ON chem.chem_options TO csrimp;


ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_USER
	FOREIGN KEY (APP_SID, MATCHED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_MAPPING_TAG_GROUP
	FOREIGN KEY (app_sid, tag_group_id)
	REFERENCES csr.tag_group (app_sid, tag_group_id)
;


CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description, 
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,		
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
		ms.realtime_metering, ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;
CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.password, g.base_url,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;
CREATE OR REPLACE VIEW chain.v$qnr_security_scheme_summary
AS
	SELECT NVL(p.security_scheme_id, s.security_scheme_id) security_scheme_id, 
       NVL(p.action_security_type_id, s.action_security_type_id) action_security_type_id,
       CASE WHEN p.company_function_id > 0 THEN 1 ELSE 0 END has_procurer_config, 
       CASE WHEN s.company_function_id > 0 THEN 1 ELSE 0 END has_supplier_config
	  FROM (
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 1
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) p
	 FULL JOIN (           
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 2
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) s
	   ON p.security_scheme_id = s.security_scheme_id AND p.action_security_type_id = s.action_security_type_id;

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT nc.non_compliance_id, NVL(ias.survey_sid, qsr.survey_sid) survey_sid, NVL(ias.survey_response_id, qsr.survey_response_id) survey_response_id
		  FROM csr.non_compliance nc
		  JOIN csr.internal_audit ia ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
		  JOIN csr.quick_survey_question qsq ON qsq.question_id = nc.question_id AND qsq.app_sid = nc.app_sid
		  LEFT JOIN csr.quick_survey_response qsr ON (ia.survey_response_id = qsr.survey_response_id OR ia.summary_response_id = qsr.survey_response_id) AND qsr.survey_sid = qsq.survey_sid AND qsr.app_sid = ia.app_sid
	      LEFT JOIN csr.internal_audit_survey ias ON ias.internal_audit_sid = nc.created_in_audit_sid AND qsq.survey_sid = ias.survey_sid AND ias.app_sid = nc.app_sid
	     WHERE ia.deleted = 0
	       AND NVL(ias.survey_response_id, qsr.survey_response_id) IS NOT NULL
	       AND NVL(ias.survey_sid, qsr.survey_sid) IS NOT NULL
	     GROUP BY non_compliance_id, NVL(ias.survey_sid, qsr.survey_sid), NVL(ias.survey_response_id, qsr.survey_response_id)
	     ORDER BY non_compliance_id
	) LOOP
		UPDATE csr.non_compliance
		   SET survey_response_id = r.survey_response_id
		 WHERE non_compliance_id = r.non_compliance_id;
	END LOOP;
END;
/
DECLARE
	v_response_ids		security.T_SID_TABLE;
BEGIN
	
	FOR r IN (
		SELECT host, app_sid FROM csr.customer WHERE app_sid IN (
		    SELECT DISTINCT app_sid FROM (
				SELECT qsr.app_sid, qsr.survey_version old_survey_version,
					   MAX(qsv.survey_version) new_survey_version
				  FROM csr.quick_survey_response qsr
				  JOIN csr.quick_survey_version qsv
					ON qsr.app_sid = qsv.app_sid 
				   AND qsr.survey_sid = qsv.survey_sid
				   AND qsr.created_dtm > qsv.published_dtm
				 WHERE qsr.question_xml_override IS NOT NULL
				 GROUP BY qsr.app_sid, qsr.survey_response_id, qsr.survey_version
			  ) p
			 WHERE p.old_survey_version > p.new_survey_version
		)
	) LOOP
		security.user_pkg.logonadmin(r.host);	
		
		SELECT survey_response_id
		  BULK COLLECT INTO v_response_ids
		  FROM (
			SELECT qsr.survey_response_id, qsr.survey_version old_survey_version,
				   MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			   AND qsr.survey_sid = qsv.survey_sid
			   AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.question_xml_override IS NOT NULL
			 GROUP BY qsr.survey_response_id, qsr.survey_version
		  ) p
		 WHERE p.old_survey_version > p.new_survey_version;
		 
		UPDATE csr.quick_survey_response u
		  SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
		  
		UPDATE csr.quick_survey_submission u
			SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE submission_id = 0
			AND u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
		  
		UPDATE csr.quick_survey_answer u
			SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE submission_id = 0
			AND u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
		  
		  UPDATE csr.qs_submission_file u
			SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE submission_id = 0
			AND u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/
CREATE OR REPLACE PROCEDURE csr.temp_EnablePortletForCustomer(
	in_portlet_id	IN portlet.portlet_id%TYPE
)
AS
	v_customer_portlet_sid		security_pkg.T_SID_ID;
	v_type						portlet.type%TYPE;
BEGIN
	-- allow fiddling with portlets only for people with permissions on Capabilities/System management
--	IF NOT csr_data_pkg.CheckCapability('System management') THEN
--		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "System management" capability');
--	END IF;
	
	SELECT type
	  INTO v_type
	  FROM portlet
	 WHERE portlet_id = in_portlet_id;
	
	BEGIN
		v_customer_portlet_sid := securableobject_pkg.GetSIDFromPath(
				SYS_CONTEXT('SECURITY','ACT'),
				SYS_CONTEXT('SECURITY','APP'),
				'Portlets/' || v_type);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
				securableobject_pkg.GetSIDFromPath(
					SYS_CONTEXT('SECURITY','ACT'),
					SYS_CONTEXT('SECURITY','APP'),
					'Portlets'),
				security.class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
	END;
	BEGIN
		INSERT INTO customer_portlet
				(portlet_id, customer_portlet_sid, app_sid)
		VALUES
				(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
				NULL;
	END;
END;
/
BEGIN
	FOR r IN (SELECT host FROM csr.customer WHERE property_flow_sid IS NOT NULL) 
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		-- Enable standalone geo-maps portlet
		csr.temp_EnablePortletForCustomer(1048);
	END LOOP;
	security.user_pkg.LogonAdmin(NULL);
END;
/
DROP PROCEDURE csr.temp_EnablePortletForCustomer;
BEGIN
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Metering.Plugins.MeterCharacteristics'
	 WHERE js_class = 'Credit360.Metering.MeterCharacteristicsTab';
END;
/
BEGIN
	-- Sync the est_meter table with the region's active state
	FOR r IN (
		SELECT r.app_sid, r.region_sid, r.active, r.disposal_dtm
		  FROM csr.region r
		  JOIN csr.est_meter m ON m.app_sid = r.app_sid AND m.region_sid = r.region_sid
		 WHERE r.active != m.active
		    OR (r.disposal_dtm IS NULL AND m.inactive_dtm IS NOT NULL)
		    OR (r.disposal_dtm IS NOT NULL AND m.inactive_dtm IS NULL)
		    OR r.disposal_dtm != m.inactive_dtm
	) LOOP
		UPDATE csr.est_meter
		   SET active = r.active,
		       inactive_dtm = DECODE(r.active, 1, NULL, r.disposal_dtm)
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid;
	END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE csr.tmp_SetSelfRegistrationPerms(
	in_setting						IN	NUMBER
)
IS
	v_app_sid				security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID;
	v_ind_root_sid			security.security_pkg.T_SID_ID;
	v_region_root_sid		security.security_pkg.T_SID_ID;
	v_usercreatordaemon_sid	security.security_pkg.T_SID_ID;
	
	v_ind_acl_id			security.security_pkg.T_SID_ID;
	v_region_acl_id			security.security_pkg.T_SID_ID;
	v_current_ind_perms		security.acl.permission_set%TYPE;
	v_current_region_perms	security.acl.permission_set%TYPE;
	v_current_ind_access	BOOLEAN;
	v_current_region_access	BOOLEAN;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getact;
	
	-- Add/remove UserCreatorDaemon write access from the Indicator and Region roots.
	v_ind_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Indicators');
	v_region_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Regions');
	BEGIN
		v_usercreatordaemon_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users/usercreatordaemon');
	EXCEPTION
		 WHEN security.security_pkg.OBJECT_NOT_FOUND THEN RETURN;
	END;
	v_ind_acl_id := security.acl_pkg.GetDACLIDForSID(v_ind_root_sid);
	v_region_acl_id := security.acl_pkg.GetDACLIDForSID(v_region_root_sid);
	
	v_current_ind_perms := 0;
	v_current_region_perms := 0;
	v_current_ind_access := FALSE;
	v_current_region_access := FALSE;
	
	BEGIN
		SELECT MAX(permission_set)
		  INTO v_current_ind_perms
		  FROM security.ACL
		 WHERE acl_id = v_ind_acl_id 
		   AND sid_id = v_usercreatordaemon_sid
		   AND ace_flags = security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;
	BEGIN
		SELECT MAX(permission_set)
		  INTO v_current_region_perms
		  FROM security.ACL
		 WHERE acl_id = v_region_acl_id 
		   AND sid_id = v_usercreatordaemon_sid
		   AND ace_flags = security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;
	IF v_current_ind_perms = security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE THEN
		v_current_ind_access := TRUE;
	END IF;
	   
	IF v_current_region_perms = security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE THEN
		v_current_region_access := TRUE;
	END IF;
	IF in_setting = 0 THEN
		IF v_current_ind_access = TRUE THEN
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ind_root_sid), v_usercreatordaemon_sid);
		END IF;
		IF v_current_region_access = TRUE THEN
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), v_usercreatordaemon_sid);
		END IF;
	ELSE
		IF v_current_ind_access = FALSE THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ind_root_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, 
				v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE);
		END IF;
		IF v_current_region_access = FALSE THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, 
				v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE);
		END IF;
	END IF;
END;
/
BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT host
		  FROM csr.customer
		 WHERE property_flow_sid is not null
	) 
	LOOP
		security.user_pkg.logonadmin(r.host);
		csr.tmp_SetSelfRegistrationPerms(1);
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
DROP PROCEDURE csr.tmp_SetSelfRegistrationPerms;
BEGIN
	INSERT INTO chain.dedupe_match_type (dedupe_match_type_id, label) VALUES (1, 'Auto');
	INSERT INTO chain.dedupe_match_type (dedupe_match_type_id, label) VALUES (2, 'Manual');
END;
/
begin
	begin
		INSERT INTO csr.std_measure (
			std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd
		) VALUES (
			40, 'm^2/kg', 'm^2/kg', 0, '#,##0', 'sum', NULL, 0, 2, -1, 0, 0, 0, 0, 0
		);
	exception
		when dup_val_on_index then
			null;
	end;
	begin			
		INSERT INTO csr.std_measure_conversion (
			std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
		) VALUES (
			28185, 40, 'm^3/(tonne.km)', 1000000, 1, 0, 1
		);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/
BEGIN
	FOR r IN (
		SELECT o.app_sid, a.strict_building_poll
		  FROM csr.est_options o
		  JOIN csr.est_account a ON a.est_account_sid = o.default_account_sid
	) LOOP
		UPDATE csr.est_options
		   SET trash_when_polling = r.strict_building_poll
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/
ALTER TABLE CSR.EST_ACCOUNT DROP COLUMN STRICT_BUILDING_POLL;
DELETE FROM chain.filter_value fv
 WHERE EXISTS (
	SELECT app_sid, filter_value_id 
	 FROM (
		SELECT app_sid, filter_value_id, 
			ROW_NUMBER() OVER 
				(PARTITION BY app_sid, filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid, user_sid, min_num_val, 
					max_num_val, compound_filter_id_value, saved_filter_sid_value, period_set_id, period_interval_id, start_period_id, filter_type, null_filter 
				ORDER BY app_sid, filter_value_id) rn
		  FROM chain.filter_value
	)
	 WHERE rn > 1 AND app_sid = fv.app_sid AND filter_value_id = fv.filter_value_id
);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (73, 'Like for like', 'EnableLikeforlike', 'Consult with DEV before enable this! Enables the like for like module.', 1);






@..\audit_pkg
@..\quick_survey_pkg
@..\property_pkg
@..\property_report_pkg
@..\schema_pkg
@..\meter_pkg
@..\space_pkg
@..\region_pkg
@..\energy_star_pkg
@..\meter_monitor_pkg
@..\chain\chain_pkg
@..\chain\helper_pkg
@..\chain\company_dedupe_pkg
@..\customer_pkg
@..\dataview_pkg
@..\templated_report_pkg
@..\templated_report_schedule_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\chem\substance_pkg
@..\like_for_like_pkg
@..\csrimp\imp_pkg
@..\enable_pkg


@..\audit_body
@..\quick_survey_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\tab_body
@..\property_body
@..\property_report_body
@..\region_body
@..\schema_body
@..\..\..\postcode\db\geo_region_body
@..\meter_body
@..\space_body
@..\energy_star_body
@..\energy_star_job_body
@..\energy_star_job_data_body
@..\meter_monitor_body
@..\automated_import_body
@..\campaign_body
@..\chain\company_dedupe_body
@..\chain\helper_body
@..\csr_app_body
@..\customer_body
@..\dataview_body
@..\templated_report_body
@..\templated_report_schedule_body
@..\enable_body
@..\chem\substance_body
@..\chem\audit_body
@..\schema_body 
@..\like_for_like_body
@..\section_body
@..\csr_data_body
@..\csr_user_body
@..\initiative_body
@..\util_script_body
@..\actions\task_body
@..\donations\donation_body
@..\..\..\aspen2\cms\db\filter_body



@update_tail
