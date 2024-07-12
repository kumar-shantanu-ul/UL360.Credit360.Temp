-- Please update version.sql too -- this keeps clean builds in sync
define version=3388
define minor_version=5
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
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_app_ui_surveys		security.security_pkg.T_SID_ID;
	v_sag_sid					security.security_pkg.T_SID_ID;
	v_acl_id					security.security_pkg.T_ACL_ID;

	PROCEDURE INTERNAL_CreateOrGetResource(
		in_act_id			IN	security.security_pkg.T_ACT_ID,
		in_web_root_sid_id	IN	security.security_pkg.T_SID_ID,
		in_parent_sid_id	IN	security.security_pkg.T_SID_ID,
		in_page_name		IN	security.web_resource.path%TYPE,
		out_page_sid_id		OUT	security.web_resource.sid_id%TYPE
	)
	AS
	BEGIN
		security.web_pkg.CreateResource(
			in_act_id			=> in_act_id,
			in_web_root_sid_id	=> in_web_root_sid_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_page_name		=> in_page_name,
			in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
			in_rewrite_path		=> NULL,
			out_page_sid_id		=> out_page_sid_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_page_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_parent_sid_id, in_page_name);
	END;

BEGIN
	FOR r IN (
		SELECT app_sid, name
		  FROM csr.customer
		 WHERE question_library_enabled = 1
	) LOOP
		security.user_pkg.logonadmin(r.name);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

		-- Create new page web resource
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.surveys', v_www_app_ui_surveys);

		-- Add surveys authorised guest security
		BEGIN
			SELECT csr_user_sid
			  INTO v_sag_sid
			  FROM csr.csr_user
			  WHERE user_name = 'surveyauthorisedguest';

			v_acl_id := security.acl_pkg.GetDACLIDForSID(v_www_app_ui_surveys);
			security.acl_pkg.RemoveACEsForSid(v_act_id, v_acl_id, v_sag_sid);
			security.acl_pkg.AddACE(v_act_id, v_acl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;

		security.user_pkg.logonadmin();
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
