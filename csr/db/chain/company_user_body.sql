CREATE OR REPLACE PACKAGE BODY CHAIN.company_user_pkg
IS

/****************************************************************************************
****************************************************************************************
	SECURITY OVERRIDE FUNCTIONS
****************************************************************************************
****************************************************************************************/

PROCEDURE AddGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	BEGIN
	    INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END; 

PROCEDURE DeleteGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 	
	DELETE FROM security.group_members
     WHERE member_sid_id = in_member_sid and group_sid_id = in_group_sid;
END;

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/


/* INTERNAL ONLY */
PROCEDURE UpdatePasswordResetExpirations 
AS
BEGIN
	-- don't worry about sec checks - this needs to be done anyways
	
	-- get rid of anything that's expired
	DELETE FROM reset_password
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (expiration_dtm < SYSDATE OR
		   (	expiration_dtm < SYSDATE + (1/(24*12)) -- 5 minutes
			AND expiration_grace = chain_pkg.ACTIVE
		   ));
END;

FUNCTION GetPasswordResetUsername (
	in_guid					IN  security_pkg.T_ACT_ID
) RETURN security_pkg.T_SO_NAME
AS
	v_user_name		security_pkg.T_SO_NAME;
BEGIN
	SELECT MIN(csru.user_name)
	  INTO v_user_name
	  FROM reset_password rp
	  JOIN csr.csr_user csru
		ON rp.app_sid = csru.app_sid
	   AND rp.user_sid = csru.csr_user_sid
	 WHERE rp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(rp.guid) = LOWER(in_guid);
	
	RETURN v_user_name;
END;

FUNCTION GetPasswordResetDetails (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_user_sid 			OUT security_pkg.T_SID_ID,
	out_invitation_id 		OUT reset_password.accept_invitation_on_reset%TYPE,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_user_name				security_pkg.T_SO_NAME;
	v_invitation_guid		invitation.guid%TYPE;
BEGIN
	UpdatePasswordResetExpirations;
	
	BEGIN	
		SELECT rp.user_sid, rp.accept_invitation_on_reset, csru.user_name, i.guid 
		  INTO out_user_sid, out_invitation_id, v_user_name, v_invitation_guid
		  FROM reset_password rp, csr.csr_user csru, invitation i
		 WHERE rp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rp.app_sid = csru.app_sid
		   AND rp.user_sid = csru.csr_user_sid
		   AND LOWER(rp.guid) = LOWER(in_guid)
		   AND i.app_sid (+) = rp.app_sid
		   AND i.invitation_id (+) = rp.accept_invitation_on_reset;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			OPEN out_state_cur FOR 
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;
	
	
	OPEN out_state_cur FOR 
		SELECT chain_pkg.GUID_OK guid_state, out_user_sid user_sid, v_user_name user_name, out_invitation_id invitation_id, v_invitation_guid invitation_guid FROM DUAL;
		
	RETURN TRUE;
END;


-- collects a paged cursor of users based on sids passed in as a T_SID_TABLE
PROCEDURE CollectSearchResults (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_all_results			IN  security.T_SID_TABLE,
	in_show_admins			IN  BOOLEAN,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_show_user_companies  IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_filtered_results		security.T_SID_TABLE;
	v_chain_company_users	security.T_SID_TABLE;
	v_temp					security.T_SID_TABLE;
	v_show_admins			NUMBER(1) DEFAULT 0;
	v_user_sid				security_pkg.T_SID_ID;
	v_company_sid_t 		security.T_SID_TABLE;
BEGIN
	IF in_show_admins THEN
		v_show_admins := 1;
	END IF;
	
	IF in_all_results.COUNT = 1 AND csr.csr_user_pkg.IsSuperAdmin(in_all_results(in_all_results.FIRST)) = 1 THEN
		SELECT column_value
		  BULK COLLECT INTO v_filtered_results
		  FROM TABLE(in_all_results);
	ELSE
		SELECT ccu.user_sid 
		  BULK COLLECT INTO v_chain_company_users
		  FROM v$chain_company_user ccu
		 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ccu.company_sid = in_company_sid;
		   
		SELECT TCU.column_value
		  BULK COLLECT INTO v_filtered_results
		  FROM TABLE(v_chain_company_users) TCU, TABLE(in_all_results) T
		 WHERE TCU.column_value = T.column_value;
	END IF;
	
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(v_filtered_results);
	
	-- limit list to one page of results (page size of null or 0 means get all results)
	IF NVL(in_page_size, 0) != 0 THEN
		SELECT user_sid
		  BULK COLLECT INTO v_temp
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT * FROM (
							SELECT cu.user_sid, cu.full_name, CASE WHEN v_show_admins = 1 THEN NVL(ca.user_sid, 0) ELSE 0 END is_admin
							  FROM v$chain_user cu, TABLE(v_filtered_results) T, (
									SELECT app_sid, user_sid 
									  FROM v$company_admin
									 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
									   AND company_sid = in_company_sid
									) ca
							 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
							   AND cu.app_sid = ca.app_sid(+)
							   AND cu.user_sid = T.column_value
							   AND cu.user_sid = ca.user_sid(+)
							)
						 ORDER BY is_admin DESC, LOWER(full_name)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
		v_filtered_results := v_temp;
	END IF;
	
	OPEN out_result_cur FOR 
		SELECT * FROM (
			SELECT cu.*, in_company_sid company_sid, CASE WHEN v_show_admins = 1 THEN NVL(ca.user_sid, 0) ELSE 0 END is_admin, csru.anonymised is_anonymised
			  FROM v$chain_user cu, TABLE(v_filtered_results) T, csr.csr_user csru, (
					SELECT app_sid, user_sid 
					  FROM v$company_admin
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND company_sid = in_company_sid
					) ca
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cu.app_sid = ca.app_sid(+)
			   AND cu.user_sid = T.column_value
			   AND cu.user_sid = ca.user_sid(+)
			   AND csru.csr_user_sid = cu.user_sid
			   AND csru.csr_user_sid = T.column_value
			)
		 ORDER BY is_admin DESC, LOWER(full_name);
	
	OPEN out_role_cur FOR
		SELECT ctr.company_type_id, r.name role_name, ctr.role_sid,
			   ctr.mandatory, ctr.cascade_to_supplier, ctr.pos,
			   rrm.user_sid
		  FROM csr.region_role_member rrm
		  JOIN chain.company_type_role ctr ON rrm.role_sid = ctr.role_sid
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		  JOIN csr.supplier s ON rrm.region_sid = s.region_sid
		  JOIN company c ON s.company_sid = c.company_sid AND ctr.company_type_id = c.company_type_id
		  JOIN TABLE(v_filtered_results) T ON rrm.user_sid = T.column_value
		 WHERE rrm.inherited_from_sid = rrm.region_sid
		   AND s.company_sid = in_company_sid
		 ORDER BY ctr.pos;

	IF in_show_user_companies = 1 THEN
		v_company_sid_t := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ);
		
		OPEN out_companies_cur FOR
			SELECT c.company_sid,
				   CASE WHEN T.column_value IS NULL THEN '' ELSE c.name END name,
				   vcu.user_sid,
				   CASE WHEN T.column_value IS NULL THEN 0 ELSE 1 END is_viewable
			  FROM chain.company_group cug
			  JOIN security.group_members gm ON cug.group_sid = gm.group_sid_id
			  JOIN chain.chain_user vcu
				ON cug.app_sid = vcu.app_sid
			   AND gm.member_sid_id = vcu.user_sid
			   AND vcu.registration_status_id <> 2 -- not rejected 
			   AND vcu.registration_status_id <> 3 -- not merged 
			   AND vcu.deleted = 0
			  JOIN chain.company c ON cug.app_sid = c.app_sid and cug.company_sid = c.company_sid
			  LEFT JOIN (SELECT column_value FROM TABLE(v_company_sid_t) ORDER BY column_value) T ON c.company_sid = T.column_value
			 WHERE c.app_sid = security_pkg.getapp
			   AND c.company_sid <> in_company_sid
			   AND c.deleted = 0
			   AND c.pending = 0
			   AND cug.company_group_type_id= 2 -- users
			   AND cug.group_sid IS NOT NULL;
	ELSE
		OPEN out_companies_cur FOR
			SELECT NULL company_sid, NULL user_sid, 0 is_viewable
			  FROM DUAL
			 WHERE 0 = 1;
	END IF;
END;

/*Check if the email domain falls into the allowed email stubs*/
FUNCTION IsEmailDomainAllowed(
	in_user_sid		IN  security_pkg.T_SID_ID,
	in_company_sid	IN  security_pkg.T_SID_ID,
	in_email_domain	IN  csr.csr_user.email%TYPE
) RETURN NUMBER
AS
  v_is_restricted 	    NUMBER DEFAULT chain.helper_pkg.IsEmailDomainRestricted;
  v_top_company_sid		security_pkg.T_SID_ID DEFAULT chain.helper_pkg.GetTopCompanySid;
  v_count				NUMBER;
BEGIN
	
	IF v_is_restricted = 0 THEN
		RETURN 1;
	END IF;
	
	IF in_company_sid <> v_top_company_sid THEN
		RETURN 1; --allow all domains for the suppliers
	END IF;
	
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM chain.email_stub
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid	
	   AND LOWER(TRIM(stub)) = LOWER(TRIM(in_email_domain));
	   
	RETURN v_count;
END;

PROCEDURE InternalUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE, 
	in_email				IN  csr.csr_user.email%TYPE,
	in_send_alerts 			IN  csr.csr_user.send_alerts%TYPE,
	in_from_user_sid		IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_user_name 			IN  csr.csr_user.user_name%TYPE DEFAULT NULL
)
AS
	v_cur_details			csr.csr_user%ROWTYPE;
	v_old_email				csr.csr_user.email%TYPE;
	v_old_user_name			csr.csr_user.user_name%TYPE;
	v_user_name				csr.csr_user.user_name%TYPE DEFAULT in_user_name;
	v_visibility_id			chain_user.visibility_id%TYPE DEFAULT CASE WHEN helper_pkg.AreVisibilityOptionsEnabled = 0 THEN chain_pkg.FULL ELSE in_visibility_id END;
