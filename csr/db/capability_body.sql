CREATE OR REPLACE PACKAGE BODY CSR.capability_pkg IS

FUNCTION GetCapabilityContainer 
  RETURN security_pkg.T_SID_ID
AS
	v_cap_container_id	security_pkg.T_SID_ID;
BEGIN
	SELECT sid_id
	  INTO v_cap_container_id
	  FROM security.securable_object 
	 WHERE name = 'Capabilities' AND parent_sid_id = security.security_pkg.GetApp;

	 RETURN v_cap_container_id;
END;

FUNCTION GetCapabilityClass 
  RETURN security.securable_object_class.class_id%TYPE
AS
	v_cap_class_id	security.securable_object_class.class_id%TYPE;
BEGIN
	SELECT class_id 
	  INTO v_cap_class_id
	  FROM security.securable_object_class 
	 WHERE class_name = 'CSRCapability';

	 RETURN v_cap_class_id;
END;

PROCEDURE GetCapabilities(
	out_cur OUT SYS_REFCURSOR
)
AS
	v_cap_class_id	security.securable_object_class.class_id%TYPE;
BEGIN
	v_cap_class_id := GetCapabilityClass;

	OPEN out_cur FOR
		SELECT c.name, c.allow_by_default, c.description, CASE WHEN so.name IS NOT NULL THEN 1 ELSE 0 END manually_enabled
		  FROM CAPABILITY c
		  LEFT JOIN security.securable_object so ON so.name = c.name AND 
					so.class_id = v_cap_class_id AND
					so.application_sid_id = security.security_pkg.GetApp
		 WHERE c.description IS NOT NULL
		 ORDER BY LOWER(name) ASC;
END;

PROCEDURE ChangeCapability(
	in_capability_name	IN CAPABILITY.name%TYPE,
	in_action			IN NUMBER
)
AS
	v_cap_container_id	security_pkg.T_SID_ID;
	v_cap_class_id		security.securable_object_class.class_id%TYPE;
	v_sid_id			security_pkg.T_SID_ID;
BEGIN
	v_cap_container_id := GetCapabilityContainer;
	v_cap_class_id := GetCapabilityClass;


	IF in_action = 0 THEN
		BEGIN
			SELECT sid_id 
			  INTO v_sid_id
			  FROM security.securable_object
			 WHERE name = in_capability_name AND 
				   class_id = v_cap_class_id AND
				   application_sid_id = security.security_pkg.GetApp;

			security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, v_sid_id);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;
	ELSE
		BEGIN
			security.securableobject_pkg.CreateSO(security.security_pkg.GetACT, v_cap_container_id, v_cap_class_id,
				in_capability_name, v_sid_id);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
	END IF;
	
	LogChangeCapability(in_capability_name, in_action, security.security_pkg.GetSid);
END;

PROCEDURE LogChangeCapability(
	in_capability_name	IN CAPABILITY.name%TYPE,
	in_action			IN NUMBER,
	in_user_sid			IN security.security_pkg.T_SID_ID
)
AS
	v_app 		security.security_pkg.T_SID_ID := security.security_pkg.GetApp;
	v_action 	VARCHAR2(20);
BEGIN
	v_action := CASE WHEN in_action = 0 THEN 'disabled' ELSE 'enabled' END;
	
	-- Write log entry
	csr_data_pkg.WriteAuditLogEntryForSid(in_user_sid, csr_data_pkg.AUDIT_TYPE_CAPABILITY_ENABLED, v_app, v_app,
		'Capability {0} : {1}', v_action, in_capability_name);
END;

END capability_pkg;
/
