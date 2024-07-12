-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=0
define is_combined=1
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

CREATE SEQUENCE csr.flow_involvement_type_id_seq
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE SEQUENCE csr.audit_type_flw_inv_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.flow_item_involvement (
	app_sid							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	flow_item_id					NUMBER(10)	NOT NULL,
	user_sid						NUMBER(10)	NOT NULL,
	CONSTRAINT chk_fii_fit CHECK (flow_involvement_type_id >= 10000)
);

CREATE TABLE csr.audit_type_flow_inv_type (
	app_sid							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	audit_type_flow_inv_type_id		NUMBER(10)	NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	internal_audit_type_id			NUMBER(10)	NOT NULL,
	min_users						NUMBER(10)	NOT NULL,
	max_users						NUMBER(10)	NULL,
	CONSTRAINT pk_audit_type_flow_inv_type PRIMARY KEY (app_sid, audit_type_flow_inv_type_id),
	CONSTRAINT uk_audit_type_flow_inv_type UNIQUE (app_sid, flow_involvement_type_id, internal_audit_type_id),
	CONSTRAINT chk_atfit_min_max CHECK ((0 = min_users AND (max_users IS NULL OR max_users > 0)) OR (0 < min_users AND (max_users IS NULL OR min_users <= max_users)))
);

CREATE TABLE CSRIMP.FLOW_INVOLVEMENT_TYPE
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_ALERT_CLASS				VARCHAR2(256) NOT NULL,
	LABEL							VARCHAR2(256) NOT NULL,
	CSS_CLASS						VARCHAR2(256) NOT NULL,
	CONSTRAINT PK_FLOW_INV_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT FK_FLOW_INV_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_ITEM_INVOLVEMENT
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_ITEM_ID					NUMBER(10) NOT NULL,
	USER_SID						NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_ITEM_INV PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_INVOLVEMENT_TYPE_ID, FLOW_ITEM_ID, USER_SID),
	CONSTRAINT FK_FLOW_ITEM_INV_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.AUDIT_TYPE_FLOW_INV_TYPE
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	AUDIT_TYPE_FLOW_INV_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID			NUMBER(10) NOT NULL,
	MIN_USERS						NUMBER(10) NOT NULL,
	MAX_USERS						NUMBER(10),
	CONSTRAINT PK_ADT_T_FL_INV_T PRIMARY KEY (CSRIMP_SESSION_ID, AUDIT_TYPE_FLOW_INV_TYPE_ID),
	CONSTRAINT FK_ADT_T_FL_INV_T_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_FLOW_INVOLVEMENT_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10)	NOT NULL,
	NEW_FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_FLOW_INV_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FLOW_INVOLVEMENT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_FLOW_INV_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_FLOW_INVOLVEMENT_TYPE_ID) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_INV_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_AUD_TP_FLOW_INV_TP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_AUD_TP_FLOW_INV_TP_ID		NUMBER(10)	NOT NULL,
	NEW_AUD_TP_FLOW_INV_TP_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_AUD_TP_FLOW_INV_TP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_AUD_TP_FLOW_INV_TP_ID) USING INDEX,
	CONSTRAINT UK_MAP_AUD_TP_FLOW_INV_TP UNIQUE (CSRIMP_SESSION_ID, NEW_AUD_TP_FLOW_INV_TP_ID) USING INDEX,
    CONSTRAINT FK_MAP_AUD_TP_FLOW_INV_TP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
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