BEGIN
	SELECT email, user_name
	  INTO v_old_email, v_old_user_name
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;

	IF LOWER(TRIM(in_email)) <> LOWER(TRIM(v_old_email)) THEN
		IF helper_pkg.AllowDuplicateEmails = 0 AND IsEmailUsed(in_email, in_user_sid) = 1 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate e-mail found');
		END IF;

		IF v_user_name IS NULL AND LOWER(TRIM(v_old_user_name)) = LOWER(TRIM(v_old_email)) THEN
			v_user_name := in_email;
		END IF;

		INSERT INTO chain_user_email_address_log(user_sid, email, modified_by_sid)
			VALUES(in_user_sid, v_old_email, in_from_user_sid);
	END IF;
	
	v_user_name := NVL(v_user_name, in_email);

	IF IsUsernameUsed(v_user_name, in_user_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate user name found');
	END IF;

	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> security_pkg.GetAct,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> in_friendly_name,
		in_email					=> in_email,
		in_job_title				=> in_job_title,
		in_phone_number				=> in_phone_number,
		in_active					=> NULL,
		in_info_xml					=> v_cur_details.info_xml,
		in_send_alerts				=> in_send_alerts
	);
	
	UPDATE chain_user
	   SET visibility_id = v_visibility_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid
	   AND v_visibility_id <> -1;
END;

/* Used by API */
PROCEDURE UNSEC_UpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_send_alerts 			IN  csr.csr_user.send_alerts%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE
)
AS
	v_visibility_id			chain_user.visibility_id%TYPE;
BEGIN

	SELECT visibility_id
	  INTO v_visibility_id
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	InternalUpdateUser (
		in_user_sid				=> in_user_sid,
		in_full_name			=> in_full_name,
		in_friendly_name		=> in_friendly_name,
		in_phone_number			=> in_phone_number, 
		in_job_title			=> in_job_title,
		in_visibility_id		=> v_visibility_id,
		in_email				=> in_email,
		in_send_alerts 			=> in_send_alerts,
		in_user_name			=> in_user_name
	);

END;

FUNCTION CreateUserINTERNAL (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_skip_capability_check IN  BOOLEAN
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_rsa					customer_options.default_receive_sched_alerts%TYPE;
	v_top_company_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT in_skip_capability_check AND NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.CREATE_USER)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating users in the company with sid '||in_company_sid);
	END IF;
	
	BEGIN
		-- we call the INTERNAL_ version of this because otherwise we could end up in some kind of 
		-- circular dependency because the "regular" CreateUser function calls the chain stuff.
		-- This stuff all needs a bit more thinking about -- i.e. maybe merging some of the chain
		-- stuff back into core.
		csr.csr_user_pkg.INTERNAL_CreateUser(
			in_act						=> security_pkg.GetAct, 
			in_app_sid					=> security_pkg.GetApp, 
			in_user_name				=> TRIM(in_user_name),
			in_password					=> TRIM(in_password),
			in_full_name				=> TRIM(in_full_name),
			in_friendly_name			=> TRIM(in_friendly_name),
			in_email					=> TRIM(in_email),
			in_job_title				=> NULL,
			in_phone_number				=> NULL,
			in_info_xml					=> NULL,
			in_send_alerts				=> 1,
			in_enable_aria				=> 0,
			in_line_manager_sid			=> NULL,
			in_primary_region_sid		=> NULL,
			in_user_ref					=> NULL,
			in_account_expiry_enabled	=> 1,
			out_user_sid				=> v_user_sid
		);		

		csr.csr_user_pkg.DeactivateUser(security_pkg.GetAct, v_user_sid);

		-- see what the app default for receiving schedualed alerts is
		SELECT default_receive_sched_alerts, top_company_sid
		  INTO v_rsa, v_top_company_sid
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		INSERT INTO chain_user
		(user_sid, visibility_id, registration_status_id, default_company_sid, tmp_is_chain_user, receive_scheduled_alerts)
		VALUES
		(v_user_sid, chain_pkg.NAMEJOBTITLE, chain_pkg.PENDING, in_company_sid, chain_pkg.ACTIVE, v_rsa);
		
		-- Add top company users to "Supply Chain Managers" group if there is one
		-- This is for the case where the top company uses features of the CSR system
		-- and allows them to add users either in chain or in CSR
		IF in_company_sid = v_top_company_sid THEN
			BEGIN
				group_pkg.AddMember(security_pkg.GetAct, v_user_sid,
					securableobject_pkg.GetSidFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Groups/Supply Chain Managers')
				);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					NULL; -- Do nothing
			END;
		END IF;
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.CONFIRM_YOUR_DETAILS,
			in_to_user_sid              => v_user_sid
		);
		
	EXCEPTION
		-- if we've got a dup object name, check to see if they're pending
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			GetUserSid(in_user_name, v_user_sid);
			-- verify that they're pending, otherwise it's a problem
			BEGIN
				SELECT user_sid
				  INTO v_user_sid
				  FROM chain_user
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND registration_status_id = chain_pkg.PENDING
				   AND user_sid = v_user_sid;
			EXCEPTION
				-- if they're not pending, rethrow the error
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'User '||in_user_name||' already exists and is not PENDING');
			END;	
	END;
	
	RETURN v_user_sid;
END;

PROCEDURE UNSEC_SetBusinessUnits (
	in_user_sid						IN	security_pkg.T_SID_ID, 
	in_business_unit_ids			IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_business_unit_ids		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_business_unit_ids);
BEGIN
	-- Permissions is a bit tricky - here we assume that previous calls (e.g. creating/updating the user)
	-- would have triggered the correct security checks
	
	DELETE FROM business_unit_member
	 WHERE user_sid = in_user_sid
	   AND business_unit_id NOT IN (
			SELECT item FROM TABLE(v_business_unit_ids)
	);
	
	IF helper_pkg.NumericArrayEmpty(in_business_unit_ids) = 0 THEN
		FOR i IN in_business_unit_ids.FIRST .. in_business_unit_ids.LAST
		LOOP
			BEGIN
				INSERT INTO business_unit_member (business_unit_id, user_sid, is_primary_bu)
				VALUES (in_business_unit_ids(i), in_user_sid, 1);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					BEGIN
						INSERT INTO business_unit_member (business_unit_id, user_sid)
						VALUES (in_business_unit_ids(i), in_user_sid);
					EXCEPTION
						WHEN DUP_VAL_ON_INDEX THEN
							NULL;
				END;
			END;
		END LOOP;
	END IF;	
END;

/* Only for batch jobs*/
PROCEDURE AddCompanyTypeRoleToUser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddCompanyTypeRoleToUser can be run by BuiltIn Admin only');
	END IF;
	
	UNSEC_AddCompanyTypeRoleToUser(
		in_company_sid		=>	in_company_sid,
		in_user_sid			=>	in_user_sid,
		in_role_sid			=>	in_role_sid
	);
	
END;

PROCEDURE UNSEC_AddCompanyTypeRoleToUser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
)
AS
	v_act					security_pkg.T_ACT_ID;
	v_region_sid			security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetRegionSid(in_company_sid);
	v_cascade_to_supplier	company_type_role.cascade_to_supplier%TYPE;
BEGIN
	
	BEGIN
		SELECT cascade_to_supplier
		  INTO v_cascade_to_supplier
		  FROM company_type_role ctr
		 WHERE ctr.role_sid = in_role_sid
		   AND ctr.company_type_id = company_type_pkg.GetCompanyTypeId(in_company_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--role not applicable for that company
			RETURN;
	END;
	
	BEGIN
		helper_pkg.LogonUCD;
		v_act := security_pkg.getact;
		
		csr.role_pkg.AddRoleMemberForRegion(
			in_act_id		=>v_act, 
			in_role_sid		=>in_role_sid, 
			in_region_sid	=>v_region_sid, 
			in_user_sid 	=>in_user_sid, 
			in_log			=>0, 
			in_force_alter_system_managed => 1
		);
			
		-- cascade role to one level of suppliers
		IF v_cascade_to_supplier = 1 THEN
			
			FOR s IN (
				SELECT s.region_sid
				  FROM supplier_relationship sr
				  JOIN csr.supplier s ON sr.supplier_company_sid = s.company_sid
				  JOIN csr.region r ON r.region_sid = s.region_sid
				 WHERE sr.purchaser_company_sid = in_company_sid
				   AND sr.active = 1
				   AND sr.deleted = 0
				   AND r.active = 1
			) LOOP
				csr.role_pkg.AddRoleMemberForRegion(
					in_act_id		=> v_act, 
					in_role_sid		=> in_role_sid, 
					in_region_sid	=> s.region_sid, 
					in_user_sid 	=> in_user_sid, 
					in_log			=> 0, 
					in_force_alter_system_managed => 1,
					in_inherited_from_sid => v_region_sid --"purchaser" company
				);
			END LOOP;
		END IF;
		
		helper_pkg.RevertLogonUCD;
	EXCEPTION 
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE;
	END;
END;

/* Only for batch jobs*/
PROCEDURE RemoveCompanyTypeRoleFromUser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
)
AS
	v_act					security_pkg.T_ACT_ID;
	v_region_sid			security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetRegionSid(in_company_sid);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RemoveCompanyTypeRoleFromUser can be run by BuiltIn Admin only');
	END IF;
	
	UNSEC_RemoveComTypeRoleFromUsr(
		in_company_sid			=> in_company_sid,
		in_user_sid				=> in_user_sid,
		in_role_sid				=> in_role_sid
	);
	
END;

PROCEDURE UNSEC_RemoveComTypeRoleFromUsr(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
)
AS
	v_act					security_pkg.T_ACT_ID;
	v_region_sid			security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetRegionSid(in_company_sid);
BEGIN
	BEGIN
		helper_pkg.LogonUCD;
		v_act := security_pkg.getact;
	
		--delete RRM inherited from r.region_sid
		csr.role_pkg.DeleteRegionRoleMember(
			in_act_id			=> v_act, 
			in_role_sid			=> in_role_sid, 
			in_region_sid		=> v_region_sid, 
			in_user_sid			=> in_user_sid, 
			in_force_alter_system_managed => 1
		);
		
		helper_pkg.RevertLogonUCD;
	EXCEPTION 
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE;
	END;
END;

