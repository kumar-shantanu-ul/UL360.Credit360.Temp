-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CSR.METER_DATA_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

	CREATE SEQUENCE CSR.METER_AGGREGATE_TYPE_ID_SEQ
	START WITH 10000
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CSR.METER_DATA_ID(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID						NUMBER(10, 0)	NOT NULL,
	METER_BUCKET_ID					NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NOT NULL,
	AGGREGATOR						VARCHAR2(32)	NOT NULL,
	PRIORITY						NUMBER(10, 0)	NOT NULL,
	START_DTM						DATE			NOT NULL,
	METER_DATA_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_METER_DATA_ID PRIMARY KEY (APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
);

CREATE TABLE CSR.METER_AGGREGATE_TYPE(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	METER_AGGREGATE_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NOT NULL,
	AGGREGATOR						VARCHAR2(32)	NOT NULL,
	ANALYTIC_FUNCTION				NUMBER(10, 0)	NOT NULL,
	DESCRIPTION						VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_METER_AGGREGATE_TYPE PRIMARY KEY (APP_SID, METER_AGGREGATE_TYPE_ID)
);

ALTER TABLE CSR.METER_AGGREGATE_TYPE ADD (
	ACCUMULATIVE					NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_MTR_AGG_TYP_CUMULATIVE_1_0 CHECK (ACCUMULATIVE IN (1, 0))
);

CREATE TABLE CSRIMP.METER_DATA_ID(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID						NUMBER(10, 0)	NOT NULL,
	METER_BUCKET_ID					NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NOT NULL,
	AGGREGATOR						VARCHAR2(32) 	NOT NULL,
	PRIORITY						NUMBER(10, 0)	NOT NULL,
	START_DTM						DATE			NOT NULL,
	METER_DATA_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_METER_DATA_ID PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM),
	CONSTRAINT FK_METER_DATA_ID FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.METER_AGGREGATE_TYPE(
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	METER_AGGREGATE_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID					NUMBER(10, 0)	NULL,
	AGGREGATOR						VARCHAR2(32)	NOT NULL,
	ANALYTIC_FUNCTION				NUMBER(10, 0)	NOT NULL,
	DESCRIPTION						VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_METER_AGGREGATE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, METER_AGGREGATE_TYPE_ID),
	CONSTRAINT FK_METER_AGGREGATE_TYPE FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);

ALTER TABLE CSRIMP.METER_AGGREGATE_TYPE ADD (
	ACCUMULATIVE					NUMBER(1)		NOT NULL,
	CONSTRAINT CHK_MTR_AGG_TYP_CUMULATIVE_1_0 CHECK (ACCUMULATIVE IN (1, 0))
);

CREATE TABLE csrimp.map_meter_data_id  (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_data_id				NUMBER(10)		NOT NULL,
	new_meter_data_id				NUMBER(10)		NOT NULL,
	CONSTRAINT pk_map_meter_data_id primary key (csrimp_session_id, old_meter_data_id) USING INDEX,
	CONSTRAINT uk_map_meter_bucket_id unique (csrimp_session_id, new_meter_data_id) USING INDEX,
    CONSTRAINT fk_map_meter_data_id FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_aggregate_type  (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_aggregate_type_id		NUMBER(10)		NOT NULL,
	new_meter_aggregate_type_id		NUMBER(10)		NOT NULL,
	CONSTRAINT pk_map_meter_aggregate_type primary key (csrimp_session_id, old_meter_aggregate_type_id) USING INDEX,
	CONSTRAINT uk_map_meter_aggregate_type unique (csrimp_session_id, new_meter_aggregate_type_id) USING INDEX,
    CONSTRAINT fk_map_meter_aggregate_type FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE UNIQUE INDEX CSR.UK_METER_DATA_ID ON CSR.METER_DATA_ID(APP_SID, METER_DATA_ID);
CREATE INDEX CSR.IX_METER_DATA_ID_REGION ON CSR.METER_DATA_ID(APP_SID, REGION_SID);

-- Not sure if this is needed - need to see what happens when there's alot more data in the table
CREATE INDEX CSR.IX_METER_DATA_ID_APP ON CSR.METER_DATA_ID(APP_SID);
CREATE INDEX CSR.IX_METER_LIVE_DATA_APP ON CSR.METER_LIVE_DATA(APP_SID);

CREATE TABLE chain.saved_filter_region (	
	app_sid							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	saved_filter_sid				NUMBER(10)		NOT NULL,
	region_sid						NUMBER(10)		NOT NULL,
	CONSTRAINT pk_saved_filter_region PRIMARY KEY (app_sid, saved_filter_sid, region_sid),
	CONSTRAINT fk_svd_fltr_region_svd_fltr FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid),
	CONSTRAINT fk_svd_fltr_region_region FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid)
);

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_REGION_TAG (
	REGION_SID						NUMBER(10)		NOT NULL,
	TAG_ID							NUMBER(10)
) ON COMMIT DELETE ROWS;


