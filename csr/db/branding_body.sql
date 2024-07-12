CREATE OR REPLACE PACKAGE BODY csr.branding_pkg AS

PROCEDURE GetAllBrandings(
	out_all_brandings		OUT	SYS_REFCURSOR
)
AS
	v_branding_title			csr.branding.branding_title%TYPE;
	v_client_folder_name		csr.branding.client_folder_name%TYPE;
	v_author					csr.branding.author%TYPE;
BEGIN

	OPEN out_all_brandings FOR
		SELECT branding_title, client_folder_name, author
		  INTO v_branding_title, v_client_folder_name, v_author
		  FROM csr.branding
	     ORDER BY branding_title ASC;
END;

PROCEDURE GetAvailableBrandings(
	out_branding_availability		OUT	SYS_REFCURSOR
)
AS
	v_branding_title			csr.branding.branding_title%TYPE;
	v_client_folder_name		csr.branding.client_folder_name%TYPE;
	v_author					csr.branding.author%TYPE;
BEGIN
	OPEN out_branding_availability FOR
		SELECT b.branding_title, b.client_folder_name, b.author
		  INTO v_branding_title, v_client_folder_name, v_author
		  FROM csr.branding b,
		       csr.branding_availability bav
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.client_folder_name = bav.client_folder_name
	  ORDER BY branding_title ASC;
END;

/*
	Called from SecMgr
*/
PROCEDURE UNSEC_ChangeBranding(
	in_client_name					IN	csr.branding.client_folder_name%TYPE
)
AS
	TYPE t_string_tab 					IS TABLE OF VARCHAR2(30);

	v_www								security.security_pkg.T_SID_ID;
	v_www_new_client					security.security_pkg.T_SID_ID;
	v_www_new_client_styles				security.security_pkg.T_SID_ID;

	v_groups 							security.security_pkg.T_SID_ID;
	v_everyone							security.security_pkg.T_SID_ID;
	v_registered_users					security.security_pkg.T_SID_ID;
	v_admins							security.security_pkg.T_SID_ID; 

	v_tab_branding_attributes			T_STRING_TAB;

	v_current_attr						security.security_pkg.T_SO_ATTRIBUTE_STRING;
	v_new_attr							security.security_pkg.T_SO_ATTRIBUTE_STRING;

	v_current_attr_branding				VARCHAR2(30);

	v_act_id 							security.security_pkg.T_ACT_ID;
	v_app_sid							security.security_pkg.T_SID_ID;
BEGIN
	/* SESSION */
	v_act_id := security.security_pkg.getACT;
	v_app_sid := security.security_pkg.getApp;

	/* WEB RESOURCE ROOT */
	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	/* GROUPS */
	v_groups := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_everyone := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'Everyone');
	v_registered_users := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'RegisteredUsers');
	v_admins := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'Administrators');

	/* V_TAB_BRANDING_ATTRIBUTES
	     Application attributes to update.

	     NOTE: the web resource to rename is taken from the value found in the last attribute
	           listed here.
	*/
	v_tab_branding_attributes := T_STRING_TAB(
		'edit-css',
		'default-css',
		'default-stylesheet'
	);

	/* ATTRIBUTES */
	FOR i in 1 .. v_tab_branding_attributes.COUNT
	LOOP
		v_current_attr := GetBrandingAttribute(v_tab_branding_attributes(i));

		IF LENGTH(v_current_attr) > 0 THEN
			v_current_attr_branding := GetBrandingNameFromWebPath(v_current_attr);
			IF v_current_attr_branding IS NOT NULL AND v_current_attr_branding != in_client_name THEN
				-- don't update the stylesheet if new branding is currently in force.
				IF v_tab_branding_attributes(i) != 'default-stylesheet' OR
				   v_current_attr != '/csr/shared/branding/generic.xsl'
				THEN
					v_new_attr := '/'||in_client_name||'/'|| SUBSTR(v_current_attr, instr(v_current_attr, '/'||v_current_attr_branding||'/', 1, 1) + length(v_current_attr_branding) + 2);
					SetBrandingAttribute(v_tab_branding_attributes(i), v_new_attr);
				END IF;
			END IF;
		END IF;
	END LOOP;

	/* WEB RESOURCES */
	IF v_current_attr_branding IS NOT NULL AND v_current_attr_branding != in_client_name THEN
		/* Attempt to create the new client web resource */
		BEGIN
			security.web_pkg.CreateResource(v_act_id, v_www, v_www, in_client_name, v_www_new_client);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_www_new_client := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, in_client_name);
		END;

		BEGIN
			/* Give Administrators full access to the new client root */
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_new_client),
			security.security_pkg.ACL_INDEX_LAST,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins,
			security.security_pkg.PERMISSION_STANDARD_ALL);
		EXCEPTION
			WHEN security.security_pkg.duplicate_object_name THEN
				NULL;
		END;

		/* Attempt to create a new styles web resource under the new client */
		BEGIN
			security.web_pkg.CreateResource(v_act_id, v_www, v_www_new_client, 'styles', v_www_new_client_styles);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_www_new_client_styles := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_new_client, 'styles');
		END;

		BEGIN
			/* Give Registered Users read access to the new client root */
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_new_client),
			security.security_pkg.ACL_INDEX_LAST,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_registered_users,
			security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.duplicate_object_name THEN
				NULL;
		END;

		/* Give all users read access to the new styles folder */
		BEGIN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_new_client_styles),
			security.security_pkg.ACL_INDEX_LAST,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_everyone,
			security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.duplicate_object_name THEN
				NULL;
		END;
	END IF;
