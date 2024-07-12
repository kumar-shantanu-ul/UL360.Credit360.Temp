CREATE OR REPLACE PACKAGE BODY CHAIN.dev_pkg
IS

PROCEDURE ValidateAccess
AS
	v_sug_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.SID_ROOT, '//csr/SuperAdmins');
	v_var					NUMBER(10);
	v_deny					BOOLEAN DEFAULT NOT security_pkg.IsAdmin(security_pkg.GetAct);
BEGIN
	-- check to see if we're a super user
	IF v_deny THEN	
		SELECT COUNT(*)
		  INTO v_var
		  FROM TABLE(group_pkg.GetMembersAsTable(security_pkg.GetAct, v_sug_sid))
		 WHERE sid_id = security_pkg.GetSid;
		 
		v_deny := v_var = 0; 
	END IF;
	
	-- see if the application allows administators to use access development pages
	IF v_deny THEN	
		SELECT admin_has_dev_access
		  INTO v_var
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetApp;
		
		IF v_var = chain_pkg.ACTIVE AND helper_pkg.IsChainAdmin THEN
			v_deny := FALSE;
		END IF;
	END IF;
	
	-- if not, blow up!
	IF v_deny THEN
		RAISE_APPLICATION_ERROR(-20001, 'You do not have permission to call this procedure.');
	END IF;
END;

FUNCTION GenerateSOName (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SO_NAME
AS
	v_cc					company.country_code%TYPE DEFAULT in_country_code;
BEGIN
	WHILE LENGTH(v_cc) < 2
	LOOP
		v_cc := ' '||v_cc;
	END LOOP;
	
	
	RETURN in_company_name || ' ('||v_cc||')';
END;


-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------


PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE
)
AS
	v_cc					company.country_code%TYPE;
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	SELECT MIN(country_code) -- first alphabetically
	  INTO v_cc
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND LOWER(name) = LOWER(in_company_name);
	
	SetCompany(in_company_name, v_cc);
END;


PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- check that we get dev level access
	ValidateAccess;
		
	BEGIN
		v_company_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, helper_pkg.GetCompaniesContainer, GenerateSOName(in_company_name, in_country_code));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			security_pkg.SetContext('CHAIN_COMPANY', NULL);
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'A company named '''||in_company_name||''' could not be found.');
	END;
	
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
END;


PROCEDURE GetOpenInvitations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR		
)
AS
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	OPEN out_cur FOR
		SELECT fc.name from_company_name, fcu.full_name from_full_name, fcu.email from_email,
		  	   tc.name to_company_name, tcu.full_name to_full_name, tcu.email to_email,
		  	   i.*
		  FROM v$company fc, v$company tc, v$chain_user fcu, v$chain_user tcu, invitation i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = fc.app_sid
		   AND i.app_sid = tc.app_sid
		   AND i.app_sid = fcu.app_sid
		   AND i.app_sid = tcu.app_sid
		   AND i.from_company_sid = fc.company_sid
		   AND i.to_company_sid = tc.company_sid
		   AND i.from_user_sid = fcu.user_sid
		   AND i.to_user_sid = tcu.user_sid
		   AND i.invitation_status_id = chain_pkg.ACTIVE
		 ORDER BY LOWER(tc.name), LOWER(tcu.full_name);
END;

PROCEDURE GetOpenActiveActivations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check that we get dev level access
	ValidateAccess;

	OPEN out_cur FOR
		SELECT cu.*, au.requested_dtm, au.guid
		  FROM csr.v$autocreate_user au, v$chain_user cu
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.app_sid = au.app_sid
		   AND cu.user_sid = au.created_user_sid
		   AND au.activated_dtm IS NULL;
END;


PROCEDURE GetCompanies (
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	OPEN out_cur FOR
		SELECT c.*, NVL(ca.count, 0) ca_count, NVL(cu.count, 0) cu_count, NVL(cpu.count, 0) cpu_count
		  FROM company c, (
		  			SELECT company_sid, COUNT(*) count
		  			  FROM v$company_admin
		  			 GROUP BY company_sid
		  		) ca, (
		  			SELECT company_sid, COUNT(*) count
		  			  FROM v$company_user
		  			 GROUP BY company_sid
		  		) cu, (
		  			SELECT company_sid, COUNT(*) count
					  FROM v$company_pending_user
		  			 GROUP BY company_sid
		  		) cpu
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.deleted = 0
		   AND c.pending = 0
		   AND c.company_sid = ca.company_sid(+)
		   AND c.company_sid = cu.company_sid(+)
		   AND c.company_sid = cpu.company_sid(+)
		 ORDER BY c.name;

END;


PROCEDURE DeleteCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	-- ensure it's a chain company
	SELECT company_sid
	  INTO v_company_sid
	  FROM company
	 WHERE company_sid = in_company_sid;
	  
	company_pkg.DeleteCompany(v_company_sid);
END;

/* Internal use only */
PROCEDURE Execute (
	in_proc				VARCHAR2,
	in_arg_1			NUMBER DEFAULT NULL,
	in_arg_2			NUMBER DEFAULT NULL,
	in_arg_3			NUMBER DEFAULT NULL,
	in_arg_4			NUMBER DEFAULT NULL
)
AS
	PROC_NOT_FOUND		EXCEPTION;
	PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);
	v_args				VARCHAR2(1000);
BEGIN
	
	IF in_arg_1 IS NOT NULL THEN
		v_args := in_arg_1;
		
		IF in_arg_2 IS NOT NULL THEN
			v_args := v_args||', '||in_arg_2;
	
			IF in_arg_3 IS NOT NULL THEN
				v_args := v_args||', '||in_arg_3;

				IF in_arg_4 IS NOT NULL THEN
					v_args := v_args||', '||in_arg_4;
				END IF;
			END IF;
		END IF;
	END IF;

	BEGIN
		EXECUTE IMMEDIATE ('BEGIN '||in_proc||'('||v_args||'); END;');
	EXCEPTION
		WHEN PROC_NOT_FOUND THEN
			NULL; -- it is acceptable that it is not supported
	END;
END;

PROCEDURE GenerateSuppliers (
	in_company							VARCHAR2,
	in_questionnaire_class				VARCHAR2,
	in_from_user						VARCHAR2,
	in_country							VARCHAR2,
	in_base_supplier_name				VARCHAR2,
	in_start_index						NUMBER,
	in_count							NUMBER,
	in_before_invite_sent_callback		VARCHAR2 DEFAULT NULL, -- procedure that takes paremeters of (from_company_sid, from_user_sid, to_company_sid, to_user_sid)
	in_invite_sent_callback				VARCHAR2 DEFAULT NULL, -- procedure that takes paremeters of (from_company_sid, from_user_sid, to_company_sid, to_user_sid)
	in_invite_accepted_callback			VARCHAR2 DEFAULT NULL,  -- procedure that takes paremeters of (purchaser_company_sid, supplier_company_sid, supplier_user_sid)
	in_on_behalf_of						NUMBER DEFAULT NULL
)
AS
	v_super_admins						security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, 0, 'csr/SuperAdmins');
	
	v_base_supplier_name				VARCHAR2(100) DEFAULT TRIM(NVL(in_base_supplier_name, 'Supplier')) || ' ';
	v_base_user_name					VARCHAR2(100) DEFAULT v_base_supplier_name || '* User';
	v_country							VARCHAR2(100) DEFAULT NVL(in_country, 'gb');
	v_start_index						NUMBER(10) DEFAULT in_start_index;
	v_count								NUMBER(10) DEFAULT NVL(in_count, 1);
	
	v_found								NUMBER(10);
	v_use_supp_code						NUMBER(10);
	v_company_sid   					security_pkg.T_SID_ID;
	v_from_user_sid						security_pkg.T_SID_ID;
	v_supplier_sid						security_pkg.T_SID_ID;
	v_user_name							VARCHAR2(100);
	v_user_sid							security_pkg.T_SID_ID;
	v_qnr_types							security_pkg.T_SID_IDS;
	v_due_dates							chain_pkg.T_STRINGS;
	v_key								supplier_relationship.virtually_active_key%TYPE;
	v_inv								chain.invitation%ROWTYPE;
	v_cur								security_pkg.T_OUTPUT_CUR;
	
	v_supp_code							company.supp_rel_code_label%TYPE;
	
	v_nullStringArray 					chain_pkg.T_STRINGS; --cannot pass NULL so need an empty varchar2 array instead
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GenerateSuppliers can only be run as BuiltIn/Administrator');
	END IF;
	
	IF v_start_index IS NULL THEN
		v_start_index := 0;
		v_found := 1;
		
		WHILE v_found <> 0
		LOOP
			v_start_index := v_start_index + 1;
			
			SELECT COUNT(*)
			  INTO v_found
			  FROM company
			 WHERE LOWER(name) = LOWER(v_base_supplier_name)||v_start_index;
		
		END LOOP;
	END IF;	
	
	-- do we need to put a supplier code in
	SELECT COUNT(*) 
	  INTO v_use_supp_code
	  FROM company c
	 WHERE company_sid = v_company_sid
	   AND supp_rel_code_label IS NOT NULL;
	
	BEGIN
		dev_pkg.SetCompany(in_company);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			-- maybe the sid has been passed in
			company_pkg.SetCompany(to_number(in_company));
	END;

	v_company_sid := company_pkg.GetCompany;
	
	IF SUBSTR(in_from_user, 1, 2) = '//' THEN
		SELECT cu.csr_user_sid
		  INTO v_from_user_sid
		  FROM csr.csr_user cu, security.group_members gm
		 WHERE cu.csr_user_sid = gm.member_sid_id
		   AND gm.group_sid_id = v_super_admins
		   AND user_name = SUBSTR(in_from_user, 3, 100);
	ELSE
		SELECT csr_user_sid
		  INTO v_from_user_sid
		  FROM csr.csr_user
		 WHERE user_name = in_from_user;		  
	END IF;
	
	helper_pkg.LogonUCD(v_company_sid);
	
	SELECT questionnaire_type_id
	  BULK COLLECT INTO v_qnr_types
	  FROM questionnaire_type
	 WHERE class = in_questionnaire_class;

	FOR i IN v_start_index .. v_start_index + v_count - 1
	LOOP
		v_user_name := replace(v_base_user_name, '*', i);
		
		company_pkg.CreateCompany(	
			in_name				=> v_base_supplier_name || i,
			in_country_code		=> v_country,
			in_company_type_id	=> NULL,
			in_sector_id		=> NULL,
			in_lookup_keys		=> v_nullStringArray,
			in_values			=> v_nullStringArray,
			out_company_sid		=> v_supplier_sid
		);
		
		v_user_sid := company_user_pkg.CreateUserForInvitation(v_supplier_sid, v_user_name, v_user_name, lower(replace(v_user_name, ' ', '.'))||'@credit360.com');
	
		-- random due date between tomorrow and 10 days from now
		SELECT to_char(SYSDATE + (floor((abs(dbms_random.value) * 10)) + 1), 'DD/MM/YY HH24:MI:SS') BULK COLLECT INTO v_due_dates FROM DUAL; 

		Execute(in_before_invite_sent_callback, v_company_sid, v_from_user_sid, v_supplier_sid, v_user_sid);
		
		-- find an unused supplier code
		IF v_use_supp_code <> 0 THEN
			
			WHILE v_found <> 0
			LOOP			
				SELECT 'TEST-' || i || '-' || TO_CHAR(SYSDATE, 'DDMMYYYY') 
				  INTO v_supp_code
				FROM DUAL;
			
				SELECT COUNT(*)
				  INTO v_found
				  FROM supplier_relationship 
				 WHERE LOWER(supp_rel_code) = LOWER(v_supp_code)
				   AND purchaser_company_sid = v_company_sid;
			END LOOP;
		END IF;
		
		
		chain.invitation_pkg.CreateInvitation(
			in_invitation_type_id		  => chain.chain_pkg.QUESTIONNAIRE_INVITATION,
			in_from_company_sid			  => v_company_sid,
			in_from_user_sid			  => v_from_user_sid,
			in_on_behalf_of_company_sid   => in_on_behalf_of,
			in_to_company_sid			  => v_supplier_sid,
			in_to_user_sid				  => v_user_sid,
			in_supp_rel_code			  => v_supp_code,
			in_expiration_life_days		  => 1, --just a dummy value for now
			in_qnr_types				  => v_qnr_types,
			in_due_dtm_strs				  => v_due_dates,
			out_cur						  => v_cur
		);
		
		FETCH v_cur INTO v_inv;
		CLOSE v_cur;
		
		FOR r IN (
			SELECT cu.user_sid, 0 is_super_admin
			  FROM company_group cg, security.group_members gm, chain_user cu 
			 WHERE cg.group_sid = gm.group_sid_id 
			   AND gm.member_sid_id = cu.user_sid
			   AND cg.company_group_type_id in (1, 2)
			   AND cg.company_sid = v_company_sid
			 UNION ALL
			SELECT cu.user_sid, 1 is_superadmin
			  FROM chain_user cu, security.group_members gm
			 WHERE cu.user_sid = gm.member_sid_id
			   AND gm.group_sid_id = v_super_admins
		) LOOP
			company_pkg.AddSupplierFollower(v_company_sid, v_supplier_sid, r.user_sid);
			IF r.is_super_admin = 1 THEN
				company_pkg.AddPurchaserFollower(v_company_sid, v_supplier_sid, r.user_sid);
			END IF;
		END LOOP;
		
		
		company_pkg.ActivateVirtualRelationship(v_supplier_sid, v_key);
		
		Execute(in_invite_sent_callback, v_company_sid, v_from_user_sid, v_supplier_sid, v_user_sid);
		
		company_pkg.DeactivateVirtualRelationship(v_key);
		
		invitation_pkg.AcceptInvitation(v_inv.guid, v_user_name, '12345678', NULL, NULL, NULL, v_cur);
		
		Execute(in_invite_accepted_callback, v_company_sid, v_supplier_sid, v_user_sid);
		
	END LOOP;	
	
	helper_pkg.RevertLogonUCD;
END;

END dev_pkg;
/