CREATE TABLE CSR.METERING_OPTIONS(
    APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ANALYTICS_MONTHS				NUMBER(10, 0),
    ANALYTICS_CURRENT_MONTH			NUMBER(1, 0) 	DEFAULT 0 NOT NULL,
    CHECK (ANALYTICS_CURRENT_MONTH IN(0,1)),
    CONSTRAINT PK_METERING_OPTIONS PRIMARY KEY (APP_SID)
);


CREATE TABLE CSRIMP.METERING_OPTIONS(
    CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    ANALYTICS_MONTHS				NUMBER(10, 0),
    ANALYTICS_CURRENT_MONTH			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
    CHECK (ANALYTICS_CURRENT_MONTH IN(0,1)),
    CONSTRAINT PK_METERING_OPTIONS PRIMARY KEY (CSRIMP_SESSION_ID)
);


CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_PATCH_IMPORT_ROWS (
	SOURCE_ROW						NUMBER(10),
	REGION_SID						NUMBER(10),
	METER_INPUT_ID					NUMBER(10),
	PRIORITY						NUMBER(10),
	START_DTM						DATE,
	END_DTM							DATE,
	VAL								NUMBER(24,10),
	ERROR_MSG						VARCHAR(4000)
) ON COMMIT DELETE ROWS;


CREATE TABLE csrimp.chain_saved_filter_region (	
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	saved_filter_sid				NUMBER(10)		NOT NULL,
	region_sid						NUMBER(10)		NOT NULL,
	CONSTRAINT pk_saved_filter_region PRIMARY KEY (csrimp_session_id, saved_filter_sid, region_sid),	
	CONSTRAINT fk_chain_saved_fltr_region_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.METER_DATA_ID ADD CONSTRAINT FK_METLIVDAT_METLIVDATID 
    FOREIGN KEY (APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
    REFERENCES CSR.METER_LIVE_DATA(APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
    ON DELETE CASCADE
;

ALTER TABLE CSR.METER_AGGREGATE_TYPE ADD CONSTRAINT FK_METINPAGGR_METAGGRTYPE 
    FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
    REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;

ALTER TABLE CSR.METER_AGGREGATE_TYPE ADD CONSTRAINT PK_CUSTOMER_METAGGRTYPE 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

GRANT SELECT, REFERENCES ON csr.meter_aggregate_type TO chain;

ALTER TABLE chain.customer_aggregate_type ADD (
	meter_aggregate_type_id			NUMBER(10),
	CONSTRAINT fk_cust_agg_type_meter_agg_typ FOREIGN KEY (app_sid, meter_aggregate_type_id)
		REFERENCES csr.meter_aggregate_type (app_sid, meter_aggregate_type_id)
		ON DELETE CASCADE
);

ALTER TABLE chain.customer_aggregate_type DROP CONSTRAINT chk_customer_aggregate_type;
ALTER TABLE chain.customer_aggregate_type ADD CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NOT NULL));
	   
DROP INDEX CHAIN.UK_CUSTOMER_AGGREGATE_TYPE;
CREATE UNIQUE INDEX CHAIN.UK_CUSTOMER_AGGREGATE_TYPE ON CHAIN.CUSTOMER_AGGREGATE_TYPE (
		APP_SID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID)
;
	   
	   
ALTER TABLE csrimp.chain_customer_aggregate_type ADD (
	meter_aggregate_type_id			NUMBER(10)
);

ALTER TABLE csrimp.chain_customer_aggregate_type DROP CONSTRAINT chk_customer_aggregate_type;
ALTER TABLE csrimp.chain_customer_aggregate_type ADD CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL AND meter_aggregate_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NOT NULL));

ALTER TABLE CSR.METER_INPUT ADD (
	IS_VIRTUAL					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	VALUE_HELPER				VARCHAR2(256),
	CONSTRAINT CHK_METER_INPUT_IS_VIRTUAL_1_0 CHECK (IS_VIRTUAL IN(0,1))
);

