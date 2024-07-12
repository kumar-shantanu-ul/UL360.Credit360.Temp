define version=2946
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

CREATE TABLE chain.debug_log (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	debug_log_id					NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	start_dtm						TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
	end_dtm							TIMESTAMP,
	object_id						NUMBER(10),
	CONSTRAINT pk_debug_log PRIMARY KEY (app_sid, debug_log_id)
);
CREATE TABLE chain.debug_act (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	act_id							CHAR(36) NOT NULL,
	CONSTRAINT pk_debug_act PRIMARY KEY (app_sid, act_id)
);
CREATE SEQUENCE chain.debug_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
CREATE TYPE CHAIN.T_FILTER_CACHE_VARRAY as VARRAY(1) of chain.T_FILTERED_OBJECT_TABLE;
/
CREATE TABLE chain.filter_cache (
	app_sid			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_sid		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	act_id			CHAR(36)   DEFAULT SYS_CONTEXT('SECURITY', 'ACT') NOT NULL,
	card_group_id	NUMBER(10) NOT NULL,
	expire_dtm		DATE NOT NULL,
	cms_col_sid		NUMBER(10),
	cached_rows		CHAIN.T_FILTER_CACHE_VARRAY
);
CREATE UNIQUE INDEX chain.uk_filter_cache ON chain.filter_cache(app_sid, card_group_id, user_sid, act_id, cms_col_sid);
CREATE INDEX chain.ix_filter_cache_expry ON chain.filter_cache(expire_dtm);
CREATE INDEX chain.ix_filter_cache_user ON chain.filter_cache(user_sid);
CREATE TABLE aspen2.request_queue (	
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	act_id							CHAR(36)   DEFAULT SYS_CONTEXT('SECURITY', 'ACT') NOT NULL,
	last_active_dtm					TIMESTAMP  DEFAULT SYSTIMESTAMP NOT NULL,
	guid							VARCHAR2(36) NOT NULL,
	active_request_number			NUMBER(10) NOT NULL,
	CONSTRAINT pk_request_queue PRIMARY KEY (app_sid, guid)
);
CREATE INDEX aspen2.ix_request_queue_active_dtm ON aspen2.request_queue (last_active_dtm);
CREATE SEQUENCE chain.import_source_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE SEQUENCE chain.dedupe_mapping_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE SEQUENCE chain.dedupe_rule_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE chain.import_source(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	import_source_id		NUMBER NOT NULL,
	name					VARCHAR2(255) NOT NULL,
	position				NUMBER NOT NULL,
	can_create				NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_import_source PRIMARY KEY (app_sid, import_source_id),
	CONSTRAINT uc_import_source UNIQUE (app_sid, position) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT chk_can_create CHECK (can_create IN (0,1))
);
CREATE TABLE chain.dedupe_field(
	dedupe_field_id			NUMBER NOT NULL,
	oracle_table			VARCHAR2(30) NOT NULL,
	oracle_column			VARCHAR2(30) NOT NULL,
	description				VARCHAR2(64) NOT NULL,
	CONSTRAINT pk_dedupe_field PRIMARY KEY (dedupe_field_id),
	CONSTRAINT uc_dedupe_field UNIQUE (oracle_table, oracle_column)
);
CREATE TABLE chain.dedupe_mapping(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_mapping_id		NUMBER NOT NULL,
	import_source_id		NUMBER NOT NULL,
	tab_sid					NUMBER NOT NULL,
	col_sid					NUMBER NOT NULL,
	dedupe_field_id			NUMBER NULL,
	reference_lookup		VARCHAR2(255) NULL,
	CONSTRAINT pk_dedupe_mapping PRIMARY KEY (app_sid, dedupe_mapping_id),
	CONSTRAINT chk_dedupe_field_or_ref CHECK ((dedupe_field_id IS NULL AND reference_lookup IS NOT NULL) OR (dedupe_field_id IS NOT NULL AND reference_lookup IS NULL)),
	CONSTRAINT uc_dedupe_mapping_col UNIQUE (app_sid, import_source_id, tab_sid, col_sid)
);
CREATE TABLE chain.dedupe_rule(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_rule_id			NUMBER NOT NULL,
	import_source_id		NUMBER NOT NULL,
	position				NUMBER NOT NULL,
	CONSTRAINT pk_dedupe_rule PRIMARY KEY (app_sid, dedupe_rule_id),
	CONSTRAINT uc_dedupe_rule UNIQUE (app_sid, import_source_id, position) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE chain.dedupe_rule_mapping(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_rule_id			NUMBER NOT NULL,
	dedupe_mapping_id		NUMBER NOT NULL,
	is_fuzzy				NUMBER(1, 0) DEFAULT 0 NOT NULL,
	position				NUMBER NOT NULL,
	CONSTRAINT pk_dedupe_rule_mapping PRIMARY KEY (app_sid, dedupe_rule_id, dedupe_mapping_id),
	CONSTRAINT uc_dedupe_rule_mapping UNIQUE (app_sid, dedupe_rule_id, position) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE CSRIMP.CHAIN_IMPORT_SOURCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	CAN_CREATE NUMBER(1,0) NOT NULL,
	NAME VARCHAR2(255) NOT NULL,
	POSITION NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_IMPORT_SOURCE PRIMARY KEY (CSRIMP_SESSION_ID, IMPORT_SOURCE_ID),
	CONSTRAINT FK_CHAIN_IMPORT_SOURCE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_MAPPING_ID NUMBER NOT NULL,
	COL_SID NUMBER NOT NULL,
	DEDUPE_FIELD_ID NUMBER,
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	REFERENCE_LOOKUP VARCHAR2(255),
	TAB_SID NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_MAPPING_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_MAPPING_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_RULE_ID NUMBER NOT NULL,
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	POSITION NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_RULE PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_RULE_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_RULE_MAPPIN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_RULE_ID NUMBER NOT NULL,
	DEDUPE_MAPPING_ID NUMBER NOT NULL,
	IS_FUZZY NUMBER(1,0) NOT NULL,
	POSITION NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_RULE_MAPPIN PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_RULE_ID, DEDUPE_MAPPING_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_RULE_MAPPIN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_IMPORT_SOURCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IMPORT_SOURCE_ID NUMBER(10) NOT NULL,
	NEW_IMPORT_SOURCE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_IMPORT_SOURCE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IMPORT_SOURCE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_IMPORT_SOURCE UNIQUE (CSRIMP_SESSION_ID, NEW_IMPORT_SOURCE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_IMPORT_SOURCE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MAPPING_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MAPPING_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MAPPING_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_MAPPING UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MAPPING_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_MAPPING_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.like_for_like_scenario_alert (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid			NUMBER(10, 0) NOT NULL,
	csr_user_sid				NUMBER(10, 0) NOT NULL,
	calc_job_id					NUMBER(10, 0) NOT NULL,
	calc_job_completion_dtm		DATE NOT NULL,
	CONSTRAINT PK_L4L_SCEN_ALERT		 	PRIMARY KEY	(APP_SID, LIKE_FOR_LIKE_SID, CSR_USER_SID, CALC_JOB_ID),
	CONSTRAINT FK_L4L_SCEN_ALERT_L4L_SID 	FOREIGN KEY	(APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_SCEN_ALERT_USER_SID	FOREIGN KEY	(APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
);
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
	IS_LOCKED					NUMBER(1),
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
			LAST_REFRESH_DTM, IS_LOCKED
		  INTO SELF.LIKE_FOR_LIKE_SID, SELF.NAME, SELF.IND_SID, SELF.REGION_SID,
			SELF.INCLUDE_INACTIVE_REGIONS, SELF.PERIOD_START_DTM, SELF.PERIOD_END_DTM,
			SELF.PERIOD_SET_ID, SELF.PERIOD_INTERVAL_ID, SELF.RULE_TYPE, SELF.SCENARIO_RUN_SID,
			SELF.CREATED_BY_USER_SID, SELF.CREATED_DTM, SELF.LAST_REFRESH_DTM, SELF.IS_LOCKED
		  FROM CSR.LIKE_FOR_LIKE_SLOT
		 WHERE LIKE_FOR_LIKE_SID = SID;

		 RETURN;
	END;
END;
/

CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_ROW AS 
	OBJECT (
	IND_SID				NUMBER(10),
	REGION_SID			NUMBER(10),
	PERIOD_START_DTM	DATE,
	PERIOD_END_DTM		DATE,
	VAL_NUMBER			NUMBER(24,10),
	SOURCE_TYPE_ID		NUMBER(10),
	SOURCE_ID			NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_TABLE AS 
	TABLE OF CSR.T_LIKE_FOR_LIKE_VAL_ROW;
/

CREATE GLOBAL TEMPORARY TABLE CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED
(
	IND_SID				NUMBER(10) NOT NULL,
	REGION_SID			NUMBER(10) NOT NULL,
	PERIOD_START_DTM	DATE NOT NULL,
	PERIOD_END_DTM		DATE NOT NULL,
	VAL_NUMBER			NUMBER(24,10),
	SOURCE_TYPE_ID		NUMBER(10),
	SOURCE_ID			NUMBER(10)
)
ON COMMIT DELETE ROWS
;


ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD 
	FILTER_CACHE_TIMEOUT NUMBER(10) DEFAULT 600 NOT NULL;
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS ADD 
	FILTER_CACHE_TIMEOUT NUMBER(10);
UPDATE CSRIMP.CHAIN_CUSTOMER_OPTIONS
   SET FILTER_CACHE_TIMEOUT = 600
 WHERE FILTER_CACHE_TIMEOUT IS NULL;
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS MODIFY
	FILTER_CACHE_TIMEOUT NOT NULL;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_IS
	FOREIGN KEY (app_sid, import_source_id)
	REFERENCES chain.import_source(app_sid, import_source_id);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_FIELD
	FOREIGN KEY (dedupe_field_id)
	REFERENCES chain.dedupe_field(dedupe_field_id);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_COL
	FOREIGN KEY (app_sid, col_sid, tab_sid)
	REFERENCES cms.tab_column(app_sid, column_sid, tab_sid);
ALTER TABLE chain.dedupe_rule ADD CONSTRAINT FK_DEDUPE_RULE_IMPORT_SOURCE
	FOREIGN KEY (app_sid, import_source_id)
	REFERENCES chain.import_source(app_sid, import_source_id);
	
ALTER TABLE chain.dedupe_rule_mapping ADD CONSTRAINT FK_DEDUPE_RULE_MAPPING_RULE
	FOREIGN KEY (app_sid, dedupe_rule_id)
	REFERENCES chain.dedupe_rule(app_sid, dedupe_rule_id);
	
ALTER TABLE chain.dedupe_rule_mapping ADD CONSTRAINT FK_DEDUPE_RULE_MAPPING_MAP
	FOREIGN KEY (app_sid, dedupe_mapping_id)
	REFERENCES chain.dedupe_mapping(app_sid, dedupe_mapping_id);
CREATE OR REPLACE FUNCTION get_constraintname_text(
	p_cons_name IN VARCHAR2 
)RETURN VARCHAR2
AUTHID CURRENT_USER	IS
l_search_condition		all_constraints.search_condition%TYPE;
BEGIN
	SELECT search_condition INTO l_search_condition
	  FROM all_constraints
	 WHERE constraint_name = p_cons_name;
	RETURN l_search_condition;
END;
/
BEGIN
FOR R IN (
  SELECT constraint_name, table_name, owner 
    FROM (
	  SELECT constraint_name, table_name, get_constraintname_text(constraint_name), owner
		FROM all_constraints
	   WHERE table_name LIKE UPPER('METERING_OPTIONS')
		 AND owner LIKE UPPER('CSR')
		 AND constraint_name like 'SYS_%'
		 AND (get_constraintname_text(constraint_name) like 'ANALYTICS_CURRENT_MONTH IN(0,1)')
  )
)
LOOP
  EXECUTE IMMEDIATE ('ALTER TABLE CSR.METERING_OPTIONS DROP CONSTRAINT ' || r.constraint_name);
END LOOP;
FOR R IN (
  SELECT constraint_name, table_name, owner 
    FROM (
	  SELECT constraint_name, table_name, get_constraintname_text(constraint_name), owner
		FROM all_constraints
	   WHERE table_name LIKE UPPER('METERING_OPTIONS')
		 AND owner LIKE UPPER('CSRIMP')
		 AND constraint_name like 'SYS_%'
		 AND (get_constraintname_text(constraint_name) like 'ANALYTICS_CURRENT_MONTH IN(0,1)')
  )
)
LOOP
  EXECUTE IMMEDIATE ('ALTER TABLE CSRIMP.METERING_OPTIONS DROP CONSTRAINT ' || r.constraint_name);
END LOOP;
END;
/
ALTER TABLE CSR.METERING_OPTIONS ADD CONSTRAINT CK_MET_OPT_CURR_MON_0_1	CHECK (ANALYTICS_CURRENT_MONTH IN(0,1));
ALTER TABLE CSRIMP.METERING_OPTIONS ADD CONSTRAINT CK_MET_OPT_CURR_MON_0_1	CHECK (ANALYTICS_CURRENT_MONTH IN(0,1));
DROP FUNCTION get_constraintname_text;
ALTER TABLE CSR.METERING_OPTIONS ADD (
	METERING_HELPER_PKG VARCHAR2(255)
);
ALTER TABLE CSRIMP.METERING_OPTIONS ADD (
	METERING_HELPER_PKG VARCHAR2(255)
);


GRANT SELECT, REFERENCES ON chain.debug_log TO csr;
grant select, insert, update, delete on csrimp.chain_import_source to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_mapping to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_rule to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_rule_mappin to web_user;
grant select, insert, update on chain.import_source to csrimp;
grant select, insert, update on chain.dedupe_mapping to csrimp;
grant select, insert, update on chain.dedupe_rule to csrimp;
grant select, insert, update on chain.dedupe_rule_mapping to csrimp;
grant select on chain.import_source_id_seq to csrimp;
grant select on chain.import_source_id_seq to CSR;
grant select on chain.dedupe_mapping_id_seq to csrimp;
grant select on chain.dedupe_mapping_id_seq to CSR;
grant select on chain.dedupe_rule_id_seq to csrimp;
grant select on chain.dedupe_rule_id_seq to CSR;
grant select, insert, update on chain.import_source to CSR;
grant select, insert, update on chain.dedupe_mapping to CSR;
grant select, insert, update on chain.dedupe_rule to CSR;
grant select, insert, update on chain.dedupe_rule_mapping to CSR;
grant select on chain.import_source_id_seq to CSR;
grant select on chain.dedupe_mapping_id_seq to CSR;
grant select on chain.dedupe_rule_id_seq to CSR;




CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency, r.geo_type,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, pf.fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		LEFT JOIN (
			-- In the case of multiple fund ownership, the "default" fund is the fund with the highest
			-- ownership. Where multiple funds have the same ownership, the default is the fund that was
			-- created first. Fund ID is retained for compatibility with pre-multi ownership code.
			SELECT
				app_sid, region_sid, fund_id, ownership,
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid
								   ORDER BY ownership DESC, fund_id ASC) priority
			FROM csr.property_fund
		) pf ON pf.app_sid = r.app_sid AND pf.region_sid = r.region_sid AND pf.priority = 1;
CREATE OR REPLACE VIEW chain.v$debug_log AS
	SELECT app_sid, debug_log_id, end_dtm - start_dtm duration, label, object_id, start_dtm, end_dtm
	  FROM chain.debug_log
	 ORDER BY debug_log_id DESC;
CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM meter_source_data sd
			 WHERE sd.app_sid = m.app_sid
			   AND sd.region_sid = m.region_sid
		) 
	)
	--
	-- Legacy meter readings part
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost, 
		mr.baseline_val, mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, 
		mr.meter_document_id, mr.created_invoice_id, mr.approved_dtm, mr.approved_by_sid, 
		mr.is_estimate, mr.flow_item_id, mr.pm_reading_id, mr.format_mask,
		m.auto_source
	  FROM m
	  JOIN csr.v$meter_reading mr on mr.app_sid = m.app_sid AND mr.region_sid = m.legacy_region_sid
	--
	-- Source data part
	UNION
	SELECT MAX(x.app_sid) app_sid, ROW_NUMBER() OVER (ORDER BY x.start_dtm) meter_reading_id, 
		MAX(x.region_sid) region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, NULL note, NULL reference, 
		NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid, 
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask,
		x.auto_source
	FROM (
		-- Consumption
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.raw_consumption val_number, NULL cost, m.auto_source
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.raw_consumption cost, m.auto_source
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28180, 17, 'TJ/Gg', 0.000001, 1, 0, 1);


DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'ASPEN2',
			object_name     => 'REQUEST_QUEUE',
			policy_name     => 'REQUEST_QUEUE_POLICY',
			function_schema => 'ASPEN2',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
	EXCEPTION
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
	END;
END;
/


INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible)
VALUES (28181,3,'1/1000000km',0.000000000001,1,0,1);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible)
VALUES (28182,3,'1/200000hrs',0.00000000138889,1,0,1);
DECLARE
    job BINARY_INTEGER;
BEGIN
	FOR r IN (
		SELECT job_name FROM all_scheduler_jobs WHERE UPPER(job_name) = UPPER('ExpireRequestQueue') AND OWNER = UPPER('aspen2')
	)
	LOOP
		DBMS_SCHEDULER.DROP_JOB('aspen2.ExpireRequestQueue', TRUE);
	END LOOP;
	
	DBMS_SCHEDULER.CREATE_JOB (
		job_name             => 'aspen2.ExpireRequestQueue',
		job_type             => 'PLSQL_BLOCK',
		job_action           => 'request_queue_pkg.ExpireRequestQueue;',
		job_class            => 'low_priority_job',
		repeat_interval      => 'FREQ=HOURLY',
		enabled              => TRUE,
		auto_drop            => FALSE,
		start_date           => TO_DATE('2000-01-01 00:25:00','yyyy-mm-dd hh24:mi:ss'),
		comments             => 'Expire old requests in the request queue');    
	COMMIT;
END;
/
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every 10 minutes
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.RunFilterExpiry',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'filter_pkg.RemoveExpiredCaches;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=10',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Triggers job for running chain jobs');
       COMMIT;
