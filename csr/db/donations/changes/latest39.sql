-- Please update version.sql too -- this keeps clean builds in sync
define version=39
@update_header

grant select, references on scheme to security;

connect security/security@&_CONNECT_IDENTIFIER

-- ensure all schemes have Add contents permission if the users have 'update' permissions
BEGIN
    FOR r IN (
        SELECT c.host, soa.NAME, sc.description, so.sid_id, acl.acl_id
          FROM SECURITY.securable_object so, SECURITY.acl, csr.customer c, donations.scheme sc, SECURITY.securable_object soa
         WHERE so.sid_id = sc.scheme_sid
            AND so.dacl_id = acl.acl_id
            AND bitwise_pkg.bitand(acl.permission_set, 
				donations.scheme_pkg.PERMISSION_UPDATE_MINE + 
				donations.scheme_pkg.PERMISSION_UPDATE_ALL +  
				donations.scheme_pkg.PERMISSION_ADD_NEW + 
				donations.scheme_pkg.PERMISSION_UPDATE_REGION) > 0
            AND bitwise_pkg.bitand(acl.permission_set, security_pkg.PERMISSION_ADD_CONTENTS) = 0
            AND sc.app_sid = c.app_sid
            AND acl.sid_id = soa.sid_id
    )
    LOOP
        dbms_output.put_line('Fixing '||r.name||' permissions on '||r.host||' '||r.description||' scheme');
        UPDATE SECURITY.acl
           SET permission_set = bitwise_pkg.bitor(permission_set, security_pkg.PERMISSION_ADD_CONTENTS)
         WHERE acl_id = r.acl_Id;
    END LOOP;
END;
/
 
 
connect donations/donations@&_CONNECT_IDENTIFIER
 
@update_tail
