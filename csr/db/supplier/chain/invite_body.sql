CREATE OR REPLACE PACKAGE BODY SUPPLIER.invite_pkg
IS

PROCEDURE AddQuestionnaireInvite (
	in_contact_ids			IN  T_CONTACT_IDS,
	in_questionnaire_ids	IN  T_QUESTIONAIRE_IDS,
	in_due_dates			IN  T_VARCHAR,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_invite_id				invite.invite_id%TYPE;
	v_invite_ids			security_pkg.T_SID_IDS;		-- not literally sids, but fits purpose
	v_invite_id_t 			security.T_SID_TABLE;
	v_questionnaire_t		T_ID_DATE_TABLE := T_ID_DATE_TABLE();
BEGIN
	
	-- verify we can at least read the company that's set in the context
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, company_pkg.GetCompany, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the company with sid '||company_pkg.GetCompany||'.');
	END IF;

	-- verify that the current user is an authorized user of the company
	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, company_pkg.GetCompany) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user for '||company_pkg.GetCompany||'.');
	END IF;
	
	FOR i IN in_contact_ids.FIRST .. in_contact_ids.LAST
	LOOP
		INSERT INTO invite 
		(invite_id, sent_by_user_sid, sent_by_company_sid, sent_to_contact_id, creation_dtm)
		VALUES
		(invite_id_seq.NEXTVAL, security_pkg.GetSid, company_pkg.GetCompany, in_contact_ids(i), SYSDATE)
		RETURNING invite_id INTO v_invite_id;
		
		v_invite_ids(v_invite_ids.count + 1) := v_invite_id;
	END LOOP;
	
	-- resolve arrays to tables
	v_invite_id_t := security_pkg.SidArrayToTable(v_invite_ids);
	FOR i IN in_questionnaire_ids.FIRST .. in_questionnaire_ids.LAST
	LOOP
		BEGIN
			v_questionnaire_t.extend;
			v_questionnaire_t(v_questionnaire_t.COUNT) := T_ID_DATE_ROW(in_questionnaire_ids(i), to_date(in_due_dates(i), 'ddmmyyyy'));
		END;
	END LOOP;	
	
	-- insert the join data to the questionnaire_invite table
	INSERT INTO invite_questionnaire
	(invite_id, chain_questionnaire_id, due_dtm, last_msg_from_company_sid, last_msg_from_user_sid, last_msg_dtm)
	(
		SELECT i.COLUMN_VALUE, q.ITEM_ID, q.DTM, company_pkg.GetCompany, security_pkg.GetSid, SYSDATE
		  FROM TABLE(v_invite_id_t) i, TABLE(v_questionnaire_t) q
	);
	
	-- set messages for each invite/questionnaire combination
	FOR r IN (
		SELECT c.contact_id, q.chain_questionnaire_id 
		  FROM invite i, chain_questionnaire q, v$contact c, TABLE(v_invite_id_t) it, TABLE(v_questionnaire_t) qt
		 WHERE i.app_sid = q.app_sid
		   AND i.app_sid = c.app_sid
		   AND i.app_sid = security_pkg.GetApp
		   AND i.invite_id = it.COLUMN_VALUE
		   AND q.chain_questionnaire_id = qt.ITEM_ID
		   AND c.contact_id = i.sent_to_contact_id
		   AND c.owner_company_sid = i.sent_by_company_sid
	) LOOP
		message_pkg.CreateMessage(
			message_pkg.MT_CONTACT_QI,
			null, null, null,
			security_pkg.GetSid,
			r.chain_questionnaire_id,
			r.contact_id,
			message_pkg.MIDT_CONTACT
			
		);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT i.*, i.sent_to_contact_id contact_id, iq.due_dtm, q.chain_questionnaire_id, q.friendly_name  
		  FROM invite i, invite_questionnaire iq, chain_questionnaire q, TABLE(v_invite_id_t) it, TABLE(v_questionnaire_t) qt
		 WHERE i.app_sid = security_pkg.GetApp
		   AND i.app_sid = q.app_sid
		   AND i.sent_by_company_sid = company_pkg.GetCompany
		   AND i.sent_by_user_sid = security_pkg.GetSid
		   AND i.invite_id = iq.invite_id
		   AND q.chain_questionnaire_id = iq.chain_questionnaire_id
		   AND i.invite_id = it.COLUMN_VALUE
		   AND q.chain_questionnaire_id = qt.ITEM_ID;
	
