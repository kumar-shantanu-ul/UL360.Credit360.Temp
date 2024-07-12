define version=3417
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE OR REPLACE TYPE CSR.T_GET_VALUE_RESULT_ROW AS
	OBJECT (
		period_start_dtm	DATE,
		period_end_dtm		DATE,
		source				NUMBER(10,0),
		source_id			NUMBER(20,0),
		source_type_id		NUMBER(10,0),
		ind_sid				NUMBER(10,0),
		region_sid			NUMBER(10,0),
		val_number			NUMBER(24,10),
		error_code			NUMBER(10,0),
		changed_dtm			DATE,
		note				CLOB,
		flags				NUMBER (10,0),
		is_leaf				NUMBER(1,0),
		is_merged			NUMBER(1,0),
		path				VARCHAR2(1024)
	);
/
CREATE OR REPLACE TYPE CSR.T_GET_VALUE_RESULT_TABLE AS
	TABLE OF CSR.T_GET_VALUE_RESULT_ROW;
/
DROP TABLE CSR.temp_sheets_ind_region_to_use;
CREATE OR REPLACE TYPE CSR.TT_AUDIT_CAP_DATA_ROW AS
	OBJECT ( 
		INTERNAL_AUDIT_SID		NUMBER(10), 
		INTERNAL_AUDIT_TYPE_ID	NUMBER(10),
		FLOW_CAPABILITY_ID		NUMBER(10),
		PERMISSION_SET			NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.TT_AUDIT_CAP_DATA_TABLE AS
	TABLE OF CSR.TT_AUDIT_CAP_DATA_ROW;
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_AGGR_VAL_DATA_ROW AS
  OBJECT (
	INITIATIVE_SID			NUMBER(10),
	INITIATIVE_METRIC_ID	NUMBER(10),
	REGION_SID				NUMBER(10),
	START_DTM				DATE,
	END_DTM					DATE,
	VAL_NUMBER				NUMBER(24, 10)
  );
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_AGGR_VAL_DATA_TABLE AS 
  TABLE OF CSR.T_INITIATIVE_AGGR_VAL_DATA_ROW;
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_SID_DATA_ROW AS
  OBJECT (
	INITIATIVE_SID			NUMBER(10)
  );
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_SID_DATA_TABLE AS 
  TABLE OF CSR.T_INITIATIVE_SID_DATA_ROW;
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_METRIC_ID_DATA_ROW AS
  OBJECT (
	INITIATIVE_METRIC_ID 		NUMBER(10),
	MEASURE_CONVERSION_ID		NUMBER(10)
  );
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_METRIC_ID_DATA_TABLE AS 
  TABLE OF CSR.T_INITIATIVE_METRIC_ID_DATA_ROW;
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_DATA_ROW AS
  OBJECT (
	INITIATIVE_SID			NUMBER(10),
	FLOW_STATE_ID			NUMBER(10),
	FLOW_STATE_LABEL		VARCHAR2(255),
	FLOW_STATE_LOOKUP_KEY	VARCHAR2(255),
	FLOW_STATE_COLOUR		NUMBER(10),
	FLOW_STATE_POS			NUMBER(10),
	IS_EDITABLE				NUMBER(1),
	ACTIVE					NUMBER(1),
	OWNER_SID				NUMBER(10),
	POS						NUMBER(10)
  )
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_DATA_TABLE AS
  TABLE OF CSR.T_INITIATIVE_DATA_ROW;
/
CREATE OR REPLACE TYPE CSR.T_IND_TREE_ROW AS
  OBJECT (
  APP_SID					NUMBER(10),
  IND_SID                   NUMBER(10, 0),
  PARENT_SID                NUMBER(10, 0),
  DESCRIPTION               VARCHAR2(1023),
  IND_TYPE                  NUMBER(10, 0),
  MEASURE_SID               NUMBER(10, 0),
  MEASURE_DESCRIPTION		VARCHAR2(255),
  FORMAT_MASK				VARCHAR2(255),
  ACTIVE                    NUMBER(10, 0)
  );
/
CREATE OR REPLACE TYPE CSR.T_IND_TREE_TABLE AS
  TABLE OF CSR.T_IND_TREE_ROW;
/
CREATE OR REPLACE TYPE CSR.T_SEARCH_TAG_ROW AS
  OBJECT (
  SET_ID					NUMBER(10),
  TAG_ID                    NUMBER(10, 0)
  );
/
CREATE OR REPLACE TYPE CSR.T_SEARCH_TAG_TABLE AS
  TABLE OF CSR.T_SEARCH_TAG_ROW;
/


ALTER TABLE csr.alert_template ADD (
    SAVE_IN_SENT_ALERTS     NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT CK_SAVE_IN_SENT_ALERTS CHECK (SAVE_IN_SENT_ALERTS IN (0,1))
);
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.COMPLIANCE_ITEM_HISTORY' ;
	EXCEPTION
	WHEN OTHERS THEN
		IF SQLCODE != -942 THEN  -- Raise exception if there is any other exception other than table not found"
			RAISE;
		END IF;
	END;
	/










UPDATE csr.alert_template alt
   SET save_in_sent_alerts = 0
 WHERE EXISTS (
    SELECT NULL
      FROM csr.customer_alert_type
     WHERE customer_alert_type_id = alt.customer_alert_type_id
       AND std_alert_type_id = 25 -- csr.csr_data_pkg.ALERT_PASSWORD_RESET
);
DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.indicators', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Sheet list', 0);
CREATE INDEX csr.ix_delegation_ro_deleg_sid ON csr.delegation_role (app_sid, delegation_sid);
DECLARE
	v_card_id				NUMBER(10);
	PROCEDURE SetGroupCards(
		in_group_name			IN  chain.card_group.name%TYPE,
		in_card_js_types		IN  chain.T_STRING_LIST
	)
	AS
		v_group_id				chain.card_group.card_group_id%TYPE;
		v_card_id				chain.card.card_id%TYPE;
		v_pos					NUMBER(10) := 1;
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
		
		DELETE FROM chain.card_group_progression
		 WHERE app_sid = security.security_pkg.GetApp
		   AND card_group_id = v_group_id;
		
		DELETE FROM chain.card_group_card
		 WHERE app_sid = security.security_pkg.GetApp
		   AND card_group_id = v_group_id;
		
		-- empty array check
		IF in_card_js_types IS NULL OR in_card_js_types.COUNT = 0 THEN
			RETURN;
		END IF;
		
		FOR i IN in_card_js_types.FIRST .. in_card_js_types.LAST 
		LOOP		
			SELECT card_id
			  INTO v_card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER(in_card_js_types(i));
			INSERT INTO chain.card_group_card
			(card_group_id, card_id, position)
			VALUES
			(v_group_id, v_card_id, v_pos);
			
			v_pos := v_pos + 1;
		
		END LOOP;		
	END;
