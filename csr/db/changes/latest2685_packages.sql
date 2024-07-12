--CMS
CREATE OR REPLACE PACKAGE CMS.TMP_TAB_PKG
AS

PROCEDURE tmp_FillTabSidOracleNames(
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	out_tab_sid				OUT	security_pkg.T_SID_ID,
	out_oracle_schema		OUT cms.tab.oracle_schema%TYPE,
	out_oracle_table		OUT cms.tab.oracle_table%TYPE,
	out_flow_item_col_name	OUT cms.tab_column.oracle_column%TYPE
);

FUNCTION tmp_GetFlowRoleSid(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE, 
	in_col_sid			IN	cms.tab_column.column_sid%TYPE
)RETURN security_pkg.T_SID_ID;

FUNCTION tmp_GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

PROCEDURE tmp_GenerateUserColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN  csr.flow_state_transition.flow_state_transition_id%TYPE
);

PROCEDURE tmp_GenerateRoleColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN	csr.flow_state_transition.flow_state_transition_id%TYPE,
	in_region_sids_t			IN	security.T_SID_TABLE
);

END;
/






CREATE OR REPLACE PACKAGE BODY CMS.TMP_TAB_PKG
AS

PROCEDURE tmp_FillTabSidOracleNames(
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	out_tab_sid				OUT	security_pkg.T_SID_ID,
	out_oracle_schema		OUT cms.tab.oracle_schema%TYPE,
	out_oracle_table		OUT cms.tab.oracle_table%TYPE,
	out_flow_item_col_name	OUT cms.tab_column.oracle_column%TYPE
)
AS
BEGIN
	SELECT tab_sid, oracle_schema, oracle_table
	  INTO out_tab_sid, out_oracle_schema, out_oracle_table
	  FROM cms.tab t
	  JOIN csr.flow_item fi ON fi.flow_sid = t.flow_sid
	 WHERE fi.flow_item_id = in_flow_item_id;
	 	 	 
	SELECT oracle_column
	  INTO out_flow_item_col_name
	  FROM cms.tab_column
	 WHERE tab_sid = out_tab_sid
	   AND col_type = 23 /* tab_pkg.CT_FLOW_ITEM */; 
END;

FUNCTION tmp_GetFlowRoleSid(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE, 
	in_col_sid			IN	cms.tab_column.column_sid%TYPE
)RETURN security_pkg.T_SID_ID
AS 
	v_role_sid				security_pkg.T_SID_ID;
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			cms.tab.oracle_schema%TYPE;
	v_oracle_table			cms.tab.oracle_table%TYPE;
	v_flow_item_col_name	cms.tab_column.oracle_column%TYPE;
	v_role_col_name			cms.tab_column.oracle_column%TYPE;
