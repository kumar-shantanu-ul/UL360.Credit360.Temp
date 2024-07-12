declare
begin
    user_pkg.logonadmin('&&1');
    FOR r IN (
        SELECT sid_id 
		  FROM security.securable_object 
		 WHERE parent_sid_id IN (
			securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetApp, 'menu'), 
			securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetApp, 'wwwroot')
		)
    )
    LOOP
        securableobject_pkg.DeleteSO(security_pkg.GetACT, r.sid_id);
    END LOOP;
end;
/
