-- Please update version.sql too -- this keeps clean builds in sync
define version=18
@update_header

-- run on live on 7 Apr 06 
DECLARE
	v_act		SECURITY_PKG.T_ACT_ID;
	v_csr_sid	SECURITY_PKG.T_SID_ID;
	v_sid		SECURITY_PKG.T_SID_ID;
	v_superadmins_sid	 SECURITY_PKG.T_SID_ID;
	v_users_sid	 SECURITY_PKG.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_csr_sid := securableobject_pkg.GetSIDFromPath(v_act, 0, 'csr');
	group_pkg.CreateGroup(v_act, v_csr_sid, security_pkg.GROUP_TYPE_SECURITY, 'SuperAdmins',v_superadmins_sid);
	securableobject_pkg.createSO(v_act, v_csr_sid, security_pkg.SO_CONTAINER, 'Users',v_users_sid);
END;
/

-- locate all csr customers, add superadmins group to the administrators group
DECLARE
	v_act		SECURITY_PKG.T_ACT_ID;
	v_superadmins_sid	 SECURITY_PKG.T_SID_ID;
	v_admins_sid	 SECURITY_PKG.T_SID_ID;
	v_regusers_sid	 SECURITY_PKG.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_superadmins_sid := securableobject_pkg.GetSIDFromPath(v_act, 0, 'csr/superadmins');
	FOR	r IN (
		SELECT so.parent_sid_id
      FROM CUSTOMER c, security.securable_object so
     WHERE c.csr_root_sid = so.sid_id
     )
	LOOP
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act, r.parent_sid_id, 'Groups/Administrators');
		group_pkg.AddMember(v_act, v_superadmins_sid, v_admins_sid);
		v_regusers_sid := securableobject_pkg.GetSIDFromPath(v_act, r.parent_sid_id, 'Groups/RegisteredUsers');
		group_pkg.AddMember(v_act, v_superadmins_sid, v_regusers_sid);
	END LOOP;
END;
/


COMMIT;

@update_tail
