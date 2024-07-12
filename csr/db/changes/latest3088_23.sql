-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_options ADD (
	permit_score_type_id NUMBER(10),
	CONSTRAINT FK_COMP_OPT_PERM_SCORE_TYPE FOREIGN KEY (app_sid, permit_score_type_id) REFERENCES csr.score_type(app_sid, score_type_id)
);

CREATE INDEX csr.ix_comp_op_perm_score_type_id ON csr.compliance_options (app_sid, permit_score_type_id);

ALTER TABLE csrimp.compliance_options ADD (
	permit_score_type_id NUMBER(10)
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

/* TODO 
	change fs.label to fsn.label before commit
*/
CREATE OR REPLACE VIEW csr.v$permit_item_rag AS 
	SELECT t.region_sid, t.total_items, t.compliant_items, t.pct_compliant, 
		TRIM(TO_CHAR ((
			SELECT DISTINCT FIRST_VALUE(text_colour)
			  OVER (ORDER BY st.max_value ASC) AS text_colour
			  FROM csr.compliance_options co
			  JOIN csr.score_threshold st ON co.permit_score_type_id = st.score_type_id AND st.app_sid = co.app_sid
			 WHERE co.app_sid = security.security_pkg.GetApp
				 AND t.pct_compliant <= st.max_value
		), 'XXXXXX')) pct_compliant_colour
	FROM (
		SELECT app_sid, region_sid, total_items, compliant_items, DECODE(total_items, 0, 0, ROUND(100*compliant_items/total_items)) pct_compliant
		 FROM (
		 SELECT cp.app_sid, cp.region_sid, SUM(DECODE(cpc.condition_type_id, NULL, NULL, 1)) total_items, SUM(DECODE(LOWER(fsn.label), 'compliant', 1, 0)) compliant_items
		  FROM csr.compliance_permit cp
		  LEFT JOIN csr.compliance_permit_condition cpc ON cpc.compliance_permit_id = cp.compliance_permit_id
		  LEFT JOIN csr.compliance_item_region cir ON cpc.compliance_item_id = cir.compliance_item_id
		  LEFT JOIN csr.flow_item fi ON fi.flow_item_id = cir.flow_item_id
		  LEFT JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN csr.flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
		 WHERE lower(fsn.label) != 'inactive'
		 GROUP BY cp.app_sid, cp.region_sid
		)
		ORDER BY region_sid
	) t
;


-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
VALUES (1066, 'Site permit compliance levels', 'Credit360.Portlets.SitePermitComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/SitePermitComplianceLevels.js');

DECLARE
	v_score_type_id 			NUMBER(10);
	v_ehs_managers_sid			NUMBER(10);
	v_portlet_ehs_mgr_tab_id	NUMBER(10);
	v_portlet_sid				NUMBER(10);
	v_tab_portlet_id			NUMBER(10);
	v_act_id					security.security_pkg.T_ACT_ID;
	v_groups_sid				NUMBER(10);
	PROCEDURE AddTabReturnTabId(
		in_app_sid		IN	security.security_pkg.T_SID_ID,
		in_tab_name		IN	csr.tab.name%TYPE,
		in_is_shared 	IN	csr.tab.is_shared%TYPE,
		in_is_hideable	IN	csr.tab.is_hideable%TYPE,
		in_layout		IN	csr.tab.layout%TYPE,
		in_portal_group	IN	csr.tab.portal_group%TYPE,
		out_tab_id		OUT	csr.tab.tab_id%TYPE
	)
	AS
		v_user_sid	security.security_pkg.T_SID_ID;
		v_max_pos 	csr.tab_user.pos%TYPE;
		v_tab_id	csr.tab.tab_id%TYPE;
	BEGIN
		v_user_sid := security.security_pkg.GetSID();

		SELECT NVL(MAX(pos),0)
			INTO v_max_pos
			FROM csr.v$tab_user
		 WHERE user_sid = v_user_sid
			 AND app_sid = in_app_sid;

		-- create a new tab
		INSERT INTO csr.TAB
			(tab_id, layout, name, app_sid, is_shared, is_hideable, portal_group)
		VALUES
			(csr.tab_id_seq.nextval, in_layout, in_tab_name, in_app_sid, in_is_shared, in_is_hideable, in_portal_group)
		RETURNING tab_id INTO v_tab_id;

		-- make user the owner
		INSERT INTO csr.TAB_USER
			(tab_id, user_sid, pos, is_owner)
		VALUES
			(v_tab_id, v_user_sid, v_max_pos+1, 1);
			
		out_tab_id := v_tab_id;
	END;
	
	FUNCTION GetOrCreateCustomerPortlet (
		in_portlet_type					IN  csr.portlet.type%TYPE
	) RETURN NUMBER
	AS
		v_portlet_id					csr.portlet.portlet_id%TYPE;
		v_portlet_sid					security.security_pkg.T_SID_ID;
		v_portlet_enabled				NUMBER;
		PROCEDURE EnablePortletForCustomer(
			in_portlet_id	IN csr.portlet.portlet_id%TYPE
		)
		AS
			v_customer_portlet_sid		security.security_pkg.T_SID_ID;
			v_type						csr.portlet.type%TYPE;
		BEGIN
			SELECT type
			  INTO v_type
			  FROM csr.portlet
			 WHERE portlet_id = in_portlet_id;
			
			BEGIN
				v_customer_portlet_sid := security.securableobject_pkg.GetSIDFromPath(
						SYS_CONTEXT('SECURITY','ACT'),
						SYS_CONTEXT('SECURITY','APP'),
						'Portlets/' || v_type);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
						security.securableobject_pkg.GetSIDFromPath(
							SYS_CONTEXT('SECURITY','ACT'),
							SYS_CONTEXT('SECURITY','APP'),
							'Portlets'),
						security.class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
			END;
		
			BEGIN
				INSERT INTO csr.customer_portlet
						(portlet_id, customer_portlet_sid, app_sid)
				VALUES
						(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
						NULL;
			END;
		END;
	BEGIN
		SELECT portlet_id
		  INTO v_portlet_id
		  FROM csr.portlet
		 WHERE type = in_portlet_type;
	
		SELECT COUNT(*)
		  INTO v_portlet_enabled
		  FROM csr.customer_portlet
		 WHERE portlet_id = v_portlet_id;
	
		IF v_portlet_enabled = 0 THEN
			EnablePortletForCustomer(v_portlet_id);
		END IF;
	
		SELECT customer_portlet_sid
		  INTO v_portlet_sid
		  FROM csr.customer_portlet
		 WHERE portlet_id = v_portlet_id;
		 
		RETURN v_portlet_sid;
	END;
	
	PROCEDURE AddPortletToTab(
		in_tab_id				IN	csr.tab_portlet.tab_id%TYPE,
		in_customer_portlet_sid	IN	csr.tab_portlet.customer_portlet_sid%TYPE,
		in_initial_state		IN	csr.tab_portlet.state%TYPE,
		out_tab_portlet_id		OUT	csr.tab_portlet.tab_portlet_id%TYPE
	)
	AS
		v_count					NUMBER(10);
	BEGIN
		-- move all portlets in first column position below
		UPDATE csr.TAB_PORTLET
			 SET pos = pos + 1
		 WHERE TAB_ID = in_tab_id
			 AND column_num = 0;
		
		INSERT INTO csr.TAB_PORTLET
			(customer_portlet_sid, tab_portlet_id, tab_id, column_num, pos, state)
		VALUES	
			(in_customer_portlet_sid, csr.tab_portlet_id_seq.nextval, in_tab_id, 0, 0, in_initial_state)
		RETURNING tab_portlet_id INTO out_tab_portlet_id;
	END;
BEGIN
	security.user_pkg.logonadmin();
	
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_flow_sid IS NOT NULL
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			
			INSERT INTO csr.score_type (score_type_id, label, pos, hidden, allow_manual_set, lookup_key, applies_to_supplier, reportable_months)
			VALUES (csr.score_type_id_seq.nextval, 'Permit RAG', 0, 0, 0, 'PERMIT_RAG', 0, 0)
			RETURNING score_type_id INTO v_score_type_id;

			INSERT INTO csr.score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
			VALUES (csr.score_threshold_id_seq.NEXTVAL, 'Poor',	89, 16712965, 16712965,	16712965, v_score_type_id);
			INSERT INTO csr.score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
			VALUES (csr.score_threshold_id_seq.NEXTVAL, 'Low',	94, 16770048, 16770048,	16770048, v_score_type_id);
			INSERT INTO csr.score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
			VALUES (csr.score_threshold_id_seq.NEXTVAL, 'Good',	100, 3777539, 3777539,	3777539, v_score_type_id);

			UPDATE csr.compliance_options SET permit_score_type_id = v_score_type_id;
			
			v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
			v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'Groups');
			v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
			
			SELECT MIN(tab_id)
			  INTO v_portlet_ehs_mgr_tab_id
			  FROM csr.tab
			 WHERE name = 'Permit compliance';
		
			 IF v_portlet_ehs_mgr_tab_id IS NULL THEN
		 		AddTabReturnTabId(
		 			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
		 			in_tab_name => 'Permit compliance',
		 			in_is_shared => 1,
		 			in_is_hideable => 1,
		 			in_layout => 6,
		 			in_portal_group => NULL,
		 			out_tab_id => v_portlet_ehs_mgr_tab_id
		 		);
		 	END IF;
			
			-- Add permissions on tabs.
			BEGIN
				INSERT INTO csr.tab_group(group_sid, tab_id)
				VALUES(v_ehs_managers_sid, v_portlet_ehs_mgr_tab_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		
			-- EHS Manager portlet tab contents.	
			v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.GeoMap');

			AddPortletToTab(
				in_tab_id => v_portlet_ehs_mgr_tab_id,
				in_customer_portlet_sid => v_portlet_sid,
				in_initial_state => '{"portletHeight":460,"pickerMode":0,"filterMode":0,"selectedRegionList":[],"includeInactiveRegions":false,"colourBy":"permitRag","portletTitle":"Site Permit RAG Status"}',
				out_tab_portlet_id => v_tab_portlet_id
			);
			
			v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.SitePermitComplianceLevels');
			
			AddPortletToTab(
				in_tab_id => v_portlet_ehs_mgr_tab_id,
				in_customer_portlet_sid => v_portlet_sid,
				in_initial_state => '',
				out_tab_portlet_id => v_tab_portlet_id
			);
				
			UPDATE csr.tab_portlet
			   SET column_num = 1, pos = 1
			 WHERE tab_portlet_id = v_tab_portlet_id;
			
			security.user_pkg.logonadmin();
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- Must have been enabled already
				NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg

@../geo_map_body
@../permit_body
@../property_report_body
@../schema_body
@../enable_body

@../csrimp/imp_body

@update_tail