DROP TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_ROW AS 
	 OBJECT ( 
		CARD_GROUP_ID				NUMBER(10),
		AGGREGATE_TYPE_ID			NUMBER(10),	
		DESCRIPTION 				VARCHAR2(1023),
		FORMAT_MASK					VARCHAR2(255),
		FILTER_PAGE_IND_INTERVAL_ID	NUMBER(10),
		ACCUMULATIVE				NUMBER(1)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_ROW;
/

-- fk indexes
create index chain.ix_customer_aggr_initiative_me on chain.customer_aggregate_type (app_sid, initiative_metric_id);
create index chain.ix_customer_aggr_ind_sid on chain.customer_aggregate_type (app_sid, ind_sid);
create index chain.ix_customer_aggr_meter_aggrega on chain.customer_aggregate_type (app_sid, meter_aggregate_type_id);
create index chain.ix_customer_aggr_cms_aggregate on chain.customer_aggregate_type (app_sid, cms_aggregate_type_id);
create index chain.ix_customer_aggr_filter_page_i on chain.customer_aggregate_type (app_sid, filter_page_ind_interval_id);
create index chain.ix_customer_aggr_card_group_id on chain.customer_aggregate_type (card_group_id);
create index chain.ix_filter_page_i_ind_sid on chain.filter_page_ind (app_sid, ind_sid);
create index chain.ix_filter_page_i_card_group_id on chain.filter_page_ind (card_group_id);
create index chain.ix_filter_page_i_period_set_id on chain.filter_page_ind (app_sid, period_set_id, period_interval_id);
create index chain.ix_saved_filter_customer_aggr on chain.saved_filter_aggregation_type (app_sid, customer_aggregate_type_id);
create index chain.ix_saved_filter_region_sid on chain.saved_filter_region (app_sid, region_sid);

-- *** Grants ***
GRANT SELECT ON chain.saved_filter_region TO csr;
GRANT SELECT, INSERT, UPDATE ON chain.saved_filter_region TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.meter_data_id TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.meter_aggregate_type TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metering_options TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_saved_filter_region TO web_user;

GRANT SELECT ON csr.meter_aggregate_type_id_seq TO csrimp;
GRANT SELECT ON csr.meter_data_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.meter_data_id TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.meter_aggregate_type TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.metering_options TO csrimp;

grant execute on chain.t_filter_agg_type_table TO csr;
grant execute on chain.t_filter_agg_type_row TO csr;
grant execute on chain.t_filter_agg_type_table TO cms;
grant execute on chain.t_filter_agg_type_row TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes. I will use this version when making the major scripts.

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW CSR.V$PATCHED_METER_LIVE_DATA AS
	SELECT app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id, 
			priority, start_dtm, end_dtm, meter_raw_data_id, modified_dtm, consumption
	  FROM (
		SELECT mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, 
				mld.priority, mld.start_dtm, mld.end_dtm, mld.meter_raw_data_id, mld.modified_dtm, mld.consumption,
			ROW_NUMBER() OVER (PARTITION BY mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, mld.start_dtm ORDER BY mld.priority DESC) rn
		  FROM csr.meter_live_data mld
	 )
	 WHERE rn = 1;

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('CHAIN_SAVED_FILTER_REGION', 'METER_DATA_ID', 'METER_AGGREGATE_TYPE', 'MAP_METER_AGGREGATE_TYPE', 'MAP_METER_DATA_ID', 'METERING_OPTIONS')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

-- Data
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Credit360.Property.Filters.PropertyFilter
	v_desc := 'Meter Data Filter';
	v_class := 'Credit360.Metering.Cards.MeterDataFilter';
	v_js_path := '/csr/site/meter/filters/MeterDataFilter.js';
	v_js_class := 'Credit360.Metering.Filters.MeterDataFilter';
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
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(46, 'Meter Data Filter', 'Allows filtering of meter data', 'csr.meter_report_pkg', '/csr/site/meter/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Metering.Filters.MeterDataFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Meter Data Filter', 'csr.meter_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_source_type
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 46, v_card_id, 0);
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (46, 1, 'Total consumption');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (46, 1, 1, 'Meter region');
		
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (46, 2, 2, 'Start date');
END;
/

DELETE FROM chain.card_group_column_type
	  WHERE card_group_id = 46
	    AND description = 'End date';

UPDATE chain.aggregate_type
   SET description = 'Total consumption'
 WHERE card_group_id = 46
   AND aggregate_type_id = 1;

DECLARE
	v_plugin_id			csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO csr.plugin
			(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
		VALUES 
			(csr.plugin_id_seq.nextval, 1, 'Meter data list', 
				'/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterListTab', 'Credit360.Metering.Plugins.MeterList', 
				'Quick Charts tab for meter data', '/csr/shared/plugins/screenshots/property_tab_meter_list.png');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.meter_report_pkg AS END;
/
GRANT EXECUTE ON csr.meter_report_pkg TO web_user;
GRANT EXECUTE ON csr.meter_report_pkg TO chain;

-- *** Packages ***
@../chain/chain_pkg
@../chain/filter_pkg
@../meter_report_pkg
@../meter_pkg
@../meter_monitor_pkg
@../schema_pkg
@../enable_pkg
@../audit_report_pkg
@../chain/company_filter_pkg
@../initiative_report_pkg
@../issue_report_pkg
@../non_compliance_report_pkg
@../property_report_pkg
@../../../aspen2/cms/db/filter_pkg
@../meter_patch_pkg

@../chain/filter_body
@../chain/chain_body
@../meter_report_body
@../meter_body
@../meter_monitor_body
@../meter_patch_body
@../schema_body
@../enable_body
@../property_body
@../csrimp/imp_body
@../audit_report_body
@../chain/company_filter_body
@../initiative_report_body
@../issue_report_body
@../non_compliance_report_body
@../property_report_body
@../../../aspen2/cms/db/filter_body
@../csr_app_body

@update_tail