BEGIN
	tmp_FillTabSidOracleNames(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
	
	SELECT oracle_column
	  INTO v_role_col_name
	  FROM cms.tab_column tc
	 WHERE column_sid = in_col_sid;
	 
	EXECUTE IMMEDIATE 
		'SELECT ' || v_role_col_name || '
		   FROM '|| v_oracle_schema || '.' || v_oracle_table || ' 
		  WHERE '|| v_flow_item_col_name || ' = :flow_item_id'
		   INTO v_role_sid
		  USING in_flow_item_id;
	
	RETURN v_role_sid;
END;

FUNCTION tmp_GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
BEGIN
	cms.tmp_tab_pkg.tmp_FillTabSidOracleNames(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
	
	FOR r IN ( 
		SELECT oracle_column
		  FROM cms.tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type =  24 /* CT_FLOW_REGION */
	)
	LOOP
		--BEGIN
			EXECUTE IMMEDIATE 
				'SELECT ' || r.oracle_column || '
				   FROM '|| v_oracle_schema || '.' || v_oracle_table || ' 
				  WHERE '|| v_flow_item_col_name || ' = :flow_item_id'
				   INTO v_region_sid
				  USING in_flow_item_id; 
				
			v_region_sids_t.extend;  
			v_region_sids_t(v_region_sids_t.COUNT) := v_region_sid;
		--EXCEPTION WHEN OTHERS THEN
		--	RAISE_APPLICATION_ERROR(-20001, 'Table:' || v_oracle_schema || '.' || v_oracle_table || ', flow item: '||in_flow_item_id||' ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
		--END;
	END LOOP;
	
	RETURN v_region_sids_t;
END;

PROCEDURE tmp_GenerateUserColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN  csr.flow_state_transition.flow_state_transition_id%TYPE
)
AS
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			cms.tab.oracle_schema%TYPE;
	v_oracle_table			cms.tab.oracle_table%TYPE;
	v_oracle_column			cms.tab_column.oracle_column%TYPE;
	v_flow_item_col_name	cms.tab_column.oracle_column%TYPE;
	v_coverable				cms.tab_column.coverable%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	tmp_FillTabSidOracleNames(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);

	FOR r IN(
		SELECT fi.app_sid, fta.flow_transition_alert_id, ftacc.alert_manager_flag,
			in_set_by_user_sid, tc.column_sid, in_flow_item_id, in_flow_state_log_id
		  FROM csr.flow_item fi 
		  JOIN csr.flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN csr.flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN csr.flow_transition_alert_cms_col ftacc ON fta.flow_transition_alert_id = ftacc.flow_transition_alert_id
		  JOIN cms.tab_column tc ON ftacc.column_sid = tc.column_sid
		 WHERE fi.app_sid = security_pkg.getApp
		   AND fi.flow_item_id = in_flow_item_id
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
		   AND tc.col_type IN (cms.tab_pkg.CT_USER, cms.tab_pkg.CT_OWNER_USER)
		   AND ftacc.alert_manager_flag IN (0, 1, 2) --TODO: add check constraint
	)
	LOOP
				
		SELECT oracle_column, coverable
		  INTO v_oracle_column, v_coverable
		  FROM cms.tab_column
		 WHERE column_sid = r.column_sid;	
		
		EXECUTE IMMEDIATE 
		'SELECT '|| v_oracle_column || '
		   FROM '|| v_oracle_schema || '.' || v_oracle_table || ' 
		  WHERE '|| v_flow_item_col_name || ' = :flow_item_id '
		   INTO v_user_sid
		  USING in_flow_item_id;
		
		IF v_user_sid IS NOT NULL THEN
		
			IF r.alert_manager_flag IN (0, 2) THEN --AlertUserOnly, AlertUserAndManager
				--add user col type users
				INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
					from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
				SELECT r.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, 
					in_set_by_user_sid, v_user_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id
				  FROM dual
				 WHERE NOT EXISTS(
					SELECT 1 
					  FROM csr.flow_item_generated_alert figa
					 WHERE figa.app_sid = r.app_sid
					   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
					   AND figa.flow_state_log_id = in_flow_state_log_id
					   AND figa.to_user_sid = v_user_sid
				  );
				
				--find coverable
				IF v_coverable = 1 THEN 
					FOR j IN (
						SELECT user_giving_cover_sid
						  FROM csr.user_cover
						 WHERE user_being_covered_sid = v_user_sid
						   AND start_dtm < SYSDATE
						   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
						   AND cover_terminated = 0
						   AND user_giving_cover_sid <> v_user_sid
					)
					LOOP
						INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
							from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
						SELECT r.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, 
							in_set_by_user_sid, j.user_giving_cover_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id
						  FROM dual
						 WHERE NOT EXISTS(
							SELECT 1 
							  FROM csr.flow_item_generated_alert figa
							 WHERE figa.app_sid = r.app_sid
							   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
							   AND figa.flow_state_log_id = in_flow_state_log_id
							   AND figa.to_user_sid = j.user_giving_cover_sid
						  );
				
					END LOOP;
				END IF;
			END IF;
			--line managers
			IF r.alert_manager_flag IN (1, 2) THEN--AlertUserManagerOnly, AlertUserAndManager
				INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
							from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
				SELECT r.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, 
							in_set_by_user_sid, line_manager_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id
				  FROM csr.csr_user
				 WHERE csr_user_sid = v_user_sid
				   AND line_manager_sid IS NOT NULL
				   AND line_manager_sid <> v_user_sid
				   AND NOT EXISTS(
						SELECT 1 
						  FROM csr.flow_item_generated_alert figa
						 WHERE figa.app_sid = r.app_sid
						   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
						   AND figa.flow_state_log_id = in_flow_state_log_id
						   AND figa.to_user_sid = line_manager_sid
					);
			END IF;
		END IF;
	END LOOP;	
END;

PROCEDURE tmp_GenerateRoleColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN	csr.flow_state_transition.flow_state_transition_id%TYPE,
	in_region_sids_t			IN	security.T_SID_TABLE
)
AS
	v_role_sid					security_pkg.T_SID_ID;
BEGIN
	
	--specified CMS role column by splitting out into users
	FOR r IN(
		SELECT ftacc.column_sid, fta.flow_transition_alert_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN csr.flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN csr.flow_transition_alert_cms_col ftacc ON fta.flow_transition_alert_id = ftacc.flow_transition_alert_id
		  JOIN cms.tab_column tc ON ftacc.column_sid = tc.column_sid
		 WHERE fi.app_sid = security_pkg.GetApp
		   AND fi.flow_item_id = in_flow_item_id
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
		   AND tc.col_type IN (cms.tab_pkg.CT_ROLE)
	)
	LOOP
		v_role_sid := tmp_GetFlowRoleSid(in_flow_item_id, r.column_sid);
		IF v_role_sid IS NOT NULL THEN 
			--Get the users in that role
			--security_pkg.debugmsg('CT_ROLE users for role_sid:' || v_role_sid || ' flow_transition_alert_id:' || r.flow_transition_alert_id);
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
				from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, processed_dtm)
			SELECT rrm.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, in_set_by_user_sid,
				rrm.user_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id, NULL
			  FROM csr.region_role_member rrm 
			  JOIN TABLE(in_region_sids_t) t ON t.column_value = rrm.region_sid -- perf may be improved if we pass region_sid value when v_region_t length = 1
			  JOIN csr.csr_user cu ON rrm.app_sid = cu.app_sid AND rrm.user_sid = cu.csr_user_sid AND cu.send_alerts = 1
			 WHERE rrm.role_sid = v_role_sid
			   AND NOT EXISTS ( 
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = rrm.app_sid
				   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = rrm.user_sid
				
				);
		END IF;
	END LOOP;
