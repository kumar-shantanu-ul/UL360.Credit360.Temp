CREATE OR REPLACE PACKAGE BODY CHAIN.company_pkg
IS

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/
PROCEDURE UNSEC_GetCompanyCore(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetCompanyTags(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetCompanyBU(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetCompanyFlowItems(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetCompanyFlowTrans(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetCompanyRoleMembers(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyGroupSid (
	in_company_sid			security_pkg.T_SID_ID,
	in_group				chain_pkg.T_GROUP,
	in_group_sid			security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO company_group
	(company_sid, company_group_type_id, group_sid)
	SELECT in_company_sid, company_group_type_id, in_group_sid
	  FROM company_group_type
	 WHERE name = in_group;
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_sid				IN  security_pkg.T_SID_ID,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	acl_pkg.AddACE(
		v_act_id,
		Acl_pkg.GetDACLIDForSID(in_on_sid),
		security_pkg.ACL_INDEX_LAST,
		security_pkg.ACE_TYPE_ALLOW,
		0,
		in_to_sid,
		in_permission_set
	);
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_path				IN  VARCHAR2,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	AddPermission(
		in_on_sid,
		securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, in_to_path),
		in_permission_set
	);
END;

--check reference label input arrays
FUNCTION CheckReferenceInputs(
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS
) RETURN BOOLEAN
AS
BEGIN
	IF in_lookup_keys IS NULL OR in_lookup_keys.COUNT = 0 OR
	   in_lookup_keys(1) IS NULL OR in_values IS NULL THEN
		RETURN FALSE;
	END IF;

	IF in_lookup_keys.COUNT <> in_values.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'Number of lookup keys does not match number of values.');
	END IF;

	RETURN TRUE;
END;

PROCEDURE UpdateCompanyReference_ (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_key			IN v$company_reference.lookup_key%TYPE,
	in_value				IN company_reference.value%TYPE
)
AS
	v_reference_id			reference.reference_id%TYPE;
	v_reference_perms		T_REF_PERM_TABLE;
	v_permission_set		reference_capability.permission_set%TYPE;
	v_company_type_id		company_type.company_type_id%TYPE;
	v_count					NUMBER;
	v_regex 				reference_validation.validation_regex%TYPE;
	v_regex_result 			company_reference.value%TYPE;
	v_validation_desc 		reference_validation.description%TYPE;
	v_validation_error 		reference_validation.validation_text%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	SELECT company_type_id
	  INTO v_company_type_id
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

	BEGIN
		SELECT r.reference_id
		  INTO v_reference_id
		  FROM reference r
		 WHERE r.app_sid = security_pkg.GetApp
		   AND UPPER(r.lookup_key) = UPPER(in_lookup_key)
		   AND (
				EXISTS (SELECT * FROM reference_company_type rct WHERE rct.reference_id = r.reference_id AND rct.company_type_id = v_company_type_id)
			OR NOT EXISTS (SELECT * FROM reference_company_type rct WHERE rct.reference_id = r.reference_id)
		   );
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update company ' || in_company_sid || ' with reference ' || in_lookup_key || '. No such reference configured for this company type. ');
	END;

	IF NOT chain.helper_pkg.IsElevatedAccount() THEN
		v_reference_perms := helper_pkg.GetRefPermsByType(
			in_company_sid => in_company_sid,
			in_reference_id => v_reference_id
		);

		SELECT permission_set
		  INTO v_permission_set
		  FROM TABLE(v_reference_perms);

		IF BITAND(v_permission_set, 2) != 2 THEN -- security_pkg.PERMISSION_WRITE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || in_company_sid || ' while updating reference ' || in_lookup_key || ' as user sid ' || security_pkg.GetSid);
		END IF;
	END IF;
	
	-- Validate the reference with regex
	SELECT rv.validation_regex, rv.description, rv.validation_text
	  INTO v_regex, v_validation_desc, v_validation_error
	  FROM reference r
	  JOIN reference_validation rv ON r.reference_validation_id = rv.reference_validation_id
	 WHERE reference_id = v_reference_id;

	IF in_value IS NOT NULL AND v_regex IS NOT NULL THEN
		v_regex_result := REGEXP_SUBSTR(in_value, v_regex);

		IF v_regex_result IS NULL OR v_regex_result <> in_value THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_REFERENCE_NOT_VALID, v_validation_error||'. Company reference: '||in_value||' not valid for: '||v_validation_desc);
		END IF;
	END IF;

	BEGIN
		INSERT INTO company_reference (company_reference_id, reference_id, company_sid, value)
		VALUES (company_reference_id_seq.nextval, v_reference_id, in_company_sid, in_value);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE company_reference
			   SET value = in_value
			 WHERE reference_id = v_reference_id
			   AND company_sid = in_company_sid
			   AND app_sid = security_pkg.GetApp;
	END;
END;

--only use this internally; does not do reference unique checks
PROCEDURE UpdateCompanyReferences_ (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_keys			IN chain_pkg.T_STRINGS,
	in_values				IN chain_pkg.T_STRINGS
)
AS
BEGIN
	FOR i IN 1..in_lookup_keys.COUNT LOOP
		UpdateCompanyReference_(in_company_sid, in_lookup_keys(i), in_values(i));
	END LOOP;
END;

/**
 *	The purpose of the procedure is to be a single point of company based securable object setup.
 *  Any changes to this procedure should be flexible enough to deal with situations where the
 *  object may or may not already exists, already have permissions etc. so that it can
 *  be called during any update scripts.
 */
PROCEDURE CreateSOStructure (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_is_new_company		IN  BOOLEAN
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Everyone');
	v_chain_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_ADMIN_GROUP);
	v_chain_users_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_USER_GROUP);
	v_capabilities_sid		security_pkg.T_SID_ID;
	v_admins_sid			security_pkg.T_SID_ID;
	v_users_sid				security_pkg.T_SID_ID;
	v_pending_sid			security_pkg.T_SID_ID;
	v_uploads_sid			security_pkg.T_SID_ID;
	v_filters_sid			security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
BEGIN
	/********************************************
		CREATE OBJECTS AND ADD PERMISSIONS
	********************************************/

	-- ADMIN GROUP
	BEGIN
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.ADMIN_GROUP, v_admins_sid);
	END;

	-- USER GROUP
	BEGIN
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.USER_GROUP, v_users_sid);
	END;

	-- PENDING USER GROUP
	BEGIN
		v_pending_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.PENDING_GROUP);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.PENDING_GROUP, v_pending_sid);
	END;

	SetCompanyGroupSid(in_company_sid, chain_pkg.ADMIN_GROUP, v_admins_sid);
	SetCompanyGroupSid(in_company_sid, chain_pkg.USER_GROUP, v_users_sid);
	SetCompanyGroupSid(in_company_sid, chain_pkg.PENDING_GROUP, v_pending_sid);
	SetCompanyGroupSid(in_company_sid, chain_pkg.CHAIN_ADMIN_GROUP, v_chain_admins_sid);
	SetCompanyGroupSid(in_company_sid, chain_pkg.CHAIN_USER_GROUP, v_chain_users_sid);

	-- UPLOADS CONTAINER
	BEGIN
		v_uploads_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.COMPANY_UPLOADS);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.COMPANY_UPLOADS, v_uploads_sid);
			acl_pkg.AddACE(
				v_act_id,
				acl_pkg.GetDACLIDForSID(v_uploads_sid),
				security_pkg.ACL_INDEX_LAST,
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid,
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;

	-- FILTERS CONTAINER
	BEGIN
		v_filters_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.COMPANY_FILTERS);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.COMPANY_FILTERS, v_filters_sid);
			acl_pkg.AddACE(
				v_act_id,
				acl_pkg.GetDACLIDForSID(v_filters_sid),
				security_pkg.ACL_INDEX_LAST,
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid,
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;

	-- UNINVITED SUPPLIERS CONTAINER
	BEGIN
		v_uninvited_sups_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.UNINVITED_SUPPLIERS);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);
			acl_pkg.AddACE(
				v_act_id,
				acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid),
				security_pkg.ACL_INDEX_LAST,
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid,
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;

	IF helper_pkg.UseTraditionalCapabilities THEN
		-- SETUP CAPABILITIES
		BEGIN
			v_capabilities_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.CAPABILITIES);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.CAPABILITIES, v_capabilities_sid);

				-- don't inherit dacls
				securableobject_pkg.SetFlags(v_act_id, v_capabilities_sid, 0);
				-- clean existing ACE's
				acl_pkg.DeleteAllACEs(v_act_id, Acl_pkg.GetDACLIDForSID(v_capabilities_sid));

				AddPermission(v_capabilities_sid, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);
		END;

		capability_pkg.RefreshCompanyCapabilities(in_company_sid);
	END IF;

	/********************************************
		ADD OBJECTS TO GROUPS
	********************************************/
	-- add the users group to the Chain Users group
	group_pkg.AddMember(v_act_id, v_users_sid, v_chain_users_sid);

	-- add the administrators group to the users group
	-- our group, so we're hacking this in
	--group_pkg.AddMember(v_act_id, v_admins_sid, v_users_sid);
	BEGIN
		INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (v_admins_sid, v_users_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END;

FUNCTION GetGroupMembers(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_name			IN  chain_pkg.T_GROUP
)
RETURN security.T_SO_TABLE
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN
	RETURN group_pkg.GetDirectMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, in_group_name));
END;

-- collects a paged cursor of companies based on sids passed in as a T_SID_TABLE
PROCEDURE CollectSearchResults (
	in_all_results			IN  T_FILTERED_OBJECT_TABLE,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	SELECT DISTINCT object_id
	  BULK COLLECT INTO v_results
	  FROM TABLE(in_all_results);

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE CollectSearchResults (
	in_all_results			IN  security.T_SID_TABLE,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results_total			security.T_SID_TABLE;
	v_results_paged			security.T_SID_TABLE;
BEGIN
	--filter out deleted companies before applying paging/setting total count
	SELECT c.company_sid
	  BULK COLLECT INTO v_results_total
	  FROM TABLE (in_all_results) T
	  JOIN company c ON T.column_value = c.company_sid
	 WHERE c.deleted = 0
	   AND c.pending = 0;

	IF in_page_size = 0 THEN
		v_results_paged := in_all_results;
	ELSE
		SELECT company_sid
		  BULK COLLECT INTO v_results_paged
		  FROM (
			SELECT A.company_sid, ROWNUM r
			  FROM (
			  	SELECT c.company_sid
				  FROM company c, TABLE(v_results_total) T
				 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND c.company_sid = T.column_value
				 ORDER BY LOWER(c.name), c.company_sid
			  ) A
			 WHERE ROWNUM < (in_page * in_page_size) + 1
		) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;

	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages
	      FROM TABLE(v_results_total);

	-- collect the paged results
	OPEN out_result_cur FOR
		SELECT c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm, c.address_1, c.address_2, c.address_3,
			   c.address_4, c.state, c.city, c.postcode, c.country_code, c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid,
			   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, c.user_level_messaging,
			   c.sector_id, c.country_name, c.sector_description, c.can_see_all_companies, c.company_type_id,
			   c.company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand, c.parent_sid, c.parent_name,
			   c.parent_country_code, c.parent_country_name, c.country_is_hidden, c.region_sid,
			   NVL(sr.active, chain_pkg.inactive) active_supplier,
		       CASE WHEN sr.primary_follower_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 END is_primary_follower,
			   sr.supp_rel_code, c.company_type_description,
			   CASE sr.active WHEN 0 THEN chain_pkg.PENDING_RELATIONSHIP_DESC WHEN 1 THEN chain_pkg.ACTIVE_RELATIONSHIP_DESC ELSE chain_pkg.NO_RELATIONSHIP_DESC END relationship_status,
			   fs.label flow_state_label, r.geo_longitude longitude, r.geo_latitude latitude
		  FROM v$company c
		  JOIN TABLE(v_results_paged) T ON c.company_sid = T.column_value
		  LEFT JOIN (
				 SELECT sr.*, sf.user_sid primary_follower_user_sid
				  FROM v$supplier_relationship sr, (
						SELECT *
						  FROM supplier_follower
						 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
						   AND is_primary IS NOT NULL
					   ) sf
				 WHERE sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				   AND sr.purchaser_company_sid = sf.purchaser_company_sid(+)
				   AND sr.supplier_company_sid = sf.supplier_company_sid(+)
			) sr ON c.app_sid = sr.app_sid AND c.company_sid = sr.supplier_company_sid
		  LEFT JOIN csr.flow_item fi ON sr.app_sid = fi.app_sid AND sr.flow_item_id = fi.flow_item_id
		  LEFT JOIN csr.flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  LEFT JOIN csr.region r ON c.app_sid = r.app_sid AND c.region_sid = r.region_sid
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY LOWER(c.name), c.company_sid;
END;

FUNCTION VerifyMembership (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_type			IN  chain_pkg.T_GROUP,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_g_sid					security_pkg.T_SID_ID;
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	BEGIN
		-- leave this in here so things don't blow up when we clean
		v_g_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, in_group_type);

		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetMembersAsTable(v_act_id, v_g_sid))
		 WHERE sid_id = in_user_sid;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN FALSE;
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_count > 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
	END IF;

	RETURN v_count > 0;
END;

-- downstream means "up the supply chain" for us - e.g. Staples would be "upstream" of Bobs Paper Mills
FUNCTION IsInDownstreamSuppChain (
	in_company_sid			IN  company.company_sid%TYPE
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_in_chain				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_in_chain
      FROM dual
     WHERE v_company_sid IN (
		SELECT purchaser_company_sid
		  FROM v$supplier_relationship
		 WHERE active = 1
		   AND deleted = 0
		 START WITH supplier_company_sid = in_company_sid
		CONNECT BY PRIOR purchaser_company_sid = supplier_company_sid
	 );

	RETURN v_in_chain>0;
END;

/****************************************************************************************
****************************************************************************************
	PUBLIC
****************************************************************************************
****************************************************************************************/

-- this is used to override the capability checks in a few key place as it doesn't really fit in the normal capability structure (or it would be messy)
FUNCTION CanSeeCompanyAsChainTrnsprnt (
	in_company_sid			IN  company.company_sid%TYPE
) RETURN BOOLEAN
AS
BEGIN
	-- currently a company can see any company below it if
	-- they are somewhere (at any level) above that lower company in a chain of active supplier-customer relationships
	-- the settings mean that the supply chain is transparnet for thier company (this means a top company and with the appropriate customer option at the moment)
	RETURN (IsInDownstreamSuppChain(in_company_sid) AND helper_pkg.IsChainTrnsprntForMyCmpny);
	-- downstream means "up the supply chain" for us - e.g. Staples would be "upstream" of Bobs Paper Mills
END;

/************************************************************
	SYS_CONTEXT handlers
************************************************************/
PROCEDURE SetCanSeeAllCompanies
AS
	v_can_see_all_companies	company.can_see_all_companies%TYPE;
BEGIN
	CanSeeAllCompanies(v_can_see_all_companies);
	security_pkg.SetContext('CHAIN_CAN_SEE_ALL_COMPANIES', NVL(v_can_see_all_companies, 0));
END;

FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT in_company_sid;
BEGIN
	-- if v_company_sid is 0, try to get the existing company sid out of the context
	IF NVL(v_company_sid, 0) = 0 THEN
		v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;

	IF helper_pkg.IsElevatedAccount THEN
		SetCompany(v_company_sid);
		RETURN v_company_sid;
	END IF;

	-- first, verify that this user exists as a chain_user (ensures that views work at bare minimum)
	helper_pkg.AddUserToChain(SYS_CONTEXT('SECURITY', 'SID'));

	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE
		   AND company_sid = v_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_company_sid := NULL;
	END;

	-- if we've got a company sid, verify that the user is a member
	IF v_company_sid IS NOT NULL THEN
		-- is this user a group member?
		IF NOT helper_pkg.IsChainAdmin AND
		   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND
		   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
			v_company_sid := NULL;
		END IF;
	END IF;

	-- if we don't have a company yet, check to see if a default company sid is set
	IF v_company_sid IS NULL THEN

		-- most users will belong to one company
		-- super users / admins may belong to more than 1

		BEGIN
			-- try to get a default company
			SELECT cu.default_company_sid
			  INTO v_company_sid
			  FROM chain_user cu, v$company c
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cu.app_sid = c.app_sid
			   AND cu.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND cu.default_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;

		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT helper_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;

	-- if we don't have a company yet, check to see if there is a top company set in customer options
	IF v_company_sid IS NULL THEN

		-- most users will belong to one company
		-- super users / admins may belong to more than 1

		BEGIN
			-- try to get a default company
			SELECT co.top_company_sid
			  INTO v_company_sid
			  FROM customer_options co, company c
			 WHERE co.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND co.app_sid = c.app_sid
			   AND co.top_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;

		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT helper_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;

	-- if we don't have a company yet, grab the first company we're a member of alphabetically
	IF v_company_sid IS NULL THEN
		-- ok, no valid default set - might as well just sort them alphabetically by company name and
		-- 		pick the first, at least it's predictable
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c, (
					SELECT DISTINCT so.parent_sid_id company_sid
					  FROM security.securable_object so, TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, security_pkg.GetSid)) ug -- user group sids
					 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
					   AND so.sid_id = ug.sid_id
					) uc -- user companies
				 WHERE c.company_sid = uc.company_sid
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					)
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;

	-- if there's still no company set and we're a chain admin, pick the first company alphabetically.
	IF v_company_sid IS NULL AND helper_pkg.IsChainAdmin THEN
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					)
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;

	-- set the company sid in the context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);

	-- set it in the context instead of cross joining with the company table (used in chain_company_user view)
	SetCanSeeAllCompanies();

	-- return the company sid (or 0 if it's been cleared)
	RETURN NVL(v_company_sid, 0);
END;

PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, 0);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	IF v_company_sid = 0 THEN
		v_company_sid := NULL;
	END IF;

	IF v_company_sid IS NOT NULL THEN
		IF helper_pkg.IsElevatedAccount THEN
			-- just make sure that the company exists
			SELECT COUNT(*)
			  INTO v_count
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = v_company_sid;

			IF v_count = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		ELSE
			-- is this user a group member?
			IF NOT helper_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
					security_pkg.SetContext('CHAIN_COMPANY', NULL);
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		END IF;
	END IF;

	-- set the value in sys context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);

	-- set it in the context instead of cross joining with the company table (used in chain_company_user view)
	SetCanSeeAllCompanies();
END;

PROCEDURE SetCompany(
	in_name					IN  security_pkg.T_SO_NAME
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM v$company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(name) = LOWER(in_name);

	SetCompany(v_company_sid);
END;

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company sid is not set in the session context');
	END IF;
	RETURN v_company_sid;
END;

FUNCTION GetCompanyFilterSid
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_filters_sid			security_pkg.T_SID_ID;
BEGIN
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company sid is not set in the session context');
	END IF;

	BEGIN
		v_filters_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_company_sid, chain_pkg.COMPANY_FILTERS);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN -1;
	END;
	RETURN v_filters_sid;
END;

/************************************************************
	Securable object handlers
************************************************************/
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN 
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	/* I only keep this perverse pattern just in case there is still place we try to delete companies by setting SO name to null.*/
 	/* We should be using the delete stored proc instead.*/

	-- setting name to null is actually a virtual deletion - lets leave the name as is, but set the deleted flag
	
	IF in_new_name IS NULL THEN
		BEGIN
			UPDATE company
			   SET deleted = chain_pkg.DELETED
			 WHERE app_sid = security_pkg.GetApp
			   AND company_sid = in_sid_id;
		END;
	END IF;