alter table csr.delegation
add allow_multi_period number(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.portlet
ADD (
  available_on_home_portal 		NUMBER(1) DEFAULT 1 NOT NULL,
  available_on_approval_portal 	NUMBER(1) DEFAULT 1 NOT NULL,
  available_on_chain_portal		NUMBER(1) DEFAULT 1 NOT NULL
);

ALTER TABLE csr.flow_involvement_type
ADD app_sid NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NULL;

ALTER TABLE csr.flow_state_involvement
DROP CONSTRAINT fk_flow_state_inv_inv_id;

ALTER TABLE csr.flow_transition_alert_inv
DROP CONSTRAINT fk_flow_trans_alert_inv_inv;

ALTER TABLE csr.flow_involvement_type
DROP CONSTRAINT pk_flow_involvement_type DROP INDEX;

ALTER TABLE csr.flow_involvement_type
DROP CONSTRAINT fk_flow_involv_typ_alt_cls;

BEGIN
	INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
	SELECT ia.app_sid, 'audit'
	  FROM csr.internal_audit ia
      LEFT JOIN csr.customer_flow_alert_class fac ON fac.app_sid = ia.app_sid AND fac.flow_alert_class = 'audit'
     WHERE fac.app_sid IS NULL
     GROUP BY ia.app_sid;
   
	INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
    SELECT c.app_sid, 'supplier'
	  FROM chain.company c
      LEFT JOIN csr.customer_flow_alert_class fac ON fac.app_sid = c.app_sid AND fac.flow_alert_class = 'supplier'
     WHERE fac.app_sid IS NULL
     GROUP BY c.app_sid;
	
	
	INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
	SELECT DISTINCT app_sid, 
		CASE flow_involvement_type_id
			WHEN 2 THEN 'audit'
			WHEN 1 THEN 'audit'
			WHEN 1001 THEN 'supplier'
			WHEN 1002 THEN 'supplier'
		END
	  FROM csr.flow_state_involvement
	 WHERE (app_sid, FLOW_INVOLVEMENT_TYPE_ID) not in (
		SELECT app_sid, flow_involvement_type_id
		  FROM csr.flow_involvement_type
	);
	
	FOR r IN (
		SELECT cfac.app_sid, cfac.flow_alert_class, fit.flow_involvement_type_id, fit.label, fit.css_class
		  FROM csr.customer_flow_alert_class cfac
		  JOIN csr.flow_involvement_type fit 
		    ON fit.app_sid IS NULL
		   AND fit.flow_alert_class = cfac.flow_alert_class
		   AND fit.flow_involvement_type_id < 10000
	)
	LOOP
		INSERT INTO csr.flow_involvement_type (app_sid, flow_involvement_type_id, flow_alert_class, label, css_class)
		VALUES (r.app_sid, r.flow_involvement_type_id, r.flow_alert_class, r.label, r.css_class);
	END LOOP;
	
	DELETE
	  FROM csr.flow_involvement_type
	 WHERE app_sid IS NULL;
	
	INSERT INTO csr.customer_flow_Alert_class (app_sid, flow_alert_class)
	SELECT DISTINCT app_sid, flow_alert_class
	  FROM csr.flow_involvement_type
	 WHERE (app_sid, flow_alert_class) NOT IN (
			SELECT app_sid, flow_alert_class
			  FROM csr.customer_flow_Alert_class
	 );
END;
/

ALTER TABLE csr.flow_involvement_type
MODIFY app_sid NOT NULL;

ALTER TABLE csr.flow_involvement_type
ADD CONSTRAINT pk_flow_involvement_type PRIMARY KEY (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_state_involvement
ADD CONSTRAINT fk_flow_state_inv_inv_id FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_transition_alert_inv
ADD CONSTRAINT fk_flow_trans_alert_inv_inv FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_involvement_type
ADD CONSTRAINT fk_flow_involv_typ_alt_cls FOREIGN KEY (app_sid, flow_alert_class)
REFERENCES csr.customer_flow_alert_class (app_sid, flow_alert_class);

-- Label should be unique within each app and flow type
ALTER TABLE csr.flow_involvement_type
ADD CONSTRAINT uk_label UNIQUE (app_sid, label, flow_alert_class);

-- csr.flow_item_involvement --

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT fk_fii_flow_inv_type FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT fk_fii_flow_item FOREIGN KEY (app_sid, flow_item_id)
REFERENCES csr.flow_item (app_sid, flow_item_id);

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT fk_fii_csr_user FOREIGN KEY (app_sid, user_sid)
REFERENCES csr.csr_user (app_sid, csr_user_sid);

-- csr.audit_type_flow_inv_type --

ALTER TABLE csr.audit_type_flow_inv_type
ADD CONSTRAINT fk_atfit_flow_inv_type FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.audit_type_flow_inv_type
ADD CONSTRAINT internal_audit_type_id FOREIGN KEY (app_sid, internal_audit_type_id)
REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id);

ALTER TABLE csr.aggregate_ind_val_detail
ADD LINK_URL varchar2(256);

ALTER TABLE csr.approval_dashboard_val_src
ADD LINK_URL varchar2(256);

-- *** Grants ***
grant select,insert,update on csr.PROPERTY_CHARACTER_LAYOUT to csrimp;
grant select,insert,update,delete on csrimp.property_character_layout to web_user;

GRANT INSERT ON csr.flow_involvement_type TO chain;

GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.audit_type_flow_inv_type TO web_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_item_involvement TO web_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_involvement_type TO web_user;
GRANT INSERT ON csr.audit_type_flow_inv_type TO csrimp;
GRANT INSERT ON csr.flow_item_involvement TO csrimp;
GRANT INSERT ON csr.flow_involvement_type TO csrimp;
grant select on csr.audit_type_flw_inv_type_id_seq TO csrimp;
grant select on csr.flow_involvement_type_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
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

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.SUBMIT_CONFIRMATION_TEXT as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
     AND dd.delegation_sid = d.delegation_sid  
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid 
     AND dp.delegation_sid = d.delegation_sid;
     
CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;

CREATE OR REPLACE VIEW CSR.V$AUDIT_CAPABILITY AS
	SELECT ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM internal_audit ia
	  JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN (
		SELECT fii.flow_involvement_type_id, fii.flow_item_id, fsi.flow_state_id
		  FROM flow_item_involvement fii
		  JOIN flow_state_involvement fsi 
	        ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
		 WHERE fii.user_sid = SYS_CONTEXT('SECURITY','SID')
		) finv 
		ON finv.flow_item_id = fi.flow_item_id 
	   AND finv.flow_involvement_type_id = fsrc.flow_involvement_type_id 
	   AND finv.flow_state_id = fi.current_state_id
	 WHERE ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	   AND (ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
		OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fsrc.flow_involvement_type_id = 2)	   -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
	    OR finv.flow_involvement_type_id IS NOT NULL
		OR rrm.role_sid IS NOT NULL
		OR security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16) = 1) -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
	 GROUP BY ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id;
	 
