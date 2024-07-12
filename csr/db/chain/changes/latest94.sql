define version=94
@update_header

BEGIN
	user_pkg.logonadmin;
	FOR r IN (
		SELECT host FROM chain.v$chain_host
	) LOOP
		user_pkg.logonadmin(r.host);
			for s in (
				SELECT parent_sid_id, sid_id, dacl_id, flags
					  FROM security.SECURABLE_OBJECT
					START WITH parent_sid_id = securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies')
				 CONNECT BY sid_id = parent_sid_id
			) loop
				IF bitand(s.flags, Security_Pkg.SOFLAG_INHERIT_DACL) <> 0 THEN
		            -- pass inheritable ACEs onto the child
		            security.acl_pkg.PassACEsToChild(s.parent_sid_id, s.sid_id);
		        END IF;
			end loop;
	END LOOP;
	user_pkg.logonadmin;
END;
/

@update_tail