PROCEDURE SetCompanyTypeRoles (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sids					IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_act				security_pkg.T_ACT_ID;
	v_role_sids			T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_role_sids);
	v_count				NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting users on company sid '||in_company_sid);
	END IF;
	
	BEGIN
		helper_pkg.LogonUCD;
		v_act := security_pkg.getact;
		
		FOR r IN (
			SELECT ctr.role_sid, s.region_sid, ctr.mandatory, ctr.cascade_to_supplier
			  FROM csr.region_role_member rrm
			  JOIN company_type_role ctr ON rrm.role_sid = ctr.role_sid
			  JOIN csr.supplier s ON s.region_sid = rrm.region_sid
			  JOIN csr.region r ON r.region_sid = s.region_sid
			 WHERE rrm.inherited_from_sid = rrm.region_sid
			   AND rrm.user_sid = in_user_sid
			   AND s.company_sid = in_company_sid
			   AND ctr.company_type_id = company_type_pkg.GetCompanyTypeId(in_company_sid)
			   AND ctr.role_sid NOT IN (SELECT item FROM TABLE(v_role_sids))
			   AND r.active = 1
		) LOOP
			--delete RRM inherited from r.region_sid
			csr.role_pkg.DeleteRegionRoleMember(
				in_act_id			=> v_act, 
				in_role_sid			=> r.role_sid, 
				in_region_sid		=> r.region_sid, 
				in_user_sid			=> in_user_sid,
				in_log				=> 1, 
				in_force_alter_system_managed => 1
			);
			
			IF r.mandatory = 1 THEN
				SELECT COUNT(*)
				  INTO v_count
				  FROM csr.region_role_member
				 WHERE region_sid = r.region_sid
				   AND role_sid = r.role_sid
				   AND inherited_from_sid = r.region_sid;
				   
				IF v_count = 0 THEN
					RAISE_APPLICATION_ERROR(chain_pkg.ERR_MANDATORY_ROLE_EMPTY, 'You cannot remove the last member of a mandatory role');
				END IF;
			END IF;
			
		END LOOP;
	
		FOR r IN (
			SELECT ctr.role_sid, s.region_sid, ctr.cascade_to_supplier
			  FROM (SELECT item FROM TABLE(v_role_sids)) rs
			  JOIN company_type_role ctr ON rs.item = ctr.role_sid
			  JOIN csr.supplier s ON s.company_sid = in_company_sid
			  JOIN csr.region r ON r.region_sid = s.region_sid
			  LEFT JOIN csr.region_role_member rrm
				ON rrm.inherited_from_sid = rrm.region_sid
			   AND rrm.user_sid = in_user_sid
			   AND rrm.region_sid = s.region_sid
			   AND rrm.role_sid = ctr.role_sid
			 WHERE ctr.company_type_id = company_type_pkg.GetCompanyTypeId(in_company_sid)
			   AND rrm.role_sid IS NULL
			   AND r.active = 1
		) LOOP
			csr.role_pkg.AddRoleMemberForRegion(
				in_act_id		=>v_act, 
				in_role_sid		=>r.role_sid, 
				in_region_sid	=>r.region_sid, 
				in_user_sid 	=>in_user_sid, 
				in_log			=> 1, 
				in_force_alter_system_managed => 1
			);
			
			-- cascade role to one level of suppliers
			IF r.cascade_to_supplier = 1 THEN
				
				FOR s IN (
					SELECT s.region_sid
					  FROM supplier_relationship sr
					  JOIN csr.supplier s ON sr.supplier_company_sid = s.company_sid
					  JOIN csr.region r ON r.region_sid = s.region_sid
					 WHERE sr.purchaser_company_sid = in_company_sid
					   AND sr.active = 1
					   AND sr.deleted = 0
					   AND r.active = 1
				) LOOP
					csr.role_pkg.AddRoleMemberForRegion(
						in_act_id		=> v_act, 
						in_role_sid		=> r.role_sid, 
						in_region_sid	=> s.region_sid, 
						in_user_sid 	=> in_user_sid, 
						in_log			=> 0, 
						in_force_alter_system_managed => 1,
						in_inherited_from_sid => r.region_sid --"purchaser" company
					);
									
				END LOOP;
			END IF;
		END LOOP;
		helper_pkg.RevertLogonUCD;
	EXCEPTION 
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE;
	END;
END;

FUNCTION IsLastAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF v_count = 1 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_admin
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;
		   
		IF v_count = 1 THEN
			RETURN 1;
		END IF;
	END IF;
	
	RETURN 0;
END;

FUNCTION IsCompanyAdmin RETURN NUMBER
AS
	v_count					NUMBER(10);
BEGIN	
	RETURN IsCompanyAdmin(
		in_company_sid => company_pkg.GetCompany,
		in_user_sid => security_pkg.GetSid
	);
END;

FUNCTION IsCompanyAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count					NUMBER(10);
BEGIN	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	   
	IF v_count = 1 THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

/************************************************************
	Securable object handlers
************************************************************/


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN

	-- DELETE FROM event_user_status 
	 -- WHERE event_id IN
	-- (
		-- SELECT event_id
		  -- FROM event 
		 -- WHERE ((for_user_sid = in_sid_id) 
		-- OR (related_user_sid = in_sid_id))	
		   -- AND app_sid = security_pkg.GetApp
	-- ) 
	-- AND app_sid = security_pkg.GetApp;	
	
	-- DELETE FROM event_user_status 
	 -- WHERE user_sid = in_sid_id
	   -- AND app_sid = security_pkg.GetApp;	
	   
	-- DELETE FROM event
	 -- WHERE ((for_user_sid = in_sid_id) 
		-- OR (related_user_sid = in_sid_id))	
	   -- AND app_sid = security_pkg.GetApp;	  
	
	
	
	-- -- clean up actions
	-- DELETE FROM action_user_status 
	 -- WHERE action_id IN
	-- (
		-- SELECT action_id
		  -- FROM action 
		 -- WHERE ((for_user_sid = in_sid_id) 
			-- OR (related_user_sid = in_sid_id))	
		   -- AND app_sid = security_pkg.GetApp
	-- ) 
	-- AND app_sid = security_pkg.GetApp;	
	
	-- DELETE FROM action_user_status 	
	 -- WHERE user_sid = in_sid_id
	   -- AND app_sid = security_pkg.GetApp;	
	
	-- DELETE FROM action 
	 -- WHERE ((for_user_sid = in_sid_id) 
		-- OR (related_user_sid = in_sid_id))	
	   -- AND app_sid = security_pkg.GetApp;	
	BEGIN
		FOR r IN (
			SELECT invitation_id, reinvitation_of_invitation_id
			  FROM invitation 
			 WHERE (to_user_sid = in_sid_id 
				OR from_user_sid  = in_sid_id)
			   AND app_sid = security_pkg.GetApp
				ORDER BY invitation_id asc
		)
		LOOP
			UPDATE invitation SET guid = SYS_GUID() WHERE invitation_id = r.invitation_id;
			UPDATE invitation SET reinvitation_of_invitation_id = r.reinvitation_of_invitation_id WHERE reinvitation_of_invitation_id = r.invitation_id;
			DELETE FROM questionnaire_invitation WHERE invitation_id = r.invitation_id AND app_sid = security_pkg.GetApp;
			DELETE FROM invitation_qnr_type WHERE invitation_id = r.invitation_id AND app_sid = security_pkg.GetApp;
			DELETE FROM invitation WHERE invitation_id = r.invitation_id AND app_sid = security_pkg.GetApp;
		END LOOP;
	END;

    -- DELETE FROM chain.alert_entry_named_param WHERE alert_entry_id IN (
        -- SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            -- SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            -- SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id 
    -- );
    -- DELETE FROM chain.alert_entry_ordered_param WHERE alert_entry_id IN (
        -- SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            -- SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            -- SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    -- );
    -- DELETE FROM chain.alert_entry_action WHERE user_sid=in_sid_id;
    -- DELETE FROM chain.alert_entry_action WHERE action_id IN (
        -- SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
            -- UNION
        -- SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            -- SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            -- SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    -- );
    -- DELETE FROM chain.alert_entry_event WHERE user_sid=in_sid_id;
    -- DELETE FROM chain.alert_entry_event WHERE event_id IN (
        -- SELECT event_id FROM chain.event WHERE for_user_sid=in_sid_id
            -- UNION
        -- SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            -- SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            -- SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        -- ) UNION
        -- SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    -- );
	
   UPDATE invitation 
      SET cancelled_by_user_sid = NULL
    WHERE cancelled_by_user_sid = in_sid_id 
	  AND app_sid = security_pkg.GetApp;
	
	DELETE FROM message_recipient
	 WHERE app_sid = security_pkg.GetApp
	   AND recipient_id IN (SELECT recipient_id FROM recipient WHERE to_user_sid = in_sid_id AND app_sid = security_pkg.GetApp);
	
	DELETE FROM recipient
	 WHERE to_user_sid = in_sid_id 
	  AND app_sid = security_pkg.GetApp;
	
	DELETE FROM purchaser_follower
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM supplier_follower
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM message_recipient
	 WHERE app_sid = security_pkg.GetApp
	   AND message_id IN (SELECT message_id FROM message WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id) AND app_sid = security_pkg.GetApp);
	
	DELETE FROM message_refresh_log
	 WHERE app_sid = security_pkg.GetApp
	   AND (refresh_user_sid = in_sid_id 
	    OR message_id IN (SELECT message_id FROM message WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id) AND app_sid = security_pkg.GetApp));
	
	DELETE FROM user_message_log
	 WHERE app_sid = security_pkg.GetApp
	   AND (user_sid = in_sid_id
	    OR message_id IN (SELECT message_id FROM message WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id) AND app_sid = security_pkg.GetApp));
	
	-- A bit harsh? Fine for clearing out test users, we have soft delete for real users
	DELETE FROM message
	 WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM purchased_component
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	FOR r IN (
		SELECT product_id 
		  FROM v$product_last_revision
		 WHERE app_sid = security_pkg.GetApp
			AND (validated_root_component_id IN (
				SELECT component_id 
				  FROM component 
				 WHERE app_sid = security_pkg.GetApp 
				   AND created_by_sid = in_sid_id
			   )
			 OR supplier_root_component_id IN (
				SELECT component_id 
				  FROM component 
				 WHERE app_sid = security_pkg.GetApp 
				   AND created_by_sid = in_sid_id
				)
			)
		)
	LOOP
		chain_link_pkg.KillProduct(r.product_id);
		
		/* Purchased component belongs to the purchaser so we only break the association with the supplier */
		UPDATE purchased_component
		   SET supplier_product_id = NULL
		 WHERE app_sid = security_pkg.GetApp
		   AND supplier_product_id = r.product_id;
		
		DELETE FROM product_revision
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = r.product_id;
		
		DELETE FROM product
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = r.product_id;
	END LOOP;
		
	DELETE FROM purchased_component
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM component_document
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	   	
	DELETE FROM component_tag
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM component
	 WHERE app_sid = security_pkg.GetApp
	   AND created_by_sid = in_sid_id;
	
	DELETE FROM qnr_share_log_entry
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_sid_id;
	
	DELETE FROM qnr_status_log_entry
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_sid_id;
	
	DELETE FROM filter_field WHERE filter_id IN (
		 SELECT filter_id FROM filter WHERE compound_filter_id IN (
			SELECT compound_filter_id FROM compound_filter WHERE created_by_user_sid = in_sid_id
		)
	);
	
	DELETE FROM filter WHERE compound_filter_id IN (
		SELECT compound_filter_id FROM compound_filter WHERE created_by_user_sid = in_sid_id
	);
	
	DELETE FROM compound_filter WHERE created_by_user_sid = in_sid_id;
	
	-- can't set modified_by_sid to SID_BUILTIN_ADMINISTRATOR
	DELETE FROM chain_user_email_address_log
	 WHERE app_sid = security_pkg.GetApp
	   AND modified_by_sid = in_sid_id;

	DELETE FROM chain_user_email_address_log
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_sid_id;
	
	DELETE FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_sid_id;
	
	BEGIN
		csr.csr_user_pkg.DeleteUser(security_pkg.GetAct, in_sid_id);
	EXCEPTION
		WHEN OTHERS THEN --sometimes the user doesn't exist in csr, just skip csr delete then
			NULL;
	END;