-- *** Data changes ***

INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) 
VALUES (120, 3,'mm',1000,1,0);

-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
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

BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (4, 'Toggle mutli-period delegation flag', 'Toggles the multi-period override for the specified delegation and its children. See wiki for details ("Per delegation" section)', 
		'ToggleDelegMutliPeriodFlag', 'W2324');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (4, 'Delegation sid', 'The sid of the delegation to run against', 1);
END;
/

UPDATE CSR.PORTLET
   SET 	available_on_home_portal = 0,
		available_on_chain_portal = 0
 WHERE portlet_id IN (1052, 1053, 1055);

UPDATE CSR.PORTLET
   SET	available_on_home_portal = 0,
		available_on_approval_portal = 0
 WHERE LOWER(type) LIKE 'credit360.portlets.chain.%'
    OR portlet_id IN (543, 803, 683, 563, 1044, 1043);

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
@..\tests\test_cms_user_cover_pkg
@..\delegation_pkg
@..\util_script_pkg
@..\portlet_pkg
@..\flow_pkg
@..\audit_pkg

@..\section_body
@..\approval_dashboard_body
@..\audit_body
@..\flow_body
@..\schema_body
@..\csrimp\imp_body
@..\portlet_body
@..\delegation_body
@..\util_script_body
@..\csr_app_body
@..\property_body
@..\property_report_body
@..\region_metric_body
@..\indicator_body
@..\tag_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body
@..\chain\setup_body
@..\non_compliance_report_body
@..\recurrence_pattern_body
@..\recurrence_pattern_pkg
@..\ruleset_body
@..\tests\test_cms_user_cover_body
@..\csr_data_body

@update_tail
