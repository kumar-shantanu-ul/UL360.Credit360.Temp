-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
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
BEGIN
	INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Quick chart management', 0, 'Allows user to manage quick chart columns and filters configuration.');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

DECLARE
	v_act_id								security.security_pkg.T_ACT_ID;
	v_app_sid								security.security_pkg.T_SID_ID;
	v_sys_mng_cap_path						VARCHAR2(100) := '/Capabilities/System management';
	v_sys_mng_cap_sid						security.security_pkg.T_SID_ID;
	v_sys_mng_cap_dacl_id					security.securable_object.dacl_id%TYPE;
	v_qck_chrt_cap_path						VARCHAR2(100) := '/Capabilities/Quick chart management';
	v_qck_chrt_cap_sid						security.security_pkg.T_SID_ID;
	v_qck_chrt_cap_dacl_id					security.securable_object.dacl_id%TYPE;

	PROCEDURE EnableCapability(
		in_act_id						IN	security.security_pkg.T_ACT_ID,
		in_app_sid						IN	security.security_pkg.T_SID_ID,
		in_capability  					IN	security.security_pkg.T_SO_NAME
	)
	AS
		v_cap_path							VARCHAR2(100) := '/Capabilities';
		v_allow_by_default					csr.capability.allow_by_default%TYPE;
		v_capability_sid					security.security_pkg.T_SID_ID;
		v_capabilities_sid					security.security_pkg.T_SID_ID;
	BEGIN
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;

		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, v_cap_path);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(
					in_act_id				=> in_act_id,
					in_parent_sid			=> in_app_sid,
					in_object_class_id		=> security.security_pkg.SO_CONTAINER,
					in_object_name			=> 'Capabilities',
					out_sid_id				=> v_capabilities_sid
				);
		END;

		BEGIN
			security.securableobject_pkg.CreateSO(
				in_act_id				=> in_act_id,
				in_parent_sid			=> v_capabilities_sid,
				in_object_class_id		=> security.class_pkg.GetClassId('CSRCapability'),
				in_object_name			=> in_capability,
				out_sid_id				=> v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END;
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR r IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');

		BEGIN
			v_sys_mng_cap_sid := security.securableobject_pkg.GetSIDFromPath(
				in_act				=> v_act_id,
				in_parent_sid_id	=> v_app_sid,
				in_path				=> v_sys_mng_cap_path
			);
			v_sys_mng_cap_dacl_id := security.acl_pkg.GetDACLIDForSID(
				in_sid_id		=> v_sys_mng_cap_sid
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;

		EnableCapability(
			in_act_id		=> v_act_id,
			in_app_sid		=> v_app_sid,
			in_capability	=> 'Quick chart management'
		);

		v_qck_chrt_cap_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, v_qck_chrt_cap_path);
		v_qck_chrt_cap_dacl_id := security.acl_pkg.GetDACLIDForSID(v_qck_chrt_cap_sid);

		security.acl_pkg.DeleteAllACES(
			in_act_id			=> v_act_id,
			in_acl_id			=> v_qck_chrt_cap_dacl_id
		);

		FOR r IN (
			SELECT acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set
			  FROM security.acl
			 WHERE acl_id = v_sys_mng_cap_dacl_id
			 ORDER BY acl_index
		)
		LOOP
			security.acl_pkg.AddACE(
				in_act_id				=> v_act_id,
				in_acl_id				=> v_qck_chrt_cap_dacl_id,
				in_acl_index			=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type				=> r.ace_type,
				in_ace_flags			=> r.ace_flags,	
				in_sid_id				=> r.sid_id,
				in_permission_set		=> r.permission_set
			);
		END LOOP;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../chain/filter_body


@update_tail