END;
/
BEGIN
	-- Logoin as admin (no site)
	security.user_pkg.logonadmin;
	-- Properties
	FOR r IN (
		SELECT sid_id, description, context
		  FROM security.menu
		 -- Catches everything
		 WHERE LOWER(action) LIKE '/csr/site/property/properties/myproperties.acds%'
		    OR LOWER(action) LIKE '%/site/properties/myproperties.acds%'
	) LOOP
		-- Users will already have access to the /csr/site/property/properties
		-- web resource as other required components are already located there.
		-- The list page doesn't specify a "SelectedMenu" property but the system 
		-- appears to pick-up the correct menu context, so no need to rename the 
		-- menu item securable object node.
		security.menu_pkg.SetMenu(
			security.security_pkg.GetACT,
			r.sid_id,
			r.description,
			'/csr/site/property/properties/list.acds',
			NULL,
			r.context
		);
	END LOOP;
	-- Initiatives
	FOR r IN (
		SELECT sid_id, description, context
		  FROM security.menu
		 -- Avoids teamroom (M and S)
		 WHERE LOWER(action) LIKE '%/site/initiatives2/myinitiatives.acds%'
		    OR LOWER(action) LIKE '%/site/initiatives/myinitiatives.acds%'
	) LOOP
		-- Users will already have access to the /csr/site/initiatives
		-- web resource as other required components are already located there.
		-- The list page doesn't specify a "SelectedMenu" property but the system 
		-- appears to pick-up the correct menu context, so no need to rename the 
		-- menu item securable object node.
		security.menu_pkg.SetMenu(
			security.security_pkg.GetACT,
			r.sid_id,
			r.description,
			'/csr/site/initiatives/list.acds',
			NULL,
			r.context
		);
	END LOOP;
