define version=3441
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



ALTER TABLE csr.customer
MODIFY enable_java_auth DEFAULT 1;
ALTER TABLE csrimp.customer
ADD ENABLE_JAVA_AUTH NUMBER(1) NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD RENDER_CHARTS_AS_SVG NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_RENDER_CHARTS_AS_SVG CHECK (RENDER_CHARTS_AS_SVG IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD RENDER_CHARTS_AS_SVG NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (RENDER_CHARTS_AS_SVG DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_RENDER_CHARTS_AS_SVG CHECK (RENDER_CHARTS_AS_SVG IN (0,1));










DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM csr.util_script
	 WHERE util_script_id = 74;
	 
	IF v_exists = 0 THEN  
		INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
		VALUES (74, 'Trigger logistics recalculation', 'Trigger a recalculation by logistics service for a given transport mode', 'RecalcLogistics');
		INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
		VALUES (74, 'Transport mode', '(1 Air, 2 Sea, 3 Road, 4 Barge, 5 Rail)', 0);
	END IF;
END;
/
DECLARE
	v_superadmin_users_sid		security.security_pkg.T_SID_ID;
	v_app_users_sid				security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE enable_java_auth = 0
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_app_users_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, r.app_sid, 'Users');
	
		UPDATE csr.customer
		   SET enable_java_auth = 1
		 WHERE customer.app_sid = r.app_sid;
		-- Apply to users that are directly owned by the site (i.e. exclude super admins, but include trashed users)
		FOR u IN (SELECT cu.csr_user_sid
					FROM csr.csr_user cu
					JOIN security.securable_object so ON so.sid_id = cu.csr_user_sid
			   LEFT JOIN csr.trash t ON t.app_sid = so.application_sid_id AND t.trash_sid = so.sid_id
				   WHERE so.parent_sid_id = v_app_users_sid OR t.previous_parent_sid = v_app_users_sid)
		LOOP
			security.user_pkg.EnableJavaAuth(u.csr_user_sid);
		END LOOP;
		
		COMMIT;
	END LOOP;
	
	security.user_pkg.logonadmin;
	
	-- Migrate SuperAdmins.
	v_superadmin_users_sid := security.securableobject_pkg.GetSidFromPath_(0,'CSR/Users');
	
	FOR s IN (
		SELECT sid_id
		  FROM security.securable_object
		 WHERE parent_sid_id = v_superadmin_users_sid
	)
	LOOP
		security.user_pkg.EnableJavaAuth(s.sid_id);
	END LOOP;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
	VALUES (75, 'Toggle render charts as SVG', 'Toggles between rendering charts as SVG or PNG (Default, historic behaviour)', 'ToggleRenderChartsAsSvg');
END;
/






@..\deleg_plan_pkg
@..\util_script_pkg
@..\unit_test_pkg
@..\baseline_pkg
@..\customer_pkg


@..\deleg_plan_body
@..\region_body
@..\chain\bsci_body
@..\util_script_body
@..\csrimp\imp_body
@..\schema_body
@..\unit_test_body
@..\baseline_body
@..\customer_body
@..\audit_body
@..\calc_body



@update_tail