END;

PROCEDURE ChangeBranding(
	in_client_name					IN	csr.branding.client_folder_name%TYPE
)
AS
BEGIN
	/* PERMISSIONS */
	IF NOT CanChangeBrandings THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You do not have the "Change brandings" capability');
	END IF;

	IF IsBrandingLocked THEN
		RAISE_APPLICATION_ERROR(-20001, 'The branding for this application is locked');
	END IF;

	IF NOT IsBrandingAvailable(in_client_name) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The selected branding can not be applied to this application');
	END IF;

	UNSEC_ChangeBranding(
		in_client_name 		=> in_client_name
	);
END;

FUNCTION CanLockBrandings
	RETURN BOOLEAN
AS
BEGIN
	RETURN csr.csr_data_pkg.CheckCapability(security.security_pkg.getACT, 'Lock brandings');
	/*  AND security.security_pkg.IsAdmin(security.security_pkg.getACT) */
END;

FUNCTION CanLockBrandingsReturnLong
	RETURN NUMBER
AS
BEGIN
	IF CanLockBrandings THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

FUNCTION CanChangeBrandings
	RETURN BOOLEAN
AS
BEGIN
	RETURN csr.csr_data_pkg.CheckCapability(security.security_pkg.getACT, 'Change brandings');
END;

FUNCTION CanChangeBrandingsReturnLong
	RETURN NUMBER
AS
BEGIN
	IF CanChangeBrandings THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

FUNCTION IsBrandingLocked
	RETURN BOOLEAN
AS
	v_branding_locked   NUMBER(1);
BEGIN
	SELECT COUNT(*)
	  INTO v_branding_locked
	  FROM csr.branding_lock
	 WHERE app_sid = security.security_pkg.getApp
	   AND lock_expiry_dtm > SYSDATE
	   AND unlocked_dtm IS NULL;

	RETURN v_branding_locked >= 1;
END;

FUNCTION GetBrandingAttribute(
	in_attribute_name				IN	VARCHAR2
) RETURN VARCHAR2
AS
	v_attribute_value				VARCHAR2(100);
	v_act_id						security.security_pkg.T_ACT_ID :=  SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	/* ASPEN Application Attributes */
	IF LOWER(in_attribute_name) = 'default-admin-css' THEN
		SELECT default_admin_css
		  INTO v_attribute_value
		  FROM csr.customer
		 WHERE app_sid = v_app_sid
		   AND rownum = 1;
	ELSE
		SELECT
		  CASE
			WHEN LOWER(in_attribute_name) = 'default-stylesheet' THEN
				default_stylesheet
			WHEN LOWER(in_attribute_name) = 'edit-css' THEN
				edit_css
			WHEN LOWER(in_attribute_name) = 'default-css' THEN
				default_css
			ELSE
				NULL
			END
		  INTO v_attribute_value
		  FROM aspen2.application
		 WHERE app_sid = v_app_sid
		   AND rownum = 1;
	END IF;

	IF v_attribute_value IS NULL OR LENGTH(v_attribute_value) < 1 THEN
		RETURN NULL;
	END IF;

	RETURN v_attribute_value;
END;

