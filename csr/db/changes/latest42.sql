-- Please update version.sql too -- this keeps clean builds in sync
define version=42
@update_header


		-- remove registeredusers from indicators + regions
        acl_pkg.RemoveACEsForSid(v_act, acl_pkg.GetDACLIDForSID(v_indicators_sid), security_pkg.SID_BUILTIN_EVERYONE);
		securableObject_pkg.ClearFlag(v_act, v_indicators_sid, security_pkg.SOFLAG_INHERIT_DACL); 
        acl_pkg.RemoveACEsForSid(v_act, acl_pkg.GetDACLIDForSID(v_regions_sid), security_pkg.SID_BUILTIN_EVERYONE);
		securableObject_pkg.ClearFlag(v_act, v_regions_sid, security_pkg.SOFLAG_INHERIT_DACL);
        FOR s IN (
			SELECT ind_sid sid_id FROM IND WHERE csr_root_sid = r.csr_root_Sid
		    UNION
			SELECT region_sid sid_id FROM REGION WHERE csr_root_sid = r.csr_root_Sid
		)
		LOOP
       		acl_pkg.RemoveACEsForSid(v_act, acl_pkg.GetDACLIDForSID(s.sid_id), s.sid_id);
			acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(s.sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, s.sid_id, security_pkg.PERMISSION_STANDARD_READ);
		END LOOP; 
        -- now propagate permissions downwards
       	acl_pkg.PropogateACEs(v_act, v_indicators_sid);
       	acl_pkg.PropogateACEs(v_act, v_regions_sid);

@update_tail
