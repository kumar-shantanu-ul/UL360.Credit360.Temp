-- Change permissions
DECLARE
    v_act					security_pkg.T_ACT_ID;
    v_perms                 acl.permission_set%TYPE;
BEGIN
    user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
    FOR r IN 
        (select * from securable_object where class_id = (
         	select class_id from securable_object_class where class_name ='CSRSection'))
    LOOP
        -- Get the current permission set for the group that is the section object
        BEGIN
            SELECT permission_set
              INTO v_perms
              FROM ACL
             WHERE acl_id = r.dacl_id
               AND sid_id = r.sid_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_perms := 0;
        END;
        IF v_perms != 0 THEN
           -- Add write access to the permission set
           v_perms := bitwise_pkg.bitor(v_perms, security_pkg.PERMISSION_WRITE);
           -- Re-create the permission set
           acl_pkg.RemoveACEsForSid(v_act, acl_pkg.GetDACLIDForSID(r.sid_id), r.sid_id);
           acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(r.sid_id), security_pkg.ACL_INDEX_LAST, 
        		security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, r.sid_id, v_perms);
        END IF;
    END LOOP;
END;
/

-- Then propogate ACES
DECLARE
    v_act	 security_pkg.T_ACT_ID;
BEGIN
    user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN
		 (select * from securable_object where class_id = (
         	select class_id from securable_object_class where class_name ='CSRSectionRoot')) 
    LOOP
   		 acl_pkg.PropogateACEs(v_act, r.sid_id);
   	END LOOP;
END;
/
