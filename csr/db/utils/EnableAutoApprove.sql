set serveroutput on
DECLARE
	v_act_id			  security_pkg.T_ACT_ID;
	v_app_sid			  security_pkg.T_SID_ID;
	v_class_id			security_pkg.T_CLASS_ID;
	v_groups_sid		security_pkg.T_SID_ID;
	v_sid				    security_pkg.T_SID_ID;
	v_cap_dacl      Security_Pkg.T_ACL_ID;
	v_helper_pkg    varchar2(1024);
BEGIN
	-- log on
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	v_app_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, '//aspen/applications/&Host');
	security.security_pkg.SetACT(v_act_id, v_app_sid);
  -- enable capability
   csr.csr_data_pkg.EnableCapability('Auto Approve Valid Delegation', 1);
   security.securableobject_pkg.ClearFlag(
      v_act_id,
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Auto Approve Valid Delegation'),
      security.security_pkg.SOFLAG_INHERIT_DACL);
      
   v_cap_dacl := security.acl_pkg.GetDACLIDForSID(
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Auto Approve Valid Delegation')); 
  -- remove admins    
   DELETE FROM security.ACL
		    WHERE ACL_ID = v_cap_dacl
			  AND bitand(ACE_FLAGS, Security_Pkg.ACE_FLAG_INHERITED) != 0; 
	-- create new groups
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
  BEGIN
    security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY,
          'AutoApprovers', v_class_id, v_sid);
          
    security.acl_pkg.AddACE(security.security_pkg.GetACT, 
          v_cap_dacl, 
          -1, 
          security.security_pkg.ACE_TYPE_ALLOW, 
          security.security_pkg.ACE_FLAG_DEFAULT, 
          v_sid, 
          security.security_pkg.PERMISSION_STANDARD_ALL);
  EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'AutoApprovers');
	END;
  
  SELECT helper_pkg
    INTO v_helper_pkg
    FROM csr.customer
   WHERE app_sid = v_app_sid;
   
  INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT v_app_sid, csr.customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM csr.std_alert_type 
		 WHERE std_alert_type_id IN (csr.csr_data_pkg.ALERT_AUTO_APPROVE_SUCCESS, csr.csr_data_pkg.ALERT_AUTO_APPROVE_INVALID);
		 
  IF v_helper_pkg IS NULL OR v_helper_pkg = 'auto_approve_pkg' THEN
    UPDATE csr.customer SET helper_pkg = 'auto_approve_pkg' WHERE app_sid = v_app_sid;
    COMMIT;
  ELSE
    dbms_output.put_line('Rolled Back: Customer already has helper package, update the helper package to include auto_approve_pkg`s post_submit');
    ROLLBACK; 
  END IF;	
END;
/
set serveroutput off
