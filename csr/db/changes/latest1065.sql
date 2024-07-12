-- Please update version.sql too -- this keeps clean builds in sync
define version=1065
@update_header

UPDATE security.acl
   SET ace_flags=3
 WHERE ace_flags=2
   AND acl_id in (
	SELECT security.acl_pkg.GetDACLIDForSID(sid_id)
	  FROM security.web_resource
	 WHERE path='/csr/site/issues2'
);

BEGIN
	security.user_pkg.logonadmin;
	
	-- Now propogate changes above to relevant issues2 children
	FOR r IN (
		SELECT sid_id
		  FROM security.web_resource
		 WHERE path='/csr/site/issues2'
	) LOOP
		security.acl_pkg.PropogateACEs(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
END;
/


@update_tail