END;

END;
/

--CSR
CREATE OR REPLACE PACKAGE CSR.TMP_TRANSITION_ALERT_PKG
AS

PROCEDURE tmp_generateTransEntries(
	in_flow_item_id				IN	NUMBER,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	NUMBER,
	in_flow_state_transition_id	IN  NUMBER
);

END;
/




CREATE OR REPLACE PACKAGE BODY CSR.TMP_TRANSITION_ALERT_PKG
AS

PROCEDURE tmp_GenInvolmTypeAlertEntries(
	in_flow_item_id 					IN csr.flow_item.flow_item_id%TYPE, 
	in_set_by_user_sid					IN security_pkg.T_SID_ID,
	in_flow_transition_alert_id 		IN csr.flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id  		IN csr.flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 				IN csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_alert_class_helper_pkg		IN VARCHAR2
)
AS
BEGIN
	IF UPPER(in_flow_alert_class_helper_pkg) = 'CSR.AUDIT_PKG' THEN
		IF in_flow_involvement_type_id = 1 /* csr_data_pkg.FLOW_INV_TYPE_AUDITOR */ THEN
			--to auditor user sid
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
				from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
			SELECT app_sid, flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
				in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
			  FROM (
				SELECT DISTINCT ia.app_sid, ia.auditor_user_sid to_user_sid
				  FROM csr.internal_audit ia
				 WHERE ia.flow_item_id = in_flow_item_id
				   AND ia.deleted = 0
				  AND NOT EXISTS(
					SELECT 1 
					  FROM flow_item_generated_alert figa
					 WHERE figa.app_sid = ia.app_sid
					   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
					   AND figa.flow_state_log_id = in_flow_state_log_id
					   AND figa.to_user_sid = ia.auditor_user_sid
				  
				  )
			 );
		ELSIF in_flow_involvement_type_id = 2 /* csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY */ THEN 
			--to members of the auditor company
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
			SELECT app_sid, flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, in_set_by_user_sid, to_user_sid, NULL, 
				in_flow_item_id, in_flow_state_log_id
			  FROM (
				SELECT DISTINCT ia.app_sid, cm.user_sid to_user_sid
				  FROM csr.internal_audit ia
				  JOIN chain.v$company_member cm ON cm.company_sid = ia.auditor_company_sid
				 WHERE ia.flow_item_id = in_flow_item_id
				   AND ia.deleted = 0
				  AND NOT EXISTS(
					SELECT 1 
					  FROM flow_item_generated_alert figa
					 WHERE figa.app_sid = ia.app_sid
					   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
					   AND figa.flow_state_log_id = in_flow_state_log_id
					   AND figa.to_user_sid = cm.user_sid
				  )
			 );
		END IF;
	ELSIF UPPER(in_flow_alert_class_helper_pkg) = 'CHAIN.SUPPLIER_FLOW_PKG' THEN
		IF in_flow_involvement_type_id = 1001 /* csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER */ THEN
		--to members of the purchase company
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
				from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
			SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
				in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
			  FROM (
				SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
				  FROM chain.supplier_relationship sr
				  JOIN chain.v$company_user cu ON sr.purchaser_company_sid = cu.company_sid 
				 WHERE sr.flow_item_id = in_flow_item_id
				   AND sr.active = 1
				   AND sr.deleted = 0
				  AND NOT EXISTS(
					SELECT 1 
					  FROM csr.flow_item_generated_alert figa
					 WHERE figa.app_sid = sr.app_sid
					   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
					   AND figa.flow_state_log_id = in_flow_state_log_id
					   AND figa.to_user_sid = cu.user_sid
				  
				  )
			 );
		ELSIF in_flow_involvement_type_id = 1002 /* csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER */ THEN 
			--to members of the supplier company
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
			SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, in_set_by_user_sid, to_user_sid, NULL, 
				in_flow_item_id, in_flow_state_log_id
			  FROM (
				SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
				  FROM chain.supplier_relationship sr
				  JOIN chain.v$company_user cu ON sr.supplier_company_sid = cu.company_sid 
				 WHERE sr.flow_item_id = in_flow_item_id
				   AND sr.active = 1
				   AND sr.deleted = 0
				  AND NOT EXISTS(
					SELECT 1 
					  FROM csr.flow_item_generated_alert figa
					 WHERE figa.app_sid = sr.app_sid
					   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
					   AND figa.flow_state_log_id = in_flow_state_log_id
					   AND figa.to_user_sid = cu.user_sid
				  )
			 );
		END IF;	
	END IF;