END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	--clean up all questionnaires
	FOR r IN (
		SELECT DISTINCT qt.db_class pkg
		  FROM questionnaire q, questionnaire_type qt
		 WHERE q.questionnaire_type_id = qt.questionnaire_type_id
		   AND q.app_sid = qt.app_sid
		   AND q.company_sid = in_sid_id
		   AND q.app_sid = security_pkg.GetApp
	)
	LOOP
		-- clear questionnaire types for this company
		IF r.pkg IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||r.pkg||'.DeleteQuestionnaires(:1);end;'
				USING in_sid_id; -- company sid
		END IF;

	END LOOP;

	-- now clean up all things linked to company
	
	DELETE FROM company_product_tr
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id IN (
		SELECT product_id
		  FROM company_product
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id
		);
	
	DELETE FROM company_product
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;

	DELETE FROM dedupe_pp_alt_comp_name
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;

	DELETE FROM alt_company_name
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;

	DELETE FROM applied_company_capability
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;

	-- DELETE FROM event_user_status
	 -- WHERE event_id IN
	-- (
		-- SELECT event_id
		  -- FROM event
		 -- WHERE ((for_company_sid = in_sid_id)
			-- OR (related_company_sid = in_sid_id))
		   -- AND app_sid = security_pkg.GetApp
	-- )
	-- AND app_sid = security_pkg.GetApp;

	-- DELETE FROM event
	 -- WHERE ((for_company_sid = in_sid_id)
		-- OR (related_company_sid = in_sid_id))
	   -- AND app_sid = security_pkg.GetApp;

	-- -- clean up actions
	-- DELETE FROM action_user_status
	 -- WHERE action_id IN
	-- (
		-- SELECT action_id
		  -- FROM action
		 -- WHERE ((for_company_sid = in_sid_id)
			-- OR (related_company_sid = in_sid_id))
		   -- AND app_sid = security_pkg.GetApp
	-- )
	-- AND app_sid = security_pkg.GetApp;

	-- DELETE FROM action
	 -- WHERE ((for_company_sid = in_sid_id)
		-- OR (related_company_sid = in_sid_id))
	   -- AND app_sid = security_pkg.GetApp;

	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN
	(
		SELECT questionnaire_share_id
		  FROM questionnaire_share
		 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM qnnaire_share_alert_log
	 WHERE questionnaire_share_id IN
	(
		SELECT questionnaire_share_id
		  FROM questionnaire_share
		 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM questionnaire_share
	 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;

	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM questionnaire_invitation
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	);

	DELETE FROM questionnaire
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM company_cc_email
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM company_metric
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM task_invitation_qnr_type
	 WHERE invitation_id IN (
	 	SELECT invitation_id
		  FROM invitation
		 WHERE (from_company_sid = in_sid_id OR to_company_sid = in_sid_id OR on_behalf_of_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM invitation_qnr_type
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation
		 WHERE (from_company_sid = in_sid_id OR to_company_sid = in_sid_id OR on_behalf_of_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM questionnaire_invitation
		 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation
		 WHERE (from_company_sid = in_sid_id OR to_company_sid = in_sid_id OR on_behalf_of_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND (from_company_sid = in_sid_id OR to_company_sid = in_sid_id OR on_behalf_of_company_sid = in_sid_id);

	-- TODO: clear tasks
	/*DELETE FROM task_file
	 WHERE app_sid = security_pkg.GetApp
	   AND task_id IN (
	   		SELECT task_id
	   		  FROM task
	   		 WHERE app_sid = security_pkg.GetApp
	   		   AND (supplier_company_sid = in_sid_id OR owner_company_sid = in_sid_id)
	   	);
	*/
	DELETE FROM task
	 WHERE app_sid = security_pkg.GetApp
	   AND (supplier_company_sid = in_sid_id OR owner_company_sid = in_sid_id);

	DELETE FROM purchase_tag
	 WHERE app_sid = security_pkg.GetApp
	   AND purchase_id IN (
		SELECT purchase_id
		  FROM purchase
		 WHERE purchaser_company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	   );

	DELETE FROM purchase
	 WHERE purchaser_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM purchase_channel
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	chain_link_pkg.DeleteCompany(in_sid_id);

	UPDATE purchased_component
	   SET component_supplier_type_id = 0, supplier_company_sid = NULL
	 WHERE supplier_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM purchased_component
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM purchaser_follower
	 WHERE ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id))
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM supplier_follower
	 WHERE ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id))
	   AND app_sid = security_pkg.GetApp;

	-- we need the relationships to propagate the scores upwards,
	-- but we need to know not to follow them downwards in the calcs
	UPDATE supplier_relationship
	   SET deleted = chain_pkg.DELETED
	 WHERE ((supplier_company_sid = in_sid_id) 
		OR (purchaser_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM supplier_relationship_score
	 WHERE ((supplier_company_sid = in_sid_id)
		OR (purchaser_company_sid = in_sid_id))
	   AND app_sid = security_pkg.GetApp;
	   
	company_score_pkg.UNSEC_PropagateCompanyScores(in_sid_id);

	-- now we've done the propagation, we can delete the relationships properly.
	DELETE FROM supplier_relationship
	 WHERE ((supplier_company_sid = in_sid_id)
		OR (purchaser_company_sid = in_sid_id))
	   AND app_sid = security_pkg.GetApp;

	-- are we OK blanking this? I think so as this is reset sensibly when ever a chain page is loaded
	UPDATE chain_user
	   SET default_company_sid = NULL
	 WHERE default_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM newsflash_company WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

	/* PRODUCT RELATED ITEMS TO CLEAR */
	-- clear the default product codes
	DELETE FROM product_code_type WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

	-- clear all products and components and any links between them
	-- TODO: we'll need to fix this up...
	--DELETE FROM cmpnt_prod_rel_pending WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	--DELETE FROM cmpnt_prod_relationship WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	/* NOTE TO DO - this may be too simplistic as just clears any links where one company is deleted */
	--DELETE FROM product WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	--DELETE FROM component WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

	DELETE FROM message_recipient
	 WHERE recipient_id IN
	(
		SELECT recipient_id FROM recipient
		 WHERE app_sid = security_pkg.GetApp
		   AND to_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM recipient
	 WHERE app_sid = security_pkg.GetApp
	   AND to_company_sid = in_sid_id;

	DELETE FROM message_recipient
	 WHERE message_id IN
	(
		SELECT message_id FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND re_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM message_refresh_log
	 WHERE message_id IN
	(
		SELECT message_id FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND re_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM user_message_log
	 WHERE message_id IN
	(
		SELECT message_id FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND re_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM message
	 WHERE app_sid = security_pkg.GetApp
	   AND re_company_sid = in_sid_id;

	--secondary company messages
	DELETE FROM message_refresh_log
	 WHERE message_id IN
	(
		SELECT message_id FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND re_secondary_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM user_message_log
	 WHERE message_id IN
	(
		SELECT message_id FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND re_secondary_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM message_recipient
	 WHERE message_id IN
	(
		SELECT message_id FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND re_secondary_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;

	DELETE FROM message
	 WHERE app_sid = security_pkg.GetApp
	   AND re_secondary_company_sid = in_sid_id;

	DELETE FROM file_upload
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;

	UPDATE purchased_component
	   SET supplier_product_id = NULL
	 WHERE app_sid = security_pkg.GetApp
	   AND supplier_product_id IN
			(SELECT product_id FROM product_revision WHERE app_sid = security_pkg.GetApp AND supplier_root_component_id IN
					(SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND company_sid = in_sid_id));

	DELETE FROM product
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id IN
			(SELECT product_id FROM product_revision WHERE app_sid = security_pkg.GetApp AND supplier_root_component_id IN
					(SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND company_sid = in_sid_id));

	DELETE FROM product_revision
	 WHERE app_sid = security_pkg.GetApp
	   AND supplier_root_component_id IN
					(SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND company_sid = in_sid_id);

	DELETE FROM uninvited_supplier
	 WHERE created_as_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM company_group
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM business_unit_supplier
	 WHERE app_sid = security_pkg.GetApp
	   AND supplier_company_sid = in_sid_id;

	DELETE FROM company_tag_group
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;

	DELETE FROM company_reference
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	FOR r IN (
		SELECT sv.saved_filter_sid
		  FROM chain.saved_filter sv
		 WHERE company_sid = in_sid_id
	) LOOP
		security.securableobject_pkg.DeleteSO(in_act_id, r.saved_filter_sid);
	END LOOP;

	DELETE FROM dedupe_match
	 WHERE matched_to_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id IN (
		SELECT dedupe_processed_record_id
		  FROM dedupe_processed_record
		 WHERE (matched_to_company_sid = in_sid_id OR created_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	);

	DELETE FROM dedupe_processed_record
	 WHERE (matched_to_company_sid = in_sid_id OR created_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM dedupe_preproc_comp
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM pending_company_tag
	 WHERE pending_company_sid = in_sid_id;
	  
	DELETE FROM pend_company_suggested_match
	 WHERE (pending_company_sid = in_sid_id OR matched_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;
	
	UPDATE company
	   SET requested_by_company_sid = NULL
	 WHERE requested_by_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM company_request_action
	 WHERE (company_sid = in_sid_id OR matched_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM company
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

/************************************************************
	Company Management Handlers
************************************************************/

PROCEDURE VerifySOStructure
AS
BEGIN
	FOR r IN (
		SELECT company_sid
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		CreateSOStructure(r.company_sid, FALSE);
	END LOOP;
END;

PROCEDURE PopulateConflictingRefTable(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_country_code			IN	company.country_code%type,
	in_company_type_id		IN	company.company_type_id%type,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS
)
AS
BEGIN
	-- Delete any rows from the same transaction from previous checks
	DELETE FROM TT_REFERENCE_LABELS;

	FOR i in 1..in_values.COUNT LOOP
		INSERT INTO TT_REFERENCE_LABELS
		SELECT c.company_sid, c.name, r.lookup_key
		  FROM company c
		  JOIN reference r ON c.app_sid = r.app_sid
		  JOIN company_reference cr ON r.app_sid = cr.app_sid AND r.reference_id = cr.reference_id AND c.company_sid = cr.company_sid
		 WHERE (in_company_sid IS NULL OR c.company_sid != in_company_sid)
		   AND LOWER(TRIM(cr.value)) = LOWER(TRIM(in_values(i)))
		   AND LOWER(TRIM(r.lookup_key)) = LOWER(TRIM(in_lookup_keys(i)))
		   AND (r.reference_uniqueness_id = chain_pkg.REF_UNIQUE_GLOBAL OR (r.reference_uniqueness_id = chain_pkg.REF_UNIQUE_COUNTRY AND c.country_code = in_country_code))
		   AND LENGTH(TRIM(cr.value)) > 0
		   AND c.deleted = 0
		   AND c.pending = 0;
	END LOOP;
END;

PROCEDURE GetUniqueReferenceConflicts(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_country_code			IN	company.country_code%TYPE,
	in_company_type_id		IN	company_type.company_type_id%TYPE,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS,
	out_lookup_keys		   OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_ref_lbl_tbl			T_REFERENCE_LABEL_TABLE;
BEGIN
	--TODO: Check something that makes more sense
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	--check in_values
	IF in_values IS NULL OR in_values.COUNT = 0  THEN
		RETURN;
	END IF;

	--get conflicting ref keys
	PopulateConflictingRefTable(in_company_sid, in_country_code, in_company_type_id, in_lookup_keys, in_values);
	
	SELECT T_REFERENCE_LABEL_ROW(company_sid, name, lookup_key)
	  BULK COLLECT INTO v_ref_lbl_tbl
	  FROM (SELECT company_sid, name, lookup_key FROM TT_REFERENCE_LABELS);
	
	OPEN out_lookup_keys FOR
		SELECT trl.lookup_key, r.label, r.reference_uniqueness_id
		  FROM TABLE(v_ref_lbl_tbl) trl
		  JOIN reference r ON r.lookup_key = trl.lookup_key
		 WHERE r.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetUniqueReferenceConflicts(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS,
	out_lookup_keys		   OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_country_code			company.country_code%TYPE;
	v_company_type_id		company_type.company_type_id%TYPE;
BEGIN
	SELECT country_code, company_type_id
	  INTO v_country_code, v_company_type_id
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

	 GetUniqueReferenceConflicts(in_company_sid, v_country_code, v_company_type_id, in_lookup_keys, in_values, out_lookup_keys);
END;

FUNCTION CheckReferenceExists(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_country_code			IN	company.country_code%type,
	in_company_type_id		IN	company.company_type_id%type,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS
) RETURN BOOLEAN
AS
	v_count							NUMBER;
BEGIN
	PopulateConflictingRefTable(in_company_sid, in_country_code, in_company_type_id, in_lookup_keys, in_values);

	SELECT count(*)
	  INTO v_count
	  FROM TT_REFERENCE_LABELS;

	RETURN v_count > 0;
END;

FUNCTION CheckReferenceExists(
	in_country_code			IN	company.country_code%type,
	in_company_type_id		IN	company.company_type_id%type,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckReferenceExists(null, in_country_code, in_company_type_id, in_lookup_keys, in_values);
END;

FUNCTION CheckReferenceExists(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS
) RETURN BOOLEAN
AS
	v_country_code			company.country_code%TYPE;
	v_company_type_id		company_type.company_type_id%TYPE;
BEGIN
	SELECT country_code, company_type_id
	  INTO v_country_code, v_company_type_id
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

	RETURN CheckReferenceExists(in_company_sid, v_country_code, v_company_type_id, in_lookup_keys, in_values);
END;

PROCEDURE CreateCompanyBase(
	in_name					IN company.name%TYPE,	
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_lookup_keys			IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_is_pending			IN NUMBER DEFAULT 0,
	in_parent_sid			IN security_pkg.T_SID_ID DEFAULT NULL,
	in_so_container_sid		IN security_pkg.T_SID_ID,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_signature					company.signature%TYPE;
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_chain_admins 				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators');
	v_chain_users 				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Users');
BEGIN
	v_signature	:= helper_pkg.GenerateCompanySignature(
		in_company_name			=> in_name,
		in_country				=> in_country_code,
		in_company_type_id		=> in_company_type_id,
		in_city					=> in_city,	
		in_state				=> in_state,
		in_sector_id			=> in_sector_id,
		in_layout				=> company_type_pkg.GetDefaultRegionLayout(in_company_type_id),
		in_parent_sid			=> in_parent_sid
	);

	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, in_so_container_sid, class_pkg.getClassID('Chain Company'), NULL, out_company_sid);
	
	UPDATE security.securable_object 
	   SET name = helper_pkg.GenerateSOName(in_company_name => in_name, in_company_sid => out_company_sid) 
	 WHERE sid_id = out_company_sid;

	INSERT INTO company(
		company_sid, name, country_code, company_type_id, sector_id,
		address_1, address_2, address_3, address_4,	state,
		postcode, phone, fax, website, email, city, parent_sid, pending, signature		
	)
	VALUES(
		out_company_sid, in_name, in_country_code, in_company_type_id, in_sector_id,
		in_address_1, in_address_2,	in_address_3, in_address_4,	in_state,
		in_postcode, in_phone, in_fax, in_website, in_email, in_city, in_parent_sid, in_is_pending, v_signature
	);

	-- causes the groups and containers to get created
	CreateSOStructure(out_company_sid, TRUE);

	AddPermission(out_company_sid, security_pkg.SID_BUILTIN_ADMINISTRATOR, security_pkg.PERMISSION_STANDARD_ALL);
	AddPermission(out_company_sid, v_chain_admins, security_pkg.PERMISSION_WRITE);
	AddPermission(out_company_sid, v_chain_users, security_pkg.PERMISSION_WRITE);

	-- if we are creating a company add a company wide "check my details" action
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_to_company_sid           => out_company_sid
	);

	-- add product codes defaults for the new company
	product_pkg.SetProductCodeDefaults(out_company_sid);
END;

--create company SP that doesn't call the link package
PROCEDURE CreateCompanyNoLink(
	in_name					IN company.name%TYPE,	
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_lookup_keys			IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_is_pending			IN NUMBER DEFAULT 0,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid				security_pkg.T_SID_ID := CASE WHEN in_is_pending = 1 THEN helper_pkg.GetOrCreatePendingContainer ELSE helper_pkg.GetCompaniesContainer END;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_container_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating a company logged in as user with sid:'||security_pkg.getSid);
	END IF;

	 CreateCompanyBase(
		in_name					=> in_name, 
		in_country_code			=> in_country_code,
		in_company_type_id		=> in_company_type_id,
		in_sector_id			=> in_sector_id,
		in_address_1 			=> in_address_1,
		in_address_2 			=> in_address_2,
		in_address_3 			=> in_address_3,
		in_address_4 			=> in_address_4,
		in_state 				=> in_state,
		in_postcode 			=> in_postcode,
		in_phone 				=> in_phone,
		in_fax 					=> in_fax,
		in_website				=> in_website,
		in_email				=> in_email,
		in_city 				=> in_city,
		in_lookup_keys			=> in_lookup_keys,
		in_values				=> in_values,
		in_is_pending			=> in_is_pending,
		in_so_container_sid		=> v_container_sid,
		out_company_sid			=> out_company_sid
	);

	UpdateCompanyReferences(out_company_sid, in_lookup_keys, in_values, in_is_pending);

	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
		dedupe_preprocess_pkg.PreprocessCompany(out_company_sid);
	END IF;

	--Add USER_GROUP as a member of company type specific group
	company_type_pkg.CompanyCreated(out_company_sid);
END;

PROCEDURE AddPendingTags(
	in_pending_company_sid	IN security_pkg.T_SID_ID,
	in_tag_ids				IN security_pkg.T_SID_IDS
)
AS
BEGIN
	FOR i IN in_tag_ids.FIRST .. in_tag_ids.LAST LOOP
		INSERT INTO chain.pending_company_tag (pending_company_sid, tag_id)
		VALUES (in_pending_company_sid, in_tag_ids(i));
	END LOOP;
END;

PROCEDURE CreateNewCompany(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_lookup_keys			chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES;
BEGIN
	IF NOT (helper_pkg.IsTopCompany = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only top company users or admins can directly create a new company record');
	END IF;
	
	IF NOT capability_pkg.CheckCapabilityBySupplierType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_company_type_id, chain_pkg.CREATE_COMPANY_WITHOUT_INVIT) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You don''t have permissions creating a company of company type with id:'||in_company_type_id);
	END IF;
	
	BEGIN
		chain.helper_pkg.LogonUCD;
		
		--TODO: at some point we need to replace all instances of SPs that take lookup_keys with reference ids
		IF in_reference_ids IS NOT NULL AND in_reference_ids.COUNT != 0 AND 
		   in_reference_ids(1) IS NOT NULL AND  in_values IS NOT NULL THEN
			FOR i IN 1 .. in_reference_ids.COUNT 
			LOOP
				SELECT lookup_key
				  INTO v_lookup_keys(i)
				  FROM reference
				 WHERE reference_id = in_reference_ids(i);
			END LOOP;
		END IF;
		
		CreateCompanyNoLink(
			in_name 			=>	in_name,
			in_country_code		=>	in_country_code,
			in_company_type_id	=>	in_company_type_id,
			in_address_1 		=>	in_address_1,
			in_address_2 		=>	in_address_2,
			in_address_3 		=>	in_address_3,
			in_address_4 		=>	in_address_4,
			in_state 			=>	in_state,
			in_postcode 		=>	in_postcode,
			in_phone 			=>	in_phone,
			in_fax 				=>	in_fax,
			in_website			=>	in_website,
			in_email			=>	in_email,
			in_city 			=>	in_city,
			in_sector_id		=>	in_sector_id,
			in_lookup_keys		=>	v_lookup_keys,
			in_values			=>	in_values,
			out_company_sid		=>	out_company_sid
		);

		-- callout to customised systems
		chain_link_pkg.AddCompany(out_company_sid);
		
		ActivateCompany(out_company_sid);
		StartRelationship(
			in_purchaser_company_sid 		=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
			in_supplier_company_sid			=> out_company_sid
		);
		ActivateRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), out_company_sid);
		
		SetTags(out_company_sid, in_tag_ids);
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;

			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;
END;

FUNCTION FindExactMatches_UNSEC(
	in_company_name			company.name%TYPE,
	in_country_code			company.country_code%TYPE,
	in_company_type_id		company.company_type_id%TYPE,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_parent_sid			security_pkg.T_SID_ID DEFAULT NULL,
	in_reference_ids		security_pkg.T_SID_IDS,
	in_ref_values			chain_pkg.T_STRINGS	
)RETURN security_pkg.T_SID_IDS
AS
	v_temp_matched_sid		security_pkg.T_SID_ID;
	v_ref_matched_sids		security_pkg.T_SID_IDS;
	v_matched_sids			security_pkg.T_SID_IDS;
	v_ref_vals				security.T_VARCHAR2_TABLE DEFAULT security.T_VARCHAR2_TABLE(); /* ref id, ref value */
	v_matched_sids_tbl		security.T_SID_TABLE;
	v_signature				company.signature%TYPE;
BEGIN
	v_signature := helper_pkg.GenerateCompanySignature(
		in_company_name			=> in_company_name,
		in_country				=> in_country_code,
		in_company_type_id		=> in_company_type_id,
		in_city					=> in_city,
		in_state				=> in_state,
		in_sector_id			=> in_sector_id,
		in_layout				=> company_type_pkg.GetDefaultRegionLayout(in_company_type_id),
		in_parent_sid			=> in_parent_sid
	);

	--check if non-pending companies with the same name, country exist (by applying the company SO name uniqueness rules) 
	BEGIN
		SELECT company_sid
		  INTO v_temp_matched_sid
		  FROM company c
		 WHERE LOWER(c.signature) = LOWER(v_signature)
		   AND c.pending = 0
		   AND c.deleted = 0;
		   
		v_matched_sids(v_matched_sids.COUNT + 1) := v_temp_matched_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	--check for reference uniqueness
	IF in_reference_ids IS NOT NULL AND in_reference_ids.COUNT > 0 THEN
		FOR i IN in_reference_ids.FIRST .. in_reference_ids.LAST LOOP
			v_ref_vals.extend;
			v_ref_vals(v_ref_vals.COUNT) := security.T_VARCHAR2_ROW(pos => in_reference_ids(i), value => in_ref_values(i));
		END LOOP;
		
		SELECT DISTINCT c.company_sid
		  BULK COLLECT INTO v_ref_matched_sids
		  FROM company c
		  JOIN company_reference cr ON c.company_sid = cr.company_sid
		  JOIN reference r ON cr.reference_id = r.reference_id
		 WHERE c.pending = 0
		   AND c.deleted = 0
		   AND (r.reference_uniqueness_id = chain_pkg.REF_UNIQUE_GLOBAL 
			OR (r.reference_uniqueness_id = chain_pkg.REF_UNIQUE_COUNTRY AND c.country_code = in_country_code))
		   AND LOWER(cr.value) IN (
				SELECT LOWER(t.value)
				  FROM TABLE (v_ref_vals) t
				 WHERE t.pos = r.reference_id
			);
		
		IF v_ref_matched_sids.COUNT > 0 THEN
			FOR i IN v_ref_matched_sids.FIRST .. v_ref_matched_sids.LAST 
			LOOP
				v_matched_sids(v_matched_sids.COUNT + 1) := v_ref_matched_sids(i);
			END LOOP;
		END IF;
	END IF;
	
	v_matched_sids_tbl := security.security_pkg.SidArrayToTable(v_matched_sids);

	SELECT DISTINCT column_value
	  BULK COLLECT INTO v_matched_sids
	  FROM TABLE(v_matched_sids_tbl);
	
	RETURN v_matched_sids;
END;

PROCEDURE CreateCompanyRequest_UNSEC(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID,
	out_matched_sids		OUT security_pkg.T_SID_IDS
)
AS
	v_ref_matched_sids		security_pkg.T_SID_IDS;
	v_lookup_keys			chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES;
BEGIN
	--we need to replace all instances of SPs that take lookup_keys as params with reference ids
	IF in_reference_ids IS NOT NULL AND in_reference_ids.COUNT > 0 AND in_reference_ids(1) IS NOT NULL THEN
		FOR i IN in_reference_ids.FIRST .. in_reference_ids.LAST 
		LOOP
			SELECT lookup_key
			  INTO v_lookup_keys(i)
			  FROM reference
			 WHERE reference_id = in_reference_ids(i);
		END LOOP;
	END IF;
	
	BEGIN
		chain.helper_pkg.LogonUCD;
	
		CreateCompanyNoLink(
			in_name 			=>	in_name,
			in_country_code		=>	in_country_code,
			in_company_type_id	=>	in_company_type_id,
			in_address_1 		=>	in_address_1,
			in_address_2 		=>	in_address_2,
			in_address_3 		=>	in_address_3,
			in_address_4 		=>	in_address_4,
			in_state 			=>	in_state,
			in_postcode 		=>	in_postcode,
			in_phone 			=>	in_phone,
			in_fax 				=>	in_fax,
			in_website			=>	in_website,
			in_email			=>	in_email,
			in_city 			=>	in_city,
			in_sector_id		=>	in_sector_id,
			in_lookup_keys		=>	v_lookup_keys,
			in_values			=>	in_values,
			in_is_pending		=>	1,
			out_company_sid		=>	out_company_sid
		);
		
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;
	
	-- crap hack for ODP.NET
	IF in_tag_ids IS NOT NULL AND in_tag_ids.COUNT > 0 AND in_tag_ids(1) IS NOT NULL THEN
		AddPendingTags(out_company_sid, in_tag_ids);
	END IF;
	
	UPDATE company
	   SET requested_by_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	   requested_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE company_sid = out_company_sid;
		
	out_matched_sids := FindExactMatches_UNSEC(
		in_company_name		=> in_name,
		in_country_code		=> in_country_code,
		in_company_type_id	=> in_company_type_id,
		in_city				=> in_city,	
		in_state			=> in_state,
		in_sector_id		=> in_sector_id,
		in_parent_sid		=> NULL,
		in_reference_ids	=> in_reference_ids,
		in_ref_values		=> in_values
	);	

	IF out_matched_sids IS NOT NULL AND out_matched_sids.COUNT > 0 THEN
		FOR i IN out_matched_sids.FIRST .. out_matched_sids.LAST LOOP
			INSERT INTO pend_company_suggested_match (pending_company_sid, matched_company_sid)
				VALUES(out_company_sid, out_matched_sids(i));
		END LOOP;
	ELSE 
		out_matched_sids := company_dedupe_pkg.FindAndStoreMatchesPendi_UNSEC(out_company_sid);
	END IF;
END;

PROCEDURE DedupeNewCompany_Unsec(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID,
	out_matched_sids		OUT security_pkg.T_SID_IDS,
	out_can_create_unique	OUT NUMBER
)
AS
	v_company_row 		 T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW();
	v_ref_vals			 security.T_VARCHAR2_TABLE DEFAULT security.T_VARCHAR2_TABLE(); /* ref id, ref value */
BEGIN
	out_can_create_unique := 1;
	
	out_matched_sids := FindExactMatches_UNSEC(
		in_company_name		=>	in_name,
		in_country_code		=>	in_country_code,
		in_company_type_id	=>	in_company_type_id,
		in_city				=>	in_city,	
		in_state			=>	in_state,
		in_sector_id		=>	in_sector_id,
		in_parent_sid		=>	NULL,
		in_reference_ids	=>  in_reference_ids,
		in_ref_values		=>  in_values
	);	
	
	IF out_matched_sids IS NOT NULL AND out_matched_sids.COUNT > 0 THEN
		out_can_create_unique := 0;
	ELSE 
		v_company_row.name 			:= in_name;
		v_company_row.company_type	:= in_company_type_id;
		v_company_row.address_1 	:= in_address_1;
		v_company_row.address_2 	:= in_address_2;
		v_company_row.address_3 	:= in_address_3;
		v_company_row.address_4 	:= in_address_4;
		v_company_row.country_code 	:= in_country_code;
		v_company_row.state 		:= in_state;
		v_company_row.postcode 		:= in_postcode;
		v_company_row.phone 		:= in_phone;
		v_company_row.city 			:= in_city;
		v_company_row.website 		:= in_website;
		v_company_row.fax 			:= in_fax;
		v_company_row.sector 		:= in_sector_id;
		v_company_row.email 		:= in_email;

		out_matched_sids := company_dedupe_pkg.FindMatchesForNewCompany_UNSEC(
			in_company_row 	=> v_company_row,
			in_tag_ids		=> in_tag_ids,
			in_ref_ids		=> in_reference_ids,
			in_ref_vals		=> in_values
		);
	END IF;

	IF out_matched_sids.COUNT = 0 THEN
		CreateNewCompany(
			in_name 			=>	in_name,
			in_country_code		=>	in_country_code,
			in_company_type_id	=>	in_company_type_id,
			in_address_1 		=>	in_address_1,
			in_address_2 		=>	in_address_2,
			in_address_3 		=>	in_address_3,
			in_address_4 		=>	in_address_4,
			in_state 			=>	in_state,
			in_postcode 		=>	in_postcode,
			in_phone 			=>	in_phone,
			in_fax 				=>	in_fax,
			in_website			=>	in_website,
			in_email			=>	in_email,
			in_city 			=>	in_city,
			in_sector_id		=>	in_sector_id,
			in_reference_ids	=>	in_reference_ids,
			in_values			=>	in_values,
			in_tag_ids			=>	in_tag_ids,
			out_company_sid		=>	out_company_sid
		);
		out_can_create_unique := 0;
	END IF;
END;

PROCEDURE RequestNewCompany(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID,
	out_pend_request_creatd OUT NUMBER,
	out_can_create_unique	OUT NUMBER,
	out_matched_sids		OUT	security_pkg.T_SID_IDS
)
AS
	v_matched_sids			security_pkg.T_SID_IDS;
	v_matched_sids_t		security.T_SID_TABLE;
	v_can_create_directly	BOOLEAN DEFAULT FALSE;
BEGIN
	IF NOT capability_pkg.CheckCapabilityBySupplierType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_company_type_id, chain_pkg.CREATE_COMPANY_WITHOUT_INVIT) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You don''t have permissions adding a company of company type with id:'||in_company_type_id);
	END IF;
	
	IF helper_pkg.IsTopCompany = 1	THEN
		v_can_create_directly := TRUE;
	END IF;
	
	IF v_can_create_directly THEN
		DedupeNewCompany_Unsec(
			in_name					=> in_name,
			in_country_code			=> in_country_code,
			in_company_type_id		=> in_company_type_id,
			in_address_1 			=> in_address_1,
			in_address_2 			=> in_address_2,
			in_address_3 			=> in_address_3,
			in_address_4 			=> in_address_4,
			in_state 				=> in_state,
			in_postcode 			=> in_postcode,
			in_phone 				=> in_phone,
			in_fax 					=> in_fax,
			in_website				=> in_website,
			in_email				=> in_email,
			in_city 				=> in_city,
			in_sector_id			=> in_sector_id,
			in_reference_ids		=> in_reference_ids,
			in_values				=> in_values,
			in_tag_ids				=> in_tag_ids,
			out_company_sid			=> out_company_sid,
			out_matched_sids		=> out_matched_sids,
			out_can_create_unique	=> out_can_create_unique
		);
		
		out_pend_request_creatd := 0;
	ELSE
		--request new company
		CreateCompanyRequest_UNSEC(
			in_name						=> in_name,
			in_country_code				=> in_country_code,
			in_company_type_id			=> in_company_type_id,
			in_address_1 				=> in_address_1,
			in_address_2 				=> in_address_2,
			in_address_3 				=> in_address_3,
			in_address_4 				=> in_address_4,
			in_state 					=> in_state,
			in_postcode 				=> in_postcode,
			in_phone 					=> in_phone,
			in_fax 						=> in_fax,
			in_website					=> in_website,
			in_email					=> in_email,
			in_city 					=> in_city,
			in_sector_id				=> in_sector_id,
			in_reference_ids			=> in_reference_ids,
			in_values					=> in_values,
			in_tag_ids					=> in_tag_ids,
			out_company_sid				=> out_company_sid,
			out_matched_sids			=> out_matched_sids
		);
		
		out_pend_request_creatd := 1;
		out_can_create_unique	:= NULL;
	END IF;
END;

PROCEDURE RequestNewCompany(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_matched_comp_cur	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_matched_sids			security_pkg.T_SID_IDS;
	v_can_create_unique		NUMBER;
	v_matched_sids_t		security.T_SID_TABLE;
	v_pend_request_creatd	NUMBER;
BEGIN
	RequestNewCompany(
		in_name					=> in_name,
		in_country_code			=> in_country_code,
		in_company_type_id		=> in_company_type_id,
		in_address_1 			=> in_address_1,
		in_address_2 			=> in_address_2,
		in_address_3 			=> in_address_3,
		in_address_4 			=> in_address_4,
		in_state 				=> in_state,
		in_postcode 			=> in_postcode,
		in_phone 				=> in_phone,
		in_fax 					=> in_fax,
		in_website				=> in_website,
		in_email				=> in_email,
		in_city 				=> in_city,
		in_sector_id			=> in_sector_id,
		in_reference_ids		=> in_reference_ids,
		in_values				=> in_values,
		in_tag_ids				=> in_tag_ids,
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	IF v_pend_request_creatd = 0 THEN
		OPEN out_company_cur FOR
			SELECT v_company_sid company_sid, v_can_create_unique can_create_unique, 0 pending_request_created
			  FROM dual;
		
		v_matched_sids_t := security_pkg.SidArrayToTable(v_matched_sids);
		
		OPEN out_matched_comp_cur FOR
			SELECT column_value company_sid
			  FROM TABLE(v_matched_sids_t);
	ELSE
		OPEN out_company_cur FOR
			 SELECT v_company_sid company_sid, NULL can_create_unique, 1 pending_request_created
			   FROM dual;
		
		--we don't return the matched sids when a pending company is created
		OPEN out_matched_comp_cur FOR
			 SELECT NULL company_sid
			   FROM dual
			  WHERE 1 = 0;
	END IF;
END;

PROCEDURE CreateCompany(
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_company_type_id		IN  company_type.company_type_id%TYPE DEFAULT NULL,
	in_sector_id			IN  company.sector_id%TYPE DEFAULT NULL,
	in_lookup_keys			IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_values				IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_city 				IN  company.city%TYPE DEFAULT NULL,
	in_state 				IN  company.state%TYPE DEFAULT NULL,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_has_references		BOOLEAN DEFAULT FALSE;
BEGIN
	CreateCompanyNoLink(
		in_name 			=>	in_name,
		in_country_code		=>	in_country_code,
		in_company_type_id	=>	NVL(in_company_type_id, company_type_pkg.GetDefaultCompanyType),
		in_sector_id		=>	in_sector_id,
		in_lookup_keys		=>	in_lookup_keys,
		in_values			=>	in_values,
		in_city				=>  in_city,
		in_state			=>  in_state,
		out_company_sid		=>	out_company_sid
	);

	-- callout to customised systems
	chain_link_pkg.AddCompany(out_company_sid);
END;

/* Just preserved for backwards compatibility as there are dependant services */
PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_company_type_id		IN  company_type.company_type_id%TYPE,
	in_sector_id			IN  company.sector_id%TYPE,
	in_lookup_keys			IN	chain_pkg.T_STRINGS, --reference labels
	in_values				IN	chain_pkg.T_STRINGS, --reference labels
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	CreateCompany(	
		in_name				=> in_name,
		in_country_code		=> in_country_code,
		in_company_type_id	=> in_company_type_id,
		in_sector_id		=> in_sector_id,
		in_lookup_keys		=> in_lookup_keys,
		in_values			=> in_values,
		out_company_sid		=> out_company_sid
	);
END;

/* Create a company as a sub-entity of another company (e.g. site or business unit) */
PROCEDURE CreateSubCompany(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_name						IN	company.name%TYPE,
	in_country_code				IN	company.name%TYPE,
	in_company_type_id			IN	company_type.company_type_id%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	in_lookup_keys				IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels,
	in_values					IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels,
	out_company_sid				OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID;
BEGIN
	-- No permissions. All create company calls are done as UCD. SecurableObject_Pkg.CreateSO does some checks

	BEGIN
		v_container_sid :=  securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_parent_sid, 'Subsidiaries');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_Pkg.CreateSO(security_pkg.GetAct, in_parent_sid, security_pkg.SO_CONTAINER, 'Subsidiaries', v_container_sid);
	END;

	CreateCompanyBase(
		in_name				=> in_name,	
		in_country_code		=> in_country_code,
		in_company_type_id	=> in_company_type_id,
		in_sector_id		=> in_sector_id,
		in_lookup_keys		=> in_lookup_keys,
		in_values			=> in_values,
		in_parent_sid		=> in_parent_sid,
		in_so_container_sid	=> v_container_sid,
		out_company_sid		=> out_company_sid
	);

	 UPDATE company
	    SET active = chain_pkg.ACTIVE,
	 		activated_dtm = SYSDATE
	  WHERE company_sid = out_company_sid;

	-- There is always a relationship between parent and child
	StartRelationship(
		in_purchaser_company_sid		=> in_parent_sid,
		in_supplier_company_sid			=> out_company_sid
	);

	ActivateRelationship(in_parent_sid, out_company_sid);

	UpdateCompanyReferences(out_company_sid, in_lookup_keys, in_values);

	--Add USER_GROUP as a member of company type specific group
	company_type_pkg.CompanyCreated(out_company_sid);

	-- callout to customised systems
	chain_link_pkg.AddCompany(out_company_sid);

	-- we've also established a relationship
	chain_link_pkg.EstablishRelationship(
		in_purchaser_sid		=> in_parent_sid,
		in_supplier_sid			=> out_company_sid
	);
END;

PROCEDURE DeleteCompanyFully(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	-- user groups undder the company
	v_admin_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_pending_grp_sid		security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_users_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
	v_other_company_grp_cnt	NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;

	UPDATE customer_options
	   SET top_company_sid = NULL
	 WHERE top_company_sid = in_company_sid;

	-- This gets ran twice, but ought to reduce the number of integrity constraint errors caused by deleting users that have components etc
	chain_link_pkg.DeleteCompany(in_company_sid);

	-- Now we need to delete all users from this company
	-- We cannot do this in DeleteSO for company as
	--		the users are NOT under the company in the tree - they are just members of groups under the company
	-- 		All the info we need to indentify which users to delete (group structure under company) is cleared by the security DeleteSO before the DeleteSO call is made above
	FOR r IN (
		SELECT DISTINCT user_sid
		  FROM v$company_member
		 WHERE company_sid = in_company_sid
		   AND app_sid = security_pkg.GetApp
	)
	LOOP
		-- TO DO - this is not a full implementation but is to get round a current issue and will work currently
		-- we may need to implement a chain user SO type to do properly
		-- but - to prevent non chain users getting trashed this relies on
		-- 		only chain users will be direct members unless we add people for no good reason via secmgr
		-- 		only users who have logged on to chain should be in chain user table  - though this could incluse superusers

		-- is this user in the groups of any other company
		SELECT COUNT(*)
		INTO v_other_company_grp_cnt
		FROM
		(
			-- this should just return chain company groups
			SELECT sid_id
			  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(security_pkg.GetAct, r.user_sid))
			 WHERE sid_id NOT IN (v_admin_grp_sid, v_pending_grp_sid, v_users_grp_sid)
			 AND parent_sid_id IN (SELECT company_sid FROM company WHERE app_sid = security_pkg.GetApp)
		);

		IF v_other_company_grp_cnt = 0 THEN
			-- this user is not a member of any other companies/groups so delete them
			chain.company_user_pkg.DeleteObject(security_pkg.GetAct, r.user_sid);
		END IF;
	END LOOP;

	-- finally delete the company
	securableobject_pkg.DeleteSO(security_pkg.GetAct, in_company_sid);
END;

PROCEDURE DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_key					supplier_relationship.virtually_active_key%TYPE;
	v_ucd_act				security_pkg.T_ACT_ID;
BEGIN
	IF
		NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE)
	AND NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_DELETE)
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;

	UNSEC_DeleteCompany(
		in_company_sid => in_company_sid
	);
END;

PROCEDURE UNSEC_DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_key					supplier_relationship.virtually_active_key%TYPE;
	v_ucd_act				security_pkg.T_ACT_ID;
BEGIN
	ActivateVirtualRelationship(in_company_sid, v_key);

	UPDATE company SET deleted = 0 WHERE company_sid = in_company_sid;

	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, NULL);

	UPDATE supplier_relationship SET deleted = chain_pkg.DELETED WHERE app_sid = security_pkg.GetApp AND supplier_company_sid = in_company_sid;

	-- Send deleted message to all purchasers
	-- TODO: Do we just want to send a message for companies that have an active relationship? This assumes not to pick up rejected invitations
	FOR p IN (
		SELECT *
		  FROM supplier_relationship
		 WHERE app_sid = security_pkg.GetApp
		   AND supplier_company_sid = in_company_sid
	) LOOP
		message_pkg.TriggerMessage (
			in_primary_lookup			=> chain_pkg.COMPANY_DELETED,
			in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
			in_to_company_sid			=> p.PURCHASER_COMPANY_SID,
			in_to_user_sid				=> chain_pkg.FOLLOWERS,
			in_re_company_sid			=> in_company_sid,
			in_system_wide				=> 1
		);
	END LOOP;

	DeactivateVirtualRelationship(v_key);

	v_ucd_act := csr.csr_user_pkg.LogonUserCreatorDaemon;
	-- trash any orphaned users
	FOR r IN (
		-- grab all of our company users
		SELECT user_sid FROM (
			SELECT cm.user_sid
			  FROM v$company_member cm, chain_user cu
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cm.company_sid = in_company_sid
			   AND cm.user_sid = cu.user_sid
			   AND cu.tmp_is_chain_user = chain_pkg.ACTIVE
			 UNION
			SELECT i.to_user_sid
			  FROM invitation i
			  JOIN chain_user cu ON i.to_user_sid = cu.user_sid
			 WHERE i.to_company_sid = in_company_sid
		) cm
		 WHERE NOT EXISTS(
				SELECT NULL
				  FROM v$company_user cmp
				 WHERE cmp.user_sid = cm.user_sid
				   AND cmp.company_sid <> in_company_sid
				)
		   AND NOT EXISTS(
				SELECT NULL
				  FROM v$company_pending_user cmp
				 WHERE cmp.user_sid = cm.user_sid
				   AND cmp.company_sid <> in_company_sid
				)
		   AND NOT EXISTS (
				SELECT NULL
				  FROM invitation i
				 WHERE i.to_user_sid = cm.user_sid
				   AND i.to_company_sid <> in_company_sid
				   AND i.invitation_status_id = chain_pkg.ACTIVE
			)
	)
	LOOP
		company_user_pkg.DeleteUser(v_ucd_act, r.user_sid);
	END LOOP;

	company_score_pkg.UNSEC_PropagateCompanyScores(in_company_sid);
	
	chain_link_pkg.VirtualDeleteCompany(in_company_sid);
END;

PROCEDURE UndeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_name					company.name%TYPE;
	v_parent_sid			security_pkg.T_SID_ID;
	v_cc					company.country_code%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Undelete access denied to company with sid '||in_company_sid);
	END IF;

	-- if you need to undelete orphaned users as well, you can check the COMPANY_DELETED message time vs. the csr audit log

	UPDATE company
	   SET deleted = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	RETURNING name, country_code, parent_sid
	  INTO v_name, v_cc, v_parent_sid;

	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, helper_pkg.GenerateSOName(in_company_name => v_name, in_company_sid => in_company_sid));
	
	company_score_pkg.UNSEC_RecalculateCompanyScores(in_company_sid);
END;

FUNCTION CheckPreserve_ (
	in_new_value			VARCHAR2,
	in_old_value			VARCHAR2
) RETURN VARCHAR2
AS
BEGIN
	IF in_new_value = chain_pkg.PRESERVE_STRING THEN
		RETURN in_old_value;
	END IF;
	RETURN in_new_value;
END;

FUNCTION CheckPreserve_ (
	in_new_value			NUMBER,
	in_old_value			NUMBER
) RETURN NUMBER
AS
BEGIN
	IF in_new_value = chain_pkg.PRESERVE_NUMBER THEN
		RETURN in_old_value;
	END IF;
	RETURN in_new_value;
END;

PROCEDURE UpdateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_name						IN  company.name%TYPE := chain_pkg.PRESERVE_STRING,
	in_country_code				IN  company.country_code%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_1				IN  company.address_1%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_2				IN  company.address_2%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_3				IN  company.address_3%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_4				IN  company.address_4%TYPE := chain_pkg.PRESERVE_STRING,
	in_city						IN  company.city%TYPE := chain_pkg.PRESERVE_STRING,
	in_state					IN  company.state%TYPE := chain_pkg.PRESERVE_STRING,
	in_postcode					IN  company.postcode%TYPE := chain_pkg.PRESERVE_STRING,
	in_latitude					IN  csr.region.geo_latitude%TYPE := chain_pkg.PRESERVE_NUMBER,
	in_longitude				IN  csr.region.geo_longitude%TYPE := chain_pkg.PRESERVE_NUMBER,
	in_phone					IN  company.phone%TYPE := chain_pkg.PRESERVE_STRING,
	in_fax						IN  company.fax%TYPE := chain_pkg.PRESERVE_STRING,
	in_website					IN  company.website%TYPE := chain_pkg.PRESERVE_STRING,
	in_email					IN  company.email%TYPE := chain_pkg.PRESERVE_STRING,
	in_sector_id				IN  company.sector_id%TYPE := chain_pkg.PRESERVE_NUMBER,
	in_lookup_keys				IN	chain_pkg.T_STRINGS := chain_pkg.NullStringArray,
	in_values					IN	chain_pkg.T_STRINGS := chain_pkg.NullStringArray,
	in_trigger_link				IN  NUMBER := 1
)
AS
	v_cur_details			company%ROWTYPE;
	v_new_name				company.name%TYPE;
	v_new_country_code		company.country_code%TYPE;
	v_new_city				company.city%TYPE;
	v_new_sector_id			company.sector_id%TYPE;
	v_new_state				company.state%TYPE;
	v_signature				company.signature%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;

	SELECT *
	  INTO v_cur_details
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	v_new_name := CheckPreserve_(in_name, v_cur_details.name);
	v_new_country_code := CheckPreserve_(in_country_code, v_cur_details.country_code);
	v_new_city := CheckPreserve_(in_city, v_cur_details.city);
	v_new_state := CheckPreserve_(in_state, v_cur_details.state);
	v_new_sector_id := CheckPreserve_(in_sector_id, v_cur_details.sector_id);

	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, helper_pkg.GenerateSOName(in_company_name => v_new_name,  in_company_sid => in_company_sid));

	v_signature := helper_pkg.GenerateCompanySignature(
		in_company_name			=> v_new_name,
		in_country				=> v_new_country_code,
		in_company_type_id		=> v_cur_details.company_type_id,
		in_city					=> v_new_city,	
		in_state				=> v_new_state,
		in_sector_id			=> v_new_sector_id,
		in_layout				=> company_type_pkg.GetDefaultRegionLayout(v_cur_details.company_type_id),
		in_parent_sid			=> v_cur_details.parent_sid
	);
	
	-- Update columns to the provided values so long as they're not the parameter default
	-- value (i.e. haven't been specified).
	UPDATE company
	   SET name = v_new_name,
		   country_code = v_new_country_code,
		   address_1 = CheckPreserve_(in_address_1, address_1),
		   address_2 = CheckPreserve_(in_address_2, address_2),
		   address_3 = CheckPreserve_(in_address_3, address_3),
		   address_4 = CheckPreserve_(in_address_4, address_4),
		   state = v_new_state,
		   city = v_new_city,
		   postcode = CheckPreserve_(in_postcode, postcode),
		   phone = CheckPreserve_(in_phone, phone),
		   fax = CheckPreserve_(in_fax, fax),
	 	   website = CheckPreserve_(in_website, website),
		   email = CheckPreserve_(in_email, email),
	 	   sector_id = v_new_sector_id,
		   signature = v_signature
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	--update references
	UpdateCompanyReferences(in_company_sid, in_lookup_keys, in_values);

	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
		dedupe_preprocess_pkg.PreprocessCompany(in_company_sid);
	END IF;

	IF in_trigger_link = 1 THEN
		chain_link_pkg.UpdateCompany(in_company_sid);
	END IF;

	-- update geolocation
	IF (in_latitude IS NULL OR in_latitude != chain_pkg.PRESERVE_NUMBER) AND (in_longitude IS NULL OR in_longitude != chain_pkg.PRESERVE_NUMBER) THEN
		csr.supplier_pkg.SetLatLong(in_company_sid, in_latitude, in_longitude);
	END IF;
END;

PROCEDURE UpdateCompanyParentSid (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_parent_sid				IN  security_pkg.T_SID_ID
)
AS
	v_cur_details			company%ROWTYPE;
	v_old_parent_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;

	SELECT parent_sid
	  INTO v_old_parent_sid
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF v_old_parent_sid = in_parent_sid OR (v_old_parent_sid = NULL AND in_parent_sid = NULL) THEN
		RETURN;
	END IF;

	UPDATE company
	   SET parent_sid = in_parent_sid,
	   signature = helper_pkg.GenerateCompanySignature(in_company_name => name, in_parent_sid => parent_sid)
	 WHERE company_sid = in_company_sid;

	chain_link_pkg.UpdateCompany(in_company_sid);
END;

PROCEDURE SetBusinessUnits (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_business_unit_ids		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_business_unit_ids		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_business_unit_ids);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid||' from company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	DELETE FROM business_unit_supplier
	 WHERE supplier_company_sid = in_company_sid
	   AND business_unit_id NOT IN (
			SELECT item FROM TABLE(v_business_unit_ids)
	);

	IF helper_pkg.NumericArrayEmpty(in_business_unit_ids) = 0 THEN
		FOR i IN in_business_unit_ids.FIRST .. in_business_unit_ids.LAST
		LOOP
			BEGIN
				INSERT INTO business_unit_supplier (business_unit_id, supplier_company_sid, is_primary_bu)
				VALUES (in_business_unit_ids(i), in_company_sid, 1);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					BEGIN
						INSERT INTO business_unit_supplier (business_unit_id, supplier_company_sid)
						VALUES (in_business_unit_ids(i), in_company_sid);
					EXCEPTION
						WHEN DUP_VAL_ON_INDEX THEN
							NULL;
					END;
			END;
		END LOOP;
	END IF;
END;

PROCEDURE SetTags (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_tag_ids					IN	security_pkg.T_SID_IDS,
	in_add_calc_jobs			IN	NUMBER DEFAULT 0
)
AS
	v_tag_ids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
	v_old_tag_ids				security.T_SID_TABLE := csr.supplier_pkg.GetTags(in_company_sid);
BEGIN
	csr.supplier_pkg.SetTags(in_company_sid, in_tag_ids);

	IF in_add_calc_jobs = 1 THEN
		FOR r IN (
		   SELECT column_value
			 FROM TABLE(v_tag_ids)
			WHERE column_value NOT IN (SELECT column_value FROM TABLE(v_old_tag_ids))
			UNION
		   SELECT column_value
			 FROM TABLE(v_old_tag_ids)
			WHERE column_value NOT IN (SELECT column_value FROM TABLE(v_tag_ids))
			) LOOP
			FOR x IN (
				SELECT DISTINCT calc_ind_sid
				  FROM csr.calc_tag_dependency
				 WHERE tag_id = r.column_value
				) LOOP
				csr.calc_pkg.AddJobsForCalc(x.calc_ind_sid);
			END LOOP;
		END LOOP;
	END IF;

	--we can use a link_pkg call to set company type groups based on tags
	chain_link_pkg.SetTags(in_company_sid);
END;

FUNCTION GetCompanySidByLayout (
	in_name					IN company.name%TYPE,	
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_city					IN company.city%TYPE DEFAULT NULL,
	in_swallow_not_found	IN NUMBER DEFAULT 0
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
	v_signature			company.signature%TYPE;
	v_company_type_id	company.company_type_id%TYPE := NVL(in_company_type_id, company_type_pkg.GetDefaultCompanyType);
BEGIN
	v_signature	 := helper_pkg.GenerateCompanySignature(
		in_company_name => in_name, 
		in_country => in_country_code, 
		in_company_type_id => v_company_type_id, 
		in_sector_id => in_sector_id,
		in_state => in_state, 
		in_city	=> in_city,
		in_layout => company_type_pkg.GetDefaultRegionLayout(v_company_type_id)
	);

	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM company
		 WHERE LOWER(signature) = LOWER(v_signature)
		   AND pending = 0
		   AND deleted = 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_swallow_not_found = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company with signature '|| v_signature || ' was not found');
			END IF;
			v_company_sid := -1;
	END;

	RETURN v_company_sid;
END;

PROCEDURE GetPendingCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR,
	out_refs					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy_cur					security_pkg.T_OUTPUT_CUR;
BEGIN
	IF NOT dedupe_admin_pkg.HasProcessedRecordAccess THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to pending company with sid '||in_company_sid);
	END IF;
	
	UNSEC_GetCompanyCore(in_company_sid, out_cur);

	OPEN out_tags FOR
		SELECT pct.pending_company_sid company_sid, pct.tag_id, tgm.tag_group_id, t.tag, tgm.Pos
		  FROM pending_company_tag pct
		  JOIN csr.tag_group_member tgm ON tgm.tag_id = pct.tag_id
		  JOIN csr.v$tag t ON t.tag_id = tgm.tag_id
		 WHERE pct.app_sid = security_pkg.GetApp
		   AND pct.pending_company_sid = in_company_sid;
	
	UNSEC_GetCompanyRefs(in_company_sid, out_refs);
END;

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_refs				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetCompany(
		in_company_sid		=> GetCompany(), 
		out_cur 			=> out_cur, 
		out_bu_cur			=> out_bu_cur, 
		out_tags			=> out_tags, 
		out_refs			=> out_refs 
	);
END;

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_refs				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCompanyAccess(in_company_sid);

	UNSEC_GetCompanyCore(in_company_sid, out_cur);
	UNSEC_GetCompanyBU(in_company_sid, out_bu_cur);
	
	IF capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ) THEN
		UNSEC_GetCompanyTags(in_company_sid, out_tags);
	ELSE
		OPEN out_tags FOR
			SELECT NULL dummy FROM dual WHERE 1 = 2;
	END IF;

	UNSEC_GetCompanyRefs(in_company_sid, out_refs);
END;

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_refs				OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_items			OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_trans			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_members		OUT	security_pkg.T_OUTPUT_CUR,
	out_alt_comp_names		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetCompany(
		in_company_sid		=> GetCompany(), 
		out_cur 			=> out_cur, 
		out_bu_cur			=> out_bu_cur, 
		out_tags			=> out_tags, 
		out_refs			=> out_refs, 
		out_flow_items		=> out_flow_items, 
		out_flow_trans		=> out_flow_trans, 
		out_role_members	=> out_role_members, 
		out_alt_comp_names	=> out_alt_comp_names
	);
END;

PROCEDURE UNSEC_GetCompanyCore(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_view_crl	NUMBER;
BEGIN
	
	capability_pkg.CheckCapability(chain_pkg.VIEW_COUNTRY_RISK_LEVELS, v_view_crl);
	
	OPEN out_cur FOR
		SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.state, c.city, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id, c.pending,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid, pct.code_label1,
		   pct.code_label2, NVL(pct.code2_mandatory, 0) code2_mandatory,
		   pct.code_label3, NVL(pct.code3_mandatory, 0) code3_mandatory,
		   r.geo_longitude longitude, r.geo_latitude latitude,
		  	CASE WHEN v_view_crl = 1 THEN crl.label ELSE null END country_risk_level
		  FROM company c
		  LEFT JOIN postcode.country cou ON c.country_code = cou.country
		  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
		  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
		  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
		  LEFT JOIN postcode.country pcou ON p.country_code = pcou.country
		  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
		  LEFT JOIN product_code_type pct ON c.app_sid = pct.app_sid AND c.company_sid = pct.company_sid
		  LEFT JOIN csr.region r ON cs.app_sid = r.app_sid AND cs.region_sid = r.region_sid
		  LEFT JOIN v$current_country_risk_level crl ON c.country_code = crl.country
		 WHERE c.company_sid = in_company_sid
		   AND c.deleted = 0;
END;

PROCEDURE UNSEC_GetCompanyBU(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bu.business_unit_id, bu.description, bus.is_primary_bu
		  FROM business_unit bu
		  JOIN business_unit_supplier bus ON bu.business_unit_id = bus.business_unit_id AND bu.app_sid = bus.app_sid
		 WHERE bus.supplier_company_sid = in_company_sid;
END;

PROCEDURE UNSEC_GetCompanyTags(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	csr.supplier_pkg.GetTags(in_company_sid, out_cur);
END;

PROCEDURE UNSEC_GetCompanyRefs(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cr.lookup_key, cr.value, cr.company_sid, cr.reference_id, cr.label
			FROM v$company_reference cr
			WHERE app_sid = security_pkg.GetApp
			AND cr.company_sid = in_company_sid;
END;

PROCEDURE UNSEC_GetCompanyFlowItems(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT fi.flow_sid, fi.flow_label, fi.flow_item_id,
			   fi.current_state_id, fi.current_state_label, fi.current_state_lookup_key
		  FROM v$supplier_relationship sr
		  JOIN csr.v$flow_item fi ON fi.flow_item_id = sr.flow_item_id
		 WHERE sr.supplier_company_sid = in_company_sid
		   AND (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			    OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE UNSEC_GetCompanyFlowTrans(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT fit.flow_sid, fit.flow_item_id, fit.flow_state_transition_id,
			   fit.verb, fit.to_state_id, fit.to_state_label, fit.to_state_colour,
			   fit.transition_pos, fit.ask_for_comment, fit.button_icon_path
		  FROM v$supplier_relationship sr
			   JOIN csr.v$flow_item_transition fit ON fit.flow_item_id = sr.flow_item_id
			   JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
			   LEFT JOIN csr.flow_state_transition_inv fsti
					  ON fsti.flow_state_transition_id = fit.flow_state_transition_id
			   LEFT JOIN csr.flow_state_transition_role fstr
					  ON fit.flow_state_transition_id = fstr.flow_state_transition_id
			   LEFT JOIN csr.region_role_member rrm
					  ON rrm.region_sid = s.region_sid
					 AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 AND rrm.role_sid = fstr.role_sid
			   LEFT JOIN v$purchaser_involvement inv
			          ON inv.flow_involvement_type_id = fsti.flow_involvement_type_id
			         AND inv.supplier_company_sid = sr.supplier_company_sid
		 WHERE sr.supplier_company_sid = in_company_sid
		   AND (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			    OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND (inv.flow_involvement_type_id IS NOT NULL
			 OR (fsti.flow_involvement_type_id = csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER
			  AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
			 OR rrm.role_sid IS NOT NULL);
END;

PROCEDURE UNSEC_GetCompanyRoleMembers(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT u.csr_user_sid user_sid, u.email user_email, u.full_name user_full_name, u.phone_number user_phone_number,
			   r.role_sid, r.name role_name
		  FROM company c
		  JOIN csr.supplier s ON s.company_sid = c.company_sid AND s.app_sid = c.app_sid
		  JOIN company_type_role ctr ON ctr.company_type_id = c.company_type_id AND ctr.app_sid = c.app_sid
		  JOIN csr.role r ON r.role_sid = ctr.role_sid AND r.app_sid = ctr.app_sid
		  JOIN csr.region_role_member rrm ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		                                 AND rrm.region_sid = s.region_sid AND rrm.app_sid = s.app_sid
		  JOIN csr.v$csr_user u ON u.csr_user_sid = rrm.user_sid AND u.app_sid = rrm.app_sid
		 WHERE c.company_sid = in_company_sid
		   AND u.active = 1
		 ORDER BY ctr.pos, r.name;

END;

PROCEDURE UNSEC_GetCompanyAltNames(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT alt_company_name_id, company_sid, name
		  FROM alt_company_name
		 WHERE company_sid = in_company_sid;
END;

PROCEDURE CheckCompanyAccess(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_count					INTEGER;
BEGIN
	--TODO: Why does it imply read? Doesn't this violate the whole purpose of the SC permissions model?
	IF IsPurchaser(in_company_sid) THEN 
		-- default allow this to happen as this only implies read,and we
		-- don't really need a purchasers capability for anything other than this
		NULL;
	ELSE
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
		END IF;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid
	   AND deleted = 1;

	IF v_count = 1 THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_COMPANY_IS_DELETED, 'Company with company_sid: '||in_company_sid||' has been deleted.');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid
	   AND pending = 1;
	
	IF v_count = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company with company_sid: '||in_company_sid||' is pending.');
	END IF;
END;

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_refs				OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_items			OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_trans			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_members		OUT	security_pkg.T_OUTPUT_CUR,
	out_alt_comp_names		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCompanyAccess(in_company_sid);

	UNSEC_GetCompanyCore(in_company_sid, out_cur);
	UNSEC_GetCompanyBU(in_company_sid, out_bu_cur);
	
	IF capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ) THEN
		UNSEC_GetCompanyTags(in_company_sid, out_tags);
	ELSE
		OPEN out_tags FOR
			SELECT NULL dummy FROM dual WHERE 1 = 2;
	END IF;

	UNSEC_GetCompanyRefs(in_company_sid, out_refs);
	UNSEC_GetCompanyFlowItems(in_company_sid, out_flow_items);
	UNSEC_GetCompanyFlowTrans(in_company_sid, out_flow_trans);
	UNSEC_GetCompanyRoleMembers(in_company_sid, out_role_members);
	UNSEC_GetCompanyAltNames(in_company_sid, out_alt_comp_names);
END;

PROCEDURE GetCompanyUserLevelMessaging (
	out_user_level_messaging	OUT company.user_level_messaging%TYPE
)
AS
BEGIN
	SELECT c.user_level_messaging
	  INTO out_user_level_messaging
	  FROM company c
	 WHERE c.app_sid = security_pkg.GetApp
	   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE TransitionCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_to_state_id			IN	csr.flow_state.flow_state_id%TYPE,
	in_comment_text			IN	csr.flow_state_log.comment_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_cnt					NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM v$supplier_relationship sr
	 WHERE sr.supplier_company_sid = in_company_sid
	   AND (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND sr.flow_item_id = in_flow_item_id;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Mismatched company_sid and flow_item_id');
	END IF;

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM v$supplier_relationship sr
	   JOIN csr.v$flow_item_transition fit ON fit.flow_item_id = sr.flow_item_id
	   JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
	   LEFT JOIN csr.flow_state_transition_inv fsti
			  ON fsti.flow_state_transition_id = fit.flow_state_transition_id
	   LEFT JOIN csr.flow_state_transition_role fstr
			  ON fit.flow_state_transition_id = fstr.flow_state_transition_id
	   LEFT JOIN csr.region_role_member rrm
			  ON rrm.region_sid = s.region_sid
			 AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			 AND rrm.role_sid = fstr.role_sid
	   LEFT JOIN v$purchaser_involvement inv
			  ON inv.flow_involvement_type_id = fsti.flow_involvement_type_id
			 AND inv.supplier_company_sid = sr.supplier_company_sid
	 WHERE sr.supplier_company_sid = in_company_sid
	   AND fit.to_state_id = in_to_state_id
	   AND fit.flow_item_id = in_flow_item_id
	   AND (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND (inv.flow_involvement_type_id IS NOT NULL
		 OR (fsti.flow_involvement_type_id = csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER
			  AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		 OR rrm.role_sid IS NOT NULL);

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid to_state_id');
	END IF;

	csr.flow_pkg.SetItemState(
		in_flow_item_id => in_flow_item_id,
		in_to_state_id => in_to_state_id,
		in_comment_text => in_comment_text,
		in_cache_keys => in_cache_keys
	);
END;

FUNCTION GetCompanyName
RETURN company.name%TYPE
AS
BEGIN
	RETURN GetCompanyName(NULL);
END;

FUNCTION GetCompanyName (
	in_company_sid 			IN security_pkg.T_SID_ID
) RETURN company.name%TYPE
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_n			company.name%TYPE;
BEGIN
	IF v_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') OR capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ) OR CanSeeCompanyAsChainTrnsprnt(v_company_sid) THEN
		SELECT name
		  INTO v_n
		  FROM v$company
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = v_company_sid;
	ELSE
		BEGIN
			SELECT c.name
			  INTO v_n
			  FROM v$company c, v$company_relationship cr
			 WHERE c.app_sid = security_pkg.GetApp
			   AND c.app_sid = cr.app_sid
			   AND c.company_sid = v_company_sid
			   AND c.company_sid = cr.company_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_n := ' ';
		END;
	END IF;

	RETURN v_n;
END;

PROCEDURE CanSeeAllCompanies (
	out_can_see					OUT	company.can_see_all_companies%TYPE
)
AS
BEGIN
	BEGIN
		SELECT can_see_all_companies
		  INTO out_can_see
		  FROM company
		 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE SearchCompanies (
	in_search_term  		IN  VARCHAR2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanies(0, 0, in_search_term, v_count_cur, out_result_cur);
END;

PROCEDURE SearchCompanies (
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE;
	v_can_see_all_companies	company.can_see_all_companies%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	-- bulk collect company sid's that match our search result
	--todo: replace v_can_see_all_companies with NO_RELATIONSHIP_CAPABILITY
	--'OR ..' inside the JOIN statement caused performance issues
	--we replaced it with a left join
	--v$company_relationship excludes SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	IF v_can_see_all_companies = 1 THEN
		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT DISTINCT c.company_sid
			  FROM company c
			  LEFT JOIN chain.v$company_relationship cr ON (c.app_sid = cr.app_sid AND c.company_sid = cr.company_sid)
				--OR (v_can_see_all_companies=1 AND c.company_sid != SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
			  LEFT JOIN chain.supplier_relationship sr ON c.company_sid = sr.supplier_company_sid
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (LOWER(name) LIKE v_search
				OR	(SELECT COUNT(*)
					   FROM chain.company_reference compref
					  WHERE compref.app_sid = c.app_sid
						AND compref.company_sid = c.company_sid
						AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
				OR LOWER(sr.supp_rel_code) = LOWER(TRIM(in_search_term)))
			   AND c.company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND c.deleted = 0
			   AND c.pending = 0
		  );
	ELSE
		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT DISTINCT c.company_sid
			  FROM v$company c
			  JOIN v$company_relationship cr ON (c.app_sid = cr.app_sid AND c.company_sid = cr.company_sid)
			  LEFT JOIN supplier_relationship sr ON c.company_sid = sr.supplier_company_sid
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (LOWER(name) LIKE v_search
				OR	(SELECT COUNT(*)
					   FROM company_reference compref
					  WHERE compref.app_sid = c.app_sid
						AND compref.company_sid = c.company_sid
						AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
				-- OR LOWER(reference_id_1) = LOWER(TRIM(in_search_term))
				-- OR LOWER(reference_id_2) = LOWER(TRIM(in_search_term))
				-- OR LOWER(reference_id_3) = LOWER(TRIM(in_search_term))
				OR LOWER(sr.supp_rel_code) = LOWER(TRIM(in_search_term)))
		  );
	END IF;

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchTeamroomCompanies(
	in_search_term	IN	VARCHAR2,
	out_cur			OUT Security_Pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT c.company_sid, c.name
		  FROM (
			SELECT top_company_sid company_sid
			  FROM customer_options
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION
			SELECT CAST (SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AS NUMBER(10, 0)) company_sid
			  FROM dual
				UNION
			SELECT supplier_company_sid company_sid
			  FROM supplier_relationship
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  ) x
		  JOIN company c ON c.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND x.company_sid = c.company_sid
		  LEFT JOIN supplier_relationship sr ON c.app_sid = sr.app_sid AND c.company_sid = sr.supplier_company_sid
		 WHERE (in_search_term IS NULL OR LOWER(c.name) LIKE v_search)
		    OR 	(SELECT COUNT(*)
				   FROM company_reference compref
				  WHERE compref.app_sid = c.app_sid
					AND compref.company_sid = c.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
			OR LOWER(sr.supp_rel_code) = LOWER(TRIM(in_search_term))
         ORDER BY c.name;
END;

PROCEDURE CollectScores(
	in_results_table			IN	T_FILTERED_OBJECT_TABLE,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_score_perm_sids			security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
BEGIN
	OPEN out_score_cur FOR
		SELECT s.company_sid, s.score, s.score_type_id, s.score_threshold_id, s.format_mask, s.valid_until_dtm, s.valid
		  FROM csr.v$supplier_score s
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_results_table)) f ON s.company_sid = f.object_id
		  JOIN TABLE(v_score_perm_sids) cts ON s.company_sid = cts.column_value;
END;

PROCEDURE SearchSuppliers (
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_only_active					IN  NUMBER,
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	SearchSuppliers(
		in_company_sid			=>	SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_page					=>	in_page,
		in_page_size			=>	in_page_size,
		in_search_term			=>	in_search_term,
		in_only_active			=>	in_only_active,
		in_wanted_supplier_cts	=>	in_wanted_supplier_cts,
		out_count_cur			=>	out_count_cur,
		out_result_cur			=>	out_result_cur
	);
END;

PROCEDURE SearchSuppliers (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_only_active					IN  NUMBER, /*include active relationships */
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	in_search_for_pending			IN  NUMBER, /*include pending relationships */
	in_search_for_unrelated			IN  NUMBER, /*include no relationships when NO_RELATIONSHIP_CAPABILITY is on */
	in_search_for_tags				IN  NUMBER, /*enable search with tag ids */
	in_tag_ids						IN security_pkg.T_SID_IDS,
	in_unsec_for_not_related_sid	IN NUMBER, /* Search for suppliers of a not related (and not context) in_company_sid */
	in_only_active_companies		IN NUMBER := chain_pkg.INACTIVE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search						VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results						security.T_SID_TABLE := security.T_SID_TABLE();
	v_results_with_tags				security.T_SID_TABLE := security.T_SID_TABLE();
	v_possible_supplier_cts 		security.T_SID_TABLE := security.T_SID_TABLE();
	v_tag_ids				 		security.T_SID_TABLE;
	v_wanted_supplier_cts			T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_wanted_supplier_cts);
	v_can_see_all_companies			company.can_see_all_companies%TYPE;
	v_table 						T_PERMISSIBLE_TYPES_TABLE;
	v_no_relationship_ct_table 		T_PERMISSIBLE_TYPES_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanyTypes(in_company_sid, chain_pkg.SUPPLIER_NO_RELATIONSHIP, security_pkg.PERMISSION_READ);
	v_check_suppliers_cap			BOOLEAN DEFAULT FALSE;
	v_check_on_bhf_cap				BOOLEAN DEFAULT FALSE;
BEGIN
	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND company_sid = in_company_sid;

	--steps:
	--get permissible company types first
	--get companies joined by perm cts
	--filter with permissible sids
	IF helper_pkg.UseTraditionalCapabilities THEN
		IF capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
			SELECT company_type_id
			  BULK COLLECT INTO v_possible_supplier_cts
			  FROM company_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
	ELSE
		IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
			v_check_suppliers_cap := TRUE;
			v_table := type_capability_pkg.GetPermissibleCompanyTypes(in_company_sid, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);

			SELECT secondary_company_type_id --CHAIN_COMPANY's possible supplier company type
			  BULK COLLECT INTO v_possible_supplier_cts
			  FROM TABLE(v_table);
		ELSIF in_unsec_for_not_related_sid = 1 AND IsMember(in_company_sid, SYS_CONTEXT('SECURITY', 'SID')) THEN
			--Case: User searches for suppliers of a company that is neither the context company nor a related to the context but he is a member of
			--GetPermissibleCompanyTypes always take into account the context company for the primary company type, therefore it will return empty
			SELECT secondary_company_type_id
			  BULK COLLECT INTO v_possible_supplier_cts
			  FROM company_type_relationship ctr
			 WHERE primary_company_type_id = company_type_pkg.GetCompanyTypeId(in_company_sid);
		ELSE
			v_check_on_bhf_cap := TRUE;
			-- we can also do this if we have permission to invite certain company types on behalf of another company type
			v_table := type_capability_pkg.GetPermissibleCompanyTypes(in_company_sid, T_STRING_LIST(chain_pkg.QNR_INVITE_ON_BEHALF_OF, chain_pkg.QNR_INV_ON_BEHLF_TO_EXIST_COMP, chain_pkg.VIEW_RELATIONSHIPS));

			--if we searched for 'on behalf of - tertiary' permissible company types then we should collect tertiary instead of secondary
			SELECT tertiary_company_type_id --secondary company's possible supplier company type
			  BULK COLLECT INTO v_possible_supplier_cts
			  FROM TABLE(v_table);
		END IF;
	END IF;

	IF v_possible_supplier_cts.COUNT = 0 THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages FROM DUAL;

		OPEN out_result_cur FOR
			SELECT * FROM DUAL WHERE 0 = 1;

		RETURN;
	END IF;

	-- bulk collect company sid's that match our search result
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND v_can_see_all_companies = 1 THEN --v_can_see_all_companies could be replaced by SUPPLIER_NO_RELATIONSHIP capability
		-- not on_behalf_of and can see all companies - ignore supplier_relationship
		SELECT DISTINCT c.company_sid
		  BULK COLLECT INTO v_results
		  FROM company c
		  JOIN TABLE(v_possible_supplier_cts) psct ON c.company_type_id = psct.column_value
		  JOIN TABLE(v_wanted_supplier_cts) wsct ON c.company_type_id = wsct.item
		  LEFT JOIN supplier_relationship sr ON c.company_sid = sr.supplier_company_sid
		   AND c.app_sid = sr.app_sid
		   AND sr.deleted <> chain_pkg.DELETED
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.company_sid != in_company_sid
		   AND (LOWER(c.name) LIKE v_search
			OR LOWER(sr.supp_rel_code) = LOWER(TRIM(in_search_term))
			OR	(SELECT COUNT(*)
				   FROM company_reference compref
				  WHERE compref.app_sid = c.app_sid
					AND compref.company_sid = c.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0)
		   AND (--here the filters check the company status instead of the relationship
				   (in_only_active = chain_pkg.ACTIVE AND c.active = chain_pkg.ACTIVE)
				OR (in_search_for_pending = chain_pkg.ACTIVE AND c.active = chain_pkg.INACTIVE)
			)
		   AND c.deleted <> chain_pkg.DELETED
		   AND c.pending = 0;
	ELSE
		SELECT DISTINCT c.company_sid
		  BULK COLLECT INTO v_results
		  FROM company c
		  JOIN TABLE(v_possible_supplier_cts) psct ON c.company_type_id = psct.column_value
		  JOIN TABLE(v_wanted_supplier_cts) wsct ON c.company_type_id = wsct.item
		  JOIN supplier_relationship sr ON c.company_sid = sr.supplier_company_sid
		   AND c.app_sid = sr.app_sid
		   AND sr.purchaser_company_sid = in_company_sid
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (LOWER(c.name) LIKE v_search
			OR LOWER(sr.supp_rel_code) = LOWER(TRIM(in_search_term))
			OR	(SELECT COUNT(*)
				   FROM company_reference compref
				  WHERE compref.app_sid = c.app_sid
					AND compref.company_sid = c.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
			)
		   AND (--relationship filters
				   (in_only_active = chain_pkg.ACTIVE AND sr.active = chain_pkg.ACTIVE)
				OR (in_search_for_pending = chain_pkg.ACTIVE AND sr.active = chain_pkg.INACTIVE)
			)
		   AND ((in_only_active_companies = chain_pkg.ACTIVE and c.active = chain_pkg.ACTIVE ) or (in_only_active_companies = chain_pkg.INACTIVE ))
		   AND sr.deleted <> chain_pkg.DELETED
		   AND c.deleted <> chain_pkg.DELETED;
	END IF;

	/* add unrelated companies*/
	IF in_search_for_unrelated = 1 AND v_can_see_all_companies = 0 THEN
		/* no need to check SUPPLIER_NO_RELATIONSHIP capability, joining with permissible company types is enough */
		FOR r in (
		SELECT DISTINCT c.company_sid
			FROM company c
			JOIN TABLE(v_no_relationship_ct_table) psct ON c.company_type_id = psct.secondary_company_type_id --not supported for tertiary
			JOIN TABLE(v_wanted_supplier_cts) wsct ON c.company_type_id = wsct.item
			WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND c.deleted <> chain_pkg.DELETED
			AND c.pending = 0
			AND (LOWER(c.name) LIKE v_search
				OR	(
					SELECT COUNT(*)
						FROM company_reference compref
						WHERE compref.app_sid = c.app_sid
						AND compref.company_sid = c.company_sid
						AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))
					) > 0
				)--we dont want the related!
				AND NOT EXISTS (
				SELECT 1
					FROM chain.supplier_relationship sr
					WHERE sr.purchaser_company_sid = in_company_sid
					AND sr.supplier_company_sid = c.company_sid
					AND sr.deleted <> chain_pkg.DELETED
			)
			AND (--here the filters check the company status so we don't get unrelated but inactive companies
				   (in_only_active = chain_pkg.ACTIVE AND c.active = chain_pkg.ACTIVE)
				OR (in_search_for_pending = chain_pkg.ACTIVE AND c.active = chain_pkg.INACTIVE)
			)
		)
		LOOP
			v_results.EXTEND;
			v_results(v_results.COUNT) := r.company_sid;
		END LOOP;
	END IF;

	IF in_search_for_tags = 1 THEN
		v_tag_ids := security_pkg.SidArrayToTable(in_tag_ids);

		SELECT DISTINCT t.column_value
		  BULK COLLECT INTO v_results_with_tags
		  FROM TABLE(v_results) t
		  JOIN csr.supplier s ON t.column_value = s.company_sid
		  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid
		  JOIN TABLE(v_tag_ids) tt ON rt.tag_id = tt.column_value;

		  v_results := v_results_with_tags;

	END IF;

	IF v_check_suppliers_cap THEN
		v_results := type_capability_pkg.FilterPermissibleSidsByFlow(v_results, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);
	END IF;

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchSuppliers (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_only_active					IN  NUMBER, /*include active relationships */
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	in_search_for_pending			IN  NUMBER, /*include pending relationships */
	in_search_for_unrelated			IN  NUMBER, /*include no relationships */
	in_search_for_tags				IN  NUMBER, /*enable search with tag ids */
	in_tag_ids						IN security_pkg.T_SID_IDS,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	SearchSuppliers(
		in_company_sid		 	=> in_company_sid,
	    in_page   				=> in_page,
	    in_page_size    		=> in_page_size,
	    in_search_term  		=> in_search_term,
	    in_only_active			=> in_only_active,
	    in_wanted_supplier_cts	=> in_wanted_supplier_cts,
		in_search_for_pending	=> in_search_for_pending,
		in_search_for_unrelated	=> in_search_for_unrelated,
		in_search_for_tags		=> in_search_for_tags,
		in_tag_ids				=> in_tag_ids,
		in_unsec_for_not_related_sid	=> 0,
	    out_count_cur			=> out_count_cur,
		out_result_cur		    => out_result_cur
	);
END;

PROCEDURE SearchSuppliers (
	in_company_sid					IN security_pkg.T_SID_ID,
	in_page   						IN  number,
	in_page_size    				IN  number,
	in_search_term  				IN  varchar2,
	in_only_active					IN  number, /*include active relationships */
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	in_search_for_pending			IN  NUMBER, /*include pending relationships */
	in_search_for_unrelated			IN  NUMBER, /*include no relationships */
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tag_ids	security_pkg.T_SID_IDS;
BEGIN
	SearchSuppliers(
		in_company_sid		 	=> in_company_sid,
	    in_page   				=> in_page,
	    in_page_size    		=> in_page_size,
	    in_search_term  		=> in_search_term,
	    in_only_active			=> in_only_active,
	    in_wanted_supplier_cts	=> in_wanted_supplier_cts,
		in_search_for_pending	=> in_search_for_pending,
		in_search_for_unrelated	=> in_search_for_unrelated,
		in_search_for_tags		=> 0,
		in_tag_ids				=> v_tag_ids,
		in_unsec_for_not_related_sid	=> 0,
	    out_count_cur			=> out_count_cur,
		out_result_cur		    => out_result_cur
	);
END;

PROCEDURE SearchSuppliers (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_only_active					IN  NUMBER,
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tag_ids	security_pkg.T_SID_IDS;
BEGIN
	SearchSuppliers(
		in_company_sid		 	=> in_company_sid,
	    in_page   				=> in_page,
	    in_page_size    		=> in_page_size,
	    in_search_term  		=> in_search_term,
	    in_only_active			=> in_only_active,
	    in_wanted_supplier_cts	=> in_wanted_supplier_cts,
		in_search_for_pending	=> 0,
		in_search_for_unrelated	=> 0,
		in_search_for_tags		=> 0,
		in_tag_ids				=> v_tag_ids,
		in_unsec_for_not_related_sid	=> 0,
	    out_count_cur			=> out_count_cur,
		out_result_cur		    => out_result_cur
	);
END;

/* Get existing, active companies by permissible company type*/
FUNCTION GetExistingCompaniesByPermCT(
	in_search_term 			IN  VARCHAR2,
	in_exclude_sids			IN	security_pkg.T_SID_IDS,
	in_capability			chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE
AS
	v_exclude_sid_table		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_exclude_sids);
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
	v_permissible_table		chain.T_PERMISSIBLE_TYPES_TABLE; --permissible company type for in_capability
	v_company_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	v_permissible_table := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, in_capability);

	SELECT company_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT DISTINCT c.company_sid
		  FROM company c
		  JOIN TABLE(v_permissible_table) pt ON (c.company_type_id = pt.secondary_company_type_id)
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (LOWER(c.name) LIKE v_search
			OR	(SELECT COUNT(*)
				   FROM company_reference compref
				  WHERE compref.app_sid = c.app_sid
					AND compref.company_sid = c.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
			)
		   AND c.active = chain_pkg.ACTIVE
		   AND NOT EXISTS(
			SELECT 1
			  FROM TABLE(v_exclude_sid_table) excl
			 WHERE c.company_sid = excl.column_value
		   )
	);

	v_results := type_capability_pkg.FilterPermissibleSidsByFlow(v_results, in_capability);

	RETURN v_results;
END;

/* Get potential suppliers for requesting their questionnaire (existing or related based on the potential capability)*/
PROCEDURE SearchCompaniesForReqQnrFrom(
	in_search_term 			IN  VARCHAR2,
	in_company_sid			IN	security_pkg.T_SID_ID, --TODO: is there a case this isn't the context company?
	in_exclude_sids			IN	security_pkg.T_SID_IDS,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_chain_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_req_from_all_existing_compan  BOOLEAN:= FALSE;
	v_req_from_establ_relationship  BOOLEAN:= FALSE;
	v_tmp_companies_results			security.T_SID_TABLE := security.T_SID_TABLE();
	v_results						security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	v_req_from_all_existing_compan := type_capability_pkg.CheckPotentialCapability(chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB);
	v_req_from_establ_relationship := type_capability_pkg.CheckPotentialCapability(chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS);

	--Should not be both enabled
	IF v_req_from_all_existing_compan = TRUE AND v_req_from_establ_relationship = TRUE THEN
		RAISE_APPLICATION_ERROR(-20001, 'Capabilities REQ_QNR_FROM_EXIST_COMP_IN_DB and REQ_QNR_FROM_ESTABL_RELATIONS should not be both enabled for company with sid: "' || v_chain_company_sid || '"');
	END IF;

	IF v_req_from_all_existing_compan = FALSE AND v_req_from_establ_relationship = FALSE THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied requesting company questionnaire');
	END IF;

	IF v_req_from_all_existing_compan = TRUE THEN
		v_tmp_companies_results := GetExistingCompaniesByPermCT(in_search_term, in_exclude_sids, chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB);

		--get existing companies minus established relationships
		SELECT cr.column_value
		  BULK COLLECT INTO v_results
		  FROM TABLE (v_tmp_companies_results) cr
		 WHERE NOT EXISTS(
			 SELECT sr.supplier_company_sid company_sid
			   FROM supplier_relationship sr
			  WHERE sr.purchaser_company_sid = in_company_sid
				AND sr.supplier_company_sid = cr.column_value
				AND sr.deleted <> chain_pkg.DELETED
		 );
	ELSE
		v_tmp_companies_results := GetExistingCompaniesByPermCT(in_search_term, in_exclude_sids, chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS);

		--get only established relationships excluding already sent invitations
		SELECT sr.supplier_company_sid
		  BULK COLLECT INTO v_results
		  FROM supplier_relationship sr
		  JOIN TABLE (v_tmp_companies_results) cr ON sr.supplier_company_sid = cr.column_value
		 WHERE sr.purchaser_company_sid = in_company_sid
		   AND sr.deleted <> chain_pkg.DELETED
		   AND NOT EXISTS(
				SELECT 1
				  FROM invitation
				 WHERE from_company_sid = in_company_sid
				   AND to_company_sid = cr.column_value
				   AND invitation_status_id IN (chain_pkg.ACCEPTED, chain_pkg.ACTIVE)
		   );

	END IF;

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

/* Get potential suppliers, purchasers to build relationship with, based on the ADD_REMOVE_RELATIONSHIPS capability*/
PROCEDURE SearchCompaniesToRelateWith(
	in_search_term 			IN  VARCHAR2,
	in_company_sid			IN	security_pkg.T_SID_ID, --the supplier/purchaser company sid
	in_company_function		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
	v_chain_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_permissible_table		T_PERMISSIBLE_TYPES_TABLE; --permissible company type for ADD_REMOVE_RELATIONSHIPS
	v_company_type_id		company_type.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_company_sid);
BEGIN
 	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') OR NOT type_capability_pkg.IsCompanyPermissibleByFlow(in_company_sid, chain_pkg.ADD_REMOVE_RELATIONSHIPS) THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages
			  FROM dual;

		OPEN out_result_cur FOR
			SELECT *
			  FROM dual
			 WHERE 0 = 1;

		RETURN;
	END IF;

	--check whether in_company_sid satisfies the flow permissions as a secondary company with the context company as primary

	v_permissible_table := type_capability_pkg.GetPermissibleCompanyTypes(v_chain_company_sid, chain_pkg.ADD_REMOVE_RELATIONSHIPS);

	-- eg: Get assessors MINUS existing not deleted relationships for the supplier
	SELECT company_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT DISTINCT c.company_sid
		  FROM company c
		  JOIN (
				SELECT primary_company_type_id, secondary_company_type_id, tertiary_company_type_id
				  FROM TABLE(v_permissible_table)
				 WHERE in_company_function = chain_pkg.SUPPLIER
				 UNION 	--here is the trick where we invert tertiary and secondary_company_type_id, so we can search both for potential suppliers and purchasers
				SELECT primary_company_type_id, tertiary_company_type_id secondary_company_type_id, secondary_company_type_id tertiary_company_type_id
				  FROM TABLE(v_permissible_table)
				 WHERE in_company_function = chain_pkg.PROCURER
			) pt ON (c.company_type_id = pt.secondary_company_type_id AND v_company_type_id = pt.tertiary_company_type_id)
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (LOWER(c.name) LIKE v_search
			OR	(SELECT COUNT(*)
				   FROM company_reference compref
				  WHERE compref.app_sid = c.app_sid
					AND compref.company_sid = c.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
			)
		   AND c.active = chain_pkg.ACTIVE
		   AND c.company_sid != in_company_sid
		--exclude already existing relationship with in_company as a supplier or a purchaser
		 MINUS	(
		SELECT sr.purchaser_company_sid company_sid
		  FROM supplier_relationship sr
		 WHERE in_company_function = chain_pkg.SUPPLIER
		   AND sr.supplier_company_sid = in_company_sid
		   AND sr.deleted <> chain_pkg.DELETED
		 UNION
		 SELECT sr.supplier_company_sid company_sid
		  FROM supplier_relationship sr
		 WHERE in_company_function = chain_pkg.PROCURER
		   AND sr.purchaser_company_sid = in_company_sid
		   AND sr.deleted <> chain_pkg.DELETED
		 )
	);

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchPotentialSuppliers(
	in_search_term 			IN  VARCHAR2,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_company_type_id		IN	company_type.company_type_id%TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
	v_chain_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_permissible_table		T_PERMISSIBLE_TYPES_TABLE;
	v_company_type_id		company_type.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_company_sid);
	v_count					NUMBER;
BEGIN
	IF in_company_sid = v_chain_company_sid THEN
		--No need to check against flow permissions as there is no supplier relationship yet
		v_permissible_table := type_capability_pkg.GetPermissibleCompanyTypes(v_chain_company_sid, chain_pkg.CREATE_RELATIONSHIP);

		SELECT count(*)
		  INTO v_count
		  FROM TABLE(v_permissible_table) pt
		 WHERE pt.secondary_company_type_id = in_company_type_id;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company type with id '||in_company_type_id||' is not permissible for company with sid '||in_company_sid);
		END IF;

		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT DISTINCT c.company_sid
			  FROM company c
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (LOWER(c.name) LIKE v_search
				OR	(SELECT COUNT(*)
					   FROM company_reference compref
					  WHERE compref.app_sid = c.app_sid
						AND compref.company_sid = c.company_sid
						AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
				)
			   AND c.active = chain_pkg.ACTIVE
			   AND c.company_sid != in_company_sid
			   AND c.company_type_id = in_company_type_id
			--exclude already existing relationship with in_company as a supplier or a purchaser
			 MINUS	(
			SELECT sr.purchaser_company_sid company_sid
			  FROM supplier_relationship sr
			 WHERE sr.supplier_company_sid = in_company_sid
			   AND sr.deleted <> chain_pkg.DELETED
			 UNION
			 SELECT sr.supplier_company_sid company_sid
			  FROM supplier_relationship sr
			 WHERE sr.purchaser_company_sid = in_company_sid
			   AND sr.deleted <> chain_pkg.DELETED
			 )
		);

 	ELSE
		v_permissible_table := type_capability_pkg.GetPermissibleCompanyTypes(v_chain_company_sid, chain_pkg.ADD_REMOVE_RELATIONSHIPS);

		SELECT count(*)
		  INTO v_count
		  FROM TABLE(v_permissible_table) pt
		 WHERE pt.secondary_company_type_id = v_company_type_id
		   AND pt.tertiary_company_type_id = in_company_type_id;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company type with id '||in_company_type_id||' is not permissible for company with sid '||in_company_sid);
		END IF;

		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT DISTINCT c.company_sid
			  FROM company c
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (LOWER(c.name) LIKE v_search
				OR	(SELECT COUNT(*)
					   FROM company_reference compref
					  WHERE compref.app_sid = c.app_sid
						AND compref.company_sid = c.company_sid
						AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
				)
			   AND c.active = chain_pkg.ACTIVE
			   AND c.company_sid != in_company_sid
			   AND c.company_type_id = in_company_type_id
			--exclude already existing relationship with in_company as a supplier or a purchaser
			 MINUS	(
			SELECT sr.purchaser_company_sid company_sid
			  FROM supplier_relationship sr
			 WHERE sr.supplier_company_sid = in_company_sid
			   AND sr.deleted <> chain_pkg.DELETED
			 UNION
			 SELECT sr.supplier_company_sid company_sid
			  FROM supplier_relationship sr
			 WHERE sr.purchaser_company_sid = in_company_sid
			   AND sr.deleted <> chain_pkg.DELETED
			 )
		);
		v_results := type_capability_pkg.FilterPermissibleSidsByFlow(v_results, chain_pkg.ADD_REMOVE_RELATIONSHIPS);
	END IF;

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchSubsidiaries(
	in_company_sid					IN	security_pkg.T_SID_ID,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy						security_pkg.T_OUTPUT_CUR;
	v_results					security.T_SID_TABLE := security.T_SID_TABLE();
	v_view_table				T_PERMISSIBLE_TYPES_TABLE; --permissible company types for VIEW_SUBSIDIARIES_OBO
	v_can_bypass_relationship	company.can_see_all_companies%TYPE;
BEGIN
	-- no permission checks, this method only returns subsidiaries you have permissions to see

	IF in_company_sid = GetCompany THEN
		-- we can see all of our own subsidiaries
		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM company
		 WHERE parent_sid = GetCompany;
	ELSE
		-- if we're not logged in as that company then we need a tertiary capability on the company types
		-- that we can see

		SELECT NVL(MIN(can_see_all_companies), 0)
		  INTO v_can_bypass_relationship
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = GetCompany;

		IF v_can_bypass_relationship = 0 AND type_capability_pkg.CheckNoRelationshipPermission(GetCompany, in_company_sid, security_pkg.PERMISSION_READ) THEN
			v_can_bypass_relationship := 1;
		END IF;

		v_view_table := type_capability_pkg.GetPermissibleCompanyTypes(in_company_sid, chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);

		-- get all subsidiaries for the company types we have capabilities on where we have a relationship
		-- with the parent company (GetPermissibleCompanyTypes returns all company types for the logged
		-- on company, but doesn't check if we have a relationship with in_company_sid, or the type of in_company_sid)
		SELECT c.company_sid
		  BULK COLLECT INTO v_results
		  FROM company c
		  JOIN company pc ON c.parent_sid = pc.company_sid AND c.app_sid = pc.app_sid
		  JOIN TABLE(v_view_table) ct ON c.company_type_id = ct.tertiary_company_type_id AND pc.company_type_id = ct.secondary_company_type_id
		  LEFT JOIN supplier_relationship sr ON c.parent_sid = sr.supplier_company_sid AND c.app_sid = sr.app_sid AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		 WHERE c.parent_sid = in_company_sid
		   AND (sr.purchaser_company_sid IS NOT NULL OR v_can_bypass_relationship > 0);

		v_results := type_capability_pkg.FilterPermissibleSidsByFlow(v_results, chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);
	END IF;

	CollectSearchResults(v_results, 0, 0, v_dummy, out_result_cur);
END;

PROCEDURE SearchPurchasingSuppliers(
	in_search_term 					IN  VARCHAR2,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results						security.T_SID_TABLE := security.T_SID_TABLE();
	v_relationships					T_COMPANY_REL_SIDS_TABLE := GetVisibleRelationships;
BEGIN
	-- only return suppliers that are also purchasers
	SELECT DISTINCT s.company_sid
	  BULK COLLECT INTO v_results
	  FROM v$company s
	  JOIN TABLE(v_relationships) r ON s.company_sid = r.primary_company_sid
	  JOIN company_type_relationship ctr ON s.company_type_id = ctr.primary_company_type_id  -- limit to company types that are purchasers
	 WHERE ctr.hidden = 0
	   AND ((in_search_term IS NULL OR LOWER(s.name) LIKE '%'||LOWER(TRIM(in_search_term)) || '%')
		    OR 	(SELECT COUNT(*)
				   FROM company_reference compref
				  WHERE compref.app_sid = s.app_sid
					AND compref.company_sid = s.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0);

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

/* Search all company relationships (suppliers + buyers). in_company_function specified the role of in_company_sid
in the relationship. If in_company_function is null, relationships in both directions are returned. */
FUNCTION GetCompanyRelationships(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_company_function				IN  chain_pkg.T_COMPANY_FUNCTION
) RETURN CHAIN.T_COMPANY_RELATIONSHIP_TABLE
AS
	v_table							T_COMPANY_RELATIONSHIP_TABLE := T_COMPANY_RELATIONSHIP_TABLE();
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_relationships					T_COMPANY_REL_SIDS_TABLE := GetVisibleRelationships(in_include_inactive_rels => 1, in_include_hidden_rels => 1);
	v_create_rels_caps				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.CREATE_RELATIONSHIP);
	v_add_remove_rels_caps			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.ADD_REMOVE_RELATIONSHIPS);
	v_set_primary_rel_caps			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.SET_PRIMARY_PRCHSR);
	v_has_read_perms				NUMBER(1);
BEGIN
	IF in_company_function IS NULL OR in_company_function = chain_pkg.SUPPLIER THEN
		FOR r IN (
			SELECT pc.company_sid, pc.name, pct.singular company_type_description, pcnt.name country_name, 
				   sr.active active_relationship, sr.is_primary, chain_pkg.SUPPLIER relationship_role,
				   CASE WHEN crc.primary_company_type_id IS NULL AND arrc.primary_company_type_id IS NULL THEN 0 ELSE 1 END editable_relationship, 
				   CASE WHEN sprc.primary_company_type_id IS NULL THEN 0 ELSE ctr.can_be_primary END can_be_primary
			  FROM TABLE(v_relationships) rel
			  JOIN supplier_relationship sr ON sr.purchaser_company_sid = rel.primary_company_sid AND sr.supplier_company_sid = rel.secondary_company_sid
			  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
			  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
			  JOIN company_type_relationship ctr ON ctr.primary_company_type_id = pc.company_type_id AND ctr.secondary_company_type_id = sc.company_type_id
			  LEFT JOIN TABLE(v_create_rels_caps) crc ON crc.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
			  LEFT JOIN TABLE(v_add_remove_rels_caps) arrc ON arrc.secondary_company_type_id = pc.company_type_id AND arrc.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
			  LEFT JOIN TABLE(v_set_primary_rel_caps) sprc ON sprc.secondary_company_type_id = pc.company_type_id AND sprc.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
			  JOIN company_type pct ON pct.company_type_id = pc.company_type_id
			  LEFT JOIN v$country pcnt ON pcnt.country_code = pc.country_code
			 WHERE sr.supplier_company_sid = in_company_sid
			   AND pc.pending = 0
			   AND sc.pending = 0
		)
		LOOP
			v_has_read_perms := 0;
			IF capability_pkg.CheckCapability(r.company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ) THEN
				v_has_read_perms := 1;
			END IF;
			v_table.extend;
			v_table(v_table.COUNT) := T_COMPANY_RELATIONSHIP_ROW(r.company_sid, r.name, r.country_name, r.active_relationship, r.editable_relationship, r.company_type_description, r.relationship_role, v_has_read_perms, r.is_primary, r.can_be_primary);
		END LOOP;
	END IF;

	IF in_company_function IS NULL OR in_company_function = chain_pkg.PROCURER THEN
		FOR r IN (
			SELECT sc.company_sid, sc.name, sct.singular company_type_description, scnt.name country_name, 
				   sr.active active_relationship, sr.is_primary, chain_pkg.PROCURER relationship_role,
				   CASE WHEN crc.primary_company_type_id IS NULL AND arrc.primary_company_type_id IS NULL THEN 0 ELSE 1 END editable_relationship, 
				   CASE WHEN sprc.primary_company_type_id IS NULL THEN 0 ELSE ctr.can_be_primary END can_be_primary
				FROM TABLE(v_relationships) rel
			  JOIN supplier_relationship sr ON sr.purchaser_company_sid = rel.primary_company_sid AND sr.supplier_company_sid = rel.secondary_company_sid
			  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
			  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
			  JOIN company_type_relationship ctr ON ctr.primary_company_type_id = pc.company_type_id AND ctr.secondary_company_type_id = sc.company_type_id
			  LEFT JOIN TABLE(v_create_rels_caps) crc ON crc.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
			  LEFT JOIN TABLE(v_add_remove_rels_caps) arrc ON arrc.secondary_company_type_id = pc.company_type_id AND arrc.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
			  LEFT JOIN TABLE(v_set_primary_rel_caps) sprc ON sprc.secondary_company_type_id = pc.company_type_id AND sprc.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
			  JOIN company_type sct ON sct.company_type_id = sc.company_type_id
			  LEFT JOIN v$country scnt ON scnt.country_code = sc.country_code
			 WHERE sr.purchaser_company_sid = in_company_sid
			   AND pc.pending = 0
			   AND sc.pending = 0
		)
		LOOP
			v_has_read_perms := 0;
			IF capability_pkg.CheckCapability(r.company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
				v_has_read_perms := 1;
			END IF;
			v_table.extend;
			v_table(v_table.COUNT) := T_COMPANY_RELATIONSHIP_ROW(r.company_sid, r.name, r.country_name, r.active_relationship, r.editable_relationship, r.company_type_description, r.relationship_role, v_has_read_perms, r.is_primary, r.can_be_primary);
		END LOOP;
	END IF;

	RETURN v_table;
END;

/* Can't use CollectSearchResults as it is now*/
PROCEDURE SearchCompanyRelationships(
	in_search_term		IN  VARCHAR2,
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_company_function	IN  chain_pkg.T_COMPANY_FUNCTION,
	in_page   			IN  NUMBER,
	in_page_size    	IN  NUMBER,
	out_count_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_scores_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search			 	VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_table  			 	CHAIN.T_COMPANY_RELATIONSHIP_TABLE := GetCompanyRelationships(in_company_sid, in_company_function);
	v_table_after_search 	CHAIN.T_COMPANY_RELATIONSHIP_TABLE := CHAIN.T_COMPANY_RELATIONSHIP_TABLE();
	v_count				 	NUMBER;
	v_score_perm_sids_table	security.T_SID_TABLE;
	v_sids_after_search		security.T_SID_TABLE;
BEGIN
	--filter by v_search,
	FOR r IN (
		SELECT *
	      FROM TABLE(v_table) t
	     WHERE lower(t.name) LIKE v_search
	)
	LOOP
		v_table_after_search.extend;
		v_table_after_search(v_table_after_search.COUNT) := CHAIN.T_COMPANY_RELATIONSHIP_ROW(r.company_sid, r.name, r.country_name, r.active_relationship, r.editable_relationship, r.company_type_description, r.relationship_role, r.has_read_perms_on_company, r.is_primary, r.can_be_primary);
	END LOOP;

	--page it
	OPEN out_result_cur FOR
		SELECT c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm, c.address_1,
		   c.address_2, c.address_3, c.address_4, c.state, c.city, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid,
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required,
		   c.user_level_messaging, c.sector_id,
		   c.country_name, c.sector_description, c.can_see_all_companies, c.company_type_id,
		   c.company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, c.parent_name, c.parent_country_code, c.parent_country_name,
		   c.country_is_hidden, c.region_sid,
		   t.active_relationship, t.editable_relationship, t.company_type_description, t.relationship_role, 
		   t.has_read_perms_on_company, t.is_primary is_primary_relationship, t.can_be_primary can_be_primary_relationship
		  FROM (
			SELECT t.*, ROWNUM r
			  FROM (
				SELECT *
				  FROM TABLE(v_table_after_search) t
				 ORDER BY LOWER(t.name), t.company_sid
			  ) t
			) t
		  JOIN v$company c ON c.company_sid = t.company_sid
		  WHERE r >= (in_page - 1) * in_page_size + 1
		    AND r < in_page * in_page_size + 1
		 ORDER BY t.relationship_role, c.company_type_id, c.name;

	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages
		  FROM TABLE(v_table_after_search);
		  
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ) OR 
		(in_company_function = chain_pkg.SUPPLIER AND (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') OR NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ))) THEN
		
		OPEN out_scores_cur FOR
			SELECT NULL
			  FROM dual
			 WHERE 1 = 0;
		
		RETURN;
	END IF;

	IF in_company_function = chain_pkg.PROCURER THEN
		SELECT company_sid
		  BULK COLLECT INTO v_sids_after_search
		  FROM TABLE(v_table_after_search);
		
		-- consider WF chain capabilities for the supplier set
		v_score_perm_sids_table := type_capability_pkg.FilterPermissibleCompanySids(v_sids_after_search, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
		
		OPEN out_scores_cur FOR
			SELECT srs.purchaser_company_sid, srs.supplier_company_sid company_sid, srs.score_threshold_id, srs.set_dtm, srs.valid_until_dtm,
				   srs.score, st.score_type_id, sth.description, sth.text_colour, sth.background_colour, st.format_mask, 
				   st.allow_manual_set, st.label score_type_label
			  FROM csr.score_type st
			  JOIN v$current_sup_rel_score srs
				ON st.score_type_id = srs.score_type_id AND srs.purchaser_company_sid = in_company_sid
			  JOIN TABLE(v_score_perm_sids_table) t ON t.column_value = srs.supplier_company_sid
			  JOIN csr.score_threshold sth ON sth.score_threshold_id = srs.score_threshold_id
			 WHERE st.hidden = 0
			   AND st.applies_to_supp_rels = 1
			 ORDER BY st.pos, st.score_type_id;
	ELSE 
		OPEN out_scores_cur FOR
			SELECT srs.purchaser_company_sid, srs.supplier_company_sid company_sid, srs.score_threshold_id, srs.set_dtm, srs.valid_until_dtm,
				   srs.score, st.score_type_id, sth.description, sth.text_colour, sth.background_colour, st.format_mask, 
				   st.allow_manual_set, st.label score_type_label
			  FROM csr.score_type st
			  JOIN v$current_sup_rel_score srs
				ON st.score_type_id = srs.score_type_id AND srs.supplier_company_sid = in_company_sid
			  JOIN TABLE(v_table_after_search) t ON t.company_sid = srs.purchaser_company_sid
			  JOIN csr.score_threshold sth ON sth.score_threshold_id = srs.score_threshold_id
			 WHERE st.hidden = 0
			   AND st.applies_to_supp_rels = 1
			 ORDER BY st.pos, st.score_type_id;
	END IF;
END;

PROCEDURE SearchFollowingSuppliers (
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_primary_only			IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	IF in_user_sid <> SYS_CONTEXT('SECURITY', 'SID') THEN
		IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		END IF;
	END IF;

	SELECT company_sid
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM supplier_follower sf, v$company c, v$supplier_relationship sr
		 WHERE sf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND sf.app_sid = c.app_sid
		   AND sf.app_sid = sr.app_sid
		   AND sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sf.purchaser_company_sid = sr.purchaser_company_sid
		   AND sf.supplier_company_sid = c.company_sid
		   AND sf.supplier_company_sid = sr.supplier_company_sid
		   AND sf.user_sid = in_user_sid
		   AND c.active = chain_pkg.ACTIVE
		   AND (sf.is_primary = 1 OR in_primary_only = 0)
		   AND ((LOWER(c.name) LIKE v_search) OR (LOWER(sr.supp_rel_code) = LOWER(TRIM(in_search_term))))
	  );

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE GetFollowingSupplierSids (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_primary_only				IN  BOOLEAN,
	out_company_sids			OUT security.T_SID_TABLE
)
AS
	v_primary_only				NUMBER(1) DEFAULT CASE WHEN in_primary_only THEN 1 ELSE 0 END;
BEGIN
	IF in_user_sid <> SYS_CONTEXT('SECURITY', 'SID') THEN
		IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		END IF;
	END IF;

	SELECT sf.supplier_company_sid
	  BULK COLLECT INTO out_company_sids
	  FROM supplier_follower sf, v$company c
	 WHERE sf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sf.app_sid = c.app_sid
	   AND sf.supplier_company_sid = c.company_sid
	   AND sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sf.user_sid = in_user_sid
	   AND (v_primary_only = 0 OR sf.is_primary = 1);
END;

FUNCTION GetCompanySidBySupRelCode (
	in_supplier_code		IN  supplier_relationship.supp_rel_code%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_supplier_sid				security_pkg.T_SID_ID;
BEGIN
	-- no sec check here as we're just trying to establish (effectively) if the company exists and if you have a relationship with them.
	-- We only return a sid. We need to be able to do this even if the relationship is not active.

	BEGIN
		SELECT company_sid
		  INTO v_supplier_sid
		  FROM chain.v$company c
		  JOIN chain.supplier_relationship sr ON c.company_sid = sr.supplier_company_sid
		 WHERE c.app_sid = security_pkg.GetApp
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.deleted <> chain_pkg.DELETED
		   AND LOWER(sr.supp_rel_code) = LOWER(TRIM(in_supplier_code));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_supplier_sid := -1;
	END;

	RETURN v_supplier_sid;
END;

PROCEDURE GetPurchaserNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.purchaser_company_sid
		   AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
END;

PROCEDURE SearchMyCompanies (
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	IF helper_pkg.IsChainAdmin THEN
		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM (
				SELECT company_sid
				  FROM v$company
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND active = chain_pkg.ACTIVE
				   AND LOWER(name) LIKE v_search
				);
	ELSE
		-- bulk collect company sid's that match our search result
		SELECT company_sid
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT c.company_sid
			  FROM v$company_member cm, v$company c
			 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cm.app_sid = c.app_sid
			   AND cm.company_sid = c.company_sid
			   AND cm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND c.active = chain_pkg.ACTIVE
			   AND LOWER(c.name) LIKE v_search
		  );
	END IF;

	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

FUNCTION CompanyTypeRelationshipExists(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_purchaser_company_type_id company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_purchaser_company_sid);
	v_supplier_company_type_id  company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
	v_ct_relationship_count     NUMBER(1);
BEGIN
	SELECT count(*)
	  INTO v_ct_relationship_count
	  FROM chain.company_type_relationship
	 WHERE primary_company_type_id = v_purchaser_company_type_id
	   AND secondary_company_type_id = v_supplier_company_type_id;

	RETURN v_ct_relationship_count > 0;
END;

FUNCTION GetAllDescConnectedRels(
	in_company_sid				IN security.security_pkg.T_SID_ID
) RETURN chain.T_COMPANY_REL_SIDS_TABLE
AS
	v_relationships				T_COMPANY_REL_SIDS_TABLE;
BEGIN
	
	SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(purchaser_company_sid, supplier_company_sid, active)
	  BULK COLLECT INTO v_relationships
	  FROM (
		SELECT sr.purchaser_company_sid, sr.supplier_company_sid, sr.active
		  FROM supplier_relationship sr
		  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
		 WHERE sr.deleted = 0
		   AND pc.deleted = 0
		   AND sc.deleted = 0
		)
   CONNECT BY purchaser_company_sid = PRIOR supplier_company_sid
	 START WITH purchaser_company_sid = in_company_sid;
	
	RETURN v_relationships;
END;

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE DEFAULT NULL,
	in_source_type				IN	chain_pkg.T_RELATIONSHIP_SOURCE DEFAULT chain_pkg.AUTO_REL_SRC,
	in_object_id				IN	supplier_relationship_source.object_id%TYPE DEFAULT NULL
)
AS
	v_prevent_loops				NUMBER(1);
	v_relationships				T_COMPANY_REL_SIDS_TABLE;
	v_rel_count					NUMBER;
	v_purchaser_company_name	company.name%TYPE;
	v_supplier_company_name		company.name%TYPE;
BEGIN
	-- no security because I'm not really sure what to check
	-- seems pointless checking read / write access on either company or a capability
		
	IF in_purchaser_company_sid = in_supplier_company_sid THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_RELATIONSHIP_LOOP, 'No relationship was created as purchaser and supplier company is the same ('||in_purchaser_company_sid||')');
	END IF;

	--we cannot check the capabilities of the purchaser against the supplier when chain_company <> in_purchaser_company_sid (eg: SECR starts a relationship ASSESSOR => MINE)
	--we should check at least if there is a company_type_relationship between purchaser's and supplier's company type
	IF NOT CompanyTypeRelationshipExists(in_purchaser_company_sid, in_supplier_company_sid) THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_COMPANY_TYPE_RELATION_NA, 'There is no company type relationship for purchaser with sid "' || in_purchaser_company_sid || '" and supplier with sid "' || in_supplier_company_sid || '"');
	END IF;

	SELECT prevent_relationship_loops
	  INTO v_prevent_loops
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_prevent_loops = 1 THEN
		v_relationships := GetAllDescConnectedRels(in_supplier_company_sid);

		SELECT COUNT(*)
		  INTO v_rel_count
		  FROM TABLE(v_relationships)
		 WHERE secondary_company_sid = in_purchaser_company_sid;
		
		IF v_rel_count > 0 THEN
			v_purchaser_company_name := GetCompanyName(in_purchaser_company_sid);
			v_supplier_company_name := GetCompanyName(in_supplier_company_sid);

			RAISE_APPLICATION_ERROR(chain_pkg.ERR_RELATIONSHIP_LOOP, 'No relationship was created between purchaser company ('||v_purchaser_company_name||') and supplier ('||v_supplier_company_name||'), because circular relationships are not allowed.');
		END IF;
	END IF;

	BEGIN
		INSERT INTO supplier_relationship
		(purchaser_company_sid, supplier_company_sid, supp_rel_code)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_supp_rel_code);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE supplier_relationship
			   SET deleted = chain_pkg.NOT_DELETED, active = chain_pkg.PENDING, supp_rel_code = NVL(in_supp_rel_code, supp_rel_code)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND deleted = chain_pkg.DELETED
			   AND purchaser_company_sid = in_purchaser_company_sid
			   AND supplier_company_sid = in_supplier_company_sid;
	END;
	
	BEGIN
		INSERT INTO supplier_relationship_source (purchaser_company_sid, supplier_company_sid, source_type, object_id)
		VALUES (in_purchaser_company_sid, in_supplier_company_sid, in_source_type, in_object_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE DeleteSupplierRelationshipSrc(
	in_object_id				IN supplier_relationship_source.object_id%TYPE,
	in_source_type				IN chain_pkg.T_RELATIONSHIP_SOURCE
)
AS
	v_cnt						NUMBER;
BEGIN
	FOR r IN (
		SELECT purchaser_company_sid, supplier_company_sid, ROWID row_id
		  FROM supplier_relationship_source
		 WHERE source_type = in_source_type
		   AND object_id = in_object_id
	) LOOP
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM supplier_relationship_source
		 WHERE purchaser_company_sid = r.purchaser_company_sid
		   AND supplier_company_sid = r.supplier_company_sid
		   AND (source_type != in_source_type OR object_id IS NULL OR object_id != in_object_id);

		DELETE FROM supplier_relationship_source
		 WHERE ROWID = r.row_id;

		IF v_cnt = 0 THEN
			TerminateRelationship(
				in_purchaser_company_sid	=> r.purchaser_company_sid,
				in_supplier_company_sid		=> r.supplier_company_sid,
				in_force					=> TRUE
			);
		END IF;
	END LOOP;
END;

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
	v_act				security_pkg.T_ACT_ID;
BEGIN
	-- no security because I'm not really sure what to check
	-- seems pointless checking read / write access on either company or a capability

	UPDATE supplier_relationship
	   SET active = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	--Sync company type roles
	BEGIN
		chain.helper_pkg.LogonUCD;
		v_act := security_pkg.getact;

		FOR r IN (
			SELECT ctr.role_sid, ss.region_sid supplier_region_sid, ps.region_sid purchaser_region_sid, pcu.user_sid
			  FROM company_type_role ctr
			  JOIN company pc ON ctr.company_type_id = pc.company_type_id
			  JOIN v$company_user pcu ON pc.company_sid = pcu.company_sid
			  JOIN csr.supplier ps ON pc.company_sid = ps.company_sid
			  JOIN csr.supplier ss ON ss.company_sid = in_supplier_company_sid
			  JOIN csr.region_role_member rrm
				ON ps.region_sid = rrm.region_sid
			   AND pcu.user_sid = rrm.user_sid
			   AND ctr.role_sid = rrm.role_sid
			 WHERE ctr.cascade_to_supplier = 1
			   AND pc.company_sid = in_purchaser_company_sid
			   AND rrm.inherited_from_sid = rrm.region_sid
		) LOOP
				csr.role_pkg.AddRoleMemberForRegion(
					in_act_id		=> v_act,
					in_role_sid		=> r.role_sid,
					in_region_sid	=> r.supplier_region_sid,
					in_user_sid 	=> r.user_sid,
					in_log			=> 0,
					in_force_alter_system_managed => 1,
					in_inherited_from_sid => r.purchaser_region_sid
				);
		END LOOP;
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;

			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;

	purchased_component_pkg.RelationshipActivated(in_purchaser_company_sid, in_supplier_company_sid);
	supplier_flow_pkg.RelationshipActivated(in_purchaser_company_sid, in_supplier_company_sid);
	company_score_pkg.UNSEC_PropagateCompanyScores(in_supplier_company_sid);

	chain_link_pkg.ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE RelationshipActionMessage_(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_relationship_action		IN  chain_pkg.T_RELATIONSHIP_ACTION
)
AS
	v_primary_lookup_BETWEEN	chain_pkg.T_MESSAGE_DEFINITION_LOOKUP;
	v_primary_lookup			chain_pkg.T_MESSAGE_DEFINITION_LOOKUP;
BEGIN
	CASE WHEN in_relationship_action = chain_pkg.RELATIONSHIP_ACTION_ADDED THEN
		v_primary_lookup_BETWEEN := chain_pkg.RELATIONSHIP_ACTIVATED_BETWEEN;
		v_primary_lookup		 := chain_pkg.RELATIONSHIP_ACTIVATED;
	ELSE
		v_primary_lookup_BETWEEN := chain_pkg.RELATIONSHIP_DELETED_BETWEEN;
		v_primary_lookup		 := chain_pkg.RELATIONSHIP_DELETED;
	END CASE;

	--send a msg to CHAIN_COMPANY that the relationship between in_purchaser_company_sid and in_supplier_company_sid has been added/deleted
	message_pkg.TriggerMessage (
		in_primary_lookup	  	 	=> v_primary_lookup_BETWEEN,
		in_to_company_sid	  	 	=> helper_pkg.GetTopCompanySid,
		in_re_company_sid	  	 	=> in_purchaser_company_sid,
		in_system_wide				=> chain_pkg.ACTIVE,
		in_re_secondary_company_sid	=> in_supplier_company_sid
	);

	--send a msg to purchaser that a relationship with in_supplier_company_sid has been added/deleted
	message_pkg.TriggerMessage (
		in_primary_lookup	  	 	=> v_primary_lookup,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid	  	 	=> in_purchaser_company_sid,
		in_re_company_sid	  	 	=> in_supplier_company_sid,
		in_system_wide				=> chain_pkg.ACTIVE
	);

	--send a msg to purchaser that a relationship with in_supplier_company_sid has been added/deleted
	message_pkg.TriggerMessage (
		in_primary_lookup	  	 	=> v_primary_lookup,
		in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
		in_to_company_sid	  	 	=> in_supplier_company_sid,
		in_re_company_sid	  	 	=> in_purchaser_company_sid,
		in_system_wide				=> chain_pkg.ACTIVE
	);
END;

/* Count the number of tertiary relations between the company types of two companies where the
user's company has add/remove permissions on relationships. Separate counts for both directions. */
PROCEDURE CountAddRemoveRelationships_ (
	in_company_sid_1				IN  security_pkg.T_SID_ID,
	in_company_sid_2				IN  security_pkg.T_SID_ID,
	out_rel_count_1_2				OUT NUMBER,
	out_rel_count_2_1				OUT NUMBER
)
AS
	v_chain_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_permissible_table_1	T_PERMISSIBLE_TYPES_TABLE; --permissible company type for ADD_REMOVE_RELATIONSHIPS
	v_permissible_table_2	T_PERMISSIBLE_TYPES_TABLE; --permissible company type for CREATE_RELATIONSHIP
	v_company_type_id_1		company_type.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_company_sid_1);
	v_company_type_id_2		company_type.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_company_sid_2);
	v_rel_count_1_2_a		NUMBER;
	v_rel_count_1_2_b		NUMBER;
	v_rel_count_2_1_a		NUMBER;
	v_rel_count_2_1_b		NUMBER;
BEGIN
	v_permissible_table_1 := type_capability_pkg.GetPermissibleCompanyTypes(v_chain_company_sid, chain_pkg.ADD_REMOVE_RELATIONSHIPS);
	v_permissible_table_2 := type_capability_pkg.GetPermissibleCompanyTypes(v_chain_company_sid, chain_pkg.CREATE_RELATIONSHIP);

	SELECT count(*)
	  INTO v_rel_count_1_2_a
	  FROM TABLE (v_permissible_table_1)
	 WHERE secondary_company_type_id = v_company_type_id_1
	   AND tertiary_company_type_id = v_company_type_id_2;

	SELECT count(*)
	  INTO v_rel_count_2_1_a
	  FROM TABLE (v_permissible_table_1)
	 WHERE secondary_company_type_id = v_company_type_id_2
	   AND tertiary_company_type_id = v_company_type_id_1;

	SELECT count(*)
	  INTO v_rel_count_1_2_b
	  FROM TABLE (v_permissible_table_2)
	 WHERE primary_company_type_id = v_company_type_id_1
	   AND secondary_company_type_id = v_company_type_id_2;

	SELECT count(*)
	  INTO v_rel_count_2_1_b
	  FROM TABLE (v_permissible_table_2)
	 WHERE primary_company_type_id = v_company_type_id_2
	   AND secondary_company_type_id = v_company_type_id_1;

	out_rel_count_1_2 := v_rel_count_1_2_a + v_rel_count_1_2_b;
	out_rel_count_2_1 := v_rel_count_2_1_a + v_rel_count_2_1_b;
END;

/* used when supplier accepts a request Qnnaire invitation */
PROCEDURE UNSEC_EstablishRelationship(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE DEFAULT NULL,
	in_trigger_message			IN 	NUMBER DEFAULT 0,
	in_source_type				IN	chain_pkg.T_RELATIONSHIP_SOURCE DEFAULT chain_pkg.AUTO_REL_SRC,
	in_object_id				IN	supplier_relationship_source.object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	StartRelationship(
		in_purchaser_company_sid		=> in_purchaser_company_sid,
		in_supplier_company_sid			=> in_supplier_company_sid,
		in_supp_rel_code				=> in_supp_rel_code,
		in_source_type					=> in_source_type,
		in_object_id					=> in_object_id
	);
	ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);

	IF in_trigger_message = 1 THEN
		RelationshipActionMessage_(in_purchaser_company_sid, in_supplier_company_sid, chain_pkg.RELATIONSHIP_ACTION_ADDED);
	END IF;

	chain_link_pkg.EstablishRelationship(
		in_purchaser_sid		=> in_purchaser_company_sid,
		in_supplier_sid			=> in_supplier_company_sid
	);
END;

PROCEDURE EstablishRelationship(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_set_as_primary			IN  NUMBER DEFAULT 0,
	in_source_type				IN	chain_pkg.T_RELATIONSHIP_SOURCE DEFAULT chain_pkg.AUTO_REL_SRC,
	in_object_id				IN	supplier_relationship_source.object_id%TYPE DEFAULT NULL
)
AS
	v_primary_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_supplier_company_type_id	company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
	v_active					company.active%TYPE;
	v_deactivated_dtm			company.deactivated_dtm%TYPE;
BEGIN

	IF NOT helper_pkg.UseTypeCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'EstablishRelationship can be applied only for type capabilities');
	END IF;

	IF v_primary_company_sid = in_purchaser_company_sid THEN
		IF NOT type_capability_pkg.CheckCapabilityBySupplierType(v_primary_company_sid, v_supplier_company_type_id, chain_pkg.CREATE_RELATIONSHIP) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on CREATE_RELATIONSHIP for purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid);
		END IF;
	ELSE
		--CheckCapabilityByTertiaryType checks flow permission as well
		IF NOT type_capability_pkg.CheckCapabilityByTertiaryType(v_primary_company_sid, in_purchaser_company_sid, v_supplier_company_type_id, chain_pkg.ADD_REMOVE_RELATIONSHIPS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on ADD_REMOVE_RELATIONSHIPS for purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid);
		END IF;
	END IF;

	SELECT active, deactivated_dtm
	  INTO v_active, v_deactivated_dtm
	  FROM company
	 WHERE company_sid = in_purchaser_company_sid;

	IF v_active = 0 AND v_deactivated_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create relationship for deactivated purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid);
	END IF;

	SELECT active, deactivated_dtm
	  INTO v_active, v_deactivated_dtm
	  FROM company
	 WHERE company_sid = in_supplier_company_sid;

	IF v_active = 0 AND v_deactivated_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create relationship for purchaser '||in_purchaser_company_sid||' and deactivated supplier '|| in_supplier_company_sid);
	END IF;

	StartRelationship(
		in_purchaser_company_sid		=> in_purchaser_company_sid,
		in_supplier_company_sid			=> in_supplier_company_sid,
		in_source_type					=> in_source_type,
		in_object_id					=> in_object_id
	);
	ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);

	RelationshipActionMessage_(in_purchaser_company_sid, in_supplier_company_sid, chain_pkg.RELATIONSHIP_ACTION_ADDED);

	/*grant any missing permissions to the purchaser against the supplier */
	supplier_audit_pkg.ResetAuditPermissions(in_purchaser_company_sid, in_supplier_company_sid, supplier_audit_pkg.REGRANT_ACTION);

	chain_link_pkg.EstablishRelationship(
		in_purchaser_sid		=> in_purchaser_company_sid,
		in_supplier_sid			=> in_supplier_company_sid
	);

	IF in_set_as_primary = 1 THEN 
		SetRelationshipAsPrimary(in_purchaser_company_sid, in_supplier_company_sid);
	END IF;
END;

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN,
	in_trigger_message			IN 	NUMBER DEFAULT 0
)
AS
	v_force						NUMBER(1) DEFAULT 0;
	v_act						security_pkg.T_ACT_ID;
	v_purchaser_region_sid		security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetRegionSid(in_purchaser_company_sid);
	v_supplier_region_sid		security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetRegionSid(in_supplier_company_sid);
BEGIN
	-- no security because I'm not really sure what to check
	-- seems pointless checking read / write access on either company or a capability

	IF in_force THEN
		v_force := 1;
	END IF;

	UPDATE supplier_relationship
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (   active = chain_pkg.PENDING
	   		OR v_force = 1);
	
	DELETE FROM supplier_relationship_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	IF in_trigger_message = 1 THEN
		RelationshipActionMessage_(in_purchaser_company_sid, in_supplier_company_sid, chain_pkg.RELATIONSHIP_ACTION_DELETED);
	END IF;

	-- Sync company type roles, remove role from suppliers for all users
	BEGIN
		chain.helper_pkg.LogonUCD;
		v_act := security_pkg.getact;

		FOR r IN (
			SELECT ctr.role_sid, pcu.user_sid
			  FROM company_type_role ctr
			  JOIN company pc ON ctr.company_type_id = pc.company_type_id
			  JOIN v$company_user pcu ON pc.company_sid = pcu.company_sid
			 WHERE ctr.cascade_to_supplier = 1
			   AND pc.company_sid = in_purchaser_company_sid
		) LOOP
			DELETE FROM csr.region_role_member
			 WHERE role_sid = r.role_sid
			   AND region_sid = v_supplier_region_sid
			   AND inherited_from_sid = v_purchaser_region_sid
			   AND user_sid = r.user_sid;
		END LOOP;
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;

			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;

	company_score_pkg.UNSEC_PropagateCompanyScores(in_supplier_company_sid);

	chain_link_pkg.TerminateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

/* Terminates the relationship + checking capability ADD_REMOVE_RELATIONSHIPS + messages */
PROCEDURE DeleteRelationship(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_trigger_message			IN 	NUMBER DEFAULT 0
)
AS
	v_primary_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_tertiary_company_type_id	company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
BEGIN
	IF NOT helper_pkg.UseTypeCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'DeleteRelationship can be applied only for type capabilities');
	END IF;

	IF NOT type_capability_pkg.CheckCapabilityByTertiaryType(v_primary_company_sid, in_purchaser_company_sid, v_tertiary_company_type_id, chain_pkg.ADD_REMOVE_RELATIONSHIPS)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on DeleteRelationship_ for purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid);
	END IF;

	TerminateRelationship(in_purchaser_company_sid, in_supplier_company_sid, TRUE, in_trigger_message);

	-- clear supplier followers 
	csr.supplier_pkg.UNSEC_RemoveFollowerRoles(
		in_purchaser_company_sid	=> in_purchaser_company_sid,
		in_supplier_company_sid		=> in_supplier_company_sid
	);

	DELETE FROM supplier_follower 
	 WHERE purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	/* revoke any audit permissions from the purchaser against this supplier */
	supplier_audit_pkg.ResetAuditPermissions(in_purchaser_company_sid, in_supplier_company_sid, supplier_audit_pkg.REVOKE_ACTION);

	chain_link_pkg.DeleteRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE SetRelationshipAsPrimary(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
	v_primary_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_purchaser_company_type_id	company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_purchaser_company_sid);
	v_supplier_company_type_id	company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
	v_check 					NUMBER;
BEGIN
	IF NOT helper_pkg.UseTypeCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'SetRelationshipAsPrimary can be applied only for type capabilities');
	END IF;

	IF NOT type_capability_pkg.CheckCapabilityByTertiaryType(v_primary_company_sid, in_purchaser_company_sid, v_supplier_company_type_id, chain_pkg.SET_PRIMARY_PRCHSR) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on SetRelationshipAsPrimary for purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid);
	END IF;

	SELECT COUNT(*)
	  INTO v_check
	  FROM company_type_relationship
	 WHERE primary_company_type_id = v_purchaser_company_type_id
	   AND secondary_company_type_id = v_supplier_company_type_id
	   AND can_be_primary =1;

	IF v_check = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Relationship between purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid || 'cannot be primary.');
	END IF;

	UPDATE supplier_relationship sr
	   SET sr.is_primary = 0 
	 WHERE sr.supplier_company_sid = in_supplier_company_sid
	   AND EXISTS (
	 	SELECT NULL
	 	  FROM company pc 
		 WHERE pc.company_sid = sr.purchaser_company_sid
	 	   AND pc.company_type_id = company_type_pkg.GetCompanyTypeId(in_purchaser_company_sid)
	 	);

	 UPDATE supplier_relationship
	 	SET is_primary = 1
	  WHERE supplier_company_sid = in_supplier_company_sid
	    AND purchaser_company_sid = in_purchaser_company_sid;

	chain_link_pkg.UpdateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
)
AS
BEGIN
	ActivateVirtualRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, out_key);
END;

PROCEDURE ActivateVirtualRelationship (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid			IN  security_pkg.T_SID_ID,
	out_key							OUT supplier_relationship.virtually_active_key%TYPE
)
AS
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied activating virtual relationships where you are neither the purchaser or supplier');
	END IF;

	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = sysdate + interval '1' minute, virtually_active_key = virtually_active_key_seq.NEXTVAL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (virtually_active_key IS NULL
	    OR sysdate > virtually_active_until_dtm)
 RETURNING virtually_active_key INTO out_key;
END;

PROCEDURE DeactivateVirtualRelationship (
	in_key							IN  supplier_relationship.virtually_active_key%TYPE
)
AS
	v_purchaser_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	-- get company_sid's for security check
	BEGIN
		SELECT purchaser_company_sid, supplier_company_sid
		  INTO v_purchaser_company_sid, v_supplier_company_sid
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND virtually_active_key = in_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RETURN;
	END;

	IF v_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND v_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deactivating virtual relationships where you are niether the purchaser or supplier');
	END IF;

	-- Only deactivate if in_key was the key that set up the relationship
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = NULL, virtually_active_key = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND virtually_active_key = in_key;
END;

FUNCTION GetVisibleCompanySids
RETURN security.T_SID_TABLE
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_can_see_all_companies			company.can_see_all_companies%TYPE;
	v_visible_company_sids			security.T_SID_TABLE := security.T_SID_TABLE();
	v_temp_company_sids				security.T_SID_TABLE := security.T_SID_TABLE();
	v_permissions					T_PERMISSIBLE_TYPES_TABLE;
	v_perm_comp_t					security.T_SID_TABLE;
BEGIN
	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = v_company_sid;

	IF v_can_see_all_companies = 1 THEN
		SELECT company_sid
		  BULK COLLECT into v_visible_company_sids
		  FROM company
		 WHERE deleted = 0
		   AND pending = 0;
	ELSE
		-- We are allowed to know the existence of ourself, plus any company in a relationship with us.

		v_permissions := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.SUPPLIER_NO_RELATIONSHIP, security_pkg.PERMISSION_READ);

		SELECT company_sid
		  BULK COLLECT INTO v_temp_company_sids
		  FROM (
			SELECT v_company_sid company_sid 
			  FROM dual 
			 UNION
			SELECT sr.purchaser_company_sid 
			  FROM supplier_relationship sr
			 WHERE sr.supplier_company_sid = v_company_sid
			   AND sr.deleted = 0
			 UNION
			SELECT sr.supplier_company_sid 
			  FROM v$supplier_relationship sr
			 WHERE sr.purchaser_company_sid = v_company_sid
			   AND sr.deleted = 0
			 UNION
			-- Also we can see companies where we have the 'view without relationship' permission
			SELECT c.company_SID
			  FROM company c
			  JOIN TABLE(v_permissions) p ON c.company_type_id = p.secondary_company_type_id
			 WHERE c.deleted = 0
			   AND c.pending = 0
		);
		-- Finally, we can see the subsidiaries of any company that we can see so far,
		-- if we have the 'view subsidiaries on behalf of' tertiary permission.

		v_perm_comp_t := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);

		SELECT company_sid
		  BULK COLLECT INTO v_visible_company_sids
		  FROM (
			SELECT sc.company_sid 
			  FROM company sc
			  JOIN company pc ON pc.company_sid = sc.parent_sid
			  JOIN (SELECT column_value FROM TABLE(v_perm_comp_t) order by column_value) p ON pc.company_sid = p.column_value
			  JOIN (SELECT column_value FROM TABLE(v_temp_company_sids) order by column_value) vc ON vc.column_value = pc.company_sid
			 WHERE sc.active = 1
			   AND pc.active = 1
			 UNION
			SELECT company_sid FROM (SELECT column_value company_sid FROM TABLE(v_temp_company_sids) order by company_sid ) 
		);
	END IF;

	RETURN v_visible_company_sids;
END;

FUNCTION GetVisibleRelationships (
	in_include_inactive_rels	IN	NUMBER DEFAULT 0,
	in_include_hidden_rels		IN	NUMBER DEFAULT 0,
	in_allow_admin				IN	NUMBER DEFAULT 0
) RETURN chain.T_COMPANY_REL_SIDS_TABLE
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_can_see_all_companies			company.can_see_all_companies%TYPE;
	v_visible_company_sids			security.T_SID_TABLE;
	v_relationships					T_COMPANY_REL_SIDS_TABLE;
	v_view_relationship_caps		T_PERMISSIBLE_TYPES_TABLE;
	v_view_subsidiaries_caps		T_PERMISSIBLE_TYPES_TABLE;
BEGIN
	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = v_company_sid;

	IF v_can_see_all_companies = 1 OR (in_allow_admin = 1 AND security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(sr.purchaser_company_sid, sr.supplier_company_sid, sr.active)
		  BULK COLLECT INTO v_relationships
		  FROM supplier_relationship sr
		  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
		  JOIN company_type_relationship ctr ON ctr.primary_company_type_id = pc.company_type_id AND ctr.secondary_company_type_id = sc.company_type_id
		 WHERE sr.deleted = 0
		   AND pc.deleted = 0
		   AND sc.deleted = 0
		   AND (in_include_inactive_rels = 1 OR sr.active = 1)
		   AND (in_include_hidden_rels = 1 OR ctr.hidden = 0);
	ELSE
		v_visible_company_sids := GetVisibleCompanySids;

		-- Within the companies we can see, we're allowed to see the relationships that involve us,
		-- or ones where we have the capability to view the relationships.

		v_view_relationship_caps := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.VIEW_RELATIONSHIPS);

		v_view_subsidiaries_caps := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);

		SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(sr.purchaser_company_sid, sr.supplier_company_sid, sr.active)
		  BULK COLLECT INTO v_relationships
		  FROM supplier_relationship sr
		  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
		  JOIN company_type_relationship ctr ON ctr.primary_company_type_id = pc.company_type_id AND ctr.secondary_company_type_id = sc.company_type_id
		  LEFT JOIN TABLE(v_view_relationship_caps) vrc ON pc.company_type_id = vrc.secondary_company_type_id AND sc.company_type_id = vrc.tertiary_company_type_id
		  LEFT JOIN TABLE(v_view_subsidiaries_caps) vsc ON pc.company_type_id = vsc.secondary_company_type_id AND sc.company_type_id = vsc.tertiary_company_type_id
		  WHERE (
			sr.deleted = 0 AND pc.deleted = 0 AND sc.deleted = 0
		  ) AND (
			in_include_inactive_rels = 1 OR sr.active = 1
		  ) AND (
			in_include_hidden_rels = 1 OR ctr.hidden = 0
		  ) AND (
			(sr.purchaser_company_sid = v_company_sid) OR
			(sr.supplier_company_sid = v_company_sid) OR
			(vrc.primary_company_type_id IS NOT NULL) OR
			(vsc.primary_company_type_id IS NOT NULL AND sc.parent_sid = pc.company_sid)
		  ) AND EXISTS (
			SELECT * FROM TABLE(v_visible_company_sids) WHERE column_value = sr.purchaser_company_sid
		  ) AND EXISTS (
			SELECT * FROM TABLE(v_visible_company_sids) WHERE column_value = sr.supplier_company_sid
		  );
	END IF;

	RETURN v_relationships;
END;

FUNCTION GetSuppRelCode (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN supplier_relationship.supp_rel_code%TYPE
AS
	v_code 						supplier_relationship.supp_rel_code%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on supplier with sid '|| in_supplier_company_sid);
	END IF;

	SELECT MIN(supp_rel_code)
	  INTO v_code
	  FROM supplier_relationship
	 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_company_sid
	   AND app_sid = security_pkg.GetApp;

	RETURN v_code;
END;

PROCEDURE UpdateSuppRelCode (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE
)
AS
BEGIN
	UpdateSuppRelCode(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, in_supp_rel_code);
END;

PROCEDURE UpdateSuppRelCode (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE
)
AS
BEGIN
	-- TO DO - temp commented out -
	-- the code belongs to the purchasing company
	--IF NOT capability_pkg.CheckCapability(in_purchaser_company_sid, chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE)  THEN
	--	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on supplier relationship code for purchaser '||in_purchaser_company_sid||' and supplier '|| in_supplier_company_sid);
	--END IF;

	UPDATE supplier_relationship
	   SET supp_rel_code = TRIM(in_supp_rel_code)
	 WHERE purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE AddPurchaserFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT IsMember(in_supplier_company_sid, in_user_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding a purchaser follower (pc='||in_purchaser_company_sid||') user who is not a member of the supplier company (sc='||in_supplier_company_sid||', su='||in_user_sid||')');
	END IF;

	BEGIN
		INSERT INTO purchaser_follower
		(purchaser_company_sid, supplier_company_sid, user_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddSupplierFollower_UNSEC (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	--we should run this check even in the unsec version
	IF NOT IsMember(in_purchaser_company_sid, in_user_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding a supplier follower (sc='||in_supplier_company_sid||') user who is not a member of the purchaser company (pc='||in_purchaser_company_sid||', pu='||in_user_sid||')');
	END IF;

	BEGIN
		-- Always set the first follower as the primary
		INSERT INTO supplier_follower
		(purchaser_company_sid, supplier_company_sid, user_sid, is_primary)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			BEGIN
				INSERT INTO supplier_follower
				(purchaser_company_sid, supplier_company_sid, user_sid)
				VALUES
				(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
	END;

	csr.supplier_pkg.UNSEC_SyncCompanyFollowerRoles(
		in_purchaser_company_sid	=> in_purchaser_company_sid,
		in_supplier_company_sid		=> in_supplier_company_sid,
		in_user_sid					=> in_user_sid
	);

	-- copy existing messages for this company to this user
	BEGIN
		message_pkg.CopyCompanyFollowerMessages(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL; -- these were previously swallowed before the refactor, so keep swallowing them?
	END;
END;

PROCEDURE AddSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.CHANGE_SUPPLIER_FOLLOWER)  THEN
		IF in_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN
			IF NOT capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.EDIT_OWN_FOLLOWER_STATUS)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied changing supplier followers for the company with sid '||in_supplier_company_sid);
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied changing supplier followers for the company with sid '||in_supplier_company_sid);
		END IF;
	END IF;

	AddSupplierFollower_UNSEC(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
END;

FUNCTION CanAddSupplierFollower(
	in_purchaser_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_type_id	IN company_type.company_type_id%TYPE,
	in_user_sid					IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_supplier_company_type_id		company_type.company_type_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckPotentialCapability(v_supplier_company_type_id, chain_pkg.CHANGE_SUPPLIER_FOLLOWER)
		AND (in_user_sid <> SYS_CONTEXT('SECURITY', 'SID') OR capability_pkg.CheckPotentialCapability(v_supplier_company_type_id, chain_pkg.EDIT_OWN_FOLLOWER_STATUS))
	THEN
		RETURN FALSE;
	END IF;

	RETURN TRUE;
END;

PROCEDURE RemoveSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
	v_primary_user_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT user_sid
		  INTO v_primary_user_sid
		  FROM supplier_follower
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND purchaser_company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid
		   AND is_primary = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	IF NOT capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.CHANGE_SUPPLIER_FOLLOWER)  THEN
		IF in_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN
			IF NOT capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.EDIT_OWN_FOLLOWER_STATUS)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied changing supplier followers for the company with sid '||in_supplier_company_sid);
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied changing supplier followers for the company with sid '||in_supplier_company_sid);
		END IF;
	END IF;

	DELETE FROM supplier_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND user_sid = in_user_sid;

	csr.supplier_pkg.UNSEC_SyncCompanyFollowerRoles(
		in_purchaser_company_sid	=> in_purchaser_company_sid,
		in_supplier_company_sid		=> in_supplier_company_sid,
		in_user_sid					=> in_user_sid
	);

	message_pkg.RemoveCompanyFollowerMessages(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
END;

FUNCTION GetPurchaserFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading purchaser follower details where you are niether the purchaser or supplier');
	END IF;

	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM purchaser_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_user_sids;
END;

FUNCTION GetSupplierFollowersNoCheck (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM supplier_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_user_sids;
END;

FUNCTION GetSupplierFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading supplier follower details where you are niether the purchaser or supplier. Purchaser: '
			||in_purchaser_company_sid||' Supplier: '||in_supplier_company_sid||' Logged in as: '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	RETURN GetSupplierFollowersNoCheck(in_purchaser_company_sid, in_supplier_company_sid);
END;

FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN helper_pkg.IsChainAdmin OR
	   VerifyMembership(in_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) OR
	   VerifyMembership(in_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid);
END;

FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	in_user_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN helper_pkg.IsChainAdmin(in_user_sid) OR
	   VerifyMembership(in_company_sid, chain_pkg.USER_GROUP, in_user_sid) OR
	   VerifyMembership(in_company_sid, chain_pkg.PENDING_GROUP, in_user_sid);
END;

PROCEDURE IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	out_result		OUT NUMBER
)
AS
BEGIN
	IF IsMember(in_company_sid, security_pkg.GetSid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF IsSupplier(in_supplier_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid);
END;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_count > 0;
END;

-- TO DO - if this gets used a lot we might need a new COMPANYorSUPPLIERorPURCHASER type capability
-- but this is only intended to be used for a specific "GetPurchaserCompany" which is a read only "get me the company details of someone I sell to"
PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF IsPurchaser(in_purchaser_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsPurchaser(in_purchaser_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(in_purchaser_company_sid, in_supplier_company_sid);
END;

FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_status					supplier_relationship.active%TYPE;
BEGIN
	BEGIN
		SELECT active
		  INTO v_status
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND purchaser_company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_status := -1;
	END;

	RETURN v_status;
END;

PROCEDURE UNSEC_ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_active					company.active%TYPE;
BEGIN
	SELECT active
	  INTO v_active
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF v_active = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;

	UPDATE company
	   SET active = chain_pkg.ACTIVE,
	       activated_dtm = SYSDATE,
		   deactivated_dtm = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	chain_link_pkg.ActivateCompany(in_company_sid);
END;

PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;

	UNSEC_ActivateCompany(in_company_sid);
END;

PROCEDURE UNSEC_DeactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_active					company.active%TYPE;
	v_is_top_company			company_type.is_top_company%TYPE;
	v_ucd_act					security_pkg.T_ACT_ID;
BEGIN
	SELECT is_top_company
	  INTO v_is_top_company
	  FROM company c
	  JOIN company_type ct ON ct.company_type_id = c.company_type_id AND ct.app_sid = c.app_sid
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.company_sid = in_company_sid;

	IF v_is_top_company != 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot deactivate the top company');
	END IF;

	SELECT active
	  INTO v_active
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF v_active != chain_pkg.ACTIVE THEN
		RETURN;
	END IF;

	UPDATE company
	   SET active = chain_pkg.INACTIVE,
	       deactivated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED,
		   cancelled_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
		   cancelled_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND to_company_sid = in_company_sid
	   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED);

	v_ucd_act := csr.csr_user_pkg.LogonUserCreatorDaemon;

	-- deactivate any users	who have no companies left
	FOR r IN (
		-- grab all of our company users
		SELECT user_sid FROM (
			SELECT vcu.user_sid
			  FROM v$company_user vcu
			  JOIN chain_user cu ON vcu.user_sid = cu.user_sid
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND vcu.company_sid = in_company_sid
			   AND cu.tmp_is_chain_user = chain_pkg.ACTIVE
		) vcu
		 WHERE NOT EXISTS(
				SELECT NULL
				  FROM v$company_user cmp
				  JOIN company c ON cmp.company_sid = c.company_sid
				 WHERE cmp.user_sid = vcu.user_sid
				   AND c.active = 1
				   AND cmp.company_sid <> in_company_sid
			)
	)
	LOOP
		csr.csr_user_pkg.DeactivateUser(v_ucd_act, r.user_sid);
		chain_link_pkg.DeactivateUser(r.user_sid);
	END LOOP;

	company_score_pkg.UNSEC_PropagateCompanyScores(in_company_sid);

	chain_link_pkg.DeactivateCompany(in_company_sid);
END;

PROCEDURE DeactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.DEACTIVATE_COMPANY)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Deactivate access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;

	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') = in_company_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot deactivate the current company');
	END IF;

	UNSEC_DeactivateCompany(in_company_sid);
END;

PROCEDURE UNSEC_ReactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_active					company.active%TYPE;
	v_deactivated_dtm			company.deactivated_dtm%TYPE;
BEGIN
	SELECT active, deactivated_dtm
	  INTO v_active, v_deactivated_dtm
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF v_active = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;

	IF v_deactivated_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot reactivate the company with sid '||in_company_sid||' because it has not been deactivated.  Did you mean to call ActivateCompany?');
	END IF;

	UPDATE company
	   SET active = chain_pkg.ACTIVE,
	       activated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	company_score_pkg.UNSEC_PropagateCompanyScores(in_company_sid);

	chain_link_pkg.ReactivateCompany(in_company_sid);

	-- We do this last so that the link package helpers can use the deactivated date
	UPDATE company
	   SET deactivated_dtm = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
END;

PROCEDURE ReactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.DEACTIVATE_COMPANY)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Reactivate access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;

	UNSEC_ReactivateCompany(in_company_sid);
END;

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT email
		  FROM company_cc_email
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;

	DELETE FROM company_cc_email
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF in_emails IS NULL OR in_emails.COUNT = 0 OR in_emails(1) IS NULL THEN
		RETURN;
	END IF;

	FOR i IN in_emails.FIRST .. in_emails.LAST
	LOOP
		BEGIN
			INSERT INTO company_cc_email
			(company_sid, lower_email, email)
			VALUES
			(in_company_sid, LOWER(TRIM(in_emails(i))), TRIM(in_emails(i)));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- this cursor should provide two colomns, one row - columns named: email_from_name, email_from_address
	-- TODO: Actually look this up (only return a valid cursor IF the email_from_address is set)
	OPEN out_cur FOR
		SELECT support_email email_from_name, support_email email_from_address FROM customer_options WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetUserCompanies (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF helper_pkg.IsChainAdmin(in_user_sid) THEN
		OPEN out_count_cur FOR
			SELECT COUNT(*) companies_count
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND deleted = chain_pkg.NOT_DELETED
			   AND active = chain_pkg.ACTIVE
			   AND pending = 0;

		OPEN out_companies_cur FOR
			SELECT company_sid, name, ct.plural company_type_name
			  FROM v$company c, company_type ct
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.app_sid = ct.app_sid
			   AND c.active = chain_pkg.ACTIVE
			   AND c.company_type_id = ct.company_type_id
		     ORDER BY ct.position, LOWER(c.name);

		RETURN;
	END IF;

	OPEN out_count_cur FOR
		SELECT COUNT(*) companies_count
		  FROM v$company_member cm, v$company c
		 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cm.app_sid = c.app_sid
		   AND cm.company_sid = c.company_sid
		   AND cm.user_sid = in_user_sid
		   AND c.active = chain_pkg.ACTIVE;

	OPEN out_companies_cur FOR
		SELECT c.company_sid, c.name, ct.singular company_type_name
		  FROM v$company_member cm, v$company c, company_type ct
		 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cm.app_sid = c.app_sid
		   AND cm.app_sid = ct.app_sid
		   AND cm.company_sid = c.company_sid
		   AND cm.user_sid = in_user_sid
		   AND c.active = chain_pkg.ACTIVE
		   AND c.company_type_id = ct.company_type_id
		 ORDER BY ct.position, LOWER(c.name);
END;

PROCEDURE SetStubSetupDetails (
	in_active				IN  company.allow_stub_registration%TYPE,
	in_approve				IN  company.approve_stub_registration%TYPE,
	in_stubs				IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing stub registration data');
	END IF;

	UPDATE company
	   SET allow_stub_registration = in_active,
	       approve_stub_registration = in_approve
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	DELETE FROM email_stub
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	IF in_stubs IS NULL OR in_stubs.COUNT = 0 OR in_stubs(1) IS NULL THEN
		RETURN;
	END IF;

	FOR i IN in_stubs.FIRST .. in_stubs.LAST
		LOOP
			BEGIN
				INSERT INTO email_stub
				(company_sid, lower_stub, stub)
				VALUES
				(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), LOWER(TRIM(in_stubs(i))), TRIM(in_stubs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
	END LOOP;
END;

PROCEDURE GetStubSetupDetails (
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data required for stub registration');
	END IF;

	UPDATE company
	   SET stub_registration_guid = user_pkg.GenerateAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND stub_registration_guid IS NULL;

	OPEN out_options_cur FOR
		SELECT stub_registration_guid, allow_stub_registration, approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	GetStubEmailAddresses(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), out_stubs_cur);
END;

PROCEDURE GetStubEmailAddresses (
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security as this is called from registration page where no users are logged in
	OPEN out_stubs_cur FOR
		SELECT stub, lower_stub
		  FROM email_stub
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		 ORDER BY lower_stub;
END;

PROCEDURE GetCompanyFromStubGuid (
	in_guid					IN  company.stub_registration_guid%TYPE,
	out_state_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- no sec checks (public page)
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE -- company is active
		   AND allow_stub_registration = chain_pkg.ACTIVE -- allow stub registration
		   AND LOWER(stub_registration_guid) = LOWER(in_guid) -- match guid
		   			-- email stubs are set
		   AND company_sid IN (SELECT company_sid FROM email_stub WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'));

		OPEN out_state_cur FOR
			SELECT chain_pkg.GUID_OK guid_state FROM DUAL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;

			RETURN;
	END;

	OPEN out_company_cur FOR
		SELECT company_sid, name, country_name
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid;

	GetStubEmailAddresses(v_company_sid, out_stubs_cur);
END;

PROCEDURE ConfirmCompanyDetails (
	in_company_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RETURN;
	END IF;

	UPDATE company
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

	message_pkg.CompleteMessageIfExists (
		in_primary_lookup           => chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_to_company_sid           => in_company_sid
	);
END;

/* Obsolete, only being used by the create-company card */
PROCEDURE CheckSupplierExists (
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_company_type_id		IN	company.company_type_id%TYPE,
	in_name					IN	company.name%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS,
	in_supp_rel_code		IN 	supplier_relationship.supp_rel_code%TYPE,
	in_sector_id			IN 	company.sector_id%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_has_references		BOOLEAN DEFAULT FALSE;
	v_company_type_id		company.company_type_id%TYPE := NVL(in_company_type_id, company_type_pkg.GetDefaultCompanyType);
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- restrict to those who can send invitations as this is the only place this function is used
	IF NOT chain.capability_pkg.CheckPotentialCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE)
		AND NOT chain.capability_pkg.CheckPotentialCapability(chain_pkg.SEND_INVITE_ON_BEHALF_OF)
		AND NOT chain.capability_pkg.CheckPotentialCapability(chain_pkg.SEND_COMPANY_INVITE)
		AND NOT chain.capability_pkg.CheckPotentialCapability(chain_pkg.CREATE_COMPANY_WITHOUT_INVIT) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied inviting companies');
	END IF;

	v_has_references := CheckReferenceInputs(in_lookup_keys, in_values);

	IF v_has_references THEN
	   	PopulateConflictingRefTable(in_company_sid, in_country_code, v_company_type_id, in_lookup_keys, in_values);
	END IF;

	v_company_sid := GetCompanySidByLayout (
		in_name					=> in_name,
		in_country_code			=> in_country_code,
		in_company_type_id		=> in_company_type_id,
		in_sector_id			=> in_sector_id,
		in_swallow_not_found 	=> 1
	);

	OPEN out_cur FOR
		SELECT company_sid, name
		  FROM (
			SELECT company_sid, name
			  FROM company
			 WHERE company_sid = v_company_sid
			   AND v_company_sid != in_company_sid
			   AND v_company_sid > 0
			 UNION
			SELECT c.company_sid, c.name
			  FROM v$company c
			  JOIN supplier_relationship sr ON c.company_sid = sr.supplier_company_sid
			 WHERE c.company_sid != in_company_sid
			   AND LOWER(sr.supp_rel_code) = LOWER(in_supp_rel_code)
			 UNION
			SELECT company_sid, name
			  FROM TT_REFERENCE_LABELS
			)
		 WHERE ROWNUM<10; -- More than 10 rows is not useful
END;

FUNCTION GetSectorId (
	in_sector_name			IN  sector.description%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_id		security_pkg.T_SID_ID;
BEGIN
	SELECT sector_id
	  INTO v_id
	  FROM sector
	 WHERE description = in_sector_name;

	RETURN v_id;
END;

FUNCTION GetCompanyGroupTypeId (
	in_group				IN  chain_pkg.T_GROUP
) RETURN NUMBER
AS
	v_company_group_type_id	company_group_type.company_group_type_id%TYPE;
BEGIN
	SELECT company_group_type_id
	  INTO v_company_group_type_id
	  FROM company_group_type
	 WHERE name = in_group;

	RETURN v_company_group_type_id;
END;

PROCEDURE GetCompanyGroupTypes (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cgt.company_group_type_id, cgt.name, cgt.is_global
		  FROM company_group_type cgt;
END;

PROCEDURE HasSupplierRelationships (
	out_result				OUT NUMBER
)
AS
	v_count					NUMBER;
BEGIN
	IF chain.capability_pkg.CheckPotentialCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$supplier_relationship
		 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	ELSE
		v_count := 0;
	END IF;

	out_result := 0;
	IF v_count > 0 THEN
		out_result := 1;
	END IF;
END;

PROCEDURE UpdateCompanyReference (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_key			IN v$company_reference.lookup_key%TYPE,
	in_value				IN company_reference.value%TYPE
)
AS
	v_values					chain_pkg.T_STRINGS;
	v_lookupKeys 				chain_pkg.T_STRINGS;
BEGIN
	v_values(1) := in_value;
	v_lookupKeys(1) := in_lookup_key;

	UpdateCompanyReferences(in_company_sid, v_lookupKeys, v_values);
END;

--this can be called from anywhere, will check everything is ok before updating
PROCEDURE UpdateCompanyReferences (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_keys			IN chain_pkg.T_STRINGS,
	in_values				IN chain_pkg.T_STRINGS,
	in_is_pending			IN NUMBER DEFAULT 0
)
AS
	v_duplicate_reference_label	VARCHAR2(1024);
BEGIN
	IF NOT CheckReferenceInputs(in_lookup_keys, in_values) THEN
		RETURN;
	END IF;

	IF in_is_pending = 0 AND CheckReferenceExists(in_company_sid, in_lookup_keys, in_values) THEN
		
		SELECT LISTAGG(r.label, ',')
		  INTO v_duplicate_reference_label
		  FROM TT_REFERENCE_LABELS t
		  JOIN reference r ON r.lookup_key = t.lookup_key
		 WHERE r.app_sid = security_pkg.GetApp;
		 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, v_duplicate_reference_label);
	END IF;

	UpdateCompanyReferences_(in_company_sid, in_lookup_keys, in_values);
END;

FUNCTION TryGetCompanyReferenceValue(
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_key			IN v$company_reference.lookup_key%TYPE
) RETURN chain.company_reference.value%TYPE
AS
	v_value 	chain.company_reference.value%TYPE;
BEGIN
	BEGIN
		SELECT value
		  INTO v_value
		  FROM chain.v$company_reference
		 WHERE company_sid = in_company_sid
		   AND UPPER(lookup_key) = UPPER(in_lookup_key);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_value := NULL;
	END;

	RETURN v_value;
END;

PROCEDURE GetCompanyRoleMembers(
	in_company_sid					IN  activity.target_company_sid%TYPE,
	in_role_sid						IN	activity.target_role_sid%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT rrm.user_sid
		  FROM csr.region_role_member rrm
		  JOIN csr.supplier s ON rrm.app_sid = s.app_sid AND rrm.region_sid = s.region_sid
		 WHERE rrm.role_sid = in_role_sid
		   AND s.company_sid = in_company_sid;
END;

PROCEDURE GetCompanyTabs (
	in_page_company_type_id			IN company.company_type_id%TYPE,
	in_user_company_type_id			IN company.company_type_id%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_tabs_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
		       p.details, p.preview_image_path, ctb.label, ctb.pos, ctb.page_company_type_id, ctb.user_company_type_id,
			   p.form_path, ctb.business_relationship_type_id
		  FROM csr.plugin p
		  JOIN company_tab ctb
		    ON p.plugin_id = ctb.plugin_id
		 WHERE (ctb.page_company_type_id IS NULL OR ctb.page_company_type_id = in_page_company_type_id)
		   AND (ctb.user_company_type_id IS NULL OR ctb.user_company_type_id = in_user_company_type_id)
		 GROUP BY p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
		          p.details, p.preview_image_path, ctb.label, ctb.pos, ctb.page_company_type_id, ctb.user_company_type_id,
				  p.form_path, ctb.business_relationship_type_id
		 ORDER BY ctb.pos;
END;

FUNCTION GetConnectedRelationships(
	in_company_sid					IN security_pkg.T_SID_ID
) RETURN chain.T_COMPANY_REL_SIDS_TABLE
AS
	v_relationships					T_COMPANY_REL_SIDS_TABLE := GetVisibleRelationships;
	v_ancestor_relationships		T_COMPANY_REL_SIDS_TABLE;
	v_descendant_relationships		T_COMPANY_REL_SIDS_TABLE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(primary_company_sid, secondary_company_sid, active)
	  BULK COLLECT INTO v_ancestor_relationships
	  FROM TABLE(v_relationships)
		   CONNECT BY secondary_company_sid = PRIOR primary_company_sid
		   START WITH secondary_company_sid = in_company_sid;

	SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(primary_company_sid, secondary_company_sid, active)
	  BULK COLLECT INTO v_descendant_relationships
	  FROM TABLE(v_relationships)
		   CONNECT BY primary_company_sid = PRIOR secondary_company_sid
		   START WITH primary_company_sid = in_company_sid;

	RETURN v_ancestor_relationships MULTISET UNION v_descendant_relationships;
END;

PROCEDURE GetCompaniesGraph(
	in_company_sid					IN security_pkg.T_SID_ID DEFAULT NULL,
	out_companies_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_relationships_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_scores_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_relationships					T_COMPANY_REL_SIDS_TABLE;
	v_results						T_FILTERED_OBJECT_TABLE;
	v_dummy_cur						security_pkg.T_OUTPUT_CUR;
BEGIN
	IF in_company_sid IS NOT NULL THEN
		v_company_sid := in_company_sid;
	END IF;

	v_relationships := GetConnectedRelationships(v_company_sid);

	SELECT T_FILTERED_OBJECT_ROW(x.company_sid, NULL, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT v_company_sid company_sid
		  FROM dual
		 UNION
		SELECT primary_company_sid company_sid
		  FROM TABLE(v_relationships)
		 UNION
		SELECT secondary_company_sid company_sid
		  FROM TABLE(v_relationships)
	  ) x
	  GROUP BY x.company_sid;

	CollectSearchResults(v_results, 0, 0, v_dummy_cur, out_companies_cur);
	CollectScores(v_results, out_scores_cur);

	OPEN out_relationships_cur FOR
		SELECT sr.purchaser_company_sid, sr.supplier_company_sid
		  FROM v$supplier_relationship sr
		 WHERE EXISTS (
			SELECT * FROM TABLE(v_relationships) r WHERE r.primary_company_sid = sr.purchaser_company_sid AND r.secondary_company_sid = sr.supplier_company_sid
		 );
END;

PROCEDURE DeactivateSupplierHelper(
    in_flow_sid                 	IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             	IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            	IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              	IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             	IN  csr.flow_state_log.comment_text%TYPE,
    in_user_sid                 	IN  security.security_pkg.T_SID_ID
)
AS
	v_company_sid	                security.security_pkg.T_SID_ID;
BEGIN
	--This helper deactivates suppliers who pass through the transition

	--find company sid
	SELECT DISTINCT supplier_company_sid
	  INTO v_company_sid
	  FROM chain.supplier_relationship
	 WHERE flow_item_id = in_flow_item_id;

	--deactivate it!
	chain.company_pkg.DeactivateCompany(v_company_sid);
END;

PROCEDURE ActivateSupplierHelper(
    in_flow_sid                 	IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             	IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            	IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              	IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             	IN  csr.flow_state_log.comment_text%TYPE,
    in_user_sid                 	IN  security.security_pkg.T_SID_ID
)
AS
	v_company_sid	                security.security_pkg.T_SID_ID;
BEGIN
	--This helper activates suppliers who pass through the transition

	--find company sid
	SELECT DISTINCT supplier_company_sid
	  INTO v_company_sid
	  FROM chain.supplier_relationship
	 WHERE flow_item_id = in_flow_item_id;

	--Activate it!
	chain.company_pkg.ActivateCompany(v_company_sid);
END;

/* Used by structured import */
PROCEDURE GetCompanies(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetCompanies can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	OPEN out_cur FOR
		SELECT company_sid, name, company_type_id
		  FROM company
		 WHERE app_sid = security_pkg.GetApp
		   AND deleted = 0
		   AND pending = 0;
END;

PROCEDURE INTERNAL_GetSuppRelationship(
	out_supp_rel_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_supp_rel_cur FOR
		SELECT purchaser_company_sid, supplier_company_sid
		  FROM v$supplier_relationship;
END;

/* Used by supplier follower structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetCompaniesAndUsersAndSuppRel(
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_users_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_supp_rel_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetCompaniesAndUsers can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	GetCompanies(out_companies_cur);

	OPEN out_users_cur FOR
		SELECT user_sid, email, default_company_sid, company_sid
		  FROM v$company_user
		 WHERE account_enabled = 1
		   AND EXISTS (
			SELECT 1
			  FROM supplier_relationship
			 WHERE purchaser_company_sid = company_sid
			);

	INTERNAL_GetSuppRelationship(out_supp_rel_cur);
END;

/* Used by company relationship structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetCompaniesSuppRelAndTypeRel(
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_supp_rel_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_type_rel_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetCompaniesSuppRelAndTypeRel can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	GetCompanies(out_companies_cur);
	INTERNAL_GetSuppRelationship(out_supp_rel_cur);

	OPEN out_comp_type_rel_cur FOR
		SELECT primary_company_type_id, secondary_company_type_id
		  FROM company_type_relationship;
END;

PROCEDURE SaveAltCompanyNames (
	in_alt_company_name_ids	IN security_pkg.T_SID_IDS,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_alt_company_names	IN chain_pkg.T_STRINGS
)
AS
	v_alt_company_name_ids 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_alt_company_name_ids);
BEGIN
	DELETE FROM alt_company_name
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid
	   AND alt_company_name_id NOT IN (SELECT t.column_value FROM TABLE(v_alt_company_name_ids) t);

	FOR i IN 1..in_alt_company_name_ids.COUNT LOOP
		IF in_alt_company_names(i) IS NOT NULL THEN
			SaveAltCompanyName(in_alt_company_name_ids(i), in_company_sid, in_alt_company_names(i));
		END IF;
	END LOOP;
END;

PROCEDURE SaveAltCompanyName (
	in_alt_company_name_id	IN security_pkg.T_SID_ID DEFAULT -1,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_name					IN alt_company_name.name%TYPE
)
AS
	v_alt_company_name_id	security_pkg.T_SID_ID := in_alt_company_name_id;
BEGIN
	IF CheckAltCompNameExists(in_company_sid, in_name, v_alt_company_name_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate alternative company name.');
	END IF;

	IF v_alt_company_name_id = -1 THEN
		v_alt_company_name_id := null;
	END IF;

	INSERT INTO alt_company_name (alt_company_name_id, company_sid, name)
	VALUES (NVL(v_alt_company_name_id, alt_company_name_id_seq.nextval), in_company_sid, in_name);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE alt_company_name
		   SET name = in_name
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND alt_company_name_id = v_alt_company_name_id;
END;

FUNCTION CheckAltCompNameExists(
	in_company_sid			IN security_pkg.T_SID_ID,
	in_name					IN alt_company_name.name%TYPE,
	in_alt_company_name_id	IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count					NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM company c
	  LEFT JOIN alt_company_name acn ON acn.company_sid = c.company_sid
	   AND acn.alt_company_name_id != in_alt_company_name_id
	 WHERE c.app_sid = security_pkg.GetApp
	   AND c.company_sid = in_company_sid
	   AND (TRIM(acn.name) = TRIM(in_name)
		OR TRIM(c.name) = TRIM(in_name));

	RETURN v_count > 0;
END;

PROCEDURE SetSupplierRelationshipScore (
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.score_type.score_type_id%TYPE,
	in_threshold_id				IN	csr.score_threshold.score_threshold_id%TYPE,
	in_score					IN	supplier_relationship_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  supplier_relationship_score.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  supplier_relationship_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  supplier_relationship_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  supplier_relationship_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  supplier_relationship_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  supplier_relationship_score.comment_text%TYPE DEFAULT NULL
)
AS
	v_count						NUMBER;
	v_sup_rel_score_id			supplier_relationship_score.supplier_relationship_score_id%TYPE;
	
	v_set_dtm					supplier_relationship_score.set_dtm%TYPE := TRUNC(in_set_dtm);
	v_valid_until_dtm			supplier_relationship_score.valid_until_dtm%TYPE := TRUNC(in_valid_until_dtm);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting supplier relationship score for company with sid:' || in_supplier_sid);
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.score_type
	 WHERE app_sid = security_pkg.GetApp
	   AND score_type_id = in_score_type_id
	   AND allow_manual_set = 1;

	IF v_count != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot manually set score threshold for a score type that doesn''t allow manual setting');
	END IF;
	
	BEGIN    
		INSERT INTO supplier_relationship_score (supplier_relationship_score_id, purchaser_company_sid, supplier_company_sid, score_threshold_id, 
					score_type_id, score, set_dtm, valid_until_dtm, is_override, score_source_type, score_source_id, comment_text)
			VALUES (supplier_rel_score_id_seq.NEXTVAL, in_purchaser_sid, in_supplier_sid, in_threshold_id, 
					in_score_type_id, in_score, v_set_dtm, v_valid_until_dtm, in_is_override, in_score_source_type, in_score_source_id, in_comment_text)
				RETURNING supplier_relationship_score_id INTO v_sup_rel_score_id;
					
		-- end any other scores where there is no valid_until_dtm set or valid_until_dtm is after the start date of the new score - the new score id the only one that matters
		UPDATE supplier_relationship_score
		   SET valid_until_dtm = v_set_dtm
		 WHERE supplier_company_sid = in_supplier_sid
		   AND purchaser_company_sid = in_purchaser_sid
		   AND score_type_id = in_score_type_id
		   AND is_override = in_is_override
		   AND (valid_until_dtm IS NULL OR (set_dtm <= v_set_dtm AND valid_until_dtm >= v_set_dtm))
		   AND supplier_relationship_score_id <> v_sup_rel_score_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE supplier_relationship_score 
			   SET  score_threshold_id = in_threshold_id, 
					score = in_score, 
					valid_until_dtm = v_valid_until_dtm, 
					score_source_type = in_score_source_type, 
					score_source_id = in_score_source_id, 
					comment_text = in_comment_text
			 WHERE purchaser_company_sid = in_purchaser_sid
			   AND supplier_company_sid = in_supplier_sid
			   AND score_type_id = in_score_type_id
			   AND set_dtm = v_set_dtm
			   AND is_override = in_is_override;
	END;
END;

PROCEDURE SetSupplierRelationshipScore (
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.score_type.score_type_id%TYPE,
	in_thresh_lookup_key		IN	csr.score_threshold.lookup_key%TYPE,
	in_score					IN	supplier_relationship_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  supplier_relationship_score.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  supplier_relationship_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  supplier_relationship_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  supplier_relationship_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  supplier_relationship_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  supplier_relationship_score.comment_text%TYPE DEFAULT NULL
)
AS
	v_threshold_id				supplier_relationship_score.score_threshold_id%TYPE;
BEGIN
	-- want to blow up if we can't find a lookup key here
	SELECT score_threshold_id 
	  INTO v_threshold_id
	  FROM csr.score_threshold
	 WHERE score_type_id = in_score_type_id
	   AND lookup_key = in_thresh_lookup_key;

	SetSupplierRelationshipScore (in_purchaser_sid,	in_supplier_sid, in_score_type_id, v_threshold_id,	in_score, in_set_dtm,
									in_valid_until_dtm, in_is_override, in_score_source_type, in_score_source_id, in_comment_text);
END;

PROCEDURE DeleteSupRelScore (
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.score_type.score_type_id%TYPE,
	in_set_dtm					IN  supplier_relationship_score.set_dtm%TYPE,
	in_valid_until_dtm			IN  supplier_relationship_score.valid_until_dtm%TYPE,
	in_is_override				IN  supplier_relationship_score.is_override%TYPE DEFAULT 0
)
AS
	v_count						NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting supplier relationship score for company with sid:' || in_supplier_sid);
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.score_type
	 WHERE app_sid = security_pkg.GetApp
	   AND score_type_id = in_score_type_id
	   AND allow_manual_set = 1;

	IF v_count != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot manually delete score threshold for a score type that doesn''t allow manual setting');
	END IF;

	DELETE FROM supplier_relationship_score 
	 WHERE purchaser_company_sid = in_purchaser_sid
	   AND supplier_company_sid = in_supplier_sid
	   AND score_type_id = in_score_type_id
	   AND set_dtm = in_set_dtm
	   AND ((valid_until_dtm = in_valid_until_dtm) OR (valid_until_dtm IS NULL AND in_valid_until_dtm IS NULL))
	   AND is_override = in_is_override;	
END;

PROCEDURE GetSuppRelScores(
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	out_supp_rel_scores_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF in_purchaser_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		IF NOT capability_pkg.CheckCapability(in_purchaser_sid, in_supplier_sid, chain_pkg.VIEW_RELATIONSHIPS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the relationship between the company with sid '||in_purchaser_sid||' and sid '||in_supplier_sid);
		END IF;
	END IF;
	
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on company scores with sid '||in_supplier_sid);
	END IF;

	OPEN out_supp_rel_scores_cur FOR
		SELECT purchaser_company_sid, supplier_company_sid, st.score_threshold_id, set_dtm, valid_until_dtm, NVL(valid, 0) valid, s.score, 
			   t.score_type_id, st.description, st.text_colour, st.background_colour, t.format_mask, 
			   t.allow_manual_set, t.label score_type_label
		  FROM csr.score_type t
		  LEFT JOIN v$current_sup_rel_score s 
			ON t.score_type_id = s.score_type_id 
		   AND s.purchaser_company_sid = in_purchaser_sid 
		   AND s.supplier_company_sid = in_supplier_sid
		  LEFT JOIN csr.score_threshold st ON st.score_threshold_id = s.score_threshold_id
		 WHERE (t.allow_manual_set = 1 OR s.score IS NOT NULL OR s.score_threshold_id IS NOT NULL)
		   AND t.hidden = 0
		   AND t.applies_to_supp_rels = 1
		 ORDER BY t.pos, t.score_type_id;
END;

PROCEDURE PromotePendingCompany(
	in_pending_company_sid	IN security_pkg.T_SID_ID
)
AS
	v_pending_tags_ids		security_pkg.T_SID_IDS;
BEGIN
	chain_link_pkg.AddCompany(in_pending_company_sid);
	company_pkg.ActivateCompany(in_pending_company_sid);
	StartRelationship(
		in_purchaser_company_sid		=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_supplier_company_sid			=> in_pending_company_sid
	);
	ActivateRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_pending_company_sid);
	
	UPDATE company
	   SET pending = 0
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = in_pending_company_sid;
	
	SELECT tag_id
	  BULK COLLECT INTO v_pending_tags_ids
	  FROM pending_company_tag
	 WHERE pending_company_sid = in_pending_company_sid;
	 
	SetTags(in_pending_company_sid, v_pending_tags_ids);
	
	securableobject_pkg.MoveSO(security_pkg.GetAct, in_pending_company_sid, helper_pkg.GetCompaniesContainer);
END;

PROCEDURE MarkRequestAsProcessed(
	in_pending_company_sid 		IN security_pkg.T_SID_ID,
	in_error_detail 			IN company_request_action.error_detail%TYPE,
	in_error_message 			IN company_request_action.error_message%TYPE
)
AS
BEGIN
	UPDATE company_request_action
	   SET error_message = in_error_message,
		   error_detail = in_error_detail,
		   is_processed = 1
	 WHERE company_sid = in_pending_company_sid;
END;

/* called by batch jobs */
FUNCTION ProcessPendingRequest_UNSEC(
	in_pending_company_sid 		IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_error_message 			company_request_action.error_message%TYPE;
	v_company_to_relate_with 	security_pkg.T_SID_ID;
	v_action				 	company_request_action.action%TYPE;
	v_requested_by_company_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT c.requested_by_company_sid, cra.action, cra.matched_company_sid
	  INTO v_requested_by_company_sid, v_action, v_company_to_relate_with
	  FROM company_request_action cra
	  JOIN company c ON c.company_sid = cra.company_sid
	 WHERE c.company_sid = in_pending_company_sid;
	
	IF v_action = chain_pkg.ACCEPT_PENDING_COMPANY THEN
		PromotePendingCompany(in_pending_company_sid);
		v_company_to_relate_with := in_pending_company_sid;
	END IF;
	
	IF v_action IN (chain_pkg.ACCEPT_PENDING_COMPANY, chain_pkg.MERGE_PENDING_COMPANY) THEN
		BEGIN
			EstablishRelationship(v_requested_by_company_sid, v_company_to_relate_with);
		EXCEPTION
			WHEN chain_pkg.COMPANY_TYPE_RELATION_NA THEN
				v_error_message := 'This type of relationship is not supported';
		END;
	END IF;
	
	MarkRequestAsProcessed(
		in_pending_company_sid		=> in_pending_company_sid, 
		in_error_detail				=> NULL, 
		in_error_message			=> v_error_message
	);
	
	RETURN v_error_message IS NULL;
END;

PROCEDURE GetCompanySidsToProcess(
	in_batch_job_id 			IN csr.batch_job.batch_job_id%TYPE,
	out_process_recs			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_process_recs FOR
		SELECT company_sid
		  FROM company_request_action
		 WHERE batch_job_id = in_batch_job_id
		   AND is_processed = 0
	     ORDER BY company_sid;
END;

PROCEDURE ProcessPendingCompRec(
	in_batch_job_id 			IN csr.batch_job.batch_job_id%TYPE,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_success					OUT NUMBER
)
AS
	v_requested_by_company_sid 		security_pkg.T_SID_ID;
BEGIN
	SELECT requested_by_company_sid
	  INTO v_requested_by_company_sid
	  FROM csr.batch_job
	 WHERE batch_job_id = in_batch_job_id;
	 
	security.security_pkg.SetContext('CHAIN_COMPANY', v_requested_by_company_sid);
	
	out_success := CASE WHEN ProcessPendingRequest_UNSEC(in_company_sid) THEN 1 ELSE 0 END;

	security.security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

FUNCTION CreatePendingCompanyRequestJob
RETURN csr.batch_job.batch_job_id%TYPE
AS
	v_batch_job_id 			security_pkg.T_SID_ID;
BEGIN
	IF NOT (helper_pkg.IsTopCompany = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only top company users or admins can create pending company batch jobs');
	END IF;

	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id 	=> csr.batch_job_pkg.JT_PENDING_COMP_PROC_RECS,
		in_description 			=> 'Process pending company action',
		in_requesting_user		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_requesting_company	=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		out_batch_job_id 		=> v_batch_job_id
	);
	
	RETURN v_batch_job_id;
END;

PROCEDURE AddPendingCompRequestActions(
	in_company_sid				IN security_pkg.T_SID_ID,
	in_matched_company_sid		IN security_pkg.T_SID_ID,
	in_action 					IN security_pkg.T_SID_ID,
	in_batch_job_id 			IN csr.batch_job.batch_job_id%TYPE
)
AS
BEGIN
	IF NOT (helper_pkg.IsTopCompany = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only top company users or admins can add new company requests');
	END IF;

	INSERT INTO company_request_action(company_sid, matched_company_sid, action, is_processed, batch_job_id, sent_dtm)
		 VALUES (in_company_sid, in_matched_company_sid, in_action, 0, in_batch_job_id, NULL);
END;

PROCEDURE GetPrimaryPurchaserTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT ct.company_type_id, ct.singular label, ct.lookup_key
		  FROM chain.company_type_relationship ctr 
		  JOIN chain.company_type ct ON ctr.primary_company_type_id = ct.company_type_id
		 WHERE can_be_primary = 1;
END;

PROCEDURE GetPrimaryPurchasersForCompany(
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sr.supplier_company_sid company_sid, sr.purchaser_company_sid, c.name purchaser_company_name, c.company_type_id purchaser_type_id,
			   ct.singular purchaser_type_label, ct.lookup_key purchaser_type_lookup_key
		  FROM supplier_relationship sr
		  JOIN company c ON c.company_sid = sr.purchaser_company_sid
		  JOIN company_type ct ON c.company_type_id = ct.company_type_id
		 WHERE sr.supplier_company_sid = in_company_sid
		   AND sr.is_primary = 1
		   AND sr.deleted != chain_pkg.DELETED;
END;

PROCEDURE GetPendingCompanyAlerts(
	out_cur 	OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cra.app_sid, tu.csr_user_sid to_user_sid, NVL(mc.company_sid, rfc.company_sid) created_company_sid, NVL(mc.name, rfc.name) created_company,
			   cra.action, rbc.company_sid from_company_sid, rbc.name from_company, rfc.company_sid pending_company_sid
		  FROM company_request_action cra
		  JOIN company rfc ON cra.company_sid = rfc.company_sid AND cra.app_sid = rfc.app_sid -- Company that the request was made for
		  JOIN company rbc ON rfc.requested_by_company_sid = rbc.company_sid AND rfc.app_sid = rbc.app_sid -- Company that the request was made by
	 	  JOIN csr.batch_job bj ON bj.batch_job_id = cra.batch_job_id AND bj.app_sid = cra.app_sid
		  JOIN csr.csr_user tu ON rfc.requested_by_user_sid = tu.csr_user_sid AND tu.app_sid = rfc.app_sid
	 LEFT JOIN company mc ON cra.matched_company_sid = mc.company_sid AND mc.app_sid = cra.app_sid -- Company matched to
		 WHERE cra.sent_dtm IS NULL
		   AND cra.is_processed = 1
		   AND error_message IS NULL
		   AND error_detail IS NULL
		 ORDER BY cra.app_sid;
END;

PROCEDURE MarkPendingCompanyAlertSent (
	in_app_sid 			security_pkg.T_SID_ID,
	in_company_sid 		security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE company_request_action
	   SET sent_dtm = SYSDATE
	 WHERE sent_dtm IS NULL
	   AND company_sid = in_company_sid
	   AND app_sid = in_app_sid;

	COMMIT;
END;

PROCEDURE GetCompaniesToGeocode(
	in_batch_job_id		csr.batch_job.batch_job_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_geotag_is_enabled	NUMBER;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run company_pkg.GetCompaniesToGeocode');
	END IF;

	v_geotag_is_enabled := helper_pkg.IsCompanyGeotagEnabled;

	OPEN out_cur FOR
		SELECT c.company_sid, r.region_sid, c.address_1 street, c.city, c.state, c.country_code country, c.postcode
		  FROM csr.region r
		  JOIN csr.supplier s ON r.region_sid = s.region_sid
		  JOIN company c ON c.company_sid = s.company_sid
		  JOIN geotag_batch gb ON gb.batch_job_id = in_batch_job_id  
		  JOIN geotag_batch_company_queue gbcq ON c.company_sid = gbcq.company_sid AND gbcq.geotag_batch_id = gb.geotag_batch_id
		 WHERE v_geotag_is_enabled = 1
		   AND c.deleted = 0; 
END;

FUNCTION CreateGeotagBatchJob(
	in_geotag_source	geotag_batch.source%TYPE
)
RETURN geotag_batch.batch_job_id%TYPE
AS 
	v_batch_job_id			geotag_batch.batch_job_id%TYPE;
	v_geotag_batch_id		geotag_batch.geotag_batch_id%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run company_pkg.CreateGeotagBatchJob');
	END IF;

	IF helper_pkg.IsCompanyGeotagEnabled = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Customer option for geo-tagging companies is not enabled');
	END IF;

	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_COMPANY_GEOCODE,
		in_description => 'Geotag companies',
		out_batch_job_id => v_batch_job_id
	);

	INSERT INTO geotag_batch (geotag_batch_id, batch_job_id, source) 
	VALUES (geotag_batch_id_seq.NEXTVAL, v_batch_job_id, in_geotag_source)
	RETURNING geotag_batch_id INTO v_geotag_batch_id;

	IF in_geotag_source =  chain.chain_pkg.GEOTAG_SRC_ALL_COMPANIES THEN
		INSERT INTO geotag_batch_company_queue (geotag_batch_id, company_sid)
		SELECT v_geotag_batch_id, c.company_sid
		  FROM csr.region r
		  JOIN csr.supplier s ON r.region_sid = s.region_sid
		  JOIN company c ON c.company_sid = s.company_sid
		 WHERE r.geo_type != csr.region_pkg.REGION_GEO_TYPE_LOCATION
		   AND (c.address_1 IS NOT NULL OR c.city IS NOT NULL OR c.state IS NOT NULL OR c.postcode IS NOT NULL)
		   AND c.deleted = 0; 
	END IF;
	 
	RETURN v_geotag_batch_id;
END;

PROCEDURE GetCompanyAddress(
	in_company_sid			security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT address_1, city, state, postcode 
		  FROM company
		 WHERE company_sid = in_company_sid;
END;

PROCEDURE QueueCompanyInGeotagBatch(
	in_company_sid 		security_pkg.T_SID_ID,
	in_geotag_batch_id	geotag_batch.geotag_batch_id%TYPE
)
AS
	v_count		NUMBER;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run company_pkg.QueueCompanyInGeotagBatch');
	END IF;
	
	INSERT INTO geotag_batch_company_queue (company_sid, geotag_batch_id)
	VALUES (in_company_sid, in_geotag_batch_id);
END;

PROCEDURE MarkGeotagCompany(
	in_company_sid 			security_pkg.T_SID_ID,
	in_batch_job_id			geotag_batch.batch_job_id%TYPE,
	in_longitude			NUMBER DEFAULT NULL,
	in_latitude				NUMBER DEFAULT NULL
)
AS
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run company_pkg.MarkGeotagCompany');
	END IF;

	UPDATE geotag_batch_company_queue 
	   SET processed_dtm = SYSDATE,
		   longitude = in_longitude,
		   latitude = in_latitude
	 WHERE company_sid = in_company_sid
	   AND geotag_batch_id IN ( 
		   SELECT geotag_batch_id
			 FROM geotag_batch
			WHERE batch_job_id = in_batch_job_id
		);
END;

PROCEDURE UNSEC_GetCompanySidsByReference (
	in_comp_ref_val			IN  company_reference.value%TYPE,
	in_ref_lookup			IN  reference.lookup_key%TYPE,
	out_company_sids		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_company_sids FOR
		SELECT cr.company_sid
		  FROM chain.company_reference cr
		  JOIN chain.reference r ON r.reference_id = cr.reference_id
		  JOIN chain.company c on c.company_sid = cr.company_sid
		 WHERE cr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cr.value = in_comp_ref_val
		   AND r.lookup_key = in_ref_lookup
		   AND c.active = chain_pkg.ACTIVE;
END;

FUNCTION Unsec_GetCompanyTags(
	in_company_sid		IN security_pkg.T_SID_ID,
	in_lookup_key		IN csr.tag_group.lookup_key%TYPE
) RETURN csr.T_VARCHAR2_TABLE
AS
	v_table		csr.T_VARCHAR2_TABLE;
BEGIN
	SELECT t.lookup_key
	  BULK COLLECT INTO v_table
	  FROM csr.supplier s
	  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
	  JOIN csr.tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
	  JOIN csr.tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
	  JOIN csr.tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
	 WHERE s.company_sid = in_company_sid 
	   AND tg.lookup_key = in_lookup_key;

	RETURN v_table;
END;

FUNCTION Unsec_GetSubsidiaries(
	in_parent_company_sid	IN security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE
AS
	v_company_sids		security.T_SID_TABLE;
BEGIN
	SELECT company_sid
	  BULK COLLECT INTO v_company_sids
	  FROM company
	 WHERE parent_sid = in_parent_company_sid; 

	RETURN v_company_sids;
END;

FUNCTION Unsec_GetParentSid(
	in_company_sid	IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT parent_sid
	  INTO v_parent_sid
	  FROM company
	 WHERE company_sid = in_company_sid; 

	RETURN v_parent_sid;
END;

END company_pkg;
/
