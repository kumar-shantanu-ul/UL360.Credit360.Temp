-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_chain_users_group_sid		security.security_pkg.T_SID_ID;
	v_act_id 					security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogOnAdmin;

	FOR r IN (
		SELECT c.app_sid, c.host, cu.csr_user_sid
		  FROM csr.csr_user cu
		  JOIN csr.customer c ON cu.app_sid = c.app_sid
		 WHERE user_name = 'Invitation Respondent'
	) LOOP
		security.user_pkg.LogOnAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;

		BEGIN
			v_chain_users_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'Groups/Chain Users');
			security.group_pkg.AddMember(v_act_id, r.csr_user_sid, v_chain_users_group_sid);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		security.user_pkg.LogOff(v_act_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/setup_body
@../chain/invitation_pkg
@../chain/invitation_body
@../chain/dev_body

@update_tail