BEGIN
    security.user_pkg.logonadmin;
	INSERT INTO chain.card_group
	(card_group_id, name, description, helper_pkg, list_page_url)
	VALUES
	(69, 'Sheet Filter', 'Allows filtering of sheets', 'csr.sheet_report_pkg', '/csr/site/delegation/sheet2/list/List.acds?savedFilterSid=');
	
	v_card_id := chain.card_id_seq.NEXTVAL;
	
	INSERT INTO chain.card
	(card_id, description, class_type, js_include, js_class_type, css_include)
	VALUES
	(v_card_id, 'Sheet Filter', 'Credit360.Delegation.Cards.SheetDataFilter', '/csr/site/delegation/sheet2/list/filters/DataFilter.js', 'Credit360.Delegation.Sheet.Filters.DataFilter', null);
	INSERT INTO chain.filter_type (
		filter_type_id,
		description,
		helper_pkg,
		card_id
	) VALUES (
		chain.filter_type_id_seq.NEXTVAL,
		'Sheet Filter',
		'csr.sheet_report_pkg',
		v_card_id
	);
    
    INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (69, 1, 'Number of records');
    
	FOR r IN (
		SELECT host 
		  FROM csr.customer c
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		EXCEPTION
			WHEN OTHERS THEN
				CONTINUE;
		END;
		--chain.card_pkg.SetGroupCards
		SetGroupCards('Sheet Filter', chain.T_STRING_LIST('Credit360.Delegation.Sheet.Filters.DataFilter'));
	END LOOP;
	security.user_pkg.logonadmin;
END;
/




CREATE OR REPLACE PACKAGE csr.sheet_report_pkg AS END;
/
GRANT EXECUTE ON csr.sheet_report_pkg TO chain;
GRANT EXECUTE ON csr.sheet_report_pkg TO web_user; 


@..\val_datasource_pkg
@..\region_api_pkg
@..\scenario_pkg
@..\compliance_pkg
@..\chain\filter_pkg
@..\sheet_report_pkg


@..\val_datasource_body
@..\audit_body
@..\region_api_body
@..\initiative_aggr_body
@..\initiative_grid_body
@..\initiative_export_body
@..\alert_body
@..\csr_app_body
@..\scenario_body
@..\compliance_body
@..\tag_body
@..\sheet_report_body



@update_tail
