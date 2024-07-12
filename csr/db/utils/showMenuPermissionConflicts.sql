-- This script shows superfluous and conflicting permissions between menu SOs and their corresponding web resource SOs.

-- e.g. If group can see a menu entry but that group doesn't have direct access to the associated web resource, then this
-- script will report that.

-- Note that group membership is not considered - and should not be. e.g. If the "Registered Users" group can see both the
-- menu and web page and the "Administators" group can only see the web page, then this is undesirable even though it
-- currently causes no issues (either because all administrator users are also registered users or because the "Administrators"
-- group is a member of the "Registered Users" group): if permission is removed from the "Registered Users" group, then this
-- would leave "Administrators" able to visit the page without the menu item being visible. In the rare situation where we're
-- providing hidden functionality to users, this may be acceptable if deliberate. The reverse, permission on the menu but not
-- on the page, is definitely not.

SET SERVEROUTPUT ON

DECLARE
	v_app_sid		security_pkg.T_SID_ID;
	v_path_sid		security_pkg.T_SID_ID;
	v_act			security_pkg.T_ACT_ID;
	v_menu_sid		security_pkg.T_SID_ID;
	v_subpath		NUMBER(1);
	v_menu_reported	NUMBER(1);
BEGIN
	SELECT sys_context('SECURITY', 'APP')
	  INTO v_app_sid
	  FROM dual;
	  
	IF v_app_sid IS NULL THEN
		dbms_output.put_line('No app_sid set in current context. Logon as a site admin to use this script.');
	ELSE
		v_act := sys_context('SECURITY', 'ACT');
		v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Menu');
		
		FOR r IN (
			SELECT so.sid_id menu_sid, m.description, m.action, instr(m.action, '?') cgi_idx
			  FROM security.securable_object so
			  JOIN security.menu m
			    ON so.sid_id = m.sid_id
			 WHERE m.action LIKE '/%'						-- This script only supports absolute URLs, not non-HTTP protocols or cross-domain links, or relative URLs.
			 START WITH so.parent_sid_id = v_menu_sid		-- SOs have RLS, but not all menu SOs have an application_sid_id set (which is probably wrong, but there you go).
		   CONNECT BY so.parent_sid_id = PRIOR so.sid_id
		     ORDER BY m.description, m.sid_id
		) LOOP
			v_subpath := 0;
			v_path_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'wwwroot');
			
			BEGIN
				FOR s IN (
					SELECT item step
					  FROM TABLE(csr.utils_pkg.SplitString(CASE r.cgi_idx WHEN 0 THEN r.action ELSE substr(r.action, 1, r.cgi_idx - 1) END, '/'))
				) LOOP
					v_path_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_path_sid, s.step);
				END LOOP;
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					v_subpath := 1;
			END;
			
			v_menu_reported := 0;
			
			FOR p IN (
				SELECT sid_id principal_sid, ace_type, MAX(link_or_menu) link_or_menu
				  FROM (
					-- Security principals with read permission on the web resource.
					SELECT acl.sid_id, acl.ace_type, 1 link_or_menu
					  FROM security.acl
					  JOIN security.securable_object so
						ON acl.acl_id = so.dacl_id
					 WHERE so.sid_id = v_path_sid
					   AND bitand(acl.permission_set, security.security_pkg.PERMISSION_READ) <> 0
					   AND (v_subpath = 0 OR bitand(acl.ace_flags, security.security_pkg.ACE_FLAG_INHERITABLE) <> 0)
					 -- Security prinicpals with read permission on the menu item.
					 UNION ALL SELECT acl.sid_id, acl.ace_type, 2 link_or_menu
					  FROM security.acl
					  JOIN security.securable_object so
						ON acl.acl_id = so.dacl_id
					 WHERE so.sid_id = r.menu_sid
					   AND bitand(acl.permission_set, security.security_pkg.PERMISSION_READ) <> 0
				 )
				 GROUP BY sid_id, ace_type
				HAVING COUNT(*) = 1
				 ORDER BY principal_sid, ace_type
			) LOOP
				IF v_menu_reported = 0 THEN
					dbms_output.put_line('--');
					dbms_output.put_line('Menu "' || r.description || '" (' || r.menu_sid || ') pointing to ' || r.action || ' conflicts with web resource');
					dbms_output.put_line(security.securableobject_pkg.GetPathFromSID(v_act, v_path_sid) || ' (' || v_path_sid || ')');
					v_menu_reported := 1;
				END IF;
				dbms_output.put_line('--- ' || CASE p.ace_type WHEN security.security_pkg.ACE_TYPE_ALLOW THEN 'Read granted to ' WHEN security.security_pkg.ACE_TYPE_DENY THEN 'Read denied to ' ELSE '? ' END
					|| security.securableobject_pkg.GetPathFromSID(v_act, p.principal_sid) || ' (' || p.principal_sid || ') '
					|| CASE p.link_or_menu WHEN 1 THEN 'on web resource' ELSE 'on menu' END);
			END LOOP;
			
		END LOOP;
	END IF;
END;
/
