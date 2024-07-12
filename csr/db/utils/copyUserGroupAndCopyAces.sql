DECLARE
    v_new_group_sid                 security_pkg.T_SID_ID;
    v_old_group_sid 		        security_pkg.T_SID_ID := &&GROUP_SID_TO_COPY;
    v_group_node_sid                security_pkg.T_SID_ID;
    v_new_group_name				VARCHAR2(255) := '&&GROUP_NAME_TO_CREATE';
    v_act                           security_pkg.T_ACT_ID;
    v_class_id                      SECURITY.SECURABLE_OBJECT_CLASS.class_id%TYPE;
    v_last_acl_id                   security.acl.ACL_ID%TYPE;
    v_index                         NUMBER;
BEGIN

        --get act
        user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
        
        --get csr group object security class id
		SELECT class_id INTO v_class_id FROM security.securable_object_class WHERE class_name = 'CSRUserGroup';
        
        -- get the parent node of the old group
        select parent_sid_id into v_group_node_sid from security.securable_object where sid_id = v_old_group_sid ;
        
        -- create group 
        security.group_pkg.CreateGroupWithClass(v_act, v_group_node_sid, 1, v_new_group_name, v_class_id, v_new_group_sid);
		
		csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_GROUP_CHANGE, security_pkg.GetAPP, security_pkg.GetSID, 'Created group "{0}"', v_new_group_name);
		
        --copy Access Control Entries ACEs from the original group's access control list ACL 
        
       v_last_acl_id := -1;
       v_index := 1;
       
       for r in 
       (
        select acl_id, (select max(acl_index)+1 from security.acl b where a.acl_id=b.acl_id) acl_index, ace_type,ace_flags, permission_set
          from security.acl a
         where sid_id=v_old_group_sid
         order by acl_id      
       )
        LOOP
        
            if v_last_acl_id != r.acl_id then
                v_index := 1;
                v_last_acl_id := r.acl_id; 
            end if;
        
            
          insert into security.acl (acl_id, acl_index, ace_Type, ace_flags, sid_id, permission_set) 
                values
               (r.acl_id, r.acl_index + v_index, r.ace_type, r.ace_flags, v_new_group_sid, r.permission_set);
                
            DBMS_OUTPUT.PUT_LINE('ACL_ID = ' || r.acl_id || ' ACL_INDEX = ' || To_CHAR(r.acl_index + v_index));
                
            v_index := v_index + 1; 
            
        END LOOP;

END;
/


