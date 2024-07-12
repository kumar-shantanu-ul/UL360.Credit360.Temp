CREATE OR REPLACE PACKAGE BODY SUPPLIER.company_user_pkg
IS

PROCEDURE AddSuperUsersToAllCompanies
AS
BEGIN
	-- sec checks are handled in subsequent procedures
	
	FOR r IN (
		SELECT company_sid
		  FROM all_company
		 WHERE app_sid = security_pkg.GetApp
	)
	LOOP
		AddSuperUsersToCompany(r.company_sid);
	END LOOP;
END;

PROCEDURE AddSuperUsersToCompany (
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
	v_su_container_sid		security_pkg.T_SID_ID;
	v_su_sids				security.T_SO_TABLE;
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to company with sid '||in_company_sid);
	END IF;
	
	v_su_container_sid 	:= securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.SID_ROOT, 'csr/Users');
	v_su_sids 			:= securableobject_pkg.GetChildrenAsTable(v_act_id, v_su_container_sid);
	
	FOR r IN (
		SELECT su.sid_id user_sid
		  FROM csr.csr_user csru, TABLE(v_su_sids) su
		 WHERE csru.csr_user_sid = su.sid_id
		 MINUS
		SELECT csr_user_sid user_sid
		  FROM company_user
		 WHERE company_sid = in_company_sid
	) LOOP
		AddUserToCompany(in_company_sid, r.user_sid, USER_IS_AUTHORIZED);
		SetPrivacy(r.user_sid, in_company_sid, FULLY_HIDDEN);		
	END LOOP;
END;




