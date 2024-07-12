-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSRIMP.PROPERTY_CHARACTER_LAYOUT (
    CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ELEMENT_NAME 					VARCHAR2(255) NOT NULL,
    POS 							NUMBER(10,0) NOT NULL,
    COL 							NUMBER(10,0) NOT NULL,
	IND_SID							NUMBER(10),
	TAG_GROUP_ID					NUMBER(10),
    CONSTRAINT PK_PROPERTY_CHARACTER_LAYOUT PRIMARY KEY (CSRIMP_SESSION_ID, ELEMENT_NAME),
	CONSTRAINT FK_PROPERTY_CHAR_LAYOUT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE,
	CONSTRAINT CHK_PROP_CHAR_LAYT_IND_TG_GRP 
		CHECK ((ind_sid IS NULL AND tag_group_id IS NULL) OR (ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);

-- Alter tables
ALTER TABLE csr.property_element_layout ADD (
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT fk_prop_el_layout_reg_metric FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT fk_property_el_layout_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group,
	CONSTRAINT chk_prop_el_layout_ind_tg_grp 
		CHECK ((ind_sid IS NULL AND tag_group_id IS NULL) OR (ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);
CREATE UNIQUE INDEX csr.idx_prop_el_layout_ind_sid ON csr.property_element_layout(app_sid, NVL(TO_CHAR(ind_sid), element_name));
CREATE UNIQUE INDEX csr.idx_prop_el_layout_tag_grp_id ON csr.property_element_layout(app_sid, NVL(TO_CHAR(tag_group_id), element_name));

-- csrexp/imp

ALTER TABLE csr.property_character_layout ADD (
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT fk_prop_char_layt_reg_metric FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT fk_property_char_layt_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group,
	CONSTRAINT chk_prop_char_layt_ind_tg_grp 
		CHECK ((ind_sid IS NULL AND tag_group_id IS NULL) OR (ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);

CREATE UNIQUE INDEX csr.idx_prop_chr_layout_ind_sid ON csr.property_character_layout(app_sid, NVL(TO_CHAR(ind_sid), element_name));
CREATE UNIQUE INDEX csr.idx_prop_chr_layout_tag_grp_id ON csr.property_character_layout(app_sid, NVL(TO_CHAR(tag_group_id), element_name));


ALTER TABLE csrimp.property_element_layout ADD (
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT chk_prop_el_layout_ind_tg_grp 
		CHECK ((ind_sid IS NULL AND tag_group_id IS NULL) OR (ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);

ALTER TABLE cms.tab ADD (
	show_in_property_filter			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_tab_show_in_prop_filter CHECK (show_in_property_filter IN (0,1))
);

ALTER TABLE csrimp.cms_tab ADD show_in_property_filter NUMBER(1) NULL;
UPDATE csrimp.cms_tab SET show_in_property_filter = 0 WHERE show_in_property_filter IS NULL;
ALTER TABLE csrimp.cms_tab MODIFY show_in_property_filter NOT NULL;
ALTER TABLE csrimp.cms_tab ADD CONSTRAINT chk_tab_show_in_prop_filter CHECK (show_in_property_filter IN (0,1));

-- *** Grants ***
grant select,insert,update on csr.PROPERTY_CHARACTER_LAYOUT to csrimp;
grant select,insert,update,delete on csrimp.property_character_layout to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
-- @..\create_views
CREATE OR REPLACE VIEW csr.v$region_metric_val_converted AS
	SELECT rmv.app_sid, rmv.region_sid, rmv.ind_sid, rmv.effective_dtm, rmv.entered_by_sid, rmv.entered_dtm, 
	       rmv.val, rmv.note, rmv.region_metric_val_id, rmr.source_type_id, rmr.measure_sid, rmr.measure_conversion_id,
		   ROUND(NVL(NVL(mc.a, mcp.a), 1) * POWER(rmv.val, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0),10) base_val_number
	  FROM region_metric_val rmv
	  JOIN region_metric_region rmr ON rmv.app_sid = rmr.app_sid AND rmv.region_sid = rmr.region_sid AND rmv.ind_sid = rmr.ind_sid
	  LEFT JOIN measure_conversion mc ON rmr.measure_conversion_id = mc.measure_conversion_id
	  LEFT JOIN measure_conversion_period mcp ON mc.measure_conversion_id = mcp.measure_conversion_id
	 WHERE (rmv.effective_dtm >= mcp.start_dtm OR mcp.start_dtm is null)
	   AND (rmv.effective_dtm < mcp.end_dtm OR mcp.end_dtm is null);   

-- *** Data changes ***
-- RLS
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'PROPERTY_CHARACTER_LAYOUT',
		policy_name     => 'PROPERTY_CHARACTER_LAYOUT', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
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
	v_desc := 'Property Filter';
	v_class := 'Credit360.Property.Cards.PropertyFilter';
	v_js_path := '/csr/site/property/properties/filters/PropertyFilter.js';
	v_js_class := 'Credit360.Property.Filters.PropertyFilter';
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

	-- Credit360.Property.Filters.PropertyCmsFilter
	v_desc := 'Property CMS Filter';
	v_class := 'Credit360.Property.Cards.PropertyCmsFilter';
	v_js_path := '/csr/site/property/properties/filters/PropertyCmsFilter.js';
	v_js_class := 'Credit360.Property.Filters.PropertyCmsFilter';
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
	
	-- Credit360.Property.Filters.PropertyIssuesFilter
	v_desc := 'Property Issues Filter';
	v_class := 'Credit360.Property.Cards.PropertyIssuesFilter';
	v_js_path := '/csr/site/property/properties/filters/PropertyIssuesFilter.js';
	v_js_class := 'Credit360.Property.Filters.PropertyIssuesFilter';
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
		VALUES(44, 'Property Filter', 'Allows filtering of properties', 'csr.property_report_pkg', '/csr/site/property/properties/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Property.Filters.PropertyFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Property Filter', 'csr.property_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with properties
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
		 WHERE property_flow_sid IS NOT NULL
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 44, v_card_id, 0);
	END LOOP;
END;
/

DECLARE
	v_card_id	NUMBER(10);
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Property.Filters.PropertyCmsFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Property CMS Filter', 'csr.property_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with properties
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
		 WHERE property_flow_sid IS NOT NULL
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 44, v_card_id, 1);
	END LOOP;
END;
/

DECLARE
	v_card_id	NUMBER(10);
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Property.Filters.PropertyIssuesFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Property Issues Filter', 'csr.property_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with issues property tab enabled.
	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
		 WHERE property_flow_sid IS NOT NULL
		   AND app_sid IN (
				SELECT pt.app_sid
				  FROM csr.property_tab pt
				  JOIN csr.plugin p ON pt.plugin_id = p.plugin_id
				 WHERE p.js_class = 'Controls.IssuesPanel'
		)
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		SELECT r.app_sid, 44, v_card_id, MAX(position) + 1
		  FROM chain.card_group_card
		 WHERE app_sid = r.app_sid
		   AND card_group_id = 44;
	END LOOP;
END;
/


INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
     VALUES (44, 1, 'Number of properties');

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.property_report_pkg AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY csr.property_report_pkg AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/
GRANT EXECUTE ON csr.property_report_pkg TO web_user;
GRANT EXECUTE ON csr.property_report_pkg TO chain;


-- Replaced constants with vals for change script.
-- INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
-- VALUES (chain.filter_pkg.FILTER_TYPE_PROPERTY, csr.property_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Property region');
INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
VALUES (44, 1, 1, 'Property region');


-- Property filtering.
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'REGION_SID', 'Region Sid', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'DESCRIPTION', 'Property description', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'PROPERTY_TYPE_LABEL', 'Site type', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'CURRENT_STATE_LABEL', 'Current property state', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'STREET_ADDR_1', 'Property street address 1', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'STREET_ADDR_2', 'Property street address 2', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'CITY', 'Property city', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'STATE', 'Property state', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'POSTCODE', 'Property postcode', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'COUNTRY_NAME', 'Property country', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'LOOKUP_KEY', 'Property lookup key', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (44, 'PROPERTY_LINK', 'Property link', 0, NULL);
	
END;
/

-- enable property cms filtering on tables that are used in the property plugins
UPDATE cms.tab
   SET show_in_property_filter = 1
 WHERE (app_sid, tab_sid) IN (
	SELECT app_sid, tab_sid
	  FROM csr.plugin
	 WHERE plugin_type_id = 1
	   AND tab_sid IS NOT NULL
);

-- turn off charting on all numbers by default, we don't know the useful ones
UPDATE cms.tab_column
   SET show_in_breakdown = 0
 WHERE col_type = 0 
   AND data_type = 'NUMBER';


-- *** Packages ***
@..\chain\filter_pkg
@..\property_pkg
@..\property_report_pkg
@..\region_metric_pkg
@..\schema_pkg
@..\..\..\aspen2\cms\db\filter_pkg

@..\csr_app_body
@..\csrimp\imp_body
@..\property_body
@..\property_report_body
@..\region_metric_body
@..\indicator_body
@..\schema_body
@..\tag_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