END;
/
BEGIN
	--company table
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (1, 'COMPANY', 'NAME', 'Company name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (2, 'COMPANY', 'PARENT_SID', 'Parent company');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (3, 'COMPANY', 'COMPANY_TYPE_ID', 'Company type');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (4, 'COMPANY', 'CREATED_DTM', 'Created date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (5, 'COMPANY', 'ACTIVATED_DTM', 'Activated date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (6, 'COMPANY', 'ACTIVE', 'Active');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (7, 'COMPANY', 'ADDRESS', 'Address');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (8, 'COMPANY', 'STATE', 'State');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (9, 'COMPANY', 'POSTCODE', 'Postcode');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (10, 'COMPANY', 'COUNTRY_CODE', 'Country');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (11, 'COMPANY', 'PHONE', 'Phone');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (12, 'COMPANY', 'FAX', 'Fax');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (13, 'COMPANY', 'WEBSITE', 'Website');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (14, 'COMPANY', 'EMAIL', 'Email');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (15, 'COMPANY', 'DELETED', 'Deleted');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (16, 'COMPANY', 'SECTOR_ID', 'Sector');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (17, 'COMPANY', 'CITY', 'City');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (18, 'COMPANY', 'DEACTIVATED_DTM', 'Deactivated date');
END;
/
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (76, 'Like for like dataset calculation complete',
	 'The underlying dataset for a like for like slot has completing calculating.',
	 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).', 1, 14
);
 
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'SLOT_NAME', 'Slot name', 'The name of the like for like slot', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'SCENARIO_RUN_NAME', 'Scenario name', 'The name of the underlying scenario', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'COMPLETION_DTM', 'Completion time', 'The date and time that the dataset completed calculating', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'START_DTM', 'Start date', 'The start date of the like for like slot', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'END_DTM', 'End date', 'The end date of the like for like slot', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'LINK_URL', 'Link to slot', 'A link to the like for like page for the slot', 11);
 