FUNCTION UserIsAuthorized (
	in_user_sid			IN security_pkg.T_SID_ID,
	in_company_sid		IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_pending_auth		company_user.pending_company_authorization%TYPE DEFAULT USER_IS_NOT_AUTHORIZED;
BEGIN
	
	-- verify we can at least read the company that's set in the context
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the company with sid '||in_company_sid||'.');
	END IF;
	
	BEGIN
		SELECT pending_company_authorization
		  INTO v_pending_auth
		  FROM company_user
		 WHERE company_sid = in_company_sid
		   AND csr_user_sid = in_user_sid
		   AND app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN (v_pending_auth = USER_IS_AUTHORIZED);	
END;

PROCEDURE AuthorizeUser (
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT company_group_pkg.UserIsMember(company_group_pkg.GT_COMPANY_ADMIN) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied authorizing user with sid '||in_user_sid||'.');
	END IF;
	
	-- update this user
	UPDATE company_user
	   SET pending_company_authorization = USER_IS_AUTHORIZED
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = company_pkg.GetCompany
	   AND csr_user_sid = in_user_sid;
	
	-- send a message to the user and to the admin group to say that the user has been authorized
	message_pkg.CreateMessage(
		message_pkg.MT_JOIN_COMPANY_GRANTED,
		in_user_sid, company_group_pkg.GT_COMPANY_ADMIN,
		security_pkg.GetSid, in_user_sid
	);
	
	-- TODO: do this thourgh the update returning, and move the update statement above this...
	FOR r IN (
		SELECT * 
		  FROM questionnaire_request
		 WHERE app_sid = security_pkg.GetApp
		   AND supplier_company_sid = company_pkg.GetCompany
		   AND supplier_user_sid = in_user_sid
	   	   AND request_status_id = chain_questionnaire_pkg.RS_PENDING_ACCEPT
	) LOOP
	
		-- Create the message to notify the procurer of the acceptance
		message_pkg.CreateMessage(
			message_pkg.MT_QUESTIONNAIRE_ACCEPTED,
			r.procurer_company_sid, null, null,
			r.procurer_user_sid,
			r.chain_questionnaire_id,
			company_pkg.GetCompany,
			message_pkg.MIDT_SUPPLIER
		);				

		-- Create the message to notify the supplier of the acceptance
		message_pkg.CreateMessage(
			message_pkg.MT_ACCEPT_QUESTIONNAIRE,
			null,null, null,
			r.supplier_user_sid,
			r.chain_questionnaire_id,
			r.procurer_company_sid,
			message_pkg.MIDT_PROCURER			
		);	
		
	END LOOP;
	
	-- any questionnaires that have been appcepted by this user are now accepted by the company
	UPDATE questionnaire_request
	   SET request_status_id = chain_questionnaire_pkg.RS_ACCEPTED, accepted_dtm = SYSDATE
	 WHERE app_sid = security_pkg.GetApp
	   AND supplier_company_sid = company_pkg.GetCompany
	   AND supplier_user_sid = in_user_sid
	   AND request_status_id = chain_questionnaire_pkg.RS_PENDING_ACCEPT;

END;

PROCEDURE GetUser (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetUser(security_pkg.GetSid, company_pkg.GetCompany, out_cur);
END;

PROCEDURE GetUser (
	in_user_sid			IN security_pkg.T_SID_ID,
	in_company_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- verify we can read the details
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the user with sid '||in_user_sid||'.');
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the company with sid '||in_company_sid||'.');
	END IF;

	OPEN out_cur FOR
		SELECT c.company_sid, c.name, c.address_1, c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode,
		       c.country_code, c.phone, c.phone_alt, c.fax, c.internal_supplier, c.active, c.deleted, c.company_status_id, c.app_sid,
		       vcu.csr_user_sid, vcu.pending_company_authorization, vcu.user_profile_visibility_id,
		       vcu.full_name, vcu.email, vcu.job_title, vcu.phone_number
		  FROM company c, v$chain_user vcu
		 WHERE vcu.app_sid = c.app_sid
		   AND vcu.app_sid = security_pkg.GetApp
		   AND vcu.company_sid = in_company_sid
		   AND vcu.company_sid = c.company_sid
		   AND vcu.csr_user_sid = in_user_sid;
END;

PROCEDURE GetUserCompanies (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	IF NOT security_pkg.IsAccessAllowedSID(
		security_pkg.GetAct(), 
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct(), security_pkg.GetApp(), 'Supplier/Companies'), 
		security_pkg.PERMISSION_READ
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading companies container');
	END IF;

	OPEN out_cur FOR
		SELECT c.company_sid, c.name, c.address_1, c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode,
		       c.country_code, c.phone, c.phone_alt, c.fax, c.internal_supplier, c.active, c.deleted, c.company_status_id, c.app_sid
		  FROM company c, company_user cu
		 WHERE c.company_sid = cu.company_sid
		   AND c.app_sid = cu.app_sid
		   AND c.app_sid = security_pkg.GetApp
   		   AND cu.csr_user_sid = security_pkg.GetSid
   		 ORDER BY LOWER(c.name);
END;

PROCEDURE AddUserToCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_pending_authorization	IN  T_CU_AUTHORIZED_STATE
)
AS
	v_do_sec_check				BOOLEAN DEFAULT TRUE;
	v_count						NUMBER(10);
	v_already_exists			BOOLEAN DEFAULT FALSE;
BEGIN

	-- we need to do a bit of trickery here so that a user can be added through self registration
	
	-- if the user is not authorized, allow them to be added
	IF in_pending_authorization = USER_IS_NOT_AUTHORIZED THEN
		v_do_sec_check := FALSE;
	ELSE
		SELECT COUNT(*)
		  INTO v_count
		  FROM company_user
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid;
		
		-- theres no other users there now, allow them to be added
		IF v_count = 0 THEN
			v_do_sec_check := FALSE;
		END IF;
	END IF;
	
	IF v_do_sec_check THEN
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), in_company_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access writing to the company with sid '||in_company_sid||'.');
		END IF;
	END IF;

	BEGIN
		INSERT INTO company_user 
		(app_sid, company_sid, csr_user_sid, pending_company_authorization)
		VALUES
		(security_pkg.GetApp, in_company_sid, in_user_sid, in_pending_authorization);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			
			IF in_pending_authorization = company_user_pkg.USER_IS_AUTHORIZED THEN
				update company_user set pending_company_authorization = in_pending_authorization
				where company_sid = in_company_sid and csr_user_sid = in_user_sid;
			END IF;
			
			v_already_exists := TRUE;
	END;

	IF v_already_exists = FALSE THEN
		IF in_pending_authorization = USER_IS_NOT_AUTHORIZED THEN
			message_pkg.CreateMessage(message_pkg.MT_JOIN_COMPANY_REQUEST, null, null, in_user_sid);

			-- TODO: grant read permissions
		ELSE
			NULL;
			-- TODO: grant read/write permissions
		END IF;
	END IF;
END;

PROCEDURE GetCompanyUsers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- verify we can read the details
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), company_pkg.GetCompany, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the company with sid '||company_pkg.GetCompany||'.');
	END IF;

	OPEN out_cur FOR
		SELECT company_sid, app_sid, csr_user_sid, pending_company_authorization, user_profile_visibility_id, full_name, email, job_title, phone_number
		  FROM v$chain_user
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = company_pkg.GetCompany
		 ORDER BY LOWER(full_name);
END;

PROCEDURE AmendUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE,
	in_email					IN  csr.csr_user.email%TYPE,
	in_job_title				IN  csr.csr_user.job_title%TYPE,
	in_phone_number				IN  csr.csr_user.phone_number%TYPE
)
AS
	v_user						csr.csr_user%ROWTYPE;
	v_user_name					csr.csr_user.user_name%TYPE;
BEGIN

	SELECT *
	  INTO v_user
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
	   
	IF LOWER(v_user.email) = LOWER(v_user.user_name) THEN
		v_user_name := in_email;
	ELSE
		v_user_name := v_user.user_name;
	END IF;

	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> security_pkg.GetAct,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> null,
		in_email					=> in_email,
		in_job_title				=> in_job_title,
		in_phone_number				=> in_phone_number,
		in_active					=> null,
		in_info_xml					=> v_user.info_xml,
		in_send_alerts				=> v_user.send_alerts
	);