PROCEDURE SetBrandingAttribute(
	in_attribute_name				IN	VARCHAR2,
	in_attribute_value				IN	VARCHAR2
)
AS
	v_app_sid						security.security_pkg.T_SID_ID  := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	/* CSR Customer Attributes */
	IF LENGTH(in_attribute_value) > 0 THEN
		IF LOWER(in_attribute_name) = 'default-admin-css' THEN
			UPDATE csr.customer
			   SET default_admin_css = in_attribute_value
			 WHERE app_sid = v_app_sid
			   AND rownum = 1;
		/* ASPEN Application Attributes */
		ELSIF LOWER(in_attribute_name) = 'default-stylesheet' THEN
			UPDATE aspen2.application
			   SET default_stylesheet = in_attribute_value
			 WHERE app_sid = v_app_sid
			   AND rownum = 1;
		ELSIF LOWER(in_attribute_name) = 'edit-css' THEN
			UPDATE aspen2.application
			   SET edit_css = in_attribute_value
			 WHERE app_sid = v_app_sid
			   AND rownum = 1;
		ELSIF LOWER(in_attribute_name) = 'default-css' THEN
			UPDATE aspen2.application
			   SET default_css = in_attribute_value
			 WHERE app_sid = v_app_sid
			   AND rownum = 1;
		END IF;
	END IF;
END;

PROCEDURE AddBranding(
	in_client_folder_name			IN	csr.branding.client_folder_name%TYPE,
	in_branding_title				IN	csr.branding.branding_title%TYPE,
	in_author						IN	csr.branding.author%TYPE DEFAULT NULL
) AS
	v_branding_exists			NUMBER;
BEGIN
	-- TODO: should be done with unique constraints
	SELECT COUNT (*)
	  INTO v_branding_exists
	  FROM csr.branding
	 WHERE lower(in_client_folder_name) = lower(client_folder_name);

	IF v_branding_exists < 1 THEN
		INSERT INTO csr.branding (client_folder_name, branding_title, author)
		 	 VALUES (lower(in_client_folder_name), in_branding_title, in_author);
	END IF;
END;

PROCEDURE AllowBranding(
	in_client_folder_name			IN 		csr.branding.client_folder_name%TYPE
)
AS
BEGIN
	AllowBranding(SYS_CONTEXT('SECURITY', 'APP'), in_client_folder_name);
END;

PROCEDURE AllowBranding(
	in_app_sid						IN	security.security_pkg.T_SID_ID,
	in_client_folder_name			IN	csr.branding.client_folder_name%TYPE
)
AS
	v_branding_exists			NUMBER;
BEGIN
	IF NOT CanChangeBrandings THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You do not have the "Change brandings" capability');
	END IF;
	
	SELECT COUNT (*)
	  INTO v_branding_exists
	  FROM csr.branding
	 WHERE lower(in_client_folder_name) = lower(client_folder_name);

	IF v_branding_exists > 0 THEN
		BEGIN
			INSERT INTO csr.branding_availability (app_sid, client_folder_name)
			VALUES (in_app_sid, lower(in_client_folder_name));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	ELSE
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Branding not found');
	END IF;
END;

PROCEDURE GetLockInfo(
	out_lock_info					OUT SYS_REFCURSOR
)
AS
	v_app_sid							security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_locked_by 						security.security_pkg.T_SID_ID;
	v_locked_by_full_name				csr.csr_user.full_name%TYPE;
	v_locked_by_email					csr.csr_user.email%TYPE;
	v_lock_expiry_dtm					csr.branding_lock.lock_expiry_dtm%TYPE;
BEGIN
	IF NOT CanChangeBrandings THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You do not have the "Change brandings" capability');
	END IF;

	BEGIN
		SELECT LOCKED_BY
		  INTO v_locked_by
		  FROM csr.branding_lock
		 WHERE app_sid = v_app_sid
		   AND lock_expiry_dtm > SYSDATE
		   AND unlocked_dtm IS NULL
		   AND rownum=1;

		OPEN out_lock_info FOR
			SELECT usr.full_name, usr.email, bl.lock_expiry_dtm
			  INTO v_locked_by_full_name, v_locked_by_email, v_lock_expiry_dtm
			  FROM csr.csr_user usr,
			       csr.branding_lock bl
			 WHERE usr.csr_user_sid = bl.locked_by
			   AND bl.unlocked_dtm IS NULL
			   AND bl.lock_expiry_dtm > SYSDATE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_lock_info FOR
				SELECT NULL FROM DUAL;
	END;
END;

PROCEDURE ToggleBrandingLock(
	in_lock_duration_hrs			IN	NUMBER	DEFAULT 1
)
AS
	v_app_sid							security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id							security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_user_sid							security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');