DECLARE
   v_daf_id NUMBER(2);
BEGIN
	SELECT MAX(default_alert_frame_id) INTO v_daf_id FROM csr.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (76, v_daf_id, 'inactive');
END;
/
DELETE FROM security.securable_object
 WHERE name = 'Edit user line manager' AND
       class_id = (SELECT class_id FROM security.securable_object_class
                    WHERE class_name = 'CSRCapability');
DECLARE
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/
		   AND js_class = 'Credit360.Metering.MeterReadingTab';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
			VALUES (csr.plugin_id_seq.NEXTVAL, 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 
				'Readings', '/csr/site/meter/controls/meterReadingTab.js', 
				'Credit360.Metering.MeterReadingTab', 'Credit360.Metering.Plugins.MeterReading', 
				'Enter readings and check percentage tolerances.', '/csr/shared/plugins/screenshots/meter_readings.png')
			RETURNING plugin_id INTO v_plugin_id;
	END;
	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_source_type s
		  JOIN csr.customer c ON c.app_sid = s.app_sid
	) LOOP
		security.user_pkg.logonadmin(a.host);
		BEGIN
			INSERT INTO csr.meter_tab(plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_plugin_id, 16/*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 1, 'Readings');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Administrators'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the group/role is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter administrator'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the group/role  is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter reader'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the group/role  is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
BEGIN
	UPDATE csr.plugin
	   SET details = 'Display a simple chart showing total and average consumption for the lifetime of the meter.',
	       preview_image_path = '/csr/shared/plugins/screenshots/meter_low_res_chart.png'
	 WHERE js_class = 'Credit360.Metering.MeterLowResChartTab';
	UPDATE csr.plugin
	   SET details = 'Display a detailed interactive chart showing all inputs for the meter, and patch data for the meter.',
	       preview_image_path = '/csr/shared/plugins/screenshots/meter_hi_res_chart.png'
	 WHERE js_class = 'Credit360.Metering.MeterHiResChartTab';
	UPDATE csr.plugin
	   SET details = 'Display, filter, search, and export raw readings for the meter.',
	       preview_image_path = '/csr/shared/plugins/screenshots/meter_raw_data.png'
	 WHERE js_class = 'Credit360.Metering.MeterRawDataTab';
END;
/
CREATE OR REPLACE FUNCTION csr.Temp_SetCorePlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
			         in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE plugin 
			   SET description = in_description,
			   	   js_include = in_js_include,
			   	   cs_class = in_cs_class,
			   	   details = in_details,
			   	   preview_image_path = in_preview_image_path,
			   	   form_path = in_form_path
			 WHERE plugin_type_id = in_plugin_type_id
			   AND js_class = in_js_class
			   AND app_sid IS NULL
			   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
		 	RETURNING plugin_id INTO v_plugin_id;
	END;
	RETURN v_plugin_id;
END;
/
DECLARE
	v_plugin_id     csr.plugin.plugin_id%TYPE;
begin
	v_plugin_id := csr.temp_SetCorePlugin (
        in_plugin_type_id   	=> 16, --csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB
        in_js_class         	=> 'Credit360.Metering.MeterCharacteristicsTab',
		in_cs_class				=> 'Credit360.Plugins.PluginDto',
        in_description      	=> 'Meter Characteristics',
		in_details				=> 'Edit meter data.',
        in_js_include       	=> '/csr/site/meter/controls/meterCharacteristicsTab.js'
	);
end;
/
DROP FUNCTION csr.Temp_SetCorePlugin;




CREATE OR REPLACE PACKAGE aspen2.request_queue_pkg AS
	PROCEDURE Dummy;
END;
/
grant execute on aspen2.request_queue_pkg to web_user;
grant execute on aspen2.request_queue_pkg to cms, chain, csr;
create or replace package chain.company_dedupe_pkg as
procedure dummy;
end;
/
create or replace package body chain.company_dedupe_pkg as
procedure dummy
as
begin
	null;
end;
end;
/
GRANT EXECUTE ON chain.company_dedupe_pkg TO web_user;
GRANT EXECUTE ON chain.company_dedupe_pkg TO csr; --needed for csrApp

@..\chain\helper_pkg
@..\chain\filter_pkg
@..\chain\setup_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\..\..\aspen2\db\request_queue_pkg
@..\audit_pkg
@..\csr_data_pkg
@..\schema_pkg
@..\chain\company_dedupe_pkg
@..\like_for_like_pkg
@..\chain\plugin_pkg
@..\tag_pkg
@..\meter_pkg
@..\property_pkg

@..\chain\helper_body
@..\..\..\aspen2\cms\db\tab_body
@..\property_body
@..\chain\filter_body
@..\chain\setup_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\db\request_queue_body
@..\audit_report_body
@..\initiative_report_body
@..\issue_report_body
@..\meter_report_body
@..\non_compliance_report_body
@..\property_report_body
@..\user_report_body
@..\chain\company_filter_body
@..\schema_body
@..\region_body
@..\role_body
@..\flow_body
@..\csr_user_body
@..\issue_body
@..\audit_body
@..\csrimp\imp_body
@..\chain\company_dedupe_body
@..\like_for_like_body
@..\scenario_body
@..\scenario_run_body
@..\unit_test_body
@..\chain\audit_request_body
@..\chain\supplier_audit_body
@..\chain\plugin_body
@..\tag_body
@..\meter_body
@..\quick_survey_body

@update_tail
