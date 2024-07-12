define version=3368
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



ALTER TABLE csr.non_compliance ADD (
	lookup_key 	VARCHAR2(255)
);
CREATE UNIQUE INDEX csr.uk_non_compliance_lookup ON csr.non_compliance(app_sid, NVL(UPPER(lookup_key), TO_CHAR(non_compliance_id)))
;

UPDATE csr.capability
   SET description = NULL
 WHERE name = 'Context Sensitive Help Management';
DECLARE
  user_count	NUMBER;
  table_count	NUMBER;
  col_count		NUMBER;
  v_plsql       VARCHAR(4000);
BEGIN
  SELECT count(*) INTO user_count FROM dba_users WHERE UPPER(username) = 'SURVEYS';
  IF user_count = 0 THEN
    BEGIN
      dbms_output.put_line('SURVEYS user does not exist on this database.  Script terminated as it is not needed to be run.');
      RETURN;
    END;
  END IF;
  
  SELECT count(*) INTO table_count FROM dba_tables WHERE UPPER(owner) = 'SURVEYS' AND UPPER(table_name) = 'RESPONSE';
  IF table_count = 0 THEN
    BEGIN
      dbms_output.put_line('SURVEYS.RESPONSE table does not exist on this database.  Script terminated as it is not needed to be run.');
      RETURN;
    END;
  END IF;
  
  SELECT count(*) INTO col_count FROM dba_tab_columns WHERE UPPER(owner) = 'SURVEYS' AND UPPER(table_name) = 'RESPONSE' AND UPPER(column_name) = 'RESPONSE_UUID';
  IF col_count = 0 THEN
	BEGIN
      dbms_output.put_line('SURVEYS.RESPONSE.RESPONSE_UUID column does not exist on this database.  Script terminated as it is not needed to be run.');
      RETURN;
    END;
  END IF;
	
  v_plsql := ' 
    DECLARE
      updated_count NUMBER := 0;
      total_count NUMBER := 0;
      batch_count NUMBER := 0;
    BEGIN
      FOR i IN (
        SELECT sr.response_id, sr.response_uuid, sr.app_sid FROM surveys.response sr
         INNER JOIN campaigns.campaign_region_response crr ON sr.app_sid = crr.app_sid AND sr.response_id = crr.response_id
         WHERE crr.response_uuid is NULL
      ) LOOP
        UPDATE campaigns.campaign_region_response SET response_uuid = i.response_uuid 
         WHERE response_id = i.response_id AND response_uuid is null AND app_sid = i.app_sid;
        IF SQL%FOUND THEN
          updated_count := updated_count + 1;
          batch_count := batch_count + 1;
        END IF;
        IF batch_count = 1000 THEN
          COMMIT;
          batch_count := 0;
        END IF;
        total_count := total_count + 1;
      END LOOP; 
      dbms_output.put_line(''campaigns.campaign_region_response GUIDs created: '' || updated_count || '' out of '' || total_count || '' rows'');
      COMMIT;
    END;';
  EXECUTE IMMEDIATE v_plsql;
