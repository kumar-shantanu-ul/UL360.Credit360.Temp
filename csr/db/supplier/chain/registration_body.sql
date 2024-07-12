CREATE OR REPLACE PACKAGE BODY SUPPLIER.registration_pkg
IS

-- Possible status codes:
--   0 -> This company name is not in use (out_company_sid = null)
--   1 -> This company name is in use, but not for this country (out_company_sid is set)
--   2 -> This company name is in use for this country (out_company_sid is set)
PROCEDURE ValidateCompanyName (
	in_company_name			IN  security_pkg.T_SO_NAME,
	in_country_code			IN  company.country_code%TYPE,
	out_result				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_l_company_name		security_pkg.T_SO_NAME DEFAULT TRIM(LOWER(in_company_name));
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_count					NUMBER(10);
	v_status_code			NUMBER(10) DEFAULT 0;
	v_company_sid			security_pkg.T_SID_ID;
	v_country_code			company.country_code%TYPE;
BEGIN
	-- this needs to be publicly available, so no sec checks
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_company
	 WHERE app_sid = v_app_sid
	   AND LOWER(name) = v_l_company_name;
	   
	IF v_count > 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM all_company
		 WHERE app_sid = v_app_sid
	       AND LOWER(name) = v_l_company_name
	       AND country_code = in_country_code;
		
		IF v_count = 0 THEN
			
			SELECT company_sid, country_code
			  INTO v_company_sid, v_country_code
			  FROM all_company
			 WHERE app_sid = v_app_sid
			   AND LOWER(name) = v_l_company_name;
			
			v_status_code := 1;
		ELSE
			SELECT company_sid, country_code
			  INTO v_company_sid, v_country_code
			  FROM all_company
			 WHERE app_sid = v_app_sid
			   AND LOWER(name) = v_l_company_name
			   AND country_code = in_country_code;
			
			v_status_code := 2;
		END IF;
	END IF;
	
	OPEN out_result FOR
		SELECT v_status_code status_code, v_company_sid existing_company_sid, v_country_code country_code FROM DUAL;

END;

PROCEDURE ValidateEmailAsUserName (
	in_email				IN  security_pkg.T_SO_NAME,
	out_used				OUT NUMBER
)
AS
	v_l_email		security_pkg.T_SO_NAME DEFAULT TRIM(LOWER(in_email));
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	-- this needs to be publicly available, so no sec checks
	SELECT COUNT(*)
	  INTO out_used
	  FROM csr.csr_user
	 WHERE app_sid = v_app_sid
	   AND (LOWER(user_name) = v_l_email OR LOWER(email) = v_l_email);	 
END;

/**
 *  INTERNAL USE ONLY
 **/
PROCEDURE InviteAccepted (
	v_user_sid				IN  security_pkg.T_SID_ID,
	v_company_sid			IN  security_pkg.T_SID_ID,
	v_contact_id			IN  contact.contact_id%TYPE
)
AS
	v_contact	 			v$contact%rowtype;
	v_invite	 			invite%rowtype;
	v_request_status		chain_questionnaire_pkg.T_REQUEST_STATUS;
BEGIN

	/* Get the initial data */
	-- get the contact
	SELECT *
	  INTO v_contact
	  FROM v$contact
	 WHERE app_sid = security_pkg.GetApp
	   AND contact_id = v_contact_id;
	
	-- get the invite
	SELECT *
	  INTO v_invite
	  FROM invite
	 WHERE app_sid = v_contact.app_sid
	   AND sent_to_contact_id = v_contact.contact_id;
	
	-- determine the request status
	IF company_user_pkg.UserIsAuthorized(v_user_sid, v_company_sid) THEN
		v_request_status := chain_questionnaire_pkg.RS_ACCEPTED;
	ELSE
		v_request_status := chain_questionnaire_pkg.RS_PENDING_ACCEPT;
	END IF;
	
	/* Stuff the data in place */
	
	-- ensure that the procurer-supplier relationship exists (it may already)
	BEGIN
		INSERT INTO all_procurer_supplier
		(procurer_company_sid, supplier_company_sid, estimated_annual_spend, currency_code)
		VALUES
		(v_contact.owner_company_sid, v_company_sid, v_contact.estimated_annual_spend, v_contact.currency_code);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- who cares
	END;
	
	-- for each questionnaire that exists in the invite
	FOR iq IN (
		SELECT *
		  FROM invite_questionnaire
		 WHERE app_sid = v_invite.app_sid
		   AND invite_id = v_invite.invite_id
	)
	LOOP
		-- setup the intial company quesitonnaire response data
		-- there's a reasonable possibility that this record will already exist
		BEGIN
			INSERT INTO company_questionnaire_response
			(company_sid, chain_questionnaire_id)
			VALUES
			(v_company_sid, iq.chain_questionnaire_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;  -- who cares
		END;
		
		-- setup the intial procurer-supplier quesitonnaire request data
		-- there's a fairly small possibility that this record will already exist 
		-- (e.g. if two contacts from the same company were asked to fill in the same questionnaire)
		BEGIN
			INSERT INTO questionnaire_request
			(
				procurer_company_sid, supplier_company_sid, chain_questionnaire_id, 
				procurer_user_sid, supplier_user_sid, 
				request_status_id, due_dtm, accepted_dtm,
				reminder_count, last_reminder_dtm
			)
			VALUES
			(
				v_invite.sent_by_company_sid, v_company_sid, iq.chain_questionnaire_id,
				v_invite.sent_by_user_sid, v_user_sid,
				v_request_status, iq.due_dtm, CASE WHEN v_request_status = chain_questionnaire_pkg.RS_ACCEPTED THEN SYSDATE END,
				iq.reminder_count, CASE WHEN iq.reminder_count > 0 THEN iq.last_msg_dtm END
			);
			
			IF v_request_status = chain_questionnaire_pkg.RS_ACCEPTED THEN
				
				-- Create the message to notify the procurer of the acceptance
				message_pkg.CreateMessage(
					message_pkg.MT_QUESTIONNAIRE_ACCEPTED,
					v_invite.sent_by_company_sid,
					null, null,
					v_invite.sent_by_user_sid,
					iq.chain_questionnaire_id,
					company_pkg.GetCompany,
					message_pkg.MIDT_SUPPLIER
				);				
				
				-- Create the message to confirm the supplier of the acceptance
				message_pkg.CreateMessage(
					message_pkg.MT_ACCEPT_QUESTIONNAIRE,
					null, null, null,
					v_user_sid,
					iq.chain_questionnaire_id,
					v_invite.sent_by_company_sid,
					message_pkg.MIDT_PROCURER
				);				
			END IF;
			
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;  -- who cares
		END;
			
	END LOOP;

	/* Clean up the invitation stuff */
	UPDATE contact
	   SET contact_state_id = contact_pkg.CONTACT_REGISTERED,
	   	   registered_as_user_sid = v_user_sid,
	   	   registered_to_company_sid = v_company_sid
	 WHERE contact_id = v_contact.contact_id;
	
	UPDATE invite
	   SET invite_status_id = invite_pkg.INVITE_ACCEPTED
	 WHERE invite_id = v_invite.invite_id;

END;

PROCEDURE RegisterUser (
	in_contact_guid			IN  contact.contact_guid%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE,
	in_password				IN  security_Pkg.T_USER_PASSWORD,
	in_company_name			IN  all_company.name%TYPE,
	in_country_code			IN  all_company.country_code%TYPE,
	in_existing_company_sid	IN  security_pkg.T_SID_ID,
	in_info_xml				IN  csr.csr_user.info_xml%TYPE,
	out_user_sid			OUT security_pkg.T_SID_ID
)
AS
	v_contact	 			v$contact%rowtype;
	v_company_sid			security_pkg.T_SID_ID;
	v_authorized_user		company_user_pkg.T_CU_AUTHORIZED_STATE;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_l_contact_guid		contact.contact_guid%TYPE DEFAULT LOWER(in_contact_guid);
BEGIN

	-- register the user
	csr.csr_user_pkg.createUser(
		in_act						=> security_pkg.GetAct, 
		in_app_sid					=> security_pkg.GetApp, 
		in_user_name				=> in_email,
		in_password					=> in_password,
		in_full_name				=> in_full_name,
		in_friendly_name			=> null,
		in_email					=> in_email,
		in_job_title				=> in_job_title,
		in_phone_number				=> in_phone_number,
		in_info_xml					=> in_info_xml,
		in_send_alerts				=> 1,
		out_user_sid				=> out_user_sid
	);
	
	-- grab the contact record
	SELECT *
	  INTO v_contact
	  FROM v$contact
	 WHERE app_sid = v_app_sid
	   AND LOWER(contact_guid) = v_l_contact_guid;
	
	-- check if the company already exists
	IF v_contact.existing_company_sid IS NULL THEN
		
		IF NVL(in_existing_company_sid, 0) = 0 THEN
			-- it doesn't, so create it and use the initial values set by the invitation requestor
			-- (the user will have the option to change it once they've logged in
			chain_company_pkg.CreateCompany(
				in_company_name,	
				v_contact.address_1,
				v_contact.address_2,
				v_contact.address_3,
				v_contact.address_4,
				v_contact.town,
				v_contact.state,
				v_contact.postcode,
				in_country_code,
				v_company_sid
			);
			-- since this is the first user for the company, let's authorize them
			v_authorized_user := company_user_pkg.USER_IS_AUTHORIZED;		
		ELSE
			-- it's possible that the user has chosen to join an existing company - let's verify that
			-- they're trying to join a company with a matching name
			BEGIN
				SELECT company_sid
				  INTO v_company_sid
				  FROM all_company
				 WHERE app_sid = security_pkg.GetApp
				   AND company_sid = in_existing_company_sid
				   AND LOWER(name) = LOWER(in_company_name);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Could not find a matching company (name='||in_company_name||' and sid='||in_existing_company_sid||') to register to.');
			END;
			-- another user in the company will need to authorize them
			v_authorized_user := company_user_pkg.USER_IS_NOT_AUTHORIZED;			
		END IF;
	ELSE
		v_company_sid := v_contact.existing_company_sid;
		-- another user in the company will need to authorize them
		v_authorized_user := company_user_pkg.USER_IS_NOT_AUTHORIZED;
	END IF;
	
	-- required for messaging
	security_pkg.SetContext('SUPPLY_CHAIN_COMPANY', v_company_sid);
	
	-- create welcome message
	message_pkg.CreateMessage(message_pkg.MT_WELCOME_MESSAGE, out_user_sid, null);

	-- add the user to the company
	company_user_pkg.AddUserToCompany(v_company_sid, out_user_sid, v_authorized_user);
	
	InviteAccepted(out_user_sid, v_company_sid, v_contact.contact_id);
	
	-- if this user is the first user in the company, make them an admin
	IF v_authorized_user = company_user_pkg.USER_IS_AUTHORIZED THEN
		company_group_pkg.AddUserToGroup(out_user_sid, company_group_pkg.GT_COMPANY_ADMIN); 
	END IF;

END;

PROCEDURE AcceptAsRegisteredUser (
	in_contact_guid			IN  contact.contact_guid%TYPE
)
AS
	v_contact	 			v$contact%rowtype;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_l_contact_guid		contact.contact_guid%TYPE DEFAULT LOWER(in_contact_guid);
BEGIN

	-- grab the contact record
	SELECT *
	  INTO v_contact
	  FROM v$contact
	 WHERE app_sid = v_app_sid
	   AND LOWER(contact_guid) = v_l_contact_guid;
	
	-- required for messaging
	security_pkg.SetContext('SUPPLY_CHAIN_COMPANY', v_contact.existing_company_sid);
	
	-- add the user to the company (they may be already, but we'll check that first)
	company_user_pkg.AddUserToCompany(v_contact.existing_company_sid, security_pkg.GetSid, company_user_pkg.USER_IS_NOT_AUTHORIZED);
	
	InviteAccepted(security_pkg.GetSid, v_contact.existing_company_sid, v_contact.contact_id);
	
END;

PROCEDURE RejectInvitesForGuid (
	in_contact_guid			IN  contact.contact_guid%TYPE
)
AS
	v_l_contact_guid		contact.contact_guid%TYPE DEFAULT LOWER(in_contact_guid);
BEGIN
	
	FOR r IN (
		SELECT c.contact_id, i.invite_id, iq.chain_questionnaire_id
		  FROM v$contact c, invite i, invite_questionnaire iq
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.app_sid = i.app_sid
		   AND c.app_sid = iq.app_sid
		   AND LOWER(contact_guid) = v_l_contact_guid
		   AND i.sent_to_contact_id = c.contact_id
		   AND iq.invite_id = i.invite_id
	) LOOP		   
		
		-- update flags
		UPDATE contact
		   SET contact_state_id = contact_pkg.CONTACT_REMOVED_BY_REJECTION,
		       last_contact_state_update_dtm = SYSDATE
		 WHERE contact_id = r.contact_id;
		 
		UPDATE invite
		   SET invite_status_id = invite_pkg.INVITE_REJECTED,
		   	   last_status_change_dtm = SYSDATE
		 WHERE invite_id = r.invite_id;
		   
		-- TODO: create messaging
				
	END LOOP;

END;
	
END registration_pkg;
/
