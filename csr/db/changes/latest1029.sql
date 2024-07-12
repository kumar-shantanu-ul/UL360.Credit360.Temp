-- Please update version.sql too -- this keeps clean builds in sync
define version=1029
@update_header

-- FB22203
declare
    v_ind_region_sid         security.security_pkg.T_SID_ID;
    v_act                    security.security_pkg.T_ACT_ID;
    v_data_providers_sid     security.security_pkg.T_SID_ID;
    v_data_approvers_sid     security.security_pkg.T_SID_ID;
    v_reg_users_sid          security.security_pkg.T_SID_ID;
    v_menu_sid               security.security_pkg.T_SID_ID;
begin
    -- first fix the schema webresource
    for r in (
        select wr.sid_id schema_sid, wr.web_root_sid_id , c.host, c.app_sid
          from security.web_resource wr
            join security.securable_object so on wr.sid_id = so.sid_id
            left join security.securable_object soc on soc.parent_sid_id = so.sid_id and lower(soc.name) = 'indregion'
            join csr.customer c on so.application_sid_id = c.app_sid
         where path = '/csr/site/schema'
           and soc.sid_id is null
           and host not in ('survey.credit360.com', 'cairnindia.credit360.com')
    )
    loop
        dbms_output.put_line('fixing schema for '||r.host);
        security.user_pkg.logonadmin(r.host);
        v_act := SYS_CONTEXT('SECURITY','ACT');
        -- create resource
        security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.schema_sid, 'indRegion', v_ind_region_sid);
        -- clear flag on old resource (shoud be cleared but just in case)
        security.securableobject_pkg.ClearFlag(v_act, r.schema_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
        
        -- remove data providers from parent and add to child
        begin
            v_data_providers_sid := security.securableobject_pkg.getsidfrompath(v_act, r.app_sid, 'Groups/Data Providers');
            security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(r.schema_sid), v_data_providers_sid);            
            security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ind_region_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
                security.security_pkg.ACE_FLAG_DEFAULT, v_data_providers_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
        exception
            when security.security_pkg.OBJECT_NOT_FOUND THEN
                null;
        end;
        
        begin
            v_data_approvers_sid := security.securableobject_pkg.getsidfrompath(v_act, r.app_sid, 'Groups/Data Approvers');
            security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(r.schema_sid), v_data_approvers_sid);                      
            security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ind_region_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
                security.security_pkg.ACE_FLAG_DEFAULT, v_data_approvers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
        exception
            when security.security_pkg.OBJECT_NOT_FOUND THEN
                null;
        end;

        -- propagate
        security.acl_pkg.PropogateACEs(v_act, r.schema_sid);
        
        -- clear the flag on the new resource
        security.securableobject_pkg.ClearFlag(v_act, v_ind_region_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
        
        -- and on to the next....
        security.user_pkg.logonadmin;
    end loop;

    -- now fix up rss web resource
    for r in (
        select wr.sid_id rss_sid, wr.web_root_sid_id , c.host, c.app_sid
          from security.web_resource wr
            join security.securable_object so on wr.sid_id = so.sid_id
            join csr.customer c on so.application_sid_id = c.app_sid
         where path = '/csr/site/rss'
           and host not in ('rbsinitiatives.credit360.com','juniper.credit360.com')
    )
    loop
        security.user_pkg.logonadmin(r.host);
        v_act := SYS_CONTEXT('SECURITY','ACT');
        
        -- clear registered users, and unset inherit flag on web resource
        v_reg_users_sid := security.securableobject_pkg.getsidfrompath(v_act, r.app_sid, 'Groups/RegisteredUsers');
        security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(r.rss_sid), v_reg_users_sid);            
        security.securableobject_pkg.ClearFlag(v_act, r.rss_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
        
        select min(m.sid_id)
          into v_menu_sid
          from security.menu m
            join security.securable_object so on m.sid_id = so.sid_id          
         where lower(m.action) = '/csr/site/rss/rssedit.acds'
           and so.application_sid_id = r.app_sid;
        
        if v_menu_sid is not null then
			dbms_output.put_line('fixing rss for '||r.host);
			-- copy stuff from the menu option that we don't have set
			for rr in (
				-- stuff on menu
				select ace_type, sid_id,
					case ace_type 
						when security.security_pkg.ace_type_allow then security.security_pkg.ACL_INDEX_LAST
						when security.security_pkg.ace_type_deny then security.security_pkg.ACL_INDEX_FIRST
					end acl_index_type
				  from security.acl 
				 where acl_id = security.acl_pkg.GetDACLIDForSID(v_menu_sid) 
				 minus
				-- stuff currently on web resource
				select ace_type, sid_id,
					case ace_type 
						when security.security_pkg.ace_type_allow then security.security_pkg.ACL_INDEX_LAST
						when security.security_pkg.ace_type_deny then security.security_pkg.ACL_INDEX_FIRST
					end acl_index_type
				  from security.acl 
				 where acl_id = security.acl_pkg.GetDACLIDForSID(r.rss_sid) 
			)
			loop
				security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(r.rss_sid), rr.acl_index_type, rr.ace_type,
					security.security_pkg.ACE_FLAG_DEFAULT, rr.sid_id, security.security_pkg.PERMISSION_STANDARD_READ);	
			end loop;
			
			-- propagate just in case
			security.acl_pkg.PropogateACEs(v_act, r.rss_sid);
		end if;
        
        -- and on to the next....
        security.user_pkg.logonadmin;
    end loop;
end;
/


@update_tail