END;

/****************************************************************************************
****************************************************************************************
	PUBLIC 
****************************************************************************************
****************************************************************************************/



FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN CreateUserINTERNAL(in_company_sid, in_email, in_full_name, NULL, in_friendly_name, in_email, TRUE);
END;

FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	-- Allow setting of UserName for stub registrations
	RETURN CreateUserINTERNAL(in_company_sid, in_user_name, in_full_name, NULL, in_friendly_name, in_email, TRUE);
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE DEFAULT chain_pkg.FULL
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT CreateUser(in_company_sid, in_user_name, in_full_name, NULL, in_friendly_name, in_email);
BEGIN
	InternalUpdateUser(
		in_user_sid			=> v_user_sid,
		in_full_name		=> in_full_name,
		in_friendly_name	=> in_friendly_name,
		in_phone_number		=> in_phone_number,
		in_job_title		=> in_job_title,
		in_visibility_id	=> in_visibility_id,
		in_email			=> in_email,
		in_send_alerts 		=> 1,
		in_user_name 		=> in_user_name
	);
	RETURN v_user_sid;
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT CreateUser(in_company_sid, in_full_name, NULL, in_friendly_name, in_email);
BEGIN
	InternalUpdateUser(
		in_user_sid			=> v_user_sid,
		in_full_name		=> in_full_name,
		in_friendly_name	=> in_friendly_name,
		in_phone_number		=> in_phone_number,
		in_job_title		=> in_job_title,
		in_visibility_id	=> in_visibility_id,
		in_email			=> in_email,
		in_send_alerts 		=> 1
	);
	RETURN v_user_sid;
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	-- normal chain behaviour - email is username
	RETURN CreateUser(in_company_sid, in_email, in_full_name, in_password, in_friendly_name, in_email);
END;
	
FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN	
	RETURN CreateUserINTERNAL(in_company_sid, in_user_name, in_full_name, in_password, in_friendly_name, in_email, FALSE);
END;

FUNCTION CreateUserFromApi (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_send_alerts			IN  NUMBER
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	v_user_sid := CreateUserINTERNAL(in_company_sid, in_user_name, in_full_name, NULL, in_friendly_name, in_email, TRUE);
	InternalUpdateUser(v_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, chain_pkg.FULL, in_email, 1);
	RETURN v_user_sid;
END;

PROCEDURE SetMergedStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_merged_to_user_sid	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- sec checks handled by delete user
	IF in_user_sid = in_merged_to_user_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging a user with themselves');
	ELSE
		
		IF GetRegistrationStatus(in_merged_to_user_sid) != chain_pkg.REGISTERED THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging to the user with sid '||in_merged_to_user_sid||' - they are not a registered user');
		END IF;
		
		IF GetRegistrationStatus(in_user_sid) != chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging the user with sid '||in_user_sid||' - they are not pending registration');
		END IF;
	END IF;
	
	UPDATE chain_user
	   SET registration_status_id = chain_pkg.MERGED,
		   merged_to_user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

	DeleteUser(in_user_sid);
	
	UPDATE supplier_follower
	   SET user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	UPDATE purchaser_follower
	   SET user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

	UPDATE message
	   SET re_user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND re_user_sid = in_user_sid;
	
	-- TOOD: merge message recipients?
END;

FUNCTION IsUserMarkedAsDeleted(
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_deleted NUMBER;
BEGIN
	SELECT deleted
	  INTO v_deleted 
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	   
	RETURN v_deleted;
END;

PROCEDURE DeleteUser (
	in_act					IN	security_pkg.T_ACT_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- sec check handled in csr_user_pkg.DeleteUser 
	
	UPDATE chain_user
	   SET deleted = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	csr.csr_user_pkg.DeleteUser(in_act, in_user_sid);
END;

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteUser(security_pkg.GetAct, in_user_sid);
END;

PROCEDURE SetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_status				IN  chain_pkg.T_REGISTRATION_STATUS,
	in_force_pending		IN  NUMBER DEFAULT 0
)
AS
	v_cur_status	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	
	IF in_status = chain_pkg.MERGED THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged status must be set using SetMergedStatus');
	END IF;
	
	-- get the current status
	SELECT registration_status_id
	  INTO v_cur_status
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	-- if the status isn't changing, get out
	IF in_status = v_cur_status THEN
		RETURN;
	END IF;
	
	IF in_status = chain_pkg.PENDING AND in_force_pending = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot revert a user status to pending');
	END IF;
	
	IF in_status = chain_pkg.REJECTED THEN
		IF v_cur_status <> chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied setting status to rejected when the current status is not pending (on user with sid'||in_user_sid||')');
		END IF;
		
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_DELETE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting the user with sid '||in_user_sid);
		END IF;

		DeleteUser(in_user_sid);
	END IF;
	
	IF in_status = chain_pkg.REGISTERED THEN
		IF v_cur_status <> chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied setting status to registered when the current status is not pending (on user with sid'||in_user_sid||')');
		END IF;
	END IF;
	
	
	-- finally, set the new status
	UPDATE chain_user
	   SET registration_status_id = in_status
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

END;

PROCEDURE AddUserToCompany_UNSEC (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_force_admin 			IN NUMBER DEFAULT 1
)
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN

	AddGroupMember(in_user_sid, v_pending_sid);
	
	-- URG!!!! we'll make them full users straight away for now...
	ApproveUser(in_company_sid, in_user_sid);
	
	-- if we don't have an admin user, this user will go straight to the top
	IF in_force_admin = 1 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_admin
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;

		IF v_count = 0 THEN
			MakeAdmin(in_company_sid, in_user_sid);
			
			-- likewise for any mandatory roles
			FOR r IN (
				SELECT ctr.role_sid, s.region_sid
				  FROM company_type_role ctr
				  JOIN company c ON ctr.company_type_id = c.company_type_id
				  JOIN csr.supplier s On c.company_sid = s.company_sid
				 WHERE c.company_sid = in_company_sid
				   AND ctr.mandatory = 1
				   AND s.region_sid IS NOT NULL
			) LOOP
				csr.role_pkg.AddRoleMemberForRegion(
					in_act_id		=> security_pkg.GetAct, 
					in_role_sid		=> r.role_sid, 
					in_region_sid	=> r.region_sid, 
					in_user_sid 	=> in_user_sid, 
					in_log			=> 0, 
					in_force_alter_system_managed => 1
				);
							
			END LOOP;
		END IF;
	END IF;
	
	chain_link_pkg.AddCompanyUser(in_company_sid, in_user_sid);
END;

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ADD_USER_TO_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding users on company sid '||in_company_sid);
	END IF;
	
	AddUserToCompany_UNSEC(in_company_sid, in_user_sid);
END;

PROCEDURE RemoveUserFromCompany (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('COMPANY', 'CHAIN_COMPANY'),
	in_remove_last_admin	IN	NUMBER DEFAULT 0
)
AS
	v_is_admin				NUMBER(1) DEFAULT IsCompanyAdmin(in_company_sid, in_user_sid);
	v_admin_removed			NUMBER(1) DEFAULT 0;
BEGIN

	IF in_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'You cannot remove yourself from company sid '||in_company_sid);
	END IF;
	
	IF NOT ((v_is_admin = 1 AND capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER)) OR v_is_admin = 0)
		OR NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.REMOVE_USER_FROM_COMPANY) THEN
		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied removing users from company sid '||in_company_sid);
	END IF;
	
	IF v_is_admin = 1 THEN
		v_admin_removed := RemoveAdmin(in_company_sid, in_user_sid, in_remove_last_admin);
		IF v_admin_removed = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'You cannot remove user from admin group for company sid '||in_company_sid);
		END IF;
	END IF;
	
	UNSEC_RemoveUserFromCompany (
		in_user_sid				=> in_user_sid,
		in_company_sid			=> in_company_sid,
		in_remove_last_admin	=> in_remove_last_admin
	);
	
END;

PROCEDURE UNSEC_RemoveUserFromCompany (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('COMPANY', 'CHAIN_COMPANY'),
	in_remove_last_admin	IN	NUMBER DEFAULT 0
)
AS
	v_user_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain.chain_pkg.USER_GROUP);
BEGIN

	DeleteGroupMember(in_user_sid, v_user_sid);
	
	-- remove any roles from company_type
	FOR r IN (
		SELECT ctr.role_sid, s.region_sid
		  FROM company_type_role ctr
		  JOIN company c ON ctr.company_type_id = c.company_type_id
		  JOIN csr.supplier s On c.company_sid = s.company_sid
		  JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid AND ctr.role_sid = rrm.role_sid
		 WHERE c.company_sid = in_company_sid
		   AND rrm.user_sid = in_user_sid
		   AND rrm.inherited_from_sid = rrm.region_sid
	) LOOP
		csr.role_pkg.UNSEC_DeleteRegionRoleMember(
			in_act_id			=> security_pkg.GetAct, 
			in_role_sid			=> r.role_sid, 
			in_region_sid		=> r.region_sid, 
			in_user_sid			=> in_user_sid
		);
	END LOOP;
	
	chain_link_pkg.RemoveUserFromCompany(in_user_sid, in_company_sid);
END;

