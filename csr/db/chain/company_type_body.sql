CREATE OR REPLACE PACKAGE BODY CHAIN.company_type_pkg
IS

PROCEDURE LogCompanyTypeChange (
	in_description					IN	VARCHAR2,
	in_param_1          			IN  VARCHAR2 DEFAULT NULL,
	in_param_2          			IN  VARCHAR2 DEFAULT NULL,
	in_param_3          			IN  VARCHAR2 DEFAULT NULL,
	in_sub_object_id				IN	NUMBER
)
AS
BEGIN
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id				=> security_pkg.GetAct,
		in_audit_type_id		=> csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid				=> security_pkg.GetApp,
		in_object_sid			=> security_pkg.GetApp,
		in_description			=> in_description,
		in_param_1          	=> in_param_1,
		in_param_2          	=> in_param_2,
		in_param_3          	=> in_param_3,
		in_sub_object_id		=> in_sub_object_id
	);
END;

PROCEDURE SetCompanyTypeRole_ (
	in_lookup_key	IN company_type.lookup_key%TYPE
)
AS
	v_company_type_id	company_type.company_type_id%TYPE DEFAULT GetCompanyTypeId(in_lookup_key);
	v_role_sid			security_pkg.T_SID_ID;
	v_plural			company_type.plural%TYPE;
	v_singular			company_type.singular%TYPE;
BEGIN
	
	BEGIN
		SELECT plural, singular
		  INTO v_plural, v_singular
		  FROM chain.company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_type_id = v_company_type_id
		   AND use_user_role = 1
		   AND user_role_sid IS NULL;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RETURN; 
	END;   

	csr.role_pkg.SetRole(v_plural, in_lookup_key, v_role_sid);
	
	UPDATE csr.role
	   SET is_system_managed = 1
	 WHERE role_sid = v_role_sid;
	 
	UPDATE chain.company_type
	   SET user_role_sid = v_role_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = v_company_type_id;
	   
	LogCompanyTypeChange(
		in_description			=> 'Role created for company type "{0}".',
		in_param_1          	=> v_singular,
		in_sub_object_id		=> v_company_type_id
	);
	
END;

PROCEDURE Internal_Update_Group_Sid(
	in_company_type_id		IN security_pkg.T_SID_ID,
	in_group_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE company_type
	   SET user_group_sid = in_group_sid
	 WHERE company_type_id = in_company_type_id;
	 
	LogCompanyTypeChange(
		in_description			=> 'Company type user group sid changed to {0}.',
		in_param_1          	=> in_group_sid,
		in_sub_object_id		=> in_company_type_id
	);
END;

/* Create company type top level group under /Chain/CompanyTypeGroups/ */
PROCEDURE Intern_CreateCompanyTypeGroup (
	in_company_type_id		IN security_pkg.T_SID_ID,
	in_company_type_lookup	IN company_type.lookup_key%TYPE,
	out_group_sid			OUT security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_chain_sid 			security_pkg.T_SID_ID;
	v_company_type_groups_sid 	security_pkg.T_SID_ID;
BEGIN
	SELECT user_group_sid
	  INTO out_group_sid
	  FROM company_type
	 WHERE company_type_id = in_company_type_id;
	 
	 --try creating /Chain/CompanyTypeGroups container
	BEGIN
		v_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain');
		v_company_type_groups_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_chain_sid, 'CompanyTypeGroups');
		
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, v_chain_sid, security_pkg.SO_CONTAINER, 'CompanyTypeGroups', v_company_type_groups_sid);
					 
			security.acl_pkg.AddACE(
				v_act_id, 
				security.acl_pkg.GetDACLIDForSID(v_company_type_groups_sid), 
				-1, 
				security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, 
				security.securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.getApp, 'Users/UserCreatorDaemon'), 
				security.security_pkg.PERMISSION_STANDARD_ALL
			);	

			security.acl_pkg.PropogateACEs(v_act_id, v_company_type_groups_sid);
	END;

	IF out_group_sid IS NULL THEN
		BEGIN
			out_group_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_company_type_groups_sid, in_company_type_lookup);	
		EXCEPTION 
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				group_pkg.CreateGroup(v_act_id, v_company_type_groups_sid, security_pkg.GROUP_TYPE_SECURITY, in_company_type_lookup, out_group_sid);
		END;
		
		Internal_Update_Group_Sid(in_company_type_id, out_group_sid);
	END IF;

END;

FUNCTION GetCompanyTypeDescription (
	in_company_type_id			IN  company_type.company_type_id%TYPE
) RETURN VARCHAR2
AS
	v_singular 					company_type.singular%TYPE;
BEGIN
	SELECT singular
	  INTO v_singular
	  FROM company_type
	 WHERE company_type_id = in_company_type_id;
	 
	RETURN v_singular;
END;

PROCEDURE CompanyCreated(
	in_company_sid	IN security_pkg.T_SID_ID	
)
AS
	v_use_groups_enabled		customer_options.use_company_type_user_groups%TYPE := helper_pkg.UseCompanyTypeUserGroups;
	v_company_type_id			company_type.company_type_id%TYPE;
	v_company_type_lookup		company_type.lookup_key%TYPE;
	v_company_type_group_sid	security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_users_sid					security_pkg.T_SID_ID;
BEGIN
	
	-- check if customer options.USE_COMPANY_TYPE_USER_GROUPS is enabled
	IF v_use_groups_enabled = 1 THEN 
		SELECT c.company_type_id, ct.lookup_key
		  INTO v_company_type_id, v_company_type_lookup
		  FROM company c
		  JOIN company_type ct ON (c.company_type_id = ct.company_type_id)
		 WHERE c.company_sid = in_company_sid;
		 
		 --Create company type group (under root/group/) if not already exists and return sid
		 Intern_CreateCompanyTypeGroup(v_company_type_id, v_company_type_lookup, v_company_type_group_sid);
		 
		 --Add company's user group to new company type group
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
		group_pkg.AddMember(v_act_id, v_users_sid, v_company_type_group_sid);
	END IF;

END;

PROCEDURE SwitchCompanyCompanyType(
	in_company_sid			IN security_pkg.T_SID_ID,	
	in_old_company_type_id	IN company_type.company_type_id%TYPE,
	in_new_company_type_id	IN company_type.company_type_id%TYPE
)
AS
	v_use_groups_enabled			customer_options.use_company_type_user_groups%TYPE := helper_pkg.UseCompanyTypeUserGroups;
	
	v_old_company_type_group_sid	security_pkg.T_SID_ID;
	v_old_company_type_lookup		company_type.lookup_key%TYPE DEFAULT GetLookupKey(in_old_company_type_id);
	
	v_new_company_type_group_sid	security_pkg.T_SID_ID;
	v_new_company_type_lookup		company_type.lookup_key%TYPE DEFAULT GetLookupKey(in_new_company_type_id);
	
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_users_sid					security_pkg.T_SID_ID;
BEGIN
	IF in_old_company_type_id = in_new_company_type_id THEN
		RETURN;
	END IF;
	
	UPDATE chain.company
	   SET company_type_id = in_new_company_type_id
	 WHERE company_sid = in_company_sid; 
	 
	 IF v_use_groups_enabled = 1 THEN
		
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
		
		/* delete company's user group from old company type group*/
		Intern_CreateCompanyTypeGroup(in_old_company_type_id, v_old_company_type_lookup, v_old_company_type_group_sid);
		group_pkg.DeleteMember(v_act_id, v_users_sid, v_old_company_type_group_sid);
		
		/* add company's user group to new company type group */
		Intern_CreateCompanyTypeGroup(in_new_company_type_id, v_new_company_type_lookup, v_new_company_type_group_sid);
		group_pkg.AddMember(v_act_id, v_users_sid, v_new_company_type_group_sid);

	END IF;
	
	csr.supplier_pkg.SyncCompanyTypeRoles(in_company_sid);
	
	-- process companies of type X in X->Y type relationship, if there's a relationship where the company being switched here is the supplier
	FOR r IN (
		SELECT purchaser_company_sid
		  FROM chain.supplier_relationship sr 
		 WHERE supplier_company_sid = in_company_sid
	) LOOP
		csr.supplier_pkg.SyncCompanyTypeRoles(r.purchaser_company_sid);
	END LOOP;
	
