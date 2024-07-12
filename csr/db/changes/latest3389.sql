define version=3389
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


-- These came from separate minor scripts: latest3388_3 and latest3388_4
--
-- ALTER TABLE csr.flow_item ADD (
-- 	auto_failure_count	NUMBER(4) DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE csr.flow_item DROP COLUMN auto_failure_count;

BEGIN
	-- There were two fixes required for delegation permissions.
	---- 1. The first is that the "insert step before" action did not add the delegator permission to the step after the new step, meaning users could not approve their child delegation.
	---- 2. The second is that when delegating the permissions were delegated to children before the delegator permission is added to the child delegation, meaning grand+ children only have delegee permission.
	FOR r IN (
		SELECT d.app_sid, d.delegation_sid parent, du.deleg_permission_set pps, cd.delegation_sid child, cdu.deleg_permission_set cps, du.user_sid
		  FROM csr.delegation d
		  JOIN csr.delegation_user du ON d.app_sid = du.app_sid AND d.delegation_sid = du.delegation_sid AND du.inherited_from_sid = d.delegation_sid
		  JOIN csr.delegation cd ON d.app_sid = cd.app_sid AND d.delegation_sid = cd.parent_sid
		  LEFT JOIN csr.delegation_user cdu ON cd.app_sid = cdu.app_sid AND cd.delegation_sid = cdu.delegation_sid AND du.user_sid = cdu.user_sid AND cdu.inherited_from_sid = du.delegation_sid
		 WHERE (cdu.deleg_permission_set IS NULL OR cdu.deleg_permission_set < du.deleg_permission_set) -- NULL for 1. because never added. Child delegation having less permissions for 2.
		 ORDER BY app_sid
	) LOOP
		
		MERGE INTO csr.delegation_user du
		USING (
			SELECT app_sid, delegation_sid, r.user_sid user_sid, r.parent parent
			  FROM csr.delegation
			 START WITH delegation_sid = r.child
		   CONNECT BY PRIOR delegation_sid = parent_sid
		  ) u
		   ON (u.app_sid = du.app_sid AND u.user_sid = du.user_sid AND u.delegation_sid = du.delegation_sid and u.parent = du.inherited_from_sid)
		 WHEN MATCHED THEN
			UPDATE SET deleg_permission_set = 11
		 WHEN NOT MATCHED THEN
			INSERT (app_sid, delegation_sid, user_sid, deleg_permission_set, inherited_from_sid)
			VALUES (u.app_sid, u.delegation_sid, u.user_sid, 11, u.parent);	
	END LOOP;
END;
/
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_app_ui_surveys		security.security_pkg.T_SID_ID;
	v_sag_sid					security.security_pkg.T_SID_ID;
	v_acl_id					security.security_pkg.T_ACL_ID;
	PROCEDURE INTERNAL_CreateOrGetResource(
		in_act_id			IN	security.security_pkg.T_ACT_ID,
		in_web_root_sid_id	IN	security.security_pkg.T_SID_ID,
		in_parent_sid_id	IN	security.security_pkg.T_SID_ID,
		in_page_name		IN	security.web_resource.path%TYPE,
		out_page_sid_id		OUT	security.web_resource.sid_id%TYPE
	)
	AS
	BEGIN
		security.web_pkg.CreateResource(
			in_act_id			=> in_act_id,
			in_web_root_sid_id	=> in_web_root_sid_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_page_name		=> in_page_name,
			in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
			in_rewrite_path		=> NULL,
			out_page_sid_id		=> out_page_sid_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_page_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_parent_sid_id, in_page_name);
	END;
BEGIN
	FOR r IN (
		SELECT app_sid, name
		  FROM csr.customer
		 WHERE question_library_enabled = 1
	) LOOP
		security.user_pkg.logonadmin(r.name);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		-- Create new page web resource
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.surveys', v_www_app_ui_surveys);
		-- Add surveys authorised guest security
		BEGIN
			SELECT csr_user_sid
			  INTO v_sag_sid
			  FROM csr.csr_user
			  WHERE user_name = 'surveyauthorisedguest';
			v_acl_id := security.acl_pkg.GetDACLIDForSID(v_www_app_ui_surveys);
			security.acl_pkg.RemoveACEsForSid(v_act_id, v_acl_id, v_sag_sid);
			security.acl_pkg.AddACE(v_act_id, v_acl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;
		security.user_pkg.logonadmin();
	END LOOP;
END;
/
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_app_ui_surveys		security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_regusers_sid				security.security_pkg.T_SID_ID;
	PROCEDURE INTERNAL_CreateOrGetResource(
		in_act_id			IN	security.security_pkg.T_ACT_ID,
		in_web_root_sid_id	IN	security.security_pkg.T_SID_ID,
		in_parent_sid_id	IN	security.security_pkg.T_SID_ID,
		in_page_name		IN	security.web_resource.path%TYPE,
		out_page_sid_id		OUT	security.web_resource.sid_id%TYPE
	)
	AS
	BEGIN
		security.web_pkg.CreateResource(
			in_act_id			=> in_act_id,
			in_web_root_sid_id	=> in_web_root_sid_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_page_name		=> in_page_name,
			in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
			in_rewrite_path		=> NULL,
			out_page_sid_id		=> out_page_sid_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_page_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_parent_sid_id, in_page_name);
	END;
	PROCEDURE INTERNAL_AddACE_NoDups(
		in_act_id			IN	security.security_pkg.T_ACT_ID,
		in_acl_id			IN	security.security_Pkg.T_ACL_ID,
		in_acl_index		IN	security.security_Pkg.T_ACL_INDEX,
		in_ace_type			IN	security.security_Pkg.T_ACE_TYPE,
		in_ace_flags		IN	security.security_Pkg.T_ACE_FLAGS,
		in_sid_id			IN	security.security_Pkg.T_SID_ID,
		in_permission_set	IN	security.security_Pkg.T_PERMISSION
	)
	AS
	BEGIN
		security.acl_pkg.RemoveACEsForSid(in_act_id, in_acl_id, in_sid_id);
		security.acl_pkg.AddACE(in_act_id, in_acl_id, in_acl_index, in_ace_type, in_ace_flags, in_sid_id, in_permission_set);
	END;
BEGIN
	FOR r IN (
		SELECT app_sid, name
		  FROM csr.customer
		 WHERE question_library_enabled = 1
	) LOOP
		security.user_pkg.logonadmin(r.name);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		-- Create new page permissions
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.surveys', v_www_app_ui_surveys);
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
		v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_surveys), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/






@..\landing_page_pkg
@..\flow_pkg


@..\landing_page_body
@..\flow_body
@..\enable_body
@..\..\..\aspen2\cms\db\form_body



@update_tail