PROCEDURE SetVisibility (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_visibility			IN  chain_pkg.T_VISIBILITY
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the user with sid '||in_user_sid);
	END IF;
	
	BEGIN
		INSERT INTO chain_user
		(user_sid, visibility_id, registration_status_id)
		VALUES
		(in_user_sid, in_visibility, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain_user
			   SET visibility_id = in_visibility
			 WHERE app_sid =  security_pkg.GetApp
			   AND user_sid = in_user_sid;
	END;		
END;

PROCEDURE GetUserSid (
	in_user_name			IN  security_pkg.T_SO_NAME,
	out_user_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	out_user_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/'||in_user_name);
	-- we're probably getting the sid to do something with them - make sure they're in chain
	helper_pkg.AddUserToChain(out_user_sid);
END;

PROCEDURE SearchAllCompanyUsers ( 
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
	v_role_cur				security_pkg.T_OUTPUT_CUR;
	v_companies_cur 		security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchAllCompanyUsers(0, 0, in_search_term, in_show_inactive, 0, v_count_cur, out_result_cur, v_role_cur, v_companies_cur);
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
	v_role_cur				security_pkg.T_OUTPUT_CUR;
	v_companies_cur 		security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanyUsers(in_company_sid, 0, 0, in_search_term, in_show_inactive, 0, v_count_cur, out_result_cur, v_role_cur, v_companies_cur);
END;

PROCEDURE GetRegisteredUsers (
	in_company_sid			IN security_pkg.T_SID_ID,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results				security.T_SID_TABLE;
	v_show_admins			BOOLEAN := false;
	v_count_cur				security_pkg.T_OUTPUT_CUR;
	v_role_cur				security_pkg.T_OUTPUT_CUR;
	v_companies_cur			security_pkg.T_OUTPUT_CUR;
	v_supplier_relationship	NUMBER;
BEGIN
	-- are they my supplier
	SELECT COUNT(*) INTO v_supplier_relationship 
	  FROM v$supplier_relationship
	 WHERE supplier_company_sid = in_company_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	--  1 Is this my company
	--  2 Is this a supplier (e.g. they have accepted an invitation from my company)
	IF  (v_supplier_relationship = 0) AND (in_company_sid != SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
				
	-- bulk collect user sid's that match our search result
	SELECT user_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT ccu.user_sid
		  FROM v$chain_company_user ccu
		  JOIN v$chain_user cu ON cu.user_sid = ccu.user_sid and cu.app_sid = ccu.app_sid
		 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND ccu.company_sid = in_company_sid
		   AND cu.registration_status_id = chain_pkg.ACTIVE
	  );
	
	CollectSearchResults(in_company_sid, v_results, v_show_admins, 0, 0, 0, v_count_cur, out_result_cur, v_role_cur, v_companies_cur);
END;

FUNCTION IsRegisteredUserForCompany (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_supplier_relationship	NUMBER;
	v_ret NUMBER;
BEGIN

	-- if we're looking at a supplier, but they aren't active - this can't be a reg user for them
	IF((in_company_sid != SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) AND (company_pkg.GetSupplierRelationshipStatus(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_company_sid) != chain_pkg.ACTIVE)) THEN 
		RETURN 0;
	END IF;
	
	-- if they're not a member of the company at all can't be a reg user
	IF NOT(company_pkg.IsMember(in_company_sid, in_user_sid)) THEN
		RETURN 0;
	END IF;
				
	-- I don't think this could ever be anything but 0 or 1 but decode ensures it
	SELECT DECODE(COUNT(*), 0, 0, 1) INTO v_ret
	  FROM v$chain_company_user ccu
	  JOIN v$chain_user cu ON cu.user_sid = ccu.user_sid and cu.app_sid = ccu.app_sid
	 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND ccu.company_sid = in_company_sid
	   AND ccu.user_sid = in_user_sid
	   AND cu.registration_status_id = chain_pkg.ACTIVE;
	   
	RETURN v_ret;
END;

/* Can't use CollectSearchResults because it uses internally v$chain_company_user which restricts the results to related companies*/
PROCEDURE SearchSupplierUsersNoRelation(
	in_supplier_sid			IN security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_show_user_companies  IN  NUMBER DEFAULT 0,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_results		security.T_SID_TABLE;
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_company_sid	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_sid_t security.T_SID_TABLE;
BEGIN
		
	/* Do I have NO_RELATIONSHIP read access to this company */
	IF NOT type_capability_pkg.CheckNoRelationshipPermission(v_company_sid, in_supplier_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Company with sid ' || v_company_sid || 'does not have NO_RELATIONSHIP permissions to company with sid '|| in_supplier_sid);
	END IF;
	
	-- bulk collect user sid's that match our search result
	SELECT user_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT user_sid
		  FROM v$company_user --we do not want the restrictions of v$chain_company_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND company_sid = in_supplier_sid
		   AND (LOWER(user_name) LIKE v_search OR
				LOWER(full_name) LIKE v_search OR
				LOWER(email) LIKE v_search OR
				LOWER(job_title) LIKE v_search)
		   AND (in_show_inactive = 1 OR account_enabled = 1)
	  );
	--todo: show admins? 
	  
	--page the results
	OPEN out_result_cur FOR
		SELECT * 
		  FROM ( 
			SELECT cu.*, in_supplier_sid company_sid, 0 is_admin, ROWNUM r  --todo: hardcoded is admin?
			  FROM TABLE(v_results) t
			  JOIN v$chain_user cu ON t.column_value = cu.user_sid
			) usr
		  WHERE r >= (in_page - 1) * in_page_size + 1 
		    AND r < in_page * in_page_size + 1;
	  
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(v_results);
	
	
	-- Return no information about roles if search withot a relation?
	OPEN out_role_cur FOR
		SELECT null ompany_type_id, null  role_name, null role_sid,
			   null mandatory, null cascade_to_supplier, null css_class,
			   null user_sid
		  FROM dual
		 WHERE 1=0;

	IF in_show_user_companies = 1 THEN
		v_company_sid_t := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ);

		OPEN out_companies_cur FOR
			SELECT cu.company_sid,
				   CASE WHEN T.column_value IS NULL THEN '' ELSE c.name END name,
				   cu.user_sid,
				   CASE WHEN T.column_value IS NULL THEN 0 ELSE 1 END IsViewable
			  FROM chain.v$company_user cu
			  JOIN chain.company c ON cu.company_sid = c.company_sid
		 LEFT JOIN TABLE(v_company_sid_t) T ON cu.company_sid = T.column_value
			 WHERE cu.company_sid <> in_supplier_sid
			   AND c.deleted = 0
			   AND c.pending = 0;
	ELSE
		OPEN out_companies_cur FOR
			SELECT 0 FROM DUAL;
	END IF;
END;

PROCEDURE SearchNonFollowerUsers(
	in_supplier_sid			IN security_pkg.T_SID_ID,
	in_search_term  		IN varchar2,
	in_include_inactive		IN	NUMBER DEFAULT 0,
	in_exclude_user_sids	IN  security_pkg.T_SID_IDS,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_total_num_users		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_user_sids_t		security.T_SID_TABLE;
	v_search			VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_exclude_user_sids	security.T_SID_TABLE;
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on users of company with sid '||v_company_sid);
	END IF;
	
	v_exclude_user_sids := security_pkg.SidArrayToTable(in_exclude_user_sids);
	
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids_t
	  FROM (
		SELECT DISTINCT user_sid
		  FROM v$company_user cu
		 WHERE app_sid = security_pkg.getApp
		   AND (cu.account_enabled = 1 OR in_include_inactive = 1)
		   AND cu.company_sid = v_company_sid
		   AND NOT EXISTS (
				SELECT 1 
				  FROM supplier_follower sf
				 WHERE sf.user_sid = cu.user_sid
				   AND sf.purchaser_company_sid = v_company_sid
				   AND sf.supplier_company_sid = in_supplier_sid
		   )
		   AND (LOWER(user_name) LIKE v_search OR
				LOWER(full_name) LIKE v_search OR
				LOWER(email) LIKE v_search OR
				LOWER(job_title) LIKE v_search)
		   AND cu.user_sid NOT IN (SELECT column_value FROM TABLE(v_exclude_user_sids))
		);
	 
	OPEN out_result_cur FOR
		SELECT user_sid user_sid, user_sid csr_user_sid, email, user_name, full_name, friendly_name, phone_number, job_title, account_enabled
		  FROM (
			SELECT cu.user_sid, cu.email, cu.user_name, cu.full_name, cu.friendly_name, cu.phone_number, cu.job_title, cu.account_enabled
			  FROM TABLE(v_user_sids_t) t
			  JOIN v$chain_user cu on cu.user_sid = t.column_value AND cu.app_sid = security_pkg.getApp
			  ORDER BY lower(cu.full_name)
			)
		 WHERE rownum <= csr.csr_user_pkg.MAX_USERS; --keep it consistent with the csr_user
	
	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, csr.csr_user_pkg.MAX_USERS max_size
		  FROM TABLE(v_user_sids_t);
END;

PROCEDURE SearchUsersToAddToCompany(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_search_term  		IN	VARCHAR2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_total_num_users		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_perm_comp_t				security.T_SID_TABLE; --permissible companies for ADD_USER_TO_COMPANY
	v_user_sids_t				security.T_SID_TABLE;
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_show_email				NUMBER;
	v_show_user_name			NUMBER;
	v_show_user_ref				NUMBER;
BEGIN
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		IF NOT capability_pkg.CheckCapability(chain_pkg.ADD_USER_TO_COMPANY) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied for adding users to context company with sid:'|| in_company_sid);
		END IF;
		--get all permissible to ADD_USER_TO_COMPANY companies
		v_perm_comp_t := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.ADD_USER_TO_COMPANY);
	ELSE 
		--do we have the capability against the company?
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ADD_USER_TO_COMPANY) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied for adding users to company with sid:'|| in_company_sid);
		END IF;
				
		v_perm_comp_t := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.ADD_USER_TO_COMPANY);
		--check whether we should include our own company
		IF capability_pkg.CheckCapability(chain_pkg.ADD_USER_TO_COMPANY) THEN
			v_perm_comp_t.extend;
			v_perm_comp_t(v_perm_comp_t.COUNT) := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		END IF;
	END IF;
	
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids_t
	  FROM (
		SELECT DISTINCT cu.user_sid
		  FROM v$company_user cu
		  JOIN TABLE(v_perm_comp_t) t ON t.column_value = cu.company_sid
		 WHERE app_sid = v_app_sid
		   AND cu.account_enabled = 1
		   AND NOT EXISTS (
				SELECT 1 
				  FROM v$company_user ccu
				 WHERE ccu.app_sid = v_app_sid
				   AND ccu.user_sid = cu.user_sid
				   AND ccu.company_sid = in_company_sid
		   )
		   AND (LOWER(cu.user_name) LIKE v_search OR
				LOWER(cu.full_name) LIKE v_search OR
				LOWER(cu.email) LIKE v_search OR
				LOWER(cu.user_ref) LIKE v_search OR
				LOWER(cu.job_title) LIKE v_search)
		);

	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM csr.customer
	 WHERE app_sid = v_app_sid;		
		
	OPEN out_result_cur FOR
		SELECT user_sid sid, user_sid csr_user_sid, user_sid, full_name, email, user_name, user_ref, account_enabled,
			   v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
		  FROM (
			SELECT cu.user_sid, cu.full_name, cu.email, cu.user_name, cu.user_ref, cu.account_enabled
			  FROM TABLE(v_user_sids_t) t
			  JOIN v$chain_user cu on cu.user_sid = t.column_value AND cu.app_sid = v_app_sid
			  ORDER BY lower(cu.full_name)
			)
		 WHERE rownum <= csr.csr_user_pkg.MAX_USERS; --keep it consistent with the csr_user
	
	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, csr.csr_user_pkg.MAX_USERS max_size
		  FROM TABLE(v_user_sids_t);
		 
END;


PROCEDURE SearchAllCompanyUsers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_show_user_companies  IN  NUMBER DEFAULT 0,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE;
	v_show_admins			BOOLEAN := false;
	v_supplier_relationship	NUMBER;
	v_can_see_all_companies	company.can_see_all_companies%TYPE;	
	v_viewable_company_sids	security.T_SID_TABLE := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ);
BEGIN

			
	-- bulk collect user sid's that match our search result
	SELECT distinct user_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT user_sid
		  FROM v$chain_company_user ccu
		  JOIN TABLE(v_viewable_company_sids) vis ON vis.column_value = ccu.company_sid
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND (LOWER(user_name) LIKE v_search OR
				LOWER(full_name) LIKE v_search OR
				LOWER(email) LIKE v_search OR
				LOWER(job_title) LIKE v_search)
		   AND (in_show_inactive = 1 OR account_enabled = 1)
	  );

	--page the results
	OPEN out_result_cur FOR
		SELECT * 
		  FROM ( 
			SELECT cu.*, 0 company_sid, 0 is_admin, ROWNUM r  --todo: hardcoded is admin?
			  FROM TABLE(v_results) t
			  JOIN v$chain_user cu ON t.column_value = cu.user_sid
			) usr
		  WHERE (r >= (in_page - 1) * in_page_size + 1
		    AND r < in_page * in_page_size + 1)
			 OR in_page_size = 0;

	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
		  FROM TABLE(v_results);

	-- Return no information about roles if search withot a relation?
	OPEN out_role_cur FOR
		SELECT null ompany_type_id, null  role_name, null role_sid,
			   null mandatory, null cascade_to_supplier, null css_class,
			   null user_sid
		  FROM dual
		 WHERE 1=0;

	IF in_show_user_companies = 1 THEN
		OPEN out_companies_cur FOR
			SELECT cu.company_sid,
				   CASE WHEN T.column_value IS NULL THEN '' ELSE c.name END name,
				   cu.user_sid,
				   CASE WHEN T.column_value IS NULL THEN 0 ELSE 1 END IsViewable
			  FROM chain.v$company_user cu
			  JOIN chain.company c ON cu.company_sid = c.company_sid
		 LEFT JOIN TABLE(v_viewable_company_sids) T ON cu.company_sid = T.column_value
			   AND c.deleted = 0
			   AND c.pending = 0;
	ELSE
		OPEN out_companies_cur FOR
			SELECT 0 FROM DUAL;
	END IF;
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_search_term  		IN  VARCHAR2,
	out_filtered_t			OUT csr.T_USER_FILTER_TABLE,
	out_show_admins			OUT BOOLEAN
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_supplier_relationship	NUMBER;
	v_can_see_all_companies	company.can_see_all_companies%TYPE;
BEGIN
	out_show_admins := FALSE;
	
	-- Does my company have a relationship with this supplier and what sort of relationship?
	--  1 Is this my company
	--  2 Is this a supplier (e.g. they have accepted an invitation from my company)
	--  3 Is this a company I have invited but they've not responded (e.g. they may or not have accepted an invite from another company but they have never accepted an invire from my company)
	--  In case 1 or 2 then do normal capability check and look in the chain_company_user view
	--  In case 3 then only show users who have been invited by my company if any (as I have knowledge of them) not other users (as this is a potential data leak
	
	-- are they my supplier --only our related suppliers
	SELECT COUNT(*)
	  INTO v_supplier_relationship 
	  FROM v$supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = in_company_sid
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	   
	--  1 Is this my company
	--  2 Is this a supplier (e.g. they have accepted an invitation from my company)
	IF  (v_supplier_relationship > 0) OR (v_can_see_all_companies=1) OR (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) THEN 
		
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ)  THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on users of company with sid '||in_company_sid);
		END IF;
				
		-- bulk collect user sid's that match our search result
		SELECT csr.T_USER_FILTER_ROW(user_sid, account_enabled, NULL)
		  BULK COLLECT INTO out_filtered_t
		  FROM (
			SELECT user_sid, account_enabled
			  FROM v$chain_company_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND company_sid = in_company_sid
			   AND (LOWER(user_name) LIKE v_search OR
			   	    LOWER(full_name) LIKE v_search OR
					LOWER(email) LIKE v_search OR
					LOWER(job_title) LIKE v_search)
			   AND (in_show_inactive = 1 OR account_enabled = 1)
		  );
		
		out_show_admins := (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) OR (capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ));
	ELSE
	
		-- just pull back the users that my company have invited
		-- ignore any invites that are 
		--		accepted (we shouldn't be here if the company has accepted anyway) 
		-- 		rejected (don't make it "normal" to invite someone again who has rejected an invite)
		-- ?? Why are we ignoring the seach bits?
		SELECT csr.T_USER_FILTER_ROW(to_user_sid, NULL, NULL)
		  BULK COLLECT INTO out_filtered_t
		  FROM (
			SELECT DISTINCT to_user_sid 
			  FROM invitation i
			 WHERE to_company_sid = in_company_sid
			   AND from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED, chain_pkg.CANCELLED)
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		);
		
	END IF;
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_show_user_companies  IN  NUMBER DEFAULT 0,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
)
AS	
	v_filtered_t			csr.T_USER_FILTER_TABLE;
	v_results				security.T_SID_TABLE;
	v_show_admins			BOOLEAN;
BEGIN
	SearchCompanyUsers ( 
		in_company_sid		=> in_company_sid, 
		in_search_term		=> in_search_term,
		in_show_inactive 	=> in_show_inactive, 
		out_filtered_t		=> v_filtered_t,
		out_show_admins		=> v_show_admins
	);
	
	SELECT csr_user_sid	 
	  BULK COLLECT INTO v_results
	  FROM TABLE(v_filtered_t);
	  
	CollectSearchResults(in_company_sid, v_results, v_show_admins, in_page, in_page_size, in_show_user_companies, out_count_cur, out_result_cur, out_role_cur, out_companies_cur);
END;

PROCEDURE SearchSupplierFollowers (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_results				security.T_SID_TABLE;
	v_role_cur				security_pkg.T_OUTPUT_CUR;
	v_companies_cur 		security_pkg.T_OUTPUT_CUR;
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_supplier_sid);
	END IF;
	
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on user of company with sid '||in_supplier_sid);
	END IF;

	SELECT sf.user_sid
	  BULK COLLECT INTO v_results
	  FROM supplier_follower sf, v$supplier_relationship sr, v$chain_user cu
	 WHERE sf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sf.app_sid = sr.app_sid
	   AND sf.app_sid = cu.app_sid
	   AND sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sf.purchaser_company_sid = sr.purchaser_company_sid
	   AND sf.supplier_company_sid = in_supplier_sid
	   AND sf.supplier_company_sid = sr.supplier_company_sid
	   AND sf.user_sid = cu.user_sid
	   AND (LOWER(user_name) LIKE v_search OR
			LOWER(full_name) LIKE v_search OR
			LOWER(email) LIKE v_search OR
			LOWER(job_title) LIKE v_search);
	
	CollectSearchResults(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_results, FALSE, in_page, in_page_size, 0, out_count_cur, out_result_cur, v_role_cur, v_companies_cur);
END;

PROCEDURE GetPrimarySupplierFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results				security.T_SID_TABLE;
	v_count_cur				security_pkg.T_OUTPUT_CUR;
	v_role_cur				security_pkg.T_OUTPUT_CUR;
	v_companies_cur			security_pkg.T_OUTPUT_CUR;
BEGIN

	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_supplier_sid);
	END IF;
	
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on user of company with sid '||in_supplier_sid);
	END IF;

	SELECT sf.user_sid
	  BULK COLLECT INTO v_results
	  FROM supplier_follower sf, v$supplier_relationship sr
	 WHERE sf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sf.app_sid = sr.app_sid
	   AND sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sf.purchaser_company_sid = sr.purchaser_company_sid
	   AND sf.supplier_company_sid = in_supplier_sid
	   AND sf.supplier_company_sid = sr.supplier_company_sid
	   AND sf.is_primary = 1;
	   
	CollectSearchResults(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_results, FALSE, NULL, NULL, 0, v_count_cur, out_cur, v_role_cur, v_companies_cur);
END;

FUNCTION GetPrimarySupplierFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_supplier_sid);
	END IF;

	BEGIN
		SELECT sf.user_sid
		  INTO v_user_sid
		  FROM supplier_follower sf, v$supplier_relationship sr
		 WHERE sf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND sf.app_sid = sr.app_sid
		   AND sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sf.purchaser_company_sid = sr.purchaser_company_sid
		   AND sf.supplier_company_sid = in_supplier_sid
		   AND sf.supplier_company_sid = sr.supplier_company_sid
		   AND sf.is_primary = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;	   
	