END;

FUNCTION GetCountOfCompanies(
	in_company_type_id		IN	company_type.company_type_id%TYPE
) RETURN NUMBER
AS
	v_count NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;
	 
	RETURN v_count;
END;

PROCEDURE Internal_UpdatePosition(
	in_company_type_id		IN	company_type.company_type_id%TYPE,
	in_position 			IN	company_type.position%TYPE
)
AS
BEGIN
	UPDATE company_type
	   SET position = in_position
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;
	   
	LogCompanyTypeChange(
		in_description			=> 'Company type "{0}" position changed to {1}.',
		in_param_1				=> GetCompanyTypeDescription(in_company_type_id),
		in_param_2          	=> in_position,
		in_sub_object_id		=> in_company_type_id
	);
END;

PROCEDURE ElevateCompanyTypePosition (
	in_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
	v_current_position 			company_type.position%TYPE;
	v_previous_company_type_id	company_type.company_type_id%TYPE;
	v_previous_position 		company_type.position%TYPE;
BEGIN

	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ElevateCompanyTypePosition can only be run as CSR Super Admin');
	END IF;	
 
	--Find the preceding, by position, item that we are going to exchange position with
	BEGIN
		SELECT prev_company_type_id, prev_position, current_position
		  INTO v_previous_company_type_id, v_previous_position, v_current_position
		  FROM ( 
			SELECT prev.company_type_id prev_company_type_id, prev.position prev_position, curr.position current_position
			  FROM company_type prev
			  JOIN company_type curr ON (prev.app_sid = curr.app_sid)
			 WHERE prev.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND prev.company_type_id <> curr.company_type_id
			   AND prev.position < curr.position
			   AND curr.company_type_id = in_company_type_id
			 ORDER BY ABS(prev.position - curr.position) ASC
			 )
		WHERE ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Company type with company_type_id "'||in_company_type_id||'" cannot be elevated further.');
	END;
	
	--Exchange positions between our record and previous one
	Internal_UpdatePosition(v_previous_company_type_id, v_current_position); 
	Internal_UpdatePosition(in_company_type_id, v_previous_position); 

END;

PROCEDURE DowngradeCompanyTypePosition (
	in_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
	v_current_position 			company_type.position%TYPE;
	v_succ_company_type_id		company_type.company_type_id%TYPE;
	v_succeeding_position   	company_type.position%TYPE;
BEGIN

	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DowngradeCompanyTypePosition can only be run as CSR Super Admin');
	END IF;
 
	--Find the succeeding, by position, item that we are going to exchange position with
	BEGIN
		SELECT succ_company_type_id, succeeding_position, current_position
		  INTO v_succ_company_type_id, v_succeeding_position, v_current_position
		  FROM ( 
			SELECT succ.company_type_id succ_company_type_id, succ.position succeeding_position, curr.position current_position
			  FROM company_type succ
			  JOIN company_type curr ON (succ.app_sid = curr.app_sid)
			 WHERE succ.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND succ.company_type_id <> curr.company_type_id
			   AND succ.position > curr.position
			   AND curr.company_type_id = in_company_type_id
			 ORDER BY ABS(succ.position - curr.position) ASC
			 )
		WHERE ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Company type with company_type_id "'||in_company_type_id||'" cannot be downgraded further.');
	END;
	
	--Exchange positions between our record and previous one
	Internal_UpdatePosition(v_succ_company_type_id, v_current_position); 
	Internal_UpdatePosition(in_company_type_id, v_succeeding_position); 

END;

PROCEDURE SetCompanyTypePositions (
	in_order_company_type_keys 	IN  chain.T_STRING_LIST
)
AS
	v_count				NUMBER(10);
	v_position			NUMBER(10) DEFAULT 1;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetCompanyTypePositions can only be run as BuiltIn/Administrator');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_count <> in_order_company_type_keys.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'There are '||v_count||' company type but the ordering array contains '||in_order_company_type_keys.COUNT||' entiries. Each company_type must be accounted for once and only once');
	END IF;
	
	FOR i IN in_order_company_type_keys.FIRST .. in_order_company_type_keys.LAST LOOP
		
		UPDATE company_type
		   SET position = v_position
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = UPPER(in_order_company_type_keys(i));
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a company type with lookup key '||in_order_company_type_keys(i));
		END IF;
		
		v_position := v_position + 1;
		
	END LOOP;
END;

FUNCTION Internal_IsDefault(
	in_company_type_id		IN	company_type.company_type_id%TYPE
)	RETURN BOOLEAN
AS
	v_is_default company_type.is_default%TYPE;
BEGIN
	SELECT is_default
	  INTO v_is_default
	  FROM company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;
	
	RETURN v_is_default = 1;

END;

FUNCTION Internal_GetDefaultId 
RETURN company_type.company_type_id%TYPE
AS
	v_company_type_id company_type.company_type_id%TYPE;
BEGIN
	BEGIN
		SELECT company_type_id
		  INTO v_company_type_id
		  FROM company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_default = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'No default company types found.');
		END;
	RETURN v_company_type_id;
END;

FUNCTION GetDefaultCompanyTypeID 
RETURN company_type.company_type_id%TYPE
AS
BEGIN
	RETURN Internal_GetDefaultId;
END;

PROCEDURE DeleteCompanyType (
	in_company_type_id			IN	company_type.company_type_id%TYPE,
	in_move_related_companies	IN NUMBER DEFAULT 0
)
AS
	v_companies_sids			security.T_SID_TABLE;--children companies
	v_default_company_type_id	company_type.company_type_id%TYPE;
	v_desc						company_type.singular%TYPE;
	v_roles_to_delete			security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN

	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteCompanyType can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	--get related companies
	SELECT company_sid
	  BULK COLLECT 
	  INTO v_companies_sids
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	--check if company_type has related companies
	IF v_companies_sids.COUNT > 0 THEN
		--if the company_type is the default one, we shouldnt move the related companies
		IF Internal_IsDefault(in_company_type_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company type with company_type_id "'||in_company_type_id||'" is default and therefore its related companies cannot move to other company type.');	
		END IF;

		IF in_move_related_companies = 1 THEN
			--we get default company_type_id
			v_default_company_type_id := Internal_GetDefaultId();

			--move companies to default company_type 
			FOR i IN v_companies_sids.FIRST .. v_companies_sids.LAST
			LOOP
				SwitchCompanyCompanyType(v_companies_sids(i), in_company_type_id, v_default_company_type_id);
			END LOOP;
		END IF;
	END IF;

	DELETE FROM company_tab
	 WHERE app_sid = security_pkg.GetApp
	   AND (page_company_type_id = in_company_type_id 
	    OR user_company_type_id = in_company_type_id);

	DELETE FROM company_type_capability
	 WHERE app_sid = security_pkg.GetApp
	   AND (primary_company_type_id = in_company_type_id 
	    OR secondary_company_type_id = in_company_type_id
		OR tertiary_company_type_id = in_company_type_id);

	DELETE FROM tertiary_relationships
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (primary_company_type_id = in_company_type_id 
	    OR secondary_company_type_id = in_company_type_id
		OR tertiary_company_type_id = in_company_type_id);

	DELETE FROM supplier_involvement_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (user_company_type_id = in_company_type_id 
	    OR page_company_type_id = in_company_type_id);

	DELETE FROM company_type_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (primary_company_type_id = in_company_type_id 
	    OR secondary_company_type_id = in_company_type_id);

	DELETE FROM reference_company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	DELETE FROM business_rel_tier_company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	DELETE FROM reference_capability
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (primary_company_type_id = in_company_type_id 
	    OR secondary_company_type_id = in_company_type_id);

	DELETE FROM company_tab_related_co_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	DELETE FROM company_header
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (page_company_type_id = in_company_type_id 
	    OR user_company_type_id = in_company_type_id);

	DELETE FROM product_header
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (product_company_type_id = in_company_type_id 
	    OR user_company_type_id = in_company_type_id);

	DELETE FROM product_tab
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (product_company_type_id = in_company_type_id 
	    OR user_company_type_id = in_company_type_id);

	DELETE FROM product_supplier_tab
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (product_company_type_id = in_company_type_id 
	    OR user_company_type_id = in_company_type_id);

	DELETE FROM company_type_tag_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	DELETE FROM higg_config
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	DELETE FROM company_type_score_calc
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	DELETE FROM comp_type_score_calc_comp_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;

	v_desc := GetCompanyTypeDescription(in_company_type_id);
	
	SELECT DISTINCT role_sid 
	  BULK COLLECT INTO v_roles_to_delete
	  FROM (
		SELECT ctr.role_sid 
		  FROM company_type_role ctr
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		 WHERE is_system_managed = 1
		   AND company_type_id = in_company_type_id
		UNION
		SELECT user_role_sid 
		  FROM company_type ct
		  JOIN csr.role r ON ct.user_role_sid = r.role_sid
		 WHERE is_system_managed = 1
		   AND company_type_id = in_company_type_id
	  );

	DELETE FROM company_type_role
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;
	 
	DELETE FROM company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;
	   
	-- cleanup actual roles  
	FOR i IN 1 .. v_roles_to_delete.COUNT
	LOOP
		UPDATE csr.role SET is_system_managed = 0 WHERE role_sid = v_roles_to_delete(i);	
		group_pkg.DeleteGroup(security_pkg.GetAct, v_roles_to_delete(i));
	END LOOP;	
	
	LogCompanyTypeChange(
		in_description			=> 'Company type "{0}" deleted.',
		in_param_1				=> v_desc,
		in_sub_object_id		=> in_company_type_id
	);
	
END;

FUNCTION GetDefaultCompanyType
RETURN company_type.company_type_id%TYPE
AS
	v_company_type_id		company_type.company_type_id%TYPE;
BEGIN
	SELECT MIN(company_type_id)
	  INTO v_company_type_id
	  FROM company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_default = 1;

	RETURN v_company_type_id;
END;

PROCEDURE SetDefaultCompanyType (
	in_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
BEGIN
	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetDefaultCompanyType can only be run as BuiltIn/Administrator or SuperAdmins');
	END IF;
	
	--Reverse other record' isDefault from 1 to 0
	UPDATE company_type
	   SET is_default = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_default = 1;
	
	--Set isDefault to current record 
	UPDATE company_type
	   SET is_default = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND in_company_type_id = company_type_id ;
	   
	LogCompanyTypeChange(
		in_description			=> 'Company type "{0}" made the default company type.',
		in_param_1          	=> GetCompanyTypeDescription(in_company_type_id),
		in_sub_object_id		=> in_company_type_id
	);
END;

/* should be called only after security checks have been made*/
PROCEDURE SetCompanyType_UNSEC(
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,	
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
	
)
AS
	v_allow_lower_case			company_type.allow_lower_case%TYPE DEFAULT CASE WHEN in_allow_lower THEN 1 ELSE 0 END;
	v_use_user_role				company_type.use_user_role%TYPE DEFAULT CASE WHEN in_use_user_role THEN 1 ELSE 0 END;
	v_company_type_id			company_type.lookup_key%TYPE;
	v_position					company_type.position%TYPE;
	v_need_to_sync_ct_roles		BOOLEAN := FALSE;
	CURSOR c_company_type IS
		SELECT company_type_id, lookup_key, singular, plural, allow_lower_case, 
		       use_user_role, position, css_class, default_region_type, region_root_sid,
			   default_region_layout, create_subsids_under_parent, create_doc_library_folder
		  FROM company_type 
		 WHERE lookup_key = UPPER(in_lookup_key);
	r_company_type	c_company_type%ROWTYPE;
BEGIN
	
	BEGIN
		SELECT max_position + 1
		  INTO v_position
		  FROM (
		  	SELECT NVL(MAX(position), 0) max_position
			  FROM company_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			);
	
		INSERT INTO company_type (company_type_id, lookup_key, singular, plural, allow_lower_case, 
		                          use_user_role, position, css_class, default_region_type, region_root_sid,
								  default_region_layout, create_subsids_under_parent, create_doc_library_folder)
		     VALUES (company_type_id_seq.nextval, UPPER(in_lookup_key), in_singular, in_plural, 
			         v_allow_lower_case, v_use_user_role, v_position, in_css_class, in_default_region_type, 
					 in_region_root_sid, in_default_region_layout, in_create_subsids_under_parent, in_create_doc_library_folder)
		RETURNING company_type_id INTO v_company_type_id;
		
		type_capability_pkg.RefreshCompanyTypeCapabilities(UPPER(in_lookup_key));
		
		v_need_to_sync_ct_roles := TRUE;
		
		LogCompanyTypeChange(
			in_description			=> 'Created company type "{0}", with lookup key "{1}".',
			in_param_1          	=> in_singular,
			in_param_2          	=> in_lookup_key,
			in_sub_object_id		=> v_company_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			OPEN c_company_type;
			FETCH c_company_type INTO r_company_type;
			CLOSE c_company_type;
		
			UPDATE company_type
			   SET singular = in_singular, 
				   plural = in_plural, 
				   allow_lower_case = v_allow_lower_case,
				   use_user_role = v_use_user_role,
				   css_class = in_css_class,
				   default_region_type = in_default_region_type,
				   region_root_sid = in_region_root_sid,
				   default_region_layout = in_default_region_layout,
				   create_subsids_under_parent = in_create_subsids_under_parent,
				   create_doc_library_folder = in_create_doc_library_folder
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND lookup_key = UPPER(in_lookup_key)
			RETURNING company_type_id INTO v_company_type_id;
			
			IF csr.null_pkg.ne(in_singular, r_company_type.singular) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type singular description changed from "{0}" to "{1}".',
					in_param_1          	=> r_company_type.singular,
					in_param_2          	=> in_singular,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(in_plural, r_company_type.plural) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type plural description changed from "{0}" to "{1}".',
					in_param_1          	=> r_company_type.plural,
					in_param_2          	=> in_plural,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(v_allow_lower_case, r_company_type.allow_lower_case) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" allow lower case setting changed from "{1}" to "{2}".',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.allow_lower_case,
					in_param_3          	=> v_allow_lower_case,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(v_use_user_role, r_company_type.use_user_role) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" use user role setting changed from "{1}" to "{2}".',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.use_user_role,
					in_param_3          	=> v_use_user_role,
					in_sub_object_id		=> v_company_type_id
				);
				v_need_to_sync_ct_roles := TRUE;
			END IF;
			
			IF csr.null_pkg.ne(in_css_class, r_company_type.css_class) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" css class changed from "{1}" to "{2}".',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.css_class,
					in_param_3	         	=> in_css_class,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(in_default_region_type, r_company_type.default_region_type) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" default region type id changed from {1} to {2}.',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.default_region_type,
					in_param_3          	=> in_default_region_type,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(in_region_root_sid, r_company_type.region_root_sid) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" root region sid changed from {1} to {2}.',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.region_root_sid,
					in_param_3          	=> in_region_root_sid,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(in_default_region_layout, r_company_type.default_region_layout) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" default region layout changed from {1} to {2}.',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.default_region_layout,
					in_param_3          	=> in_default_region_layout,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(in_create_subsids_under_parent, r_company_type.create_subsids_under_parent) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" create subsidiaries under parent changed from {1} to {2}.',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.create_subsids_under_parent,
					in_param_3          	=> in_create_subsids_under_parent,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
			
			IF csr.null_pkg.ne(in_create_doc_library_folder, r_company_type.create_doc_library_folder) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type "{0}" create folder per company changed from {1} to {2}.',
					in_param_1				=> in_singular,
					in_param_2          	=> r_company_type.create_doc_library_folder,
					in_param_3          	=> in_create_doc_library_folder,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
	END;

	SetCompanyTypeRole_(in_lookup_key);
	
	IF v_need_to_sync_ct_roles THEN
		FOR r IN (
			SELECT company_sid 
			  FROM chain.v$company
			 WHERE company_type_id = v_company_type_id
		) LOOP
			csr.supplier_pkg.SyncCompanyTypeRoles(r.company_sid);
		END LOOP;
	END IF;

END;

PROCEDURE AddCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
	
)
AS	
	v_use_groups_enabled			customer_options.use_company_type_user_groups%TYPE := helper_pkg.UseCompanyTypeUserGroups;
	v_company_type_id				company.company_type_id%TYPE;
	v_company_type_group_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddCompanyType can only be run as BuiltIn/Administrator');
	END IF;

	SetCompanyType_UNSEC(in_lookup_key, in_singular, in_plural, in_allow_lower, in_use_user_role, in_css_class, 
		in_default_region_type, in_region_root_sid, in_default_region_layout, in_create_subsids_under_parent, in_create_doc_library_folder);
	
	type_capability_pkg.RefreshCompanyTypeCapabilities(in_lookup_key);
		
	--if company type user groups enabled, create a company type user group
	IF v_use_groups_enabled = 1 THEN
		v_company_type_id := GetCompanyTypeId(in_lookup_key);
		Intern_CreateCompanyTypeGroup(v_company_type_id, in_lookup_key, v_company_type_group_sid);
	END IF;
END;

PROCEDURE AddCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_path				IN  VARCHAR2,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
)
AS
	v_in_region_root_sid	company_type.region_root_sid%TYPE;	
BEGIN
	-- GetSidFromPath returns the root site sid if it is passed null so we need to explicitly check for this.
	IF in_region_root_path IS NULL THEN
		v_in_region_root_sid := NULL;
	ELSE
		v_in_region_root_sid := security.securableobject_pkg.GetSidFromPath(security_pkg.getAct, csr.region_tree_pkg.GetPrimaryRegionTreeRootSid, in_region_root_path);
	END IF;

	AddCompanyType(
		in_lookup_key					=> in_lookup_key,
		in_singular						=> in_singular,
		in_plural						=> in_plural,
		in_allow_lower					=> in_allow_lower,
		in_use_user_role				=> in_use_user_role,
		in_css_class					=> in_css_class,
		in_default_region_type			=> in_default_region_type,
		in_region_root_sid				=> v_in_region_root_sid,
		in_default_region_layout		=> in_default_region_layout,
		in_create_subsids_under_parent	=> in_create_subsids_under_parent,
		in_create_doc_library_folder    => in_create_doc_library_folder
	);
END;

PROCEDURE SetCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	company_type.allow_lower_case%TYPE,
	in_use_user_role				IN  company_type.use_user_role%TYPE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,	
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
)
AS
	v_use_groups_enabled		customer_options.use_company_type_user_groups%TYPE := helper_pkg.UseCompanyTypeUserGroups;
	v_company_type_id			company.company_type_id%TYPE;
	v_company_type_group_sid	security_pkg.T_SID_ID;
	v_allow_lower 			BOOLEAN DEFAULT CASE in_allow_lower WHEN 1 THEN TRUE ELSE FALSE END;
	v_use_user_role			BOOLEAN DEFAULT CASE in_use_user_role WHEN 1 THEN TRUE ELSE FALSE END;