BEGIN
	/* DURATION CHECK */
	IF in_lock_duration_hrs > 48 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The maximum lock duration is 48 hours.');
	END IF;

	IF in_lock_duration_hrs < 0.12 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The minimum lock duration is 5 minutes.');
	END IF;

	/* PERMISSIONS */
	IF NOT CanChangeBrandings THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You do not have the "Change brandings" capability');
	END IF;

	IF NOT CanLockBrandings THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Lock modification not approved: You do not have the "Lock brandings" capability.');
	END IF;

	IF NOT IsBrandingLocked THEN
		/* LOCK BRANDING */
		INSERT INTO csr.branding_lock (app_sid, lock_expiry_dtm, locked_by, unlocked_by, unlocked_dtm)
		     VALUES (v_app_sid, SYSDATE + in_lock_duration_hrs/24, v_user_sid, null, null);
	ELSE
		/* UNLOCK BRANDING */
		UPDATE csr.branding_lock
		   SET unlocked_by = v_user_sid,
		       unlocked_dtm = SYSDATE
		 WHERE app_sid = v_app_sid
		   AND lock_expiry_dtm > SYSDATE
		   AND unlocked_dtm IS NULL;
	END IF;
END;

FUNCTION GetCurrentClientFolderName
	RETURN VARCHAR2
AS
	v_default_stylesheet_path 		security.security_pkg.T_SO_ATTRIBUTE_STRING;
BEGIN
	v_default_stylesheet_path := GetBrandingAttribute('default-stylesheet');

	IF v_default_stylesheet_path IS NULL OR LENGTH(v_default_stylesheet_path) < 1 THEN
		RETURN NULL;
	END IF;

	RETURN GetBrandingNameFromWebPath(v_default_stylesheet_path);
END;

FUNCTION GetBrandingNameFromWebPath(
	in_web_path						IN	security.security_pkg.T_SO_ATTRIBUTE_STRING
) RETURN VARCHAR2
AS
	v_client_folder_name VARCHAR2(255);
BEGIN
	v_client_folder_name := REGEXP_SUBSTR(in_web_path, '/([-_.a-zA-Z0-9 ,*?]+?)/', 1, 1, 'i');
	v_client_folder_name := REPLACE(v_client_folder_name, '/');

	RETURN v_client_folder_name;
END;

FUNCTION IsBrandingAvailable(
	in_branding						IN csr.branding.client_folder_name%TYPE
) RETURN BOOLEAN
AS
	v_branding_available			NUMBER(2);
BEGIN
	IF NOT CanChangeBrandings THEN
		RETURN FALSE;
	END IF;

	SELECT DISTINCT COUNT (b.client_folder_name)
	  INTO v_branding_available
	  FROM  csr.branding b,
	        csr.branding_availability bav
	 WHERE LOWER(b.client_folder_name) = LOWER(in_branding)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND b.client_folder_name = bav.client_folder_name;

	RETURN v_branding_available >= 1;
END;

FUNCTION IsBrandingServiceEnabled
	RETURN BOOLEAN
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_enabled						NUMBER(1);
BEGIN
	SELECT branding_service_enabled
	  INTO v_enabled
	  FROM aspen2.application 
	 WHERE app_sid = v_app_sid;

	RETURN v_enabled = 1;
END;

FUNCTION Sql_IsBrandingServiceEnabled
	RETURN NUMBER
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_enabled						NUMBER(1);
BEGIN
	IF IsBrandingServiceEnabled THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;


/*
 * AddAce for SID but remove first to avoid duplicates
 * Parameters match security.acl_pkg.AddACE for easy search and replace.
 * */
 --XXX: This seems wrong this could remove an ace with more permissions to add one with less?
PROCEDURE INTERNAL_AddACE_NoDups(
	in_act_id			IN 	security.security_pkg.T_ACT_ID,
	in_acl_id			IN Security_Pkg.T_ACL_ID,
	in_acl_index		IN Security_Pkg.T_ACL_INDEX,
	in_ace_type			IN Security_Pkg.T_ACE_TYPE,
	in_ace_flags		IN Security_Pkg.T_ACE_FLAGS,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_permission_set	IN Security_Pkg.T_PERMISSION
)
AS
BEGIN
	security.acl_pkg.RemoveACEsForSid(in_act_id, in_acl_id, in_sid_id);
	security.acl_pkg.AddACE(in_act_id, in_acl_id, in_acl_index, in_ace_type, in_ace_flags, in_sid_id, in_permission_set);
END;
	