END;

PROCEDURE SetPrimarySupplierFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_relationship_active	NUMBER;
BEGIN
	
	-- I am allowed to change the primary supplier follower if:
	--       the supplier company is not deleted
	--   AND the relationship is active
	--   AND (   I am the current supplier follower
	--        OR I have permission on the change supplier follower capability)
	IF  NOT UserIsPrimaryFollower(in_supplier_sid, SYS_CONTEXT('SECURITY', 'SID'))
	AND NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.CHANGE_SUPPLIER_FOLLOWER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied changing the primary supplier follower for the company with sid '||in_supplier_sid);
	END IF;
	
	-- check that the supplier relationship and company are both valid (active, not deleted)
	SELECT COUNT(*)
	  INTO v_relationship_active
	  FROM v$supplier_relationship sr, v$company c
	 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sr.app_sid = c.app_sid
	   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.supplier_company_sid = in_supplier_sid
	   AND sr.supplier_company_sid = c.company_sid;

	IF v_relationship_active = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied changing the primary supplier follower for the company with sid '||in_supplier_sid);
	END IF;
	
	company_pkg.AddSupplierFollower(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_sid, in_user_sid);
	
	UPDATE supplier_follower
	   SET is_primary = CASE WHEN user_sid = in_user_sid THEN 1 ELSE NULL END
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_sid;
	
END;

FUNCTION UserIsFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count		NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN	
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_supplier_sid);
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM supplier_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_sid
	   AND user_sid = in_user_sid;
	   
	 RETURN v_count;
END;

FUNCTION UserIsPrimaryFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_psf_user_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT user_sid
		  INTO v_psf_user_sid
		  FROM supplier_follower
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND supplier_company_sid = in_supplier_sid
		   AND is_primary = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;
	
	RETURN v_psf_user_sid = in_user_sid;
END;

PROCEDURE GetAllCompanyUsers (
	in_company_sid_array	IN  security_pkg.T_SID_IDS,
	in_dummy				IN  NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_company_sid_table		security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_company_sid_array);