END;

PROCEDURE SetPrivacy_ (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_visibility				IN  T_CU_VISIBILITY_STATE
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid||'.');
	END IF;
	
	UPDATE company_user
	   SET user_profile_visibility_id = in_visibility
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid
	   AND csr_user_sid = in_user_sid;

END;

PROCEDURE SetPrivacy (
	in_visibility				IN  T_CU_VISIBILITY_STATE
)
AS
BEGIN
	SetPrivacy_(security_pkg.GetSid, company_pkg.GetCompany, in_visibility);
END;

PROCEDURE SetPrivacy (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_visibility				IN  T_CU_VISIBILITY_STATE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the company with sid '||in_company_sid||'.');
	END IF;

	SetPrivacy_(in_user_sid, in_company_sid, in_visibility);
END;		
	
PROCEDURE AddUserToAllCompanies (
	in_user_sid					IN security_pkg.T_SID_ID DEFAULT security_pkg.GetSid()
)
AS
BEGIN
	-- verify that we have write AND change permissions access on the application 
	-- (we don't want just anyone running this procedure...)
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), security_pkg.GetApp(), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the application with sid '||security_pkg.GetApp()|| '.');
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), security_pkg.GetApp(), security_pkg.PERMISSION_CHANGE_PERMISSIONS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing permission in the application with sid '||security_pkg.GetApp()|| '.');
	END IF;
	
	-- add the user to any companies that they don't already belong to, marking them as authorized and fully hidden
	INSERT INTO company_user
	(company_sid, csr_user_sid, pending_company_authorization, user_profile_visibility_id)
	( 
	    SELECT DISTINCT company_sid, in_user_sid, company_user_pkg.USER_IS_AUTHORIZED, company_user_pkg.FULLY_HIDDEN 
	      FROM company_user
	     WHERE app_sid = security_pkg.GetApp
	       AND company_sid NOT IN (
	            SELECT company_sid 
	              FROM company_user 
	             WHERE app_sid = security_pkg.GetApp
	               AND csr_user_sid = in_user_sid
	           )
	);
	
END;


END company_user_pkg;
/


