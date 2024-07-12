-- Please update version.sql too -- this keeps clean builds in sync
define version=323
@update_header

PROMPT enter connection string, e.g. ASPEN

-- Dickie's utility_pkg references this
connect cms/cms@&&1
grant select on item_id_seq to csr;

connect csr/csr@&&1

-- add admins to 
DECLARE
	v_admins	security_pkg.T_SID_ID;
	v_doclib	security_pkg.T_SID_ID;
	v_act		security_pkg.T_ACT_ID;
BEGIN
	FOR r IN (
		SELECT app_sid, host FROM customer where host not in ('vancitytest.credit360.com','rbsinitiatives.credit360.com','survey.credit360.com','thematrix.credit360.com','junkhsbc.credit360.com')
	)
	LOOP
		user_pkg.logonadmin(r.host);
		dbms_output.put_line(r.host);
		v_admins := securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'groups/Administrators');
		-- try and locate doclib
		BEGIN
			v_doclib := securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'wwwroot/csr/site/doclib');
			acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_doclib), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_admins, 
				security_pkg.PERMISSION_STANDARD_ALL);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- whatever
		END;
	END LOOP;
END;
/


@update_tail