BEGIN
	FOR i IN 1..in_company_sid_array.last LOOP
		v_company_sid := in_company_sid_array(i);
		IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on users of company with sid '||v_company_sid);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT ccu.app_sid, ccu.company_sid, ccu.user_sid, ccu.visibility_id, ccu.user_name, ccu.email, ccu.full_name,
		       ccu.friendly_name, ccu.phone_number, ccu.job_title, c.column_value
		  FROM v$chain_company_user ccu
		  JOIN TABLE(v_company_sid_table) c ON ccu.company_sid = c.column_value
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE ApproveUser (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_user_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_USER_IS_NOT_MEMBER, 'Access denied promoting a user who is not a company member');
	END IF;	
	
	DeleteGroupMember(in_user_sid, v_pending_sid); 
	AddGroupMember(in_user_sid, v_user_sid); 
	chain_link_pkg.ApproveUser(in_company_sid, in_user_sid);
END;

PROCEDURE MakeAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_count					NUMBER(10);
BEGIN	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_USER_IS_NOT_MEMBER, 'Access denied promoting a user who is not a company member');
	END IF;
	
	ApproveUser(in_company_sid, in_user_sid);
	AddGroupMember(in_user_sid, v_admin_sid); 
END;

FUNCTION RemoveAdmin (
	in_company_sid				IN security_pkg.T_SID_ID,
	in_user_sid					IN security_pkg.T_SID_ID,
	in_force_remove_last_admin	IN NUMBER DEFAULT 0
) RETURN NUMBER
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_count					NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied demoting users on company sid '||in_company_sid);
	END IF;
	
	IF in_force_remove_last_admin = 0 AND IsLastAdmin(in_company_sid, in_user_sid) = 1 THEN
		RETURN 0;
	END IF;
	
	DeleteGroupMember(in_user_sid, v_admin_sid); 
	
	RETURN 1;
END;

PROCEDURE CheckPasswordComplexity (
	in_email				IN  security_pkg.T_SO_NAME,
	in_password				IN  security_pkg.T_USER_PASSWORD
)
AS
BEGIN
	security.AccountPolicyHelper_Pkg.CheckComplexity(LOWER(in_email), in_password);
END;

PROCEDURE CompleteRegistration (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_password				IN  Security_Pkg.T_USER_PASSWORD
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_cur_details			csr.csr_user%ROWTYPE;
BEGIN
	-- changes to email address are not permitted during registratino completion
	
	-- major sec checks handled by csr_user_pkg
	
	IF GetRegistrationStatus(in_user_sid) != chain_pkg.PENDING THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing the registration for the user with sid '||in_user_sid||' - they are not pending registration');
	END IF;
	
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;

	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> v_act_id,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_cur_details.user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> v_cur_details.friendly_name,
		in_email					=> v_cur_details.email,
		in_job_title				=> v_cur_details.job_title,
		in_phone_number				=> v_cur_details.phone_number,
		in_active					=> 1, -- set them to active
		in_info_xml					=> v_cur_details.info_xml,
		in_send_alerts				=> v_cur_details.send_alerts
	);
	
	-- set the password
	user_pkg.ChangePasswordBySID(v_act_id, in_password, in_user_sid);
	
	-- register our user
	SetRegistrationStatus(in_user_sid, chain_pkg.REGISTERED);
END;

PROCEDURE BeginUpdateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_send_alerts 			IN  csr.csr_user.send_alerts%TYPE,
	in_user_name 			IN  csr.csr_user.user_name%TYPE
)
AS
	v_visibility_id			chain_user.visibility_id%TYPE;
	v_count					NUMBER(10);
	v_cur_details			csr.csr_user%ROWTYPE;
	v_send_alerts			csr.csr_user.send_alerts%TYPE;
BEGIN
	-- meh - just clear it out to prevent dup checks
	DELETE FROM tt_user_details;
	
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
	
	IF capability_pkg.CheckCapability(in_company_sid, chain_pkg.MANAGE_USER) THEN
		v_send_alerts := in_send_alerts;
	ELSE
		v_send_alerts := v_cur_details.send_alerts;
	END IF;
	
	-- we can update our own stuff
	IF in_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id, email, send_alerts, user_name)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id, in_email, v_send_alerts, in_user_name);
		
		RETURN;
	END IF;
	
	SELECT visibility_id
	  INTO v_visibility_id
	  FROM v$chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	-- is the user a member of our company
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
	
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_member
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;


		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User is not a member of the company with sid '||in_company_sid);
		END IF;
		
		IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY_USER, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
		END IF;

		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id, email, send_alerts, user_name)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, v_visibility_id, in_email, v_send_alerts, in_user_name);

	ELSE
		-- ok, so they must be a supplier user...
		IF v_visibility_id = chain_pkg.HIDDEN THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid||' as the visibility is hidden');
		END IF;

		-- now let's confirm that we can write to suppliers...
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid||' for company with sid:'||in_company_sid);
		END IF;

		-- they ARE a supplier user - let's see what we can actually update...
		CASE 
		WHEN v_visibility_id = chain_pkg.JOBTITLE THEN
			INSERT INTO tt_user_details
			(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id, email, send_alerts, user_name)
			VALUES
			(in_user_sid, v_cur_details.full_name, v_cur_details.friendly_name, v_cur_details.phone_number, in_job_title, v_visibility_id, in_email, v_send_alerts, in_user_name);

		WHEN v_visibility_id = chain_pkg.NAMEJOBTITLE THEN
			INSERT INTO tt_user_details
			(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id, email, send_alerts, user_name)
			VALUES
			(in_user_sid, in_full_name, in_friendly_name,v_cur_details.phone_number, in_job_title, v_visibility_id, in_email, v_send_alerts, in_user_name);

		WHEN v_visibility_id = chain_pkg.FULL THEN
			INSERT INTO tt_user_details
			(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id, email, send_alerts, user_name)
			VALUES
			(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, v_visibility_id, in_email, v_send_alerts, in_user_name);

		END CASE;	
	
	END IF;
END;

PROCEDURE EndUpdateUser (
	in_user_sid				 IN  security_pkg.T_SID_ID, 
	in_modifiied_by_user_sid IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_details				tt_user_details%ROWTYPE;
BEGIN
	IF GetRegistrationStatus(in_user_sid) != chain_pkg.REGISTERED THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid||' - they are not registered');
	END IF;

	SELECT *
	  INTO v_details
	  FROM tt_user_details
	 WHERE user_sid = in_user_sid;
	
	InternalUpdateUser(
		in_user_sid			=> in_user_sid,
		in_full_name		=> v_details.full_name,
		in_friendly_name	=> v_details.friendly_name,
		in_phone_number		=> v_details.phone_number,
		in_job_title		=> v_details.job_title,
		in_visibility_id	=> v_details.visibility_id,
		in_email			=> v_details.email,
		in_send_alerts 		=> v_details.send_alerts,
		in_from_user_sid	=> in_modifiied_by_user_sid,
		in_user_name 		=> v_details.user_name
	);
END;


FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS
AS
	v_rs			    	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the user with sid '||in_user_sid);
	END IF;
	
	RETURN GetRegistrationStatusNoCheck(in_user_sid);
END;