END;
	
PROCEDURE SendingReminder (
	in_invite_id			IN  invite_questionnaire.invite_id%TYPE,
	in_questionnaire_id		IN  invite_questionnaire.chain_questionnaire_id%TYPE,
	out_cur_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_contact_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_contact_id			contact.contact_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
	v_questionnaire_id		chain_questionnaire.chain_questionnaire_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), company_pkg.GetCompany, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with sid '||company_pkg.GetCompany);
	END IF;
	
	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, company_pkg.GetCompany) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user for '||company_pkg.GetCompany||'.');
	END IF;
	
	-- update the invite data
	UPDATE invite_questionnaire
	   SET last_msg_dtm = sysdate, reminder_count = reminder_count + 1, last_msg_from_user_sid = security_pkg.GetSid
	 WHERE last_msg_from_company_sid = company_pkg.GetCompany
	   AND app_sid = security_pkg.GetApp
   	   AND invite_id = in_invite_id
   	   AND chain_questionnaire_id = in_questionnaire_id;
   	
   	-- get the data needed for the message
   	SELECT contact_id, supplier_user_sid
	  INTO v_contact_id, v_user_sid
	  FROM v$company_questionnaire
	 WHERE invite_id = in_invite_id
	   AND chain_questionnaire_id = in_questionnaire_id
	   AND app_sid = security_pkg.GetApp
	   AND procurer_company_sid = company_pkg.GetCompany;
	
	-- get the user details of the logged on user
	company_user_pkg.GetUser(out_cur_user_cur);
	
	IF v_contact_id IS NOT NULL THEN
	
		-- create the message
		message_pkg.CreateMessage(
			message_pkg.MT_CONTACT_QI_REMINDER,
			null, null, null,
			security_pkg.GetSid,
			v_questionnaire_id,
			v_contact_id,
			message_pkg.MIDT_CONTACT			
		);

		-- get the details of the contact, invite and chain_questionnaire
		OPEN out_contact_cur FOR
			SELECT cq.*, c.full_name, c.email, c.contact_guid 
			  FROM v$company_questionnaire cq, v$contact c  
			 WHERE cq.procurer_company_sid = company_pkg.GetCompany
			   AND cq.contact_id = c.contact_id
			   AND cq.app_sid = c.app_sid
			   AND cq.app_sid = security_pkg.GetApp
			   AND invite_id = in_invite_id;
	
	END IF;
	
	IF v_user_sid IS NOT NULL THEN
		
		message_pkg.CreateMessage(
			message_pkg.MT_CONTACT_QI_REMINDER,
			null, null, null,
			security_pkg.GetSid,
			v_questionnaire_id,
			v_contact_id,
			message_pkg.MIDT_CONTACT			
		);
	
		OPEN out_contact_cur FOR
			SELECT cq.*, NVL(vcu.full_name, vcu.job_title), vcu.email, null contact_guid
			  FROM v$company_questionnaire cq, v$chain_user vcu
			 WHERE cq.procurer_company_sid = company_pkg.GetCompany
			   AND cq.supplier_user_sid = vcu.csr_user_sid
			   AND cq.app_sid = vcu.app_sid
			   AND cq.app_sid = security_pkg.GetApp
			   AND invite_id = in_invite_id;
	END IF;
	
END;