END;

PROCEDURE tmp_GenExtraFLowAlertEntries(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN	security_pkg.T_SID_ID,
	in_flow_state_transition_id 	IN  csr.flow_state_transition.flow_state_transition_id%TYPE,
	in_flow_state_log_id			IN	csr.flow_state_log.flow_state_log_id%TYPE
)
AS
	v_to_state_id	flow_state_transition.to_state_id%TYPE;
BEGIN
	SELECT to_state_id
	  INTO v_to_state_id
	  FROM csr.flow_state_transition
	 WHERE app_sid = security_pkg.getapp
	   AND flow_state_transition_id = in_flow_state_transition_id;
	   
	-- Users associated directly with the initiative in its new state (with generate_alerts flag set)
	--that will create multiple entries as multiple flow_transition_alert may end to this state
	INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
	--user might belong to more than 1 groups for the same flow_state
	SELECT security_pkg.getapp, 
			flow_item_gen_alert_id_seq.nextval,
			flow_transition_alert_id,
			in_set_by_user_sid,
			to_user_sid, -- Associated by initiative/new state
			NULL,
			in_flow_item_id,
			in_flow_state_log_id
	  FROM (
		SELECT DISTINCT 
				fta.flow_transition_alert_id,
				iu.user_sid to_user_sid -- Associated by initiative/new state
		  FROM csr.initiative i
		  JOIN csr.initiative_saving_type ist ON ist.saving_type_id = i.saving_type_id
		  JOIN csr.initiative_user iu ON iu.initiative_sid = i.initiative_sid
		  JOIN csr.initiative_group_flow_state igfs 
			ON igfs.initiative_user_group_id = iu.initiative_user_group_id 
		   AND igfs.flow_state_id = v_to_state_id 
		   AND igfs.project_sid = i.project_sid 
		   AND igfs.generate_alerts = 1
		  CROSS JOIN csr.flow_transition_alert fta 
		 WHERE i.app_sid = security_pkg.getapp
		   AND i.flow_item_id = in_flow_item_id
		   AND flow_state_transition_id = in_flow_state_transition_id 
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0 
		   AND NOT EXISTS(
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = i.app_sid
				   AND figa.flow_transition_alert_id = fta.flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = iu.user_sid
		  )
	  );