END;
/
@latestUD7851_packages
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_nct_id						NUMBER(10);
	v_tag_group_id					csr.tag_group.tag_group_id%TYPE;
	v_tag_id						csr.tag.tag_id%TYPE;
	v_nc_types						security.security_pkg.T_SID_IDS;
	v_dummy_sids					security.security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.logonadmin();
	FOR R IN (
		SELECT cr.app_sid
		  FROM chain.reference cr
		 WHERE cr.lookup_key = 'RBA_SITECODE'
	) LOOP
		security.user_pkg.logonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, v_act_id);
		v_app_sid := r.app_sid;
		
		csr.temp_audit_pkg.SetNonComplianceType(
			in_non_compliance_type_id		=> NULL,
			in_label						=> 'RBA Finding',
			in_lookup_key					=> 'RBA_FINDING',
			in_position						=> 0,
			in_colour_when_open				=> 16712965,
			in_colour_when_closed			=> 3777539, 
			in_can_have_actions				=> 1,
			in_closure_behaviour_id			=> 1,
			in_repeat_audit_type_ids		=> v_dummy_sids,
			out_non_compliance_type_id		=> v_nct_id
		);
		
		FOR ATYP IN (
			SELECT internal_audit_type_id
			  FROM csr.internal_audit_type
			 WHERE lookup_key IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT')
		) LOOP
			csr.temp_audit_pkg.SetAuditTypeNonCompType(
				in_internal_audit_type_id	=> ATYP.internal_audit_type_id,
				in_non_compliance_type_id	=> v_nct_id
			);
		END LOOP;
		
		v_nc_types(1) := v_nct_id;
		
		-- Finding Status:
		csr.temp_tag_pkg.SetTagGroup(
			in_act_id				=> v_act_id,
			in_app_sid				=> v_app_sid,
			in_name					=> 'Finding Status',
			in_multi_select			=> 0,
			in_mandatory			=> 0,
			in_applies_to_non_comp	=> 1,
			in_lookup_key			=> 'RBA_F_FINDING_STATUS',
			out_tag_group_id		=> v_tag_group_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Initiated',
			in_pos					=> 0,
			in_lookup_key			=> 'RBA_F_PLAN_INITIATED',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Submitted for Approval',
			in_pos					=> 1,
			in_lookup_key			=> 'RBA_F_PLAN_SUBMITTED_FOR_APPRO',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Needs Revision',
			in_pos					=> 2,
			in_lookup_key			=> 'RBA_F_PLAN_NEEDS_REVISION',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Approved / Actions underway',
			in_pos					=> 3,
			in_lookup_key			=> 'RBA_F_PLAN_APPROVED__ACTIONS_U',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Actions Submitted for Approval',
			in_pos					=> 4,
			in_lookup_key			=> 'RBA_F_ACTIONS_SUBMITTED_FOR_AP',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Further Action Required',
			in_pos					=> 5,
			in_lookup_key			=> 'RBA_F_FURTHER_ACTION_REQUIRED',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Actions Completed / Eligible for Closure Audit',
			in_pos					=> 6,
			in_lookup_key			=> 'RBA_F_ACTIONS_COMPLETED__ELIGI',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Closed',
			in_pos					=> 7,
			in_lookup_key			=> 'RBA_F_CLOSED',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTagGroupNCTypes(
			in_tag_group_id			=> v_tag_group_id,
			in_nc_ids				=> v_nc_types
		);
		
		-- Finding Severity:
		csr.temp_tag_pkg.SetTagGroup(
			in_act_id				=> v_act_id,
			in_app_sid				=> v_app_sid,
			in_name					=> 'Finding Severity',
			in_multi_select			=> 0,
			in_mandatory			=> 0,
			in_applies_to_non_comp	=> 1,
			in_lookup_key			=> 'RBA_F_FINDING_SEVERITY',
			out_tag_group_id		=> v_tag_group_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Priority Non-Conformance',
			in_pos					=> 0,
			in_lookup_key			=> 'RBA_F_PRIORITY_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Major Non-Conformance',
			in_pos					=> 1,
			in_lookup_key			=> 'RBA_F_MAJOR_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Minor Non-Conformance',
			in_pos					=> 2,
			in_lookup_key			=> 'RBA_F_MINOR_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Risk of Non-Conformance',
			in_pos					=> 3,
			in_lookup_key			=> 'RBA_F_RISK_OF_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Opportunity for Improvement',
			in_pos					=> 4,
			in_lookup_key			=> 'RBA_F_OPPORTUNITY_FOR_IMPROVEM',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Conformance',
			in_pos					=> 5,
			in_lookup_key			=> 'RBA_F_CONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Not Applicable',
			in_pos					=> 6,
			in_lookup_key			=> 'RBA_F_NOT_APPLICABLE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTagGroupNCTypes(
			in_tag_group_id			=> v_tag_group_id,
			in_nc_ids				=> v_nc_types
		);
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
DROP PACKAGE csr.temp_audit_pkg;
DROP PACKAGE csr.temp_tag_pkg;
ALTER TABLE csr.non_compliance DROP COLUMN lookup_key;

BEGIN
	security.user_pkg.logonadmin;
	/* runs faster through a loop, rather than a single UPDATE (i.e. 3 sec vs 2 mins on supdb)*/
	FOR r in (
		SELECT i.issue_id 
		  FROM csr.issue i
		 WHERE i.issue_type_id = 13 /*Supplier action*/
	)
	LOOP
		UPDATE csr.issue_log 
		   SET is_system_generated = 0
		 WHERE issue_id = r.issue_id
		   AND is_system_generated = 1
		   AND logged_by_user_sid !=3;
	END LOOP;
END;
/






@..\audit_pkg


@..\csr_app_body
@..\audit_body
@..\enable_body
@..\supplier_body



@update_tail