PROCEDURE CancelInvite (
	in_invite_id			IN  invite.invite_id%TYPE
)
AS
	v_count					number(10);
	v_contact_id			contact.contact_id%TYPE;
	v_questionnaire_id		chain_questionnaire.chain_questionnaire_id%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), company_pkg.GetCompany, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with sid '||company_pkg.GetCompany);
	END IF;

	-- get the data needed for the message (before we flag everything as deleted!)
	SELECT contact_id, chain_questionnaire_id
	  INTO v_contact_id, v_questionnaire_id
	  FROM v$company_questionnaire
	 WHERE invite_id = in_invite_id
	   AND app_sid = security_pkg.GetApp
	   AND procurer_company_sid = company_pkg.GetCompany;
	
	-- verify that we have an invite to delete
	SELECT COUNT(*)
	  INTO v_count
	  FROM invite
	 WHERE invite_id = in_invite_id
	   AND app_sid = security_pkg.GetApp
	   AND sent_by_company_sid = company_pkg.GetCompany;

	-- if we don't find a valid invite, kick and scream
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Cannot find the invite with id '||in_invite_id||', company sid of '||company_pkg.GetCompany||
			' and application sid of '||security_pkg.GetApp
		);
	END IF;
	
	-- flag the invite data as removed
	UPDATE invite
	   SET invite_status_id = INVITE_CANCELLED,
	       last_status_change_dtm = SYSDATE
	 WHERE invite_id = in_invite_id
	   AND app_sid = security_pkg.GetApp
	   AND sent_by_company_sid = company_pkg.GetCompany;
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	-- check to see if the contact is involved in any other invitations
	SELECT COUNT(*)
	  INTO v_count
	  FROM invite i
	 WHERE i.sent_to_contact_id = v_contact_id
	   AND i.app_sid = security_pkg.GetApp
	   AND i.sent_by_company_sid = company_pkg.GetCompany;

	-- if they're not in use, flag them as removed 
	-- (keeps lists a bit cleaner since there's no other method of user->contact management)
	IF v_count = 0 THEN
		UPDATE contact
		   SET contact_state_id = contact_pkg.CONTACT_REMOVED_BY_SUPPLIER,
		       last_contact_state_update_dtm = SYSDATE
		 WHERE app_sid = security_pkg.GetApp
		   AND owner_company_sid = company_pkg.GetCompany
       	   AND contact_id = v_contact_id;
	END IF;
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------

	-- create the cancellation message
	message_pkg.CreateMessage(
		message_pkg.MT_CONTACT_QI_CANCELLED,
		null, null, null,
		security_pkg.GetSid,
		v_questionnaire_id,
		v_contact_id,
		message_pkg.MIDT_CONTACT
	);
END;

PROCEDURE GetInvitesForGuid (
	in_contact_guid			IN  contact.contact_guid%TYPE,
	out_invite_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_contact_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	-- this needs to be publicly available, so no sec checks
	OPEN out_invite_cur FOR
		SELECT vcu.csr_user_sid sent_from_user_sid, vcu.full_name sent_from_full_name, 
			   vcu.job_title sent_from_user_job_title, vcu.email sent_from_user_email, 
			   ac.name sent_from_company_name, q.chain_questionnaire_id, q.friendly_name questionnaire_name, 
			   q.description questionnaire_description, iq.due_dtm, 
		       c.contact_id, c.contact_guid
	      FROM v$contact c, invite i, invite_questionnaire iq, chain_questionnaire q, v$all_chain_user vcu, all_company ac 
	     WHERE c.app_sid = v_app_sid
	       AND c.app_sid = i.app_sid
	       AND c.app_sid = vcu.app_sid
	       AND c.app_sid = q.app_sid
	       AND c.app_sid = iq.app_sid
	       AND c.app_sid = ac.app_sid
	       AND ac.company_sid = i.sent_by_company_sid
	       AND ac.company_sid = vcu.company_sid
	       AND vcu.csr_user_sid = i.sent_by_user_sid
	       AND c.contact_id = i.sent_to_contact_id
	       AND i.invite_id = iq.invite_id
	       AND iq.chain_questionnaire_id = q.chain_questionnaire_id
	       AND LOWER(c.contact_guid) = LOWER(in_contact_guid)
	     ORDER BY LOWER(q.friendly_name) DESC;
	     
	GetContactByGuid(in_contact_guid, out_contact_cur);
END;

PROCEDURE GetContactByGuid (
	in_contact_guid			IN  contact.contact_guid%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	-- this needs to be publicly available, so no sec checks
	OPEN out_cur FOR
		SELECT contact_id, contact_state_id, owner_company_sid, app_sid, contact_guid, existing_company_sid, existing_user_sid,
		       last_contact_state_update_dtm, registered_to_company_sid, registered_as_user_sid, full_name, email, job_title, phone_number,
		       company_name, address_1, address_2, address_3, address_4, town, state, postcode, country_code, estimated_annual_spend,
		       currency_code
		  FROM v$contact
		 WHERE app_sid = v_app_sid
		   AND LOWER(contact_guid) = LOWER(in_contact_guid);
END;
	
END invite_pkg;
/