BEGIN
	
	IF NOT (security.user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetCompanyType can only be run as CSR Super Admin or Built-in Admin');
	END IF;
	
	SetCompanyType_UNSEC(in_lookup_key, in_singular, in_plural, v_allow_lower, v_use_user_role, in_css_class, 
		in_default_region_type, in_region_root_sid, in_default_region_layout, in_create_subsids_under_parent, in_create_doc_library_folder);
	
	--if company type user groups enabled, create a company type user group
	IF v_use_groups_enabled = 1 THEN
		v_company_type_id := GetCompanyTypeId(in_lookup_key);
		Intern_CreateCompanyTypeGroup(v_company_type_id, in_lookup_key, v_company_type_group_sid);
	END IF;
END;

PROCEDURE SetCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	company_type.allow_lower_case%TYPE,
	in_use_user_role				IN  company_type.use_user_role%TYPE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_type_id			company.company_type_id%TYPE;
BEGIN
	SetCompanyType(
		in_lookup_key => in_lookup_key,	
		in_singular => in_singular,
		in_plural => in_plural,
		in_allow_lower => in_allow_lower,
		in_use_user_role => in_use_user_role,
		in_css_class => in_css_class,
		in_default_region_type => in_default_region_type,
		in_region_root_sid => in_region_root_sid,
		in_default_region_layout => in_default_region_layout,
		in_create_subsids_under_parent => in_create_subsids_under_parent,
		in_create_doc_library_folder => in_create_doc_library_folder
	);
	
	v_company_type_id := GetCompanyTypeId(in_lookup_key);
	GetCompanyTypeById(v_company_type_id, out_cur);
END;

PROCEDURE AddDefaultCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1
)
AS
	v_count						NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddDefaultCompanyType can only be run as BuiltIn/Administrator');
	END IF;
	
	AddCompanyType(
		in_lookup_key => in_lookup_key,
		in_singular => in_singular,
		in_plural => in_plural,
		in_allow_lower => in_allow_lower,
		in_use_user_role => in_use_user_role,
		in_default_region_type => in_default_region_type,
		in_region_root_sid => in_region_root_sid,
		in_default_region_layout => in_default_region_layout,
		in_create_subsids_under_parent => in_create_subsids_under_parent
	);
	
	SetDefaultCompanyType(GetCompanyTypeId(in_lookup_key));
