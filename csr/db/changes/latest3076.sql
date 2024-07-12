-- Please update version.sql too -- this keeps clean builds in sync
define version=3076
define minor_version=0
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
CREATE OR REPLACE PROCEDURE security.Temp_CreateSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_parent_sid		IN Security_Pkg.T_SID_ID,
    in_object_class_id  IN Security_Pkg.T_CLASS_ID,
    in_object_name		IN Security_Pkg.T_SO_NAME,
    out_sid_id			OUT Security_Pkg.T_SID_ID
) AS
	v_duplicates NUMBER;
	v_new_object_sid_id Security_Pkg.T_SID_ID;
	v_owner_sid Security_Pkg.T_SID_ID;
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, Security_Pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the parent object with sid '||in_parent_sid);
	END IF;

	IF in_object_name IS NOT NULL THEN
		-- Check for duplicates
	    SELECT COUNT(*) INTO v_duplicates
		  FROM securable_object
		 WHERE parent_sid_id = in_parent_sid
		   AND LOWER(name) = LOWER(in_object_name);
	    IF v_duplicates <> 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate object name '||in_object_name||' with parent sid '||in_parent_sid);
	    END IF;
	    -- The path separator is not valid in an object name (in theory it is possible, but it
	    -- needs to be quotable, and we don't support that at present, so it's better to not
	    -- let people create objects that they can't find)
	    IF INSTR(in_object_name, '/') <> 0 THEN
	    	RAISE_APPLICATION_ERROR(Security_Pkg.ERR_INVALID_OBJECT_NAME, 'Invalid object name '||in_object_name);
	    END IF;
	END IF;

	-- Get object owner sid
	User_Pkg.GetSID(in_act_id, v_owner_sid);

	-- Insert a new object
	SELECT sid_id_seq.NEXTVAL INTO v_new_object_sid_id
	  FROM dual;
    INSERT INTO securable_object (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner)
	VALUES (v_new_object_sid_id, in_parent_sid, NULL, in_object_class_id, in_object_name,
		    Security_Pkg.SOFLAG_INHERIT_DACL, v_owner_sid);

	-- inherit ACEs from parent (...)
    IF in_parent_sid IS NOT NULL THEN
		Acl_Pkg.PASSACEStochild(in_parent_sid, v_new_object_sid_id);
    END IF;
	
	out_sid_id := v_new_object_sid_id;
END;
/

GRANT EXECUTE ON security.Temp_CreateSO TO CSR;

CREATE OR REPLACE PROCEDURE csr.Temp_CreateFolder(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_description					IN	doc_folder.description%TYPE DEFAULT EMPTY_CLOB(),
	in_approver_is_override			IN	doc_folder.approver_is_override%TYPE DEFAULT 0,
	in_approver_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_lifespan_is_override			IN	doc_folder.lifespan_is_override%TYPE DEFAULT 0,
	in_lifespan						IN	doc_folder.lifespan%TYPE DEFAULT NULL,
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_property_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_is_system_managed			IN	doc_folder.is_system_managed%TYPE DEFAULT 0,
	out_sid_id						OUT	security_pkg.T_SID_ID
)
AS
	v_lifespan						doc_folder.lifespan%TYPE;
	v_approver_sid					security_pkg.T_SID_ID;
	v_company_sid					security_pkg.T_SID_ID;
	v_property_sid					security_pkg.T_SID_ID;
	v_parent_is_doc_lib				security_pkg.T_SID_ID;
	v_name							security_pkg.T_SO_NAME := in_name;
BEGIN
	-- For system managed folders e.g. Documents, Recycle bin keep so name else set so name to null
	IF in_is_system_managed = 0 THEN
		v_name := NULL;
	END IF;

	security.Temp_CreateSO(security_pkg.GetACT(), in_parent_sid, 
		class_pkg.GetClassId('DocFolder'), v_name, out_sid_id);
	
	BEGIN
		SELECT lifespan, approver_sid, company_sid, property_sid
		  INTO v_lifespan, v_approver_sid, v_company_sid, v_property_sid
		  FROM doc_folder
		 WHERE doc_folder_sid = in_parent_sid;
	EXCEPTION	
		WHEN NO_DATA_FOUND THEN
			NULL; -- ignore - probably this is under the root
	END;
	
	INSERT INTO doc_folder (doc_folder_sid, description, lifespan, approver_sid, company_sid, 
							property_sid, is_system_managed)		  
		SELECT out_sid_id doc_folder_sid, in_description description, 
			CASE WHEN in_lifespan_is_override = 1 THEN in_lifespan ELSE v_lifespan END, 
			CASE WHEN in_approver_is_override = 1 THEN in_approver_sid ELSE v_approver_sid END,
			NVL(in_company_sid, v_company_sid), NVL(in_property_sid, v_property_sid), in_is_system_managed
		  FROM dual;

	INSERT INTO doc_folder_name_translation (doc_folder_sid, lang, translated)
	SELECT out_sid_id, lang, in_name
	  FROM v$customer_lang;
END;
/

DECLARE
	v_indexes_root_sid			security.security_pkg.T_SID_ID;
	v_def_doc_lib_sid			security.security_pkg.T_SID_ID;
	v_doc_folder_sid			security.security_pkg.T_SID_ID;
	v_reports_folder_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR s IN (
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
		security.user_pkg.LogOnAdmin(s.host);
		-- Get Indexes container
		BEGIN
			v_indexes_root_sid := security.securableobject_pkg.GetSidFromPath(
				in_act				=> security.security_pkg.GetAct,
				in_parent_sid_id	=> security.security_pkg.GetApp,
				in_path				=> 'Indexes'
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;

		-- Get default/main doc lib
		BEGIN
			v_def_doc_lib_sid := security.securableobject_pkg.GetSidFromPath(
				in_act				=> security.security_pkg.GetAct,
				in_parent_sid_id	=> security.security_pkg.GetApp,
				in_path				=> 'Documents'
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;		

		BEGIN
			v_doc_folder_sid := security.securableobject_pkg.GetSidFromPath(
				in_act				=> security.security_pkg.GetAct,
				in_parent_sid_id	=> v_def_doc_lib_sid,
				in_path				=> 'Documents'
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;

		BEGIN
			v_reports_folder_sid := security.securableobject_pkg.GetSidFromPath(
				in_act				=> security.security_pkg.GetAct,
				in_parent_sid_id	=> v_doc_folder_sid,
				in_path				=> 'Reports'
			);
			
			UPDATE csr.doc_folder
			   SET is_system_managed = 1
			 WHERE doc_folder_sid = v_reports_folder_sid
			   AND is_system_managed = 0;

		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				csr.Temp_CreateFolder(
					in_parent_sid			=> v_doc_folder_sid, 
					in_name					=> 'Reports',
					in_is_system_managed	=> 1,
					out_sid_id				=> v_reports_folder_sid
				);
		END;
		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/

DROP PROCEDURE csr.Temp_CreateFolder;
DROP PROCEDURE security.Temp_CreateSO;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