PROCEDURE SetMegaMenu(
	in_value						IN  NUMBER
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_user_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_groups_sid					security_pkg.T_SID_ID;
	v_everyone_sid					security_pkg.T_SID_ID;
	v_registered_users				security_pkg.T_SID_ID;
	v_menu_sid						security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT csr.csr_user_pkg.IsSuperAdmin = 1 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You must be a super admin');
	END IF;

	UPDATE aspen2.application 
	   SET mega_menu_enabled = in_value 
	 WHERE app_sid = v_app_sid;
	 
	csr_data_pkg.WriteAuditLogEntry(v_act_id, csr_data_pkg.AUDIT_TYPE_MODULE_ENABLED, v_app_sid, v_user_sid, 'Set mega menu {0}', CASE in_value WHEN 1 THEN 'on' WHEN 0 THEN 'off' ELSE 'off' END);

	v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
	v_registered_users := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'ui.menu');
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERITABLE, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_registered_users, security.security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERITABLE, v_registered_users, security.security_pkg.PERMISSION_STANDARD_READ);
END;

FUNCTION IsMegaMenuEnabled
	RETURN NUMBER
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_enabled						NUMBER(1);
BEGIN
	SELECT mega_menu_enabled
	  INTO v_enabled
	  FROM aspen2.application 
	 WHERE app_sid = v_app_sid;

	RETURN v_enabled;
END;

FUNCTION IsMobileBrandingEnabled RETURN NUMBER
AS
	v_enabled						NUMBER(1);
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	SELECT COUNT(app_sid)
	  INTO v_enabled
	  FROM csr.customer
	 WHERE app_sid = v_app_sid
	   AND mobile_branding_enabled = 1;

	RETURN CASE WHEN v_enabled > 0 THEN 1 ELSE 0 END;
END;

PROCEDURE EnableMobileBranding(
	in_value						IN  NUMBER
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_user_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	IF NOT csr.csr_user_pkg.IsSuperAdmin = 1 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You must be a super admin');
	END IF;

	UPDATE csr.customer
	   SET mobile_branding_enabled = CASE WHEN in_value = 1 THEN 1 ELSE 0 END
	 WHERE app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(
		v_act_id,
		csr_data_pkg.AUDIT_TYPE_MODULE_ENABLED,
		v_app_sid,
		v_user_sid,
		'Enable mobile branding {0}',
		CASE in_value WHEN 1 THEN 'on' ELSE 'off' END
	);
END;

FUNCTION IsUlDesignSystemEnabled RETURN NUMBER
AS
	v_enabled						NUMBER(1);
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	SELECT COUNT(app_sid)
	  INTO v_enabled
	  FROM aspen2.application
	 WHERE app_sid = v_app_sid
	   AND ul_design_system_enabled = 1;

	RETURN CASE WHEN v_enabled > 0 THEN 1 ELSE 0 END;
END;

PROCEDURE EnableUlDesignSystem(
	in_value						IN  NUMBER
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_user_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	IF NOT csr.csr_user_pkg.IsSuperAdmin = 1 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You must be a super admin');
	END IF;

	UPDATE aspen2.application
	   SET ul_design_system_enabled = CASE WHEN in_value = 1 THEN 1 ELSE 0 END
	 WHERE app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(
		v_act_id,
		csr_data_pkg.AUDIT_TYPE_MODULE_ENABLED,
		v_app_sid,
		v_user_sid,
		'Enable UL Design System {0}',
		CASE in_value WHEN 1 THEN 'on' ELSE 'off' END
	);
END;

FUNCTION IsBrandingServiceEnabled_NEW RETURN NUMBER
AS
	v_enabled						NUMBER(1);
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	SELECT branding_service_enabled
	  INTO v_enabled
	  FROM aspen2.application
	 WHERE app_sid = v_app_sid;

	RETURN v_enabled;
END;

PROCEDURE SetBrandingServiceEnabled(
	in_value						IN  NUMBER
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_user_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	IF NOT csr.csr_user_pkg.IsSuperAdmin = 1 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'You must be a super admin');
	END IF;

	UPDATE aspen2.application 
	   SET branding_service_enabled = in_value 
	 WHERE app_sid = v_app_sid;
	 
	csr_data_pkg.WriteAuditLogEntry(v_act_id, csr_data_pkg.AUDIT_TYPE_MODULE_ENABLED, v_app_sid, v_user_sid, 'Set branding service enabled {0}', CASE in_value WHEN 2 THEN 'on - new api' WHEN 1 THEN 'on' WHEN 0 THEN 'off' ELSE 'off' END);
END;

END;
/
