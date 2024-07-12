-- Please update version.sql too -- this keeps clean builds in sync
define version=3343
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_act					security.security_pkg.T_ACT_ID;
	v_sid					security.security_pkg.T_SID_ID;
	v_acl_id				security.security_pkg.T_ACL_ID;
	v_superadmins_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer WHERE question_library_enabled = 1
		 )
	)
	LOOP
		BEGIN
		-- Create menu item
		security.menu_pkg.CreateMenu(
			in_act_id			=> v_act,
			in_parent_sid_id	=> security.securableobject_pkg.GetSIDFromPath(v_act, r.application_sid_id,'menu/setup'),
			in_name				=> 'csr_surveys_config',
			in_description		=> 'Surveys Config',
			in_action			=> '/csr/site/surveys/config.acds',
			in_pos				=> NULL,
			in_context			=> NULL,
			out_sid_id			=> v_sid
		);
		END;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