END;

PROCEDURE UNSEC_CreateFollowerRole (
	in_company_type_id				IN	company_type.company_type_id%TYPE,
	in_related_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
	v_follower_role_sid				security.security_pkg.T_SID_ID;
	v_purchaser_lookup_key			company_type.lookup_key%TYPE;
	v_supplier_lookup_key			company_type.lookup_key%TYPE;
	v_company_type_label			company_type.singular%TYPE;
	v_related_company_type_label	company_type.singular%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_chain_users_sid				security.security_pkg.T_SID_ID;
BEGIN
	SELECT singular, lookup_key
	  INTO v_company_type_label, v_purchaser_lookup_key
	  FROM company_type
	 WHERE company_type_id = in_company_type_id;
	
	SELECT lookup_key, singular
	  INTO v_supplier_lookup_key, v_related_company_type_label
	  FROM company_type
	 WHERE company_type_id = in_related_company_type_id;

	SELECT follower_role_sid
	  INTO v_follower_role_sid
	  FROM company_type_relationship
	 WHERE primary_company_type_id = in_company_type_id
	   AND secondary_company_type_id = in_related_company_type_id;
	
	IF v_follower_role_sid IS NOT NULL THEN
		-- Role already exists, so nothing to do.
		RETURN;
	END IF;
	
	csr.role_pkg.SetRole(v_company_type_label || ' followers of ' || v_related_company_type_label, v_purchaser_lookup_key || '_FOLLOWING_' || v_supplier_lookup_key, v_follower_role_sid);
	UPDATE csr.role
	   SET is_system_managed = 1
	 WHERE role_sid = v_follower_role_sid;
	 
	-- Add permission for chain users to set this role. Required when adding a follower (although since 
	-- the role is system managed they won't be able to do this directly).
	v_chain_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, 
		securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.GetApp, 'Groups'), chain.chain_pkg.CHAIN_USER_GROUP);
	security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_follower_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_chain_users_sid, 
		security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE);
	
	UPDATE company_type_relationship
	   SET follower_role_sid = v_follower_role_sid
	 WHERE primary_company_type_id = in_company_type_id
	   AND secondary_company_type_id = in_related_company_type_id;
	
	csr.supplier_pkg.UNSEC_SyncFollowerRoles(
		in_purchaser_company_type => in_company_type_id,
		in_supplier_company_type => in_related_company_type_id
	);
	
	LogCompanyTypeChange(
		in_description			=> 'Company type relationship between "{0}" (primary) and "{1}" (secondary) company types using follower role.',
		in_param_1				=> v_purchaser_lookup_key,
		in_param_2          	=> v_supplier_lookup_key,
		in_sub_object_id		=> in_company_type_id
	);