FUNCTION GetRegistrationStatusNoCheck (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS
AS
	v_rs			    	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	BEGIN
		SELECT registration_status_id
		  INTO v_rs
		  FROM chain_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			helper_pkg.AddUserToChain(in_user_sid);
			
			-- try again
			SELECT registration_status_id
			  INTO v_rs
			  FROM chain_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = in_user_sid;
	END;
	   
	RETURN v_rs;
END;
	
	
PROCEDURE GetUser (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetUser(SYS_CONTEXT('SECURITY', 'SID'), out_cur, out_bu_cur, out_role_cur);
END;

PROCEDURE GetUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_has_read_perm			NUMBER DEFAULT 1;
BEGIN
	IF in_user_sid <> SYS_CONTEXT('SECURITY', 'SID') THEN
		v_has_read_perm := 0;
		FOR r IN (
			SELECT company_sid
			  FROM v$company_user 
			 WHERE user_sid = in_user_sid
		)
		LOOP
			IF capability_pkg.CheckCapability(r.company_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ) THEN
				v_has_read_perm := 1;
				EXIT;
			END IF;
		END LOOP;
	END IF;
	
	IF v_has_read_perm = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on user with sid:'||in_user_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.user_sid, cu.email, cu.user_name, cu.full_name, cu.friendly_name, cu.phone_number, cu.job_title, cu.visibility_id,
			   cu.registration_status_id, cu.receive_scheduled_alerts, cu.details_confirmed, cu.account_enabled, cu.default_company_sid,
			   csru.anonymised is_anonymised
		  FROM v$chain_user cu
		  JOIN csr.csr_user csru ON cu.user_sid = csru.csr_user_sid
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.user_sid = in_user_sid;
	
	OPEN out_bu_cur FOR
		SELECT bum.business_unit_id, bu.description, bum.is_primary_bu
		  FROM business_unit_member bum
		  JOIN business_unit bu ON bu.business_unit_id = bum.business_unit_id AND bu.app_sid = bum.app_sid
		 WHERE bum.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND bum.user_sid = in_user_sid;
	
	OPEN out_role_cur FOR
		SELECT ctr.company_type_id, r.name role_name, ctr.role_sid,
			   ctr.mandatory, ctr.cascade_to_supplier, ctr.pos,
			   in_user_sid user_sid
		  FROM csr.region_role_member rrm
		  JOIN chain.company_type_role ctr ON rrm.role_sid = ctr.role_sid
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		  JOIN csr.supplier s ON rrm.region_sid = s.region_sid
		 WHERE rrm.user_sid = in_user_sid
		   AND rrm.inherited_from_sid = rrm.region_sid
		   AND s.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY ctr.pos;
END;
	
PROCEDURE PreparePasswordReset (
	in_param				IN  VARCHAR2,
	in_accept_guid			IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	t_users					security.T_SO_TABLE DEFAULT securableobject_pkg.GetChildrenAsTable(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users'));
	v_sid					security_pkg.T_SID_ID;
	v_guid					security_pkg.T_ACT_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN

	
	BEGIN
		SELECT csr_user_sid
		  INTO v_sid
		  FROM TABLE(t_users) so, csr.csr_user csru
		 WHERE csru.app_sid = v_app_sid
		   AND so.sid_id = csru.csr_user_sid
		   AND LOWER(TRIM(csru.user_name)) = LOWER(TRIM(in_param));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_sid IS NULL THEN
		-- email addresses aren't necessarily unique, so I guess we should only reset the password when they are
		BEGIN
			SELECT csr_user_sid
			  INTO v_sid
			  FROM TABLE(t_users) so, csr.csr_user csru
			 WHERE csru.app_sid = v_app_sid
			   AND so.sid_id = csru.csr_user_sid
			   AND LOWER(TRIM(csru.email)) = LOWER(TRIM(in_param));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
			WHEN TOO_MANY_ROWS THEN
				NULL;
		END;	
	END IF;
	   
	IF v_sid IS NULL THEN
		RETURN;
	END IF;	
	
	IF NOT csr.csr_data_pkg.CheckCapabilityOfUser(v_sid, 'Logon directly') THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_USER_CANNOT_LOGON_DIRECTLY, 'You cannot reset this user''s password as this user does not have permissions to log on directly.');
	END IF;
	
	-- do not send if the account is inactive
	IF user_pkg.GetAccountEnabled(v_act_id, v_sid) = 0 THEN
		RETURN;
	END IF;
	
	INSERT INTO reset_password
	(guid, user_sid, accept_invitation_on_reset)
	VALUES
	(user_pkg.GenerateACT, v_sid, invitation_pkg.GetInvitationId(in_accept_guid))
	RETURN guid INTO v_guid;
	
	-- TODO: Notify user that a password reset was requested
	-- this is a bit tricky because events are company specific, not user specific (doh!)
	
	OPEN out_cur FOR
		SELECT csru.friendly_name, csru.full_name, csru.email, rp.guid, rp.expiration_dtm, rp.user_sid
		  FROM csr.csr_user csru, reset_password rp
		 WHERE rp.app_sid = v_app_sid
		   AND rp.app_sid = csru.app_sid
		   AND rp.user_sid = csru.csr_user_sid
		   AND rp.guid = v_guid;
		   
END;

PROCEDURE StartPasswordReset (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
	v_result				BOOLEAN;
BEGIN
	UPDATE reset_password
	   SET expiration_grace = 1
	 WHERE app_sid = SYS_CONTEXT('SECURTY', 'APP')
	   AND LOWER(guid) = LOWER(in_guid)
	   AND expiration_dtm > SYSDATE;
	
	-- who cares about result...
	v_result := GetPasswordResetDetails(in_guid, v_user_sid, v_invitation_id, out_cur);
END;

PROCEDURE ResetPassword (
	in_guid					IN  security_pkg.T_ACT_ID,
	in_password				IN  Security_Pkg.T_USER_PASSWORD,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN

	IF (GetPasswordResetDetails(in_guid, v_user_sid, v_invitation_id, out_state_cur)) THEN
		user_pkg.ChangePasswordBySID(security_pkg.GetAct, in_password, v_user_sid);	
	END IF;
	
	-- remove all outstanding resets for this user
	DELETE FROM reset_password
	 WHERE user_sid = v_user_sid; 
END;

PROCEDURE ResetPassword (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD
)
AS
	v_count					NUMBER(10);
BEGIN
	-- only check this if we're trying to set the password of a different user
	IF in_user_sid <> security_pkg.GetSid THEN
		
		-- capability checks should have already take place as this may be called by the UCD
		-- we'll just verify that the user is actually a company user
	
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'The user with sid '||in_user_sid||' is not a user of the company with sid '||in_company_sid);
		END IF;
	END IF;
	
	user_pkg.ChangePasswordBySID(security_pkg.GetAct, in_password, in_user_sid);	
	
END;

FUNCTION IsUsernameUsed (
	in_user_name			IN	security_pkg.T_SO_NAME,
	in_exclude_user_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER
AS
	v_ret					NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_ret
	  FROM csr.v$csr_user cu
	 WHERE app_sid = security_pkg.getApp
	   AND LOWER(TRIM(cu.user_name)) = LOWER(TRIM(in_user_name))
	   AND (in_exclude_user_sid IS NULL OR cu.csr_user_sid <> in_exclude_user_sid);

	RETURN v_ret;
END;

/* deprecated, used in old cards/specific client code*/
PROCEDURE CheckUsernameAvailability (
	in_user_name			IN	security_pkg.T_SO_NAME,
	in_exclude_user_sid		IN  security_pkg.T_SID_ID DEFAULT NULL
) 
AS
BEGIN
	-- if we've got a duplicate, let's blow up!
	IF IsUsernameUsed(in_user_name, in_exclude_user_sid) <> 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate user name found');
	END IF;
END;

FUNCTION IsEmailUsed (
	in_email					IN	csr.csr_user.email%TYPE,
	in_exclude_user_sid			IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER
AS
	v_ret					NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_ret
	  FROM csr.v$csr_user cu
	 WHERE app_sid = security_pkg.getApp
	   AND LOWER(TRIM(cu.email)) = LOWER(TRIM(in_email))
	   AND (in_exclude_user_sid IS NULL OR cu.csr_user_sid <> in_exclude_user_sid);

	RETURN v_ret;
END;

PROCEDURE ActivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	csr.csr_user_pkg.ActivateUser(security_pkg.GetAct, in_user_sid);
	chain_link_pkg.ActivateUser(in_user_sid);
END;

PROCEDURE DeactivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- Check the capabilites on all companies this user is a member of
	FOR r IN (
		SELECT company_sid
		  FROM chain.v$company_user
		 WHERE user_sid = in_user_sid
	)
	LOOP
		IF NOT capability_pkg.CheckCapability(r.company_sid, chain_pkg.MANAGE_USER) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Do not have the manage user capability for user on the company '||r.company_sid);
		END IF;
	END LOOP;

	csr.csr_user_pkg.DeactivateUser(security_pkg.GetAct, in_user_sid);
	chain_link_pkg.DeactivateUser(in_user_sid);
END;

PROCEDURE ConfirmUserDetails (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE chain_user
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid;

	message_pkg.CompleteMessageIfExists (
		in_primary_lookup           => chain_pkg.CONFIRM_YOUR_DETAILS,
		in_to_user_sid          	=> in_user_sid
	);
END;

PROCEDURE GetRegUsersForCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on users of company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		-- admins
		SELECT 	chu.app_sid, chu.user_sid, chu.email, chu.user_name,   
				chu.full_name, chu.friendly_name, chu.phone_number, chu.job_title,  
				chu.visibility_id, chu.registration_status_id, chu.receive_scheduled_alerts, chu.details_confirmed, 1 is_admin
		  FROM v$chain_user chu, v$company_admin ca
		 WHERE chu.app_sid = ca.app_sid
		   AND chu.user_sid = ca.user_sid
		   AND ca.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ca.company_sid = in_company_sid
		UNION
		-- all non admins
		SELECT 	chu.app_sid, chu.user_sid, chu.email, chu.user_name,   
				chu.full_name, chu.friendly_name, chu.phone_number, chu.job_title,  
				chu.visibility_id, chu.registration_status_id, chu.receive_scheduled_alerts, chu.details_confirmed, 0 is_admin
		  FROM v$chain_user chu, v$company_user cu
		 WHERE chu.app_sid = cu.app_sid
		   AND chu.user_sid = cu.user_sid
		   AND cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.company_sid = in_company_sid
		   AND cu.user_sid NOT IN (
			SELECT user_sid FROM v$company_admin WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND company_sid = in_company_sid
		   );
END;

/* Reason for using UNSEC: We can only get the registered users of a secondary company if we are logged under an elevated account or can_see_all_companies*/
PROCEDURE UNSEC_GetAdminsForCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_count	NUMBER;
BEGIN

	OPEN out_cur FOR
		SELECT user_sid, email, user_name, full_name, friendly_name, phone_number, job_title,   
			visibility_id, registration_status_id, details_confirmed, account_enabled
		  FROM v$company_admin
		 WHERE company_sid = in_company_sid;

END;

/* 	A user with the same SID can hold more than one invitation records under more than one companies
	We are getting the most significant invitation status for every to_company_sid
	Also we return the on-behalf-of-company result sets
*/
PROCEDURE GetUsersByInvitationStatus(
	in_company_sids			IN  security_pkg.T_SID_IDS,
	in_is_accepted  		IN NUMBER,
	in_is_active  			IN NUMBER,
	in_is_expired  			IN NUMBER,
	in_is_cancelled 		IN NUMBER,
	in_is_not_invited 		IN NUMBER,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_obo_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid_table 	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_company_sids);
BEGIN
	
	OPEN out_result_cur FOR
		SELECT *
		  FROM (
			SELECT cuis.user_sid, cuis.email, cuis.full_name, cuis.friendly_name, cuis.company_sid,
				   vc.name company_name
			  FROM v$chain_user_invitation_status cuis
			  JOIN TABLE(v_company_sid_table) c ON (c.column_value = cuis.company_sid)
			  JOIN company vc on cuis.company_sid = vc.company_sid
			 WHERE (cuis.invitation_status_id = chain_pkg.ACCEPTED AND in_is_accepted = 1)
				OR (cuis.invitation_status_id = chain_pkg.ACTIVE AND in_is_active = 1)
				OR (cuis.invitation_status_id = chain_pkg.EXPIRED AND in_is_expired = 1)
				OR (cuis.invitation_status_id = chain_pkg.CANCELLED AND in_is_cancelled = 1)
			UNION
			SELECT cu.user_sid, cu.email, cu.full_name, cu.friendly_name, cu.company_sid,
				   vc.name company_name
			  FROM v$company_user cu
			  JOIN TABLE(v_company_sid_table) c ON (c.column_value = cu.company_sid)
			  JOIN company vc on cu.company_sid = vc.company_sid
			 WHERE user_sid NOT IN (
					SELECT user_sid
					  FROM v$chain_user_invitation_status cuis
					  JOIN TABLE(v_company_sid_table) c ON (c.column_value = cuis.company_sid)
					)
			   AND in_is_not_invited = 1
			);
		
	chain_link_pkg.GetOnBehalfOfCompanies(v_company_sid_table, out_obo_cur);
	
END;

/* Used by structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetUserCompaniesAndRoles(
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_roles_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetUserCompaniesAndRoles can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	OPEN out_companies_cur FOR
		SELECT cu.app_sid, cu.company_sid, cu.user_sid, CASE WHEN ca.user_sid IS NULL THEN 0 ELSE 1 END is_admin
		  FROM v$company_user cu
		  LEFT JOIN v$company_admin ca ON cu.app_sid = ca.app_sid AND cu.user_sid = ca.user_sid AND cu.company_sid = ca.company_sid
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.user_sid = in_user_sid;

	OPEN out_roles_cur FOR
		SELECT s.company_sid, ctr.company_type_id, r.name role_name, ctr.role_sid,
			   ctr.mandatory, ctr.cascade_to_supplier, ctr.pos,
			   in_user_sid user_sid
		  FROM csr.region_role_member rrm
		  JOIN company_type_role ctr ON rrm.role_sid = ctr.role_sid
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		  JOIN csr.supplier s ON rrm.region_sid = s.region_sid
		 WHERE rrm.user_sid = in_user_sid
		   AND rrm.inherited_from_sid = rrm.region_sid
		 ORDER BY ctr.pos;
END;

END company_user_pkg;
/
