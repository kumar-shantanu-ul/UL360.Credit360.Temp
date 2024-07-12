-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.filter_page_column (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	column_name				VARCHAR2(255) NOT NULL,
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	width					NUMBER(10) DEFAULT 150 NOT NULL,
	fixed_width				NUMBER(1) DEFAULT 0 NOT NULL,
	hidden					NUMBER(1) DEFAULT 0 NOT NULL,
	group_sid				NUMBER(10),
	CONSTRAINT pk_filter_page_column PRIMARY KEY (app_sid, card_group_id, column_name),
	CONSTRAINT chk_fltr_pg_col_fix_width_1_0 CHECK (fixed_width IN (1, 0)),
	CONSTRAINT chk_fltr_pg_col_hidden_1_0 CHECK (hidden IN (1, 0)),
	CONSTRAINT fk_fltr_pkg_col_app_sid FOREIGN KEY (app_sid)
		REFERENCES csr.customer (app_sid),
	CONSTRAINT fk_fltr_pg_col_card_group FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_fltr_pg_col_group_sid FOREIGN KEY (group_sid)
		REFERENCES security.group_table (sid_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.chain_filter_page_column (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	column_name				VARCHAR2(255) NOT NULL,
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	width					NUMBER(10) DEFAULT 150 NOT NULL,
	fixed_width				NUMBER(1) DEFAULT 0 NOT NULL,
	hidden					NUMBER(1) DEFAULT 0 NOT NULL,
	group_sid				NUMBER(10),
	CONSTRAINT pk_filter_page_column PRIMARY KEY (csrimp_session_id, card_group_id, column_name),
	CONSTRAINT chk_fltr_pg_col_fix_width_1_0 CHECK (fixed_width IN (1, 0)),
	CONSTRAINT chk_fltr_pg_col_hidden_1_0 CHECK (hidden IN (1, 0)),
	CONSTRAINT fk_chain_fltr_page_column_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.temp_initiative ADD (
	POS						NUMBER(10)
);

ALTER TABLE chain.tt_filter_object_data ADD (filter_value_id NUMBER(10));
ALTER TABLE chain.tt_filter_object_data DROP CONSTRAINT pk_filter_obj_data DROP INDEX;
ALTER TABLE chain.tt_filter_object_data ADD CONSTRAINT uk_filter_obj_data UNIQUE (data_type_id, agg_type_id, object_id, filter_value_id);

grant select, references on csr.ind to chain;
grant select, references on csr.initiative_metric to chain;

grant select on chain.aggregate_type to csr;
grant select on csr.v$ind to chain;

ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT chk_svd_fil_agg_type;
ALTER TABLE chain.saved_filter_aggregation_type ADD (
	initiative_metric_id	NUMBER(10),
	ind_sid					NUMBER(10),
	CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL))
);

ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT FK_SVD_FIL_AGG_TYP_INIT_METRIC
	FOREIGN KEY (APP_SID, INITIATIVE_METRIC_ID)
	REFERENCES CSR.INITIATIVE_METRIC(APP_SID, INITIATIVE_METRIC_ID)
	ON DELETE CASCADE;
	
ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT FK_SVD_FIL_AGG_TYP_IND
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES CSR.IND(APP_SID, IND_SID)
	ON DELETE CASCADE;

-- *** Grants ***
grant select, insert, update on chain.filter_page_column to csrimp;
grant select, insert, update, delete on csrimp.chain_filter_page_column to web_user;
grant select on chain.filter_page_column to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
--@..\create_views
CREATE OR REPLACE VIEW csr.v$my_initiatives AS
	SELECT  i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		r.role_sid, r.name role_name,
		MAX(fsr.is_editable) is_editable,
		rg.active,
		null owner_sid, i.internal_ref, i.name, i.project_sid
		FROM  region_role_member rrm
		JOIN  role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
		JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
		JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
		JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
		JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
	 WHERE  rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		r.role_sid, r.name,
		rg.active, i.internal_ref, i.name, i.project_sid
	 UNION ALL
	SELECT  i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		null role_sid,  null role_name,
		MAX(igfs.is_editable) is_editable,
		rg.active,
		iu.user_sid owner_sid, i.internal_ref, i.name, i.project_sid
		FROM initiative_user iu
		JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
		JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
		JOIN initiative_project_user_group ipug 
		ON iu.initiative_user_group_id = ipug.initiative_user_group_id
		 AND iu.project_sid = ipug.project_sid
		JOIN initiative_group_flow_state igfs
		ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
		 AND ipug.project_sid = igfs.project_sid
		 AND ipug.app_sid = igfs.app_sid
		 AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
		JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
		LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
	 WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		rg.active, iu.user_sid, i.internal_ref, i.name, i.project_sid;

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
		   AND t.table_name IN ('CHAIN_FILTER_PAGE_COLUMN')
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

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
		'FILTER_PAGE_COLUMN'
    );
    FOR I IN 1 .. v_list.count
 	LOOP
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23) || '_POLICY', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

-- Data
-- output from chain.card_pkg.dumpcard
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
	v_desc := 'Initiative Filter';
	v_class := 'Credit360.Initiatives.Cards.InitiativeFilter';
	v_js_path := '/csr/site/initiatives/filters/InitiativeFilter.js';
	v_js_class := 'Credit360.Initiatives.Filters.InitiativeFilter';
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
		VALUES(45, 'Initiative Filter', 'Allows filtering of initiatives', 'csr.initiative_report_pkg', '/csr/site/initiatives/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Initiatives.Filters.InitiativeFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Initiative Filter', 'csr.initiative_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.initiatives_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 45, v_card_id, 0);
	END LOOP;
END;
/

INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
     VALUES (45, 1, 'Number of initiatives');
	 
-- Replaced constants with vals for change script.
-- INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
-- VALUES (chain.filter_pkg.FILTER_TYPE_INITIATIVES, csr.initiative_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Initiative region');
INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
VALUES (45, 1, 1, 'Initiative region');


-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.initiative_report_pkg AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY csr.initiative_report_pkg AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/
GRANT EXECUTE ON csr.initiative_report_pkg TO web_user;
GRANT EXECUTE ON csr.initiative_report_pkg TO chain;



-- *** Packages ***
@..\chain\filter_pkg
@..\initiative_pkg
@..\initiative_report_pkg
@..\initiative_grid_pkg
@..\property_report_pkg
@..\schema_pkg

@..\chain\filter_body
@..\initiative_body
@..\initiative_report_body
@..\initiative_grid_body
@..\property_report_body
@..\non_compliance_report_body
@..\csrimp\imp_body
@..\schema_body

@update_tail