END;

PROCEDURE AddCompanyTypeRelationship (
	in_company_type			IN	company_type.lookup_key%TYPE,	
	in_related_company_type	IN	company_type.lookup_key%TYPE,
	in_use_user_roles		IN  BOOLEAN,
	in_flow_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_hidden				IN	BOOLEAN DEFAULT FALSE,
	in_has_follower_role	IN	BOOLEAN DEFAULT FALSE
)
AS
BEGIN
	AddCompanyTypeRelationship(
		in_company_type			=> in_company_type,
		in_related_company_type	=> in_related_company_type,
		in_use_user_roles		=> CASE in_use_user_roles WHEN TRUE THEN 1 ELSE 0 END,
		in_flow_sid				=> in_flow_sid,
		in_hidden				=> CASE in_hidden WHEN TRUE THEN 1 ELSE 0 END,
		in_has_follower_role	=> CASE in_has_follower_role WHEN TRUE THEN 1 ELSE 0 END
	);
END;

PROCEDURE AddCompanyTypeRelationship (
	in_company_type			IN	company_type.lookup_key%TYPE,	
	in_related_company_type	IN	company_type.lookup_key%TYPE,
	in_use_user_roles		IN  company_type_relationship.use_user_roles%TYPE DEFAULT 0,
	in_flow_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_hidden				IN	company_type_relationship.hidden%TYPE DEFAULT 0,
	in_has_follower_role	IN	NUMBER DEFAULT 0,
	in_can_be_primary		IN  NUMBER DEFAULT 0
)
AS
	v_company_type_id				company_type.company_type_id%TYPE := GetCompanyTypeId(in_company_type);
	v_related_company_type_id		company_type.company_type_id%TYPE := GetCompanyTypeId(in_related_company_type);
	v_orig_use_user_roles			company_type_relationship.use_user_roles%TYPE;
	v_orig_flow_sid					security_pkg.T_SID_ID;
	v_orig_hidden					company_type_relationship.hidden%TYPE;
	v_create_one_flow_item_comp		customer_options.create_one_flow_item_for_comp%TYPE;
	v_flow_item_id					supplier_relationship.flow_item_id%TYPE;
	v_need_to_sync_ct_roles		BOOLEAN := FALSE;
	v_orig_cbp					company_type_relationship.can_be_primary%TYPE;
BEGIN
	IF NOT (security.user_pkg.IsSuperAdmin() = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddCompanyTypeRelationship can only be run as a CSR Super Admin or Bultin Admin.');
	END IF;
	
	BEGIN
		INSERT INTO company_type_relationship
		(primary_company_type_id, secondary_company_type_id, use_user_roles, flow_sid, hidden, can_be_primary)
		VALUES
		(v_company_type_id, v_related_company_type_id, in_use_user_roles, in_flow_sid, in_hidden, in_can_be_primary);
		
		v_need_to_sync_ct_roles := TRUE;
		
		LogCompanyTypeChange(
			in_description			=> 'Company type relationship created between "{0}" (primary) and "{1}" (secondary) company types.',
			in_param_1				=> in_company_type,
			in_param_2				=> in_related_company_type,
			in_sub_object_id		=> v_company_type_id
		);
				
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT use_user_roles, flow_sid, hidden, can_be_primary
			  INTO v_orig_use_user_roles, v_orig_flow_sid, v_orig_hidden, v_orig_cbp
			  FROM company_type_relationship
			 WHERE primary_company_type_id = v_company_type_id
			   AND secondary_company_type_id = v_related_company_type_id;

			UPDATE company_type_relationship
			   SET use_user_roles = in_use_user_roles,
				   flow_sid = in_flow_sid,
				   hidden = in_hidden,
				   can_be_primary = in_can_be_primary
			 WHERE primary_company_type_id = v_company_type_id
			   AND secondary_company_type_id = v_related_company_type_id;

			IF csr.null_pkg.ne(in_use_user_roles, v_orig_use_user_roles) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type relationship between "{0}" and "{1}" use user role setting changed to "{2}".',
					in_param_1				=> in_company_type,
					in_param_2				=> in_related_company_type,
					in_param_3				=> in_use_user_roles,
					in_sub_object_id		=> v_company_type_id
				);
				
				v_need_to_sync_ct_roles := TRUE;
			END IF;

			IF csr.null_pkg.ne(in_flow_sid, v_orig_flow_sid) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type relationship between "{0}" and "{1}" flow sid changed to {2}.',
					in_param_1				=> in_company_type,
					in_param_2				=> in_related_company_type,
					in_param_3				=> in_flow_sid,
					in_sub_object_id		=> v_company_type_id
				);

				SELECT create_one_flow_item_for_comp
				  INTO v_create_one_flow_item_comp
				  FROM customer_options
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
				
				IF in_flow_sid IS NOT NULL AND v_create_one_flow_item_comp = 1 THEN
					FOR r IN (
						SELECT DISTINCT sr.supplier_company_sid
						  FROM supplier_relationship sr
						  JOIN company pc ON sr.purchaser_company_sid = pc.company_sid AND pc.company_type_id = v_company_type_id
						  JOIN company sc ON sr.supplier_company_sid = sc.company_sid AND sc.company_type_id = v_related_company_type_id
						 WHERE sr.flow_item_id IS NULL
						   AND sr.active = 1
						   AND sr.deleted = 0
					)
					LOOP
						v_flow_item_id := supplier_flow_pkg.GetSingleFlowItemForSupplier(r.supplier_company_sid, in_flow_sid);

						IF v_flow_item_id IS NOT NULL THEN
							UPDATE supplier_relationship
							   SET flow_item_id = v_flow_item_id
							 WHERE supplier_company_sid = r.supplier_company_sid
							   AND flow_item_id IS NULL
							   AND active = 1
							   AND deleted = 0;
						END IF;
					END LOOP;
				END IF;
			END IF;

			IF csr.null_pkg.ne(in_hidden, v_orig_hidden) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type relationship between "{0}" and "{1}" hidden changed to {2}.',
					in_param_1				=> in_company_type,
					in_param_2				=> in_related_company_type,
					in_param_3				=> in_hidden,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;


			IF csr.null_pkg.ne(in_can_be_primary, v_orig_cbp) THEN
				LogCompanyTypeChange(
					in_description			=> 'Company type relationship between "{0}" and "{1}" purchaser can be primary changed to {2}.',
					in_param_1				=> in_company_type,
					in_param_2				=> in_related_company_type,
					in_param_3				=> in_can_be_primary,
					in_sub_object_id		=> v_company_type_id
				);
			END IF;
	END;
	
	IF in_has_follower_role = 1 THEN
		UNSEC_CreateFollowerRole(v_company_type_id, v_related_company_type_id);
	END IF;
	
	type_capability_pkg.RefreshCompanyTypeCapabilities(in_company_type);
	
	-- process company type X in X->Y relationship, if there's a relationship for that pairing and the use_user_roles has changes or relationship is new
	IF v_need_to_sync_ct_roles THEN
		FOR r IN (
			SELECT DISTINCT cpur.company_sid
			  FROM chain.v$company cpur 
			  JOIN chain.supplier_relationship sr ON cpur.company_sid = sr.purchaser_company_sid
			  JOIN chain.v$company csup ON csup.company_sid = sr.supplier_company_sid
			 WHERE cpur.company_type_id = v_company_type_id
			   AND csup.company_type_id = v_related_company_type_id
		) LOOP
			csr.supplier_pkg.SyncCompanyTypeRoles(in_company_sid => r.company_sid, in_use_cascade_role_changed => 1);
		END LOOP;
	END IF;