END;

PROCEDURE tmp_generateTransEntries(
	in_flow_item_id				IN	NUMBER,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	NUMBER,
	in_flow_state_transition_id	IN  NUMBER
)
AS
	v_flow_alert_class_helper_pkg	VARCHAR2(255);
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_region_sid			security_pkg.T_SID_ID;
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			cms.tab.oracle_schema%TYPE;
	v_oracle_table			cms.tab.oracle_table%TYPE;
	v_flow_item_col_name	cms.tab_column.oracle_column%TYPE;
	v_coverable				cms.tab_column.coverable%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	--get flow alert class
	BEGIN
		SELECT fac.helper_pkg
		  INTO v_flow_alert_class_helper_pkg
		  FROM flow f
		  JOIN flow_item fi ON fi.flow_sid = f.flow_sid
		  JOIN flow_alert_class fac ON f.flow_alert_class = fac.flow_alert_class
		 WHERE f.app_sid = security_pkg.getApp
		   AND fi.flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_alert_class_helper_pkg := NULL;
	END;
	
	IF v_flow_alert_class_helper_pkg IS NULL THEN
		RETURN;
	END IF;
	
	--get region sids
	IF UPPER(v_flow_alert_class_helper_pkg) = 'CMS.TAB_PKG' THEN
		--#######
		-- CMS
		--#######
		BEGIN
			v_region_sids_t := cms.tmp_tab_pkg.tmp_GetFlowRegionSids(in_flow_item_id);
		EXCEPTION
			WHEN no_data_found THEN
				RETURN; -- managed record that has been deleted, skip
		END;
		
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.AUDIT_PKG' THEN
		--#######
		-- AUDITS
		--#######
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM csr.v$audit
		 WHERE app_sid = security_pkg.getApp
		   AND flow_item_id = in_flow_item_id;
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.SECTION_PKG' THEN
		--#######
		-- SECTION (CORP. REPORTER)
		--#######
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM csr.section s
		  JOIN csr.section_module sm ON s.module_root_sid = sm.module_root_sid
		 WHERE s.app_sid = security_pkg.getApp
		   AND s.flow_item_id = in_flow_item_id;
	
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.PROPERTY_PKG' THEN
		--#######
		-- PROPERTIES
		--#######
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM csr.v$property p
		 WHERE app_sid = security_pkg.getApp
		   AND flow_item_id = in_flow_item_id;
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.CAMPAIGN_PKG' THEN
		--#######
		-- CAMPAIGNS
		--#######
		SELECT rsr.region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM csr.qs_campaign c
		  JOIN csr.quick_survey_response qsr ON c.qs_campaign_sid = qsr.qs_campaign_sid
		  JOIN csr.flow_item fi ON qsr.survey_response_id = fi.survey_response_id
		  JOIN csr.region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		 WHERE c.app_sid = security_pkg.getApp
		   AND fi.flow_item_id = in_flow_item_id;
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.INITIATIVE_ALERT_PKG' THEN
		--#######
		-- Initiatives
		--#######
			SELECT ir.region_sid
			  BULK COLLECT INTO v_region_sids_t
			  FROM csr.initiative i
			  JOIN csr.initiative_region ir ON i.initiative_sid = ir.initiative_sid
			 WHERE i.app_sid = security_pkg.getApp
			   AND i.flow_item_id = in_flow_item_id;
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CHEM.SUBSTANCE_PKG' THEN
		--#######
		-- CHEM
		--#######
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM chem.v$substance_region
		 WHERE app_sid = security_pkg.getApp
		   AND flow_item_id = in_flow_item_id;
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CHAIN.SUPPLIER_FLOW_PKG' THEN
		--#######
		-- CHAIN
		--#######
		SELECT s.region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM chain.supplier_relationship sr
		  JOIN csr.supplier s ON sr.supplier_company_sid = s.company_sid
		 WHERE sr.app_sid = security_pkg.getApp
		   AND flow_item_id = in_flow_item_id
		   AND sr.active = 1
		   AND sr.deleted = 0;
	
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.METER_PKG' THEN
		--#######
		-- METER
		--#######
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM csr.v$meter_reading_all
		 WHERE app_sid = security_pkg.getApp
		   AND flow_item_id = in_flow_item_id;
		
	ELSIF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.APPROVAL_DASHBOARD_PKG' THEN
		--#######
		-- DASHBOARD
		--#######
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids_t
		  FROM csr.approval_dashboard_instance adi
		  JOIN csr.flow_item fi ON adi.dashboard_instance_id = fi.dashboard_instance_id
		 WHERE fi.app_sid = security_pkg.getApp
		   AND fi.flow_item_id = in_flow_item_id;
	ELSE 
		RAISE_APPLICATION_ERROR(-20001, v_flow_alert_class_helper_pkg || ' is not supported');
	END IF;
	
	--###############
	--Standard alerts
	--###############
	FOR r IN (
		 SELECT app_sid, flow_transition_alert_id, in_set_by_user_sid, to_user_sid, to_column_sid
		   FROM (
				--RRM: --distinct in case a user belongs to more than 1 roles
				SELECT DISTINCT fi.app_sid, fta.flow_transition_alert_id, rrm.user_sid to_user_sid, NULL to_column_sid
				  FROM flow_item fi 
				  JOIN flow_state_transition fst ON fi.flow_sid = fst.flow_sid
				  JOIN flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
				  JOIN flow_transition_alert_role ftar ON fta.flow_transition_alert_id = ftar.flow_transition_alert_id 
				  JOIN region_role_member rrm ON ftar.role_sid = rrm.role_sid
				  JOIN TABLE(v_region_sids_t) t ON t.column_value = rrm.region_sid  --perf may be improved if we pass region_sid value when v_region_t length = 1
				  JOIN csr_user cu ON cu.app_sid = rrm.app_sid AND cu.csr_user_sid = rrm.user_sid AND cu.send_alerts = 1
				 WHERE fi.app_sid = security_pkg.getApp
				   AND fi.flow_item_id = in_flow_item_id
				   AND fta.deleted = 0
				   AND fta.to_initiator = 0
				   AND fst.flow_state_transition_id = in_flow_state_transition_id
				
				UNION 
				 --initiator
				SELECT fi.app_sid, fta.flow_transition_alert_id, in_set_by_user_sid to_user_sid, NULL to_column_sid
				  FROM flow_item fi 
				  JOIN flow_state_transition fst ON fi.flow_sid = fst.flow_sid
				  JOIN flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
				  JOIN csr_user cu ON cu.app_sid = fi.app_sid AND cu.csr_user_sid = in_set_by_user_sid AND cu.send_alerts = 1
				  WHERE fi.app_sid = security_pkg.getApp
				  AND fi.flow_item_id = in_flow_item_id
				  AND fta.deleted = 0
				  AND fta.to_initiator = 1
				  AND fst.flow_state_transition_id = in_flow_state_transition_id
				
				UNION
				--specifically selected users
				SELECT fi.app_sid, fta.flow_transition_alert_id, ftau.user_sid to_user_sid, NULL to_column_sid
				  FROM flow_item fi 
				  JOIN flow_state_transition fst ON fi.flow_sid = fst.flow_sid
				  JOIN flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
				  JOIN flow_transition_alert_user ftau ON fta.flow_transition_alert_id = ftau.flow_transition_alert_id
				  JOIN csr_user cu ON cu.app_sid = ftau.app_sid AND cu.csr_user_sid = ftau.user_sid AND cu.send_alerts = 1
				 WHERE fi.app_sid = security_pkg.getApp
				   AND fi.flow_item_id = in_flow_item_id
				   AND fta.deleted = 0
				   AND fta.to_initiator = 0
				   AND fst.flow_state_transition_id = in_flow_state_transition_id
		)
	)
	LOOP
		--security_pkg.debugmsg('To_user_sid:' || r.to_user_sid || ' flow_transition_alert_id:' || r.flow_transition_alert_id || ' in_flow_state_log_id' || in_flow_state_log_id);
		INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
		VALUES(r.app_sid, flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, in_set_by_user_sid, r.to_user_sid, r.to_column_sid, 
			in_flow_item_id, in_flow_state_log_id);
		
	END LOOP;
	
	
	IF UPPER(v_flow_alert_class_helper_pkg) = 'CMS.TAB_PKG' THEN --no reason to call the SP for the other modules
		-- CMS user column.
		BEGIN
			cms.tmp_tab_pkg.tmp_GenerateUserColumnAlerts(in_flow_item_id, in_set_by_user_sid, in_flow_state_log_id, in_flow_state_transition_id);
		EXCEPTION
			WHEN no_data_found THEN
				RETURN; -- managed record that has been deleted, skip
		END;
		-- CMS role column.
		BEGIN
			cms.tmp_tab_pkg.tmp_GenerateRoleColumnAlerts(in_flow_item_id, in_set_by_user_sid, in_flow_state_log_id, in_flow_state_transition_id, v_region_sids_t);
		EXCEPTION
			WHEN no_data_found THEN
				RETURN; -- managed record that has been deleted, skip
		END;

	END IF;
	
	
	--loop flow_alert_involment_type and execute helper_pkg
	FOR r IN (
		SELECT fi.flow_item_id, fta.flow_transition_alert_id, ftai.flow_involvement_type_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN csr.flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN csr.flow_transition_alert_inv ftai ON fta.flow_transition_alert_id = ftai.flow_transition_alert_id
		 WHERE fi.app_sid = security_pkg.GetApp
		   AND fi.flow_item_id = in_flow_item_id
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
	)
	LOOP
		--call specific module helpers to generate alert entries
		tmp_GenInvolmTypeAlertEntries(
			in_flow_item_id, 
			in_set_by_user_sid, 
			r.flow_transition_alert_id, 
			r.flow_involvement_type_id, 
			in_flow_state_log_id,
			v_flow_alert_class_helper_pkg
		);
			
	END LOOP;
	
	--extra custom call outs
	IF UPPER(v_flow_alert_class_helper_pkg) = 'CSR.INITIATIVE_ALERT_PKG' THEN
		tmp_GenExtraFLowAlertEntries(in_flow_item_id, in_set_by_user_sid, in_flow_state_transition_id, in_flow_state_log_id);
	END IF;
	
END;

END;
/