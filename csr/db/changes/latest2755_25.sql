-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
declare
	v_new_www_sid           security.security_pkg.T_SID_ID;
    v_old_www_sid 		    security.security_pkg.T_SID_ID;
    v_www_csr_site			security.security_pkg.T_SID_ID;
    v_wwwroot_sid			security.security_pkg.T_SID_ID;
    v_act                   security.security_pkg.T_ACT_ID;
begin
	for r in (select c.host
				from csr.customer c, security.website w
			   where lower(c.host) = lower(w.website_name)) loop
			   	
		security.user_pkg.logonadmin(r.host);
		v_act := sys_context('security','act');

		begin
			v_old_www_sid := security.securableobject_pkg.getsidfrompath(v_act, security.security_pkg.getapp,'wwwroot/csr/site/dataExplorer4');
		exception
			when security.security_pkg.object_not_found then		
				v_old_www_sid := null;
		end;
		
		if v_old_www_sid is not null then
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act, sys_context('security','app'), 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act, v_wwwroot_sid, 'csr/site');
			BEGIN
				security.web_pkg.CreateResource(v_act, v_wwwroot_sid, v_www_csr_site, 'dataExplorer5', v_new_www_sid);
				
				security.acl_pkg.DeleteAllACEs(v_act, security.acl_pkg.GetDACLIDForSID(v_new_www_sid));
				FOR r IN (
					SELECT a.acl_id, a.acl_index, a.ace_type, a.ace_flags, a.permission_set, a.sid_id
					  FROM security.securable_object so
					  JOIN security.acl a ON so.dacl_id = a.acl_id
					 WHERE so.sid_id = v_old_www_sid
					 ORDER BY acl_index      
				)
				LOOP
					security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_new_www_sid), r.acl_index, 
						r.ace_type, r.ace_flags, r.sid_id, r.permission_Set);
				END LOOP;
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					NULL;
			END;
		end if;
	end loop;
	security.security_pkg.setapp(null);
	update security.menu set action='/csr/site/dataExplorer5/dataNavigator/rawExplorer.acds'
	where lower(action)=lower('/csr/site/dataExplorer4/dataNavigator/rawexplorer.acds');
	update security.menu set action='/csr/site/dataExplorer5/dataNavigator/dataBrowser.acds'
	where lower(action)=lower('/csr/site/dataExplorer4/dataNavigator/dataBrowser.acds');
	update security.menu set action='/csr/site/dataExplorer5/dataNavigator/rawExplorer.acds'
	where lower(action)=lower('/csr/site/dataExplorer4/dataNavigator/rawExplorer.acds');
end;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../csr_user_pkg
@../scenario_run_pkg
@../val_pkg
@../csr_user_body
@../delegation_body
@../scenario_run_body
@../val_body

@update_tail