END;

PROCEDURE AddTertiaryRelationship (
	in_primary_company_type		IN	company_type.lookup_key%TYPE,	
	in_secondary_company_type	IN	company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN	company_type.lookup_key%TYPE
)
AS
	v_primary_company_type_id	company_type.company_type_id%TYPE := GetCompanyTypeId(in_primary_company_type);
BEGIN
	IF NOT (security.user_pkg.IsSuperAdmin() = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddTertiaryRelationship can only be run as a CSR Super Admin or Bultin Admin.');
	END IF;
	
	BEGIN
		INSERT INTO tertiary_relationships
		(primary_company_type_id, secondary_company_type_id, tertiary_company_type_id)
		VALUES
		(v_primary_company_type_id, company_type_pkg.GetCompanyTypeId(in_secondary_company_type), company_type_pkg.GetCompanyTypeId(in_tertiary_company_type));
		
		LogCompanyTypeChange(
			in_description			=> 'Tertiary relationship created between "{0}", "{1}" and "{2}".',
			in_param_1				=> in_primary_company_type,
			in_param_2				=> in_secondary_company_type,
			in_param_3				=> in_tertiary_company_type,
			in_sub_object_id		=> v_primary_company_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE DeleteTertiaryRelationship (
	in_primary_company_type		IN	company_type.lookup_key%TYPE,	
	in_secondary_company_type	IN	company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN	company_type.lookup_key%TYPE
)
AS

BEGIN
	IF NOT (security.user_pkg.IsSuperAdmin() = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddTertiaryRelationship can only be run as a CSR Super Admin or Bultin Admin.');
	END IF;
	
	BEGIN
	
		DELETE FROM company_type_capability 
		 WHERE app_sid = security_pkg.GetApp 
		   AND primary_company_type_id = in_primary_company_type
		   AND secondary_company_type_id = in_secondary_company_type
		   AND tertiary_company_type_id = in_tertiary_company_type;
	
		DELETE FROM tertiary_relationships
		 WHERE app_sid = security_pkg.GetApp 
		   AND primary_company_type_id = in_primary_company_type
		   AND secondary_company_type_id = in_secondary_company_type
		   AND tertiary_company_type_id = in_tertiary_company_type;
		
		LogCompanyTypeChange(
			in_description			=> 'Tertiary relationship deleted between "{0}", "{1}" and "{2}".',
			in_param_1          	=> in_primary_company_type,
			in_param_2          	=> in_secondary_company_type,
			in_param_3          	=> in_tertiary_company_type,
			in_sub_object_id		=> in_primary_company_type
		);
	END;
END;

/* should be called only after security checks have been made or unit tests*/
PROCEDURE DeleteCompanyTypeRel_UNSEC(
	in_primary_company_type_id			IN	company_type.company_type_id%TYPE,
	in_secondary_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
BEGIN
	--TODO supplier relationships, underlying rrm if roles are enabled
	DELETE FROM company_type_capability
	 WHERE app_sid = security_pkg.GetApp
	   AND primary_company_type_id = in_primary_company_type_id
	   AND secondary_company_type_id = in_secondary_company_type_id;
	 
	DELETE FROM company_type_relationship
	 WHERE app_sid = security_pkg.GetApp
	   AND primary_company_type_id = in_primary_company_type_id
	   AND secondary_company_type_id = in_secondary_company_type_id; 
	
	-- process company type X in X->Y relationship, if there's a relationship for that pairing 

	-- Does the following sync ever get triggered? 
	-- The system doesn't allow deleting a CTR with existing relationships 
	FOR r IN (
		SELECT DISTINCT cpur.company_sid
		  FROM chain.v$company cpur 
		  JOIN chain.supplier_relationship sr ON cpur.company_sid = sr.purchaser_company_sid
		  JOIN chain.v$company csup ON csup.company_sid = sr.supplier_company_sid
		 WHERE cpur.company_type_id = in_primary_company_type_id
		   AND csup.company_type_id = in_secondary_company_type_id
	) LOOP
		csr.supplier_pkg.SyncCompanyTypeRoles(r.company_sid);
	END LOOP;
END;

PROCEDURE DeleteCompanyTypeRelationship (
	in_primary_company_type_id			IN	company_type.company_type_id%TYPE,
	in_secondary_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
	v_hasRelationships				NUMBER := 0;
BEGIN
	IF NOT (security.user_pkg.IsSuperAdmin() = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteCompanyTypeRelationship can only be run as a CSR Super Admin or Bultin Admin.');
	END IF;

	SELECT COUNT(*) 
	  INTO v_hasRelationships
	  FROM chain.supplier_relationship sr
	  JOIN chain.v$company cs ON cs.company_sid = sr.supplier_company_sid
	  JOIN chain.v$company cp ON cp.company_sid = sr.purchaser_company_sid
	  JOIN chain.company_type_relationship ctr ON ctr.primary_company_type_id = cp.company_type_id AND ctr.secondary_company_type_id = cs.company_type_id
	 WHERE ctr.primary_company_type_id = in_primary_company_type_id
	   AND ctr.secondary_company_type_id = in_secondary_company_type_id;

	IF v_hasRelationships > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company relationships exist for this company type relationship.');
	END IF;

	DeleteCompanyTypeRel_UNSEC(in_primary_company_type_id, in_secondary_company_type_id);
END;

PROCEDURE DeleteCompanyTypeRelationship (
	in_primary_company_type			IN	company_type.lookup_key%TYPE,
	in_secondary_company_type		IN	company_type.lookup_key%TYPE
)
AS
	v_prim_company_type_id		company_type.company_type_id%TYPE := GetCompanyTypeId(in_primary_company_type);
	v_second_company_type_id	company_type.company_type_id%TYPE := GetCompanyTypeId(in_secondary_company_type);
BEGIN
	DeleteCompanyTypeRelationship(v_prim_company_type_id, v_second_company_type_id);
END;

PROCEDURE SetTopCompanyType (
	in_company_type			IN	company_type.lookup_key%TYPE
)
AS
BEGIN
	SetTopCompanyType(GetCompanyTypeId(in_company_type));
END;

FUNCTION IsTopCompanyType (
	in_company_type			IN	company_type.lookup_key%TYPE
) RETURN BOOLEAN
AS
	v_is_top_company		company_type.is_top_company%TYPE;
BEGIN
	SELECT is_top_company
	  INTO v_is_top_company
	  FROM company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = UPPER(in_company_type);
	   
	RETURN v_is_top_company = 1;
END;

PROCEDURE SetTopCompanyType (
	in_company_type_id		IN	company_type.company_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetTopCompanyType can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE company_type ct
	   SET is_top_company = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_type_id = in_company_type_id;
END;

FUNCTION GetCompanyTypeId 
RETURN NUMBER
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	RETURN GetCompanyTypeId(v_company_sid);
END;

FUNCTION GetCompanyTypeId (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_swallow_not_found	IN  BOOLEAN DEFAULT FALSE
) RETURN NUMBER
AS
	v_company_type_id		company.company_type_id%TYPE;
BEGIN
	BEGIN
		SELECT company_type_id
		  INTO v_company_type_id
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF NOT in_swallow_not_found THEN
				RAISE;
			END IF;
	END;
	
	RETURN v_company_type_id;
END;

FUNCTION GetCompanyTypeId (
	in_lookup_key			IN  company_type.lookup_key%TYPE,
	in_swallow_not_found	IN  BOOLEAN DEFAULT FALSE
) RETURN NUMBER
AS
	v_company_type_id		company.company_type_id%TYPE;
	v_company_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	-- bit of a hack as sys_context entries are initially interpretted as a string
	--I don't understand what is the point of that
	IF in_lookup_key = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RETURN GetCompanyTypeId(v_company_sid);
	END IF;
	
	BEGIN
		SELECT company_type_id
		  INTO v_company_type_id
		  FROM company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = UPPER(in_lookup_key);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF NOT in_swallow_not_found THEN
				RAISE;
			END IF;
	END;
	
	RETURN v_company_type_id;
END;

PROCEDURE GetCompanyTypeById (
	in_company_type_id		IN company_type.company_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	--todo check capabilities
	OPEN out_cur FOR
		SELECT company_type_id, singular, plural, is_default, is_top_company, lookup_key, 
		       allow_lower_case, position, use_user_role, css_class, default_region_type, 
			   region_root_sid, default_region_layout, create_subsids_under_parent
		  FROM company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_type_id = in_company_type_id;
END;

FUNCTION GetCompanyTypeLookupKey (
	in_company_sid			IN  security_pkg.T_SID_ID
) RETURN company_type.lookup_key%TYPE
AS
	v_lookup_key company_type.lookup_key%TYPE;
BEGIN
	SELECT ct.lookup_key
	  INTO v_lookup_key
	  FROM company c
	  JOIN company_type ct ON c.company_type_id = ct.company_type_id
	 WHERE c.company_sid = in_company_sid;
	 
	RETURN v_lookup_key;
END;

FUNCTION GetLookupKey (
	in_company_type_id	IN	company_type.company_type_id%TYPE
) RETURN company_type.lookup_key%TYPE
AS
	v_lookup_key company_type.lookup_key%TYPE;
BEGIN
	SELECT lookup_key
	  INTO v_lookup_key
	  FROM company_type
	 WHERE company_type_id = in_company_type_id;
	 
	RETURN v_lookup_key;
END;

PROCEDURE GetCompanyTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ct.company_type_id, ct.singular, ct.plural, ct.is_default, ct.is_top_company, ct.lookup_key, 
		       ct.allow_lower_case, ct.use_user_role, ct.css_class, ct.default_region_type, 
			   ct.region_root_sid, r.description region_root_description, ct.default_region_layout, 
			   ct.create_subsids_under_parent, ct.create_doc_library_folder
		  FROM company_type ct
		  LEFT JOIN csr.v$region r ON ct.region_root_sid = r.region_sid
		 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ct.position;
END;

PROCEDURE GetCompanyTypeRelationships (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ctp.lookup_key primary_company_type, ctr.primary_company_type_id, 
			   cts.lookup_key secondary_company_type, ctr.secondary_company_type_id,
			   ctr.use_user_roles, ctr.flow_sid, ctr.hidden,
			   CASE WHEN ctr.follower_role_sid IS NOT NULL THEN 1 ELSE 0 END has_follower_role,
			   ctr.can_be_primary
		  FROM company_type_relationship ctr
		  JOIN company_type ctp ON ctp.company_type_id = ctr.primary_company_type_id AND ctp.app_sid = ctr.app_sid
		  JOIN company_type cts ON cts.company_type_id = ctr.secondary_company_type_id AND cts.app_sid = ctr.app_sid
		 WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY primary_company_type_id ASC;
END;

PROCEDURE GetTertiaryRelationships (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ctp.lookup_key primary_company_type, tr.primary_company_type_id,
			   cts.lookup_key secondary_company_type, tr.secondary_company_type_id,
			   ctt.lookup_key tertiary_company_type, tr.tertiary_company_type_id
		  FROM tertiary_relationships tr
		  JOIN company_type ctp ON ctp.company_type_id = tr.primary_company_type_id AND ctp.app_sid = tr.app_sid
		  JOIN company_type cts ON cts.company_type_id = tr.secondary_company_type_id AND cts.app_sid = tr.app_sid
		  JOIN company_type ctt ON ctt.company_type_id = tr.tertiary_company_type_id AND ctt.app_sid = tr.app_sid
		 WHERE tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tr.primary_company_type_id, tr.secondary_company_type_id, tr.tertiary_company_type_id;
END;

PROCEDURE GetRelatedTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ct.company_type_id, ct.singular, ct.plural, ct.is_default, ct.is_top_company, ct.lookup_key, ct.allow_lower_case, css_class
		  FROM company_type ct, company_type_relationship ctr
		 WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctr.app_sid = ct.app_sid
		   AND ctr.primary_company_type_id = GetCompanyTypeId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND ctr.secondary_company_type_id = ct.company_type_id
		 ORDER BY ct.position;
END;

FUNCTION IsType (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_lookup_key			IN  company_type.lookup_key%TYPE
) RETURN BOOLEAN
AS
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM company c, company_type ct
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = ct.app_sid
	   AND c.company_type_id = ct.company_type_id
	   AND c.company_sid = in_company_sid
	   AND ct.lookup_key = UPPER(in_lookup_key);
	
	RETURN v_count > 0;
END;

PROCEDURE IsType (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_lookup_key			IN  company_type.lookup_key%TYPE,
	out_result				OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF IsType(in_company_sid, in_lookup_key) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE GetCompanyRoles (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_type_id	company_type.company_type_id%TYPE;
BEGIN
	v_company_type_id := company_type_pkg.GetCompanyTypeId(in_company_sid);
	
	GetCompanyTypeRoles(v_company_type_id, out_cur);
END;

PROCEDURE GetCompanyTypeRoles (
	in_company_type_id		IN  company_type_role.company_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ctr.company_type_role_id, ctr.company_type_id, ctr.pos, ctr.role_sid,
			   r.name role_name, ctr.mandatory, ctr.cascade_to_supplier, r.lookup_key
		  FROM company_type_role ctr
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		 WHERE NVL(in_company_type_id, ctr.company_type_id) = ctr.company_type_id 
		 ORDER BY ctr.pos;
END;

FUNCTION IsRoleApplicable(
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_role_sid				IN security_pkg.T_SID_ID
)RETURN BOOLEAN
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_type_role
	 WHERE company_type_id = in_company_type_id
	   AND role_sid = in_role_sid;
	   
	RETURN v_count > 0;
END;

PROCEDURE LinkRoleToCompanyType_UNSEC(
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_mandatory			IN	company_type_role.mandatory%TYPE := 1,
	in_cascade_to_supplier	IN	company_type_role.cascade_to_supplier%TYPE := 0,
	in_pos					IN	company_type_role.pos%TYPE := NULL
)
AS
	v_pos		company_type_role.pos%TYPE := in_pos;
BEGIN
	IF v_pos IS NULL THEN
		SELECT NVL(MAX(pos),0) + 1
		  INTO v_pos
		  FROM company_type_role
		 WHERE company_type_id = in_company_type_id;
	END IF;
	
	BEGIN
		INSERT INTO company_type_role (company_type_role_id, company_type_id, role_sid, mandatory, cascade_to_supplier, pos)
		VALUES (company_type_role_id_seq.NEXTVAL, in_company_type_id, in_role_sid, in_mandatory, in_cascade_to_supplier, v_pos);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE company_type_role
			   SET mandatory = in_mandatory,
				   cascade_to_supplier = in_cascade_to_supplier,
				   pos = v_pos
			 WHERE company_type_id = in_company_type_id
			   AND role_sid = in_role_sid;
	END;
	
	UPDATE csr.role
	   SET is_system_managed = 1
	 WHERE role_sid = in_role_sid;
END;

PROCEDURE SetCompanyTypeRole (
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_role_name			IN	csr.role.name%TYPE DEFAULT NULL,
	in_mandatory			IN	company_type_role.mandatory%TYPE := 1,
	in_cascade_to_supplier	IN	company_type_role.cascade_to_supplier%TYPE := 0,
	in_pos					IN	company_type_role.pos%TYPE := NULL,
	in_lookup_key			IN	csr.role.lookup_key%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_role_sid				security_pkg.T_SID_ID := in_role_sid;
	v_role_sid_with_name	security_pkg.T_SID_ID := NULL;
	v_role_sid_with_lk		security_pkg.T_SID_ID := NULL;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetCompanyTypeRole can only be run as BuiltIn/Administrator or a superadmin');
	END IF;

	IF in_role_name IS NOT NULL THEN
		BEGIN
			SELECT role_sid
			  INTO v_role_sid_with_name
			  FROM csr.role
			 WHERE UPPER(name) = UPPER(in_role_name);
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;
	END IF;

	IF in_lookup_key IS NOT NULL THEN
		BEGIN
			SELECT role_sid
			  INTO v_role_sid_with_lk
			  FROM csr.role
			 WHERE UPPER(lookup_key) = UPPER(in_lookup_key);
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;
	END IF;

	IF in_role_sid IS NULL THEN
		IF in_role_name IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'A name must be provided for the new role');
		END IF;

		IF v_role_sid_with_name IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_DUPLICATE_CTR_NAME, 'A role already exists with the given name.');
		END IF;

		IF v_role_sid_with_lk IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_DUPLICATE_CTR_LOOKUP_KEY, 'A role already exists with the given lookup key.');
		END IF;
		
		csr.role_pkg.SetRole(
			in_role_name	=> in_role_name,
			in_lookup_key	=> in_lookup_key,
			out_role_sid	=> v_role_sid
		);
	ELSE
		IF NVL(v_role_sid_with_name, in_role_sid) != in_role_sid THEN 
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_DUPLICATE_CTR_NAME, 'Another role already exists with the given name.');
		END IF;

		IF NVL(v_role_sid_with_lk, in_role_sid) != in_role_sid THEN 
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_DUPLICATE_CTR_LOOKUP_KEY, 'Another role already exists with the given lookup key.');
		END IF;
		
		csr.role_pkg.AllowAlterSystemManagedRole;

		csr.role_pkg.UpdateRole(
			in_role_sid		=> in_role_sid,
			in_role_name	=> in_role_name,
			in_lookup_key	=> in_lookup_key
		);
	END IF;

	LinkRoleToCompanyType_UNSEC(
		in_company_type_id		=> in_company_type_id,
		in_role_sid				=> v_role_sid,
		in_mandatory			=> in_mandatory,
		in_cascade_to_supplier	=> in_cascade_to_supplier,
		in_pos					=> in_pos
	);

	OPEN out_cur FOR
		SELECT ctr.company_type_role_id, ctr.company_type_id, ctr.pos, ctr.role_sid,
			   r.name role_name, ctr.mandatory, ctr.cascade_to_supplier
		  FROM company_type_role ctr
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		 WHERE ctr.company_type_id = in_company_type_id
		   AND ctr.role_sid = v_role_sid;
END;

PROCEDURE DeleteCompanyTypeRole(
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID
)
AS
	v_company_type_role_id		company_type_role.company_type_id%TYPE;
	v_ctr_in_use_cnt			NUMBER;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteCompanyTypeRole can only be run as BuiltIn/Administrator or a superadmin');
	END IF;

	SELECT company_type_role_id
	  INTO v_company_type_role_id
	  FROM company_type_role
	 WHERE company_type_id = in_company_type_id
	   AND role_sid = in_role_sid;

	DELETE FROM company_tab_company_type_role
	 WHERE company_type_role_id = v_company_type_role_id;

	UPDATE supplier_involvement_type
	   SET restrict_to_role_sid = NULL
	 WHERE user_company_type_id = in_company_type_id
	   AND restrict_to_role_sid = in_role_sid;

	DELETE FROM reference_capability
	 WHERE primary_company_type_id = in_company_type_id
	   AND primary_company_type_role_sid = in_role_sid;

	DELETE FROM company_type_capability
	 WHERE primary_company_type_id = in_company_type_id
	   AND primary_company_type_role_sid = in_role_sid;

	DELETE FROM company_type_role
	 WHERE company_type_id = in_company_type_id
	   AND role_sid = in_role_sid;

	SELECT COUNT(*)
	  INTO v_ctr_in_use_cnt
	  FROM company_type_role
	 WHERE role_sid = in_role_sid;

	IF v_ctr_in_use_cnt = 0 THEN
		csr.role_pkg.AllowAlterSystemManagedRole;

		security.securableobject_pkg.DeleteSO(
			in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_sid_id			=> in_role_sid
		);
	END IF;
END;

PROCEDURE GetAvailableCompTypeRoles(
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security needed
	OPEN out_cur FOR
		SELECT r.role_sid, r.name role_name, r.lookup_key
		  FROM csr.role r
		 WHERE EXISTS (
				SELECT NULL
				 FROM company_type_role ctr
				 WHERE ctr.role_sid = r.role_sid
				   AND ctr.company_type_id != in_company_type_id
		 ) AND NOT EXISTS (
				SELECT NULL
				 FROM company_type_role ctr
				 WHERE ctr.role_sid = r.role_sid
				   AND ctr.company_type_id = in_company_type_id
		 )
		 ORDER BY UPPER(r.name);
END;

PROCEDURE GetManagementPageCompanyTypes (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT page_company_type_id company_type_id
		  FROM chain.company_tab
		 WHERE user_company_type_id = (
			SELECT company_type_id 
			  FROM company 
			 WHERE company_sid = company_pkg.GetCompany
		);
END;

PROCEDURE GetSupplierTypesWithCapability (
	in_capability			IN	chain_pkg.T_CAPABILITY,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_permissible_types		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability);
BEGIN
	
	OPEN out_cur FOR
		SELECT ct.company_type_id, ct.singular, ct.plural, ct.is_default, ct.is_top_company, ct.lookup_key,
		       ct.allow_lower_case, ct.use_user_role, ct.css_class, ct.default_region_type,
			   ct.region_root_sid, r.description region_root_description, ct.default_region_layout,
			   ct.create_subsids_under_parent
		  FROM company_type ct
		  LEFT JOIN csr.v$region r ON ct.region_root_sid = r.region_sid
		  JOIN TABLE(v_permissible_types) t_permissible ON t_permissible.secondary_company_type_id = ct.company_type_id
		  WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ct.position;
END;

PROCEDURE GetTertiaryTypesWithCapability (
	in_capability					IN	chain_pkg.T_CAPABILITY,
	in_secondary_company_type_id	IN	company_type.company_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_permissible_types		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability);
BEGIN
	
	OPEN out_cur FOR
		SELECT ct.company_type_id, ct.singular, ct.plural, ct.is_default, ct.is_top_company, ct.lookup_key,
		       ct.allow_lower_case, ct.use_user_role, ct.css_class, ct.default_region_type,
			   ct.region_root_sid, r.description region_root_description, ct.default_region_layout,
			   ct.create_subsids_under_parent
		  FROM company_type ct
		  LEFT JOIN csr.v$region r ON ct.region_root_sid = r.region_sid
		  JOIN TABLE(v_permissible_types) t_permissible ON t_permissible.tertiary_company_type_id = ct.company_type_id
		 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t_permissible.secondary_company_type_id = in_secondary_company_type_id
		 ORDER BY ct.position;
END;

FUNCTION GetDefaultRegionLayout(
	in_company_type_id		company_type.company_type_id%TYPE
) RETURN company_type.default_region_layout%TYPE
AS
	v_default_region_layout  company_type.default_region_layout%TYPE;
BEGIN
	SELECT NVL(ct.default_region_layout, '{COUNTRY}/{SECTOR}')
	  INTO v_default_region_layout
	  FROM company_type ct
	 WHERE ct.company_type_id = in_company_type_id;

	RETURN v_default_region_layout;
END;

END company_type_pkg;
/
