CREATE OR REPLACE PACKAGE BODY CHAIN.invitation_pkg
IS

FUNCTION GetAllowedInvitationTypes_
RETURN T_NUMBER_LIST;

PROCEDURE AnnounceSids
AS
	v_user_name			varchar2(100);
	v_company_name		varchar2(100);
BEGIN
	SELECT so.name
	  INTO v_user_name
	  FROM security.securable_object so
	 WHERE so.sid_id = SYS_CONTEXT('SECURITY', 'SID');
	  /*
	  , v_company_name
	  FROM security.securable_object so, chain.company c
	 WHERE so.sid_id = SYS_CONTEXT('SECURITY', 'SID')
	   AND c.company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), SYS_CONTEXT('SECURITY', 'SID'));
	*/
	RAISE_APPLICATION_ERROR(-20001, '"'||v_user_name||'" of "'||v_company_name||'"');
END;

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION GetInvitationStateByGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_invitation_id			OUT invitation.invitation_id%TYPE,
	out_to_user_sid				OUT security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
	v_to_company_active			company.active%TYPE;
BEGIN
	-- at this point, we only want to expire the invitation that we're looking at, otherwise it's possible that a user of a valid invitation can't accept because of another expired invitation
	BEGIN
		SELECT invitation_id
		  INTO out_invitation_id
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid)	
		   AND reinvitation_of_invitation_id IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;
	
	-- make sure that the expiration status' have been updated
	UpdateExpirations(out_invitation_id);
	
	-- if the invite type is SELF_REG_Q_INVITATION and the company is ACTIVE then cancel it
	-- as only the first user for any company is allowed to self register
	IF GetInvitationTypeByGuid(in_guid) = chain_pkg.SELF_REG_Q_INVITATION THEN 
		SELECT DECODE(c.deleted, 1, 0, c.active) active -- treat deleted companies as inactive 
		  INTO v_to_company_active 
		  FROM invitation i, company c
		 WHERE i.to_company_sid = c.company_sid
		   AND i.app_sid = c.app_sid
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND LOWER(guid) = LOWER(in_guid);
		
		IF v_to_company_active = chain_pkg.ACTIVE THEN
			-- reject the invite as the company is active - therefore someone else has registered
			RejectInvitation(in_guid, chain_pkg.ANOTHER_USER_REGISTERED);
		END IF;
	END IF;

	BEGIN
		SELECT i.invitation_id, i.invitation_status_id, i.to_user_sid
		  INTO out_invitation_id, v_invitation_status_id, out_to_user_sid
		  FROM invitation i, v$company fc, v$company tc
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = tc.app_sid
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.to_company_sid = tc.company_sid
		   AND LOWER(i.guid) = LOWER(in_guid)
       AND i.reinvitation_of_invitation_id IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;

	IF v_invitation_status_id <> chain_pkg.ACTIVE THEN
		OPEN out_state_cur FOR
			SELECT CASE
				WHEN v_invitation_status_id = chain_pkg.EXPIRED THEN chain_pkg.GUID_EXPIRED
				WHEN v_invitation_status_id = chain_pkg.ANOTHER_USER_REGISTERED THEN chain_pkg.GUID_ANOTHER_USER_REGISTERED
				ELSE chain_pkg.GUID_ALREADY_USED
				END guid_state FROM DUAL;
		RETURN FALSE;
	END IF;

	-- only include the to_user_sid if the guid is ok
	OPEN out_state_cur FOR
		SELECT chain_pkg.GUID_OK guid_state, out_to_user_sid to_user_sid FROM DUAL;

	RETURN TRUE;
END;

FUNCTION GetInvitationStateByGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_invitation_id			OUT invitation.invitation_id%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	RETURN GetInvitationStateByGuid(in_guid, out_invitation_id, v_to_user_sid, out_state_cur);
END;

FUNCTION HasFullInviteListAccessBool
RETURN BOOLEAN
AS
	v_inv_mgr_full_access			NUMBER;
	v_admin_for_company				NUMBER;
BEGIN

	SELECT inv_mgr_norm_user_full_access INTO v_inv_mgr_full_access FROM customer_options WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_admin_for_company
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
	
	-- has full access if a chain admin, admin for the company, or the "full access" option flag is on
	RETURN (
		(helper_pkg.IsChainAdmin) OR
		(v_admin_for_company=1) OR 
		(v_inv_mgr_full_access=1)
	); 
END;


/**********************************************************************************
	PUBLIC
**********************************************************************************/


FUNCTION HasFullInviteListAccess
RETURN NUMBER
AS
BEGIN

	IF HasFullInviteListAccessBool THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
 
END;


FUNCTION GetInvitationTypeByGuid (
	in_guid						IN  invitation.guid%TYPE
) RETURN chain_pkg.T_INVITATION_TYPE
AS
	v_invitation_type_id		chain_pkg.T_INVITATION_TYPE;
BEGIN
	BEGIN
		SELECT invitation_type_id
		  INTO v_invitation_type_id
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid)
		   AND reinvitation_of_invitation_id IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_invitation_type_id := chain_pkg.UNDEFINED;
	END;

	RETURN v_invitation_type_id;
END;

PROCEDURE UpdateExpirations (
	in_invitation_id			IN invitation.invitation_id%TYPE DEFAULT NULL
)
AS
BEGIN
	-- don't worry about sec checks - this needs to be done anyways

	-- There's a very small possibility that an invitation will expire during the time from
	-- when a user first accesses the landing page, and when they actually submit the registration (or login).
	-- Instead of confusing them, let's only count it as expired if it expired more than an hour ago.
	-- We'll track this by checking if the expriation_grace flag is set.

	FOR r IN (
		SELECT *
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = NVL(in_invitation_id, invitation_id)
		   AND invitation_status_id = chain_pkg.ACTIVE
		   AND ((
				expiration_dtm < SYSDATE
				AND expiration_grace = chain_pkg.INACTIVE
		        ) OR (
				expiration_dtm < SYSDATE - (1/24) -- one hour grace period
				AND expiration_grace = chain_pkg.ACTIVE
		        ))
	) LOOP
		UPDATE invitation
		   SET invitation_status_id = chain_pkg.EXPIRED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = r.invitation_id;

		
		IF r.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION OR r.invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION THEN
			message_pkg.TriggerMessage (
				in_primary_lookup           => chain_pkg.INVITATION_EXPIRED,
				in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
				in_to_company_sid           => r.from_company_sid,
				in_to_user_sid              => chain_pkg.FOLLOWERS,
				in_re_company_sid           => r.to_company_sid,
				in_re_user_sid              => r.to_user_sid,
				in_system_wide				=> chain_pkg.ACTIVE
			);
		END IF;
		
		chain_link_pkg.InvitationExpired(r.invitation_id, r.from_company_sid, r.to_company_sid);
		-- TODO: cleanup the dead objects that were associated with the invitation
	END LOOP;
END;

/*******************************
CreateInvitation
******************************/

PROCEDURE BulkCreateInvitations (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_batch_job_id				IN	invitation.batch_job_id%TYPE,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS,
	in_to_company_sids			IN  security_pkg.T_SID_IDS,
	in_to_user_sids				IN  security_pkg.T_SID_IDS,
	in_obo_company_sids			IN  security_pkg.T_SID_IDS
)
AS
	v_dummy				security_pkg.T_OUTPUT_CUR;
	v_batch_job_lang	invitation_batch.lang%TYPE;
	v_curr_user_sid		security_pkg.T_SID_ID;
	v_user_lang			csr.v$csr_user.language%TYPE;
BEGIN
	SELECT lang
	  INTO v_batch_job_lang
	  FROM invitation_batch
	 WHERE app_sid = security_pkg.GetApp
	   AND batch_job_id = in_batch_job_id;
	  
	FOR i IN in_to_company_sids.FIRST .. in_to_company_sids.LAST
	LOOP
		v_curr_user_sid := in_to_user_sids(i);
		v_user_lang := NULL;
		
		IF v_curr_user_sid > 0 THEN
			SELECT language
			  INTO v_user_lang
			  FROM security.user_table
			 WHERE sid_id = v_curr_user_sid;
		END IF;
		
		CreateInvitation (
			in_invitation_type_id => in_invitation_type_id,
			in_batch_job_id => in_batch_job_id,
			in_qnr_types => in_qnr_types,
			in_due_dtm_strs => in_due_dtm_strs,
			in_on_behalf_of_company_sid => CASE WHEN in_obo_company_sids(i) < 0 THEN NULL ELSE in_obo_company_sids(i) END,
			in_to_company_sid => in_to_company_sids(i),
			in_to_user_sid => v_curr_user_sid,
			in_lang	=> NVL(v_user_lang, v_batch_job_lang),
			out_cur => v_dummy
		);
	END LOOP;
END;

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_from_user_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_on_behalf_of_company_sid	IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE DEFAULT NULL,
	in_expiration_life_days		IN  NUMBER DEFAULT 0,
	in_qnr_types				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_component_id				IN 	chain.component.component_id%TYPE DEFAULT NULL, --maps to a purchased component
	in_lang						IN	VARCHAR2 DEFAULT NULL,
	in_batch_job_id				IN	invitation.batch_job_id%TYPE DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_on_behalf_of_company_sid  security_pkg.T_SID_ID DEFAULT CASE WHEN in_on_behalf_of_company_sid = 0 THEN NULL ELSE in_on_behalf_of_company_sid END;
	v_invitation_id				invitation.invitation_id%TYPE DEFAULT 0;
	v_created_invite			BOOLEAN DEFAULT FALSE;
	v_expiration_life_days		NUMBER;
	v_count						NUMBER;
	v_to_company_type_id		company_type.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_to_company_sid);
	v_on_bhlf_company_type_id	company_type.company_type_id%TYPE;
	v_product_id  				chain.product.product_id%TYPE;
	v_auto_map					customer_options.purchased_comp_auto_map%TYPE;
	v_supplier_root_component_id	product_revision.supplier_root_component_id%TYPE;	
BEGIN
	
	IF NVL(in_expiration_life_days,0) = 0 THEN
		SELECT invitation_expiration_days INTO v_expiration_life_days
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSE
		v_expiration_life_days := in_expiration_life_days;
	END IF;
	
	UpdateExpirations;
	
	-- For product questionnaire always create new invitation records 
	-- Otherwise, when the invitation is accepted, questionnaire user actions will only be assigned to the user that sent the 1st invitation
	-- Leave the process as it is for standard qnr invitations(possibly, it was built that way so the user didn't have to accept every single invitation to start the questionnaire)
	IF in_component_id IS NULL THEN
		BEGIN
			SELECT invitation_id
			  INTO v_invitation_id
			  FROM v$active_invite ai
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND invitation_type_id = in_invitation_type_id
			   AND from_company_sid = in_from_company_sid
			   AND NVL(on_behalf_of_company_sid, 0) = NVL(v_on_behalf_of_company_sid, 0)
			   AND to_company_sid = in_to_company_sid
			   AND to_user_sid = in_to_user_sid
			   AND NOT EXISTS(
					SELECT 1
					  FROM chain.invitation_qnr_type_component iqtc
					 WHERE iqtc.app_sid = security_pkg.GetApp
					   AND iqtc.invitation_id = ai.invitation_id
				);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;

	-- if the invitation doesn't exist, create a new one
	IF v_invitation_id = 0 THEN
		INSERT INTO invitation
		(	invitation_id, invitation_type_id, guid,
			from_company_sid, from_user_sid,
			on_behalf_of_company_sid,
			to_company_sid, to_user_sid,
			expiration_dtm, lang, batch_job_id
		)
		VALUES
		(
			invitation_id_seq.NEXTVAL, in_invitation_type_id, user_pkg.GenerateACT,
			in_from_company_sid, in_from_user_sid,
			v_on_behalf_of_company_sid,
			in_to_company_sid, in_to_user_sid,
			SYSDATE + v_expiration_life_days,
			in_lang, in_batch_job_id
		)
		RETURNING invitation_id INTO v_invitation_id;

		v_created_invite := TRUE;
	ELSE	
		-- if it does exist, reset the expiration dtm and mark as being ready to send
		UPDATE invitation
		   SET expiration_dtm = GREATEST(expiration_dtm, SYSDATE + v_expiration_life_days),
			   sent_dtm = NULL, batch_job_id = in_batch_job_id, lang = in_lang
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = v_invitation_id;
	END IF;


	IF in_invitation_type_id <> chain_pkg.REQUEST_QNNAIRE_INVITATION AND in_qnr_types.COUNT <> 0 AND NOT (in_qnr_types.COUNT = 1 AND in_qnr_types(in_qnr_types.FIRST) IS NULL) THEN

		IF helper_pkg.UseTraditionalCapabilities THEN
			IF NOT capability_pkg.CheckCapability(in_from_company_sid, chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitations');
			END IF;
		ELSE
			IF v_on_behalf_of_company_sid IS NULL THEN
				IF NOT type_capability_pkg.CheckCapabilityBySupplierType(in_from_company_sid, company_type_pkg.GetCompanyTypeId(in_to_company_sid), chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitations');
				END IF;
			ELSE
				v_on_bhlf_company_type_id := company_type_pkg.GetCompanyTypeId(v_on_behalf_of_company_sid);
				
				IF NOT (type_capability_pkg.CheckCapabilityBySupplierType(in_from_company_sid, v_on_bhlf_company_type_id, v_to_company_type_id, chain_pkg.QNR_INVITE_ON_BEHALF_OF)
					OR type_capability_pkg.CheckCapabilityBySupplierType(in_from_company_sid, v_on_bhlf_company_type_id, v_to_company_type_id, chain_pkg.QNR_INV_ON_BEHLF_TO_EXIST_COMP)) THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitation on behalf of company with sid '||v_on_behalf_of_company_sid);
				END IF;
			END IF;
		END IF;

		IF in_qnr_types.COUNT <> in_due_dtm_strs.COUNT THEN
			RAISE_APPLICATION_ERROR(-20001, 'Questionnaire Type Id array has a different number of elements than the Due Date Array');
		END IF;

		FOR i IN in_qnr_types.FIRST .. in_qnr_types.LAST
		LOOP
			-- for qnr invitations, check any existing qnr shares and re-send them
			-- TODO: Should this resend from the obo company or the from company?
			-- we can't see shares to the obo company with v$questionnaire_share
			-- because the view filters them out. There may also be permissions issues
			-- within questionnaire_pkg.ReSendQuestionnaire as we won't be logged in
			-- as either the two involved companies in the questionnaire share
			FOR qnr IN (
				SELECT questionnaire_share_id
				  FROM v$questionnaire_share qs
				  JOIN questionnaire_type qt ON qs.questionnaire_type_id = qt.questionnaire_type_id
				 WHERE qt.questionnaire_type_id = in_qnr_types(i)
				   AND qnr_owner_company_sid = in_to_company_sid
				   AND share_with_company_sid = in_from_company_sid
				   AND DECODE(component_id, in_component_id, 1) = 1
				   AND share_status_id NOT IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED, chain_pkg.SHARED_DATA_REJECTED)
				   AND qt.is_resendable = 1
			) LOOP
				questionnaire_pkg.ReSendQuestionnaire(qnr.questionnaire_share_id, helper_pkg.StringToDate(in_due_dtm_strs(i)));
			END LOOP;

			BEGIN
				INSERT INTO invitation_qnr_type
				(invitation_id, questionnaire_type_id, added_by_user_sid, requested_due_dtm)
				VALUES
				(v_invitation_id, in_qnr_types(i), in_from_user_sid, helper_pkg.StringToDate(in_due_dtm_strs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- TODO: Notify in_from_user_sid that added_by_user_sid had
					-- already sent the invite, otherwise, just ignore it
					-- (in normal circumstances we should be checking if this exists already,
					-- so let's just assume that it's been a race overlap)
					NULL;
			END;
		END LOOP;
	END IF;
	
	--todo: Insert qnnaire types into invitation_qnr_type for REQUEST_QNNAIRE_INVITATION (REQUESTED_DUE_DTM should be null)

	IF v_created_invite THEN
		CASE
			WHEN in_invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
			
				-- TO DO - more sophisticated solution - this is a bit of a heavyweight plugging of a security hole. 
				-- There is no good reason as things stand that a top company will be sent an invite (self reg and stub maybe OK but not normal invite)
				-- and in some systems this could expose data (e.g. RA) about a top company's suppliers to another top company
				IF helper_pkg.IsSidTopCompany(in_to_company_sid) = 1 THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitation to top company '||in_to_company_sid);
				END IF;
			
				-- start the company relationship (it will be inactive if not already present, but in there)
				company_pkg.StartRelationship(
					in_purchaser_company_sid		=> in_from_company_sid,
					in_supplier_company_sid			=> in_to_company_sid,
					in_supp_rel_code				=> in_supp_rel_code
				);
				
				IF company_pkg.CanAddSupplierFollower(in_from_company_sid, v_to_company_type_id, in_from_user_sid) THEN
					company_pkg.AddSupplierFollower_UNSEC(in_from_company_sid, in_to_company_sid, in_from_user_sid);
				END IF;

				message_pkg.TriggerMessage (
					in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	  	 	=> in_from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	  	 	=> in_to_company_sid,
					in_re_user_sid		  		=> in_to_user_sid
				);
				
				IF v_on_behalf_of_company_sid IS NOT NULL THEN
					company_pkg.StartRelationship(
						in_purchaser_company_sid		=> v_on_behalf_of_company_sid,
						in_supplier_company_sid			=> in_to_company_sid,
						in_supp_rel_code				=> in_supp_rel_code
					);
					-- Original comment: i think that we need at least one user inorder for any company user to be able to view the messages
					-- This line doesn't work unless you're a chain admin - even then it makes no sense (the logged in user
					-- isn't a member of the OBO company, otherwise they'd be logged on as the OBO inviting directly) so removing
					-- company_pkg.AddSupplierFollower(v_on_behalf_of_company_sid, in_to_company_sid, in_from_user_sid); 

					message_pkg.TriggerMessage (
						in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
						in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
						in_to_company_sid	  	 	=> v_on_behalf_of_company_sid,
						in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
						in_re_company_sid	  	 	=> in_to_company_sid,
						in_re_user_sid		  		=> in_to_user_sid,
						in_system_wide				=> chain_pkg.ACTIVE
					);
				END IF;

			WHEN in_invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- TODO: Do we need to let anyone know that anything has happened?
				NULL;
			WHEN in_invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION THEN
				-- start the company relationship (it will be inactive if not already present, but in there)
				company_pkg.StartRelationship(
					in_purchaser_company_sid		=> in_from_company_sid,
					in_supplier_company_sid			=> in_to_company_sid,
					in_supp_rel_code				=> in_supp_rel_code
				);
				--company_pkg.AddSupplierFollower(in_from_company_sid, in_to_company_sid, in_from_user_sid);
				--company_pkg.AddPurchaserFollower(in_from_company_sid, in_to_company_sid, in_from_user_sid);
				
				-- // TO DO - ignore invitation messaging atm				
				
			WHEN in_invitation_type_id = chain_pkg.NO_QUESTIONNAIRE_INVITATION THEN
				IF NOT type_capability_pkg.CheckCapabilityBySupplierType(in_from_company_sid, v_to_company_type_id, chain_pkg.SEND_COMPANY_INVITE) THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending company invitations');
				END IF;
				
				company_pkg.StartRelationship(
					in_purchaser_company_sid		=> NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')),
					in_supplier_company_sid			=> in_to_company_sid,
					in_supp_rel_code				=> in_supp_rel_code
				);
				
				IF company_pkg.CanAddSupplierFollower(NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')), v_to_company_type_id, in_from_user_sid) THEN
					company_pkg.AddSupplierFollower_UNSEC(NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')), in_to_company_sid, in_from_user_sid);
				END IF;

				message_pkg.TriggerMessage (
					in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	  	 	=> NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')),
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	  	 	=> in_to_company_sid,
					in_re_user_sid		  		=> in_to_user_sid
				);
			WHEN in_invitation_type_id = chain_pkg.REQUEST_QNNAIRE_INVITATION THEN
				IF NOT type_capability_pkg.CheckCapabilityBySupplierType(in_from_company_sid, v_to_company_type_id, chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB) AND 
					NOT type_capability_pkg.CheckCapabilityBySupplierType(in_from_company_sid, v_to_company_type_id, chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS) THEN 
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied requesting company questionnaire');
				END IF;
				
				company_pkg.StartRelationship(
					in_purchaser_company_sid		=> NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')),
					in_supplier_company_sid			=> in_to_company_sid,
					in_supp_rel_code				=> in_supp_rel_code
				);
				
				IF company_pkg.CanAddSupplierFollower(NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')), v_to_company_type_id, in_from_user_sid) THEN
					company_pkg.AddSupplierFollower_UNSEC(NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')), in_to_company_sid, in_from_user_sid);
				END IF;
				
				message_pkg.TriggerMessage (
					in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	  	 	=> NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')),
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	  	 	=> in_to_company_sid,
					in_re_user_sid		  		=> in_to_user_sid
				);
				
				message_pkg.TriggerMessage (
					in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
					in_secondary_lookup	 		=> chain_pkg.SUPPLIER_MSG,
					in_to_company_sid	  	 	=> in_to_company_sid,
					in_re_company_sid	  	 	=> NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')),
					in_re_user_sid		  		=> in_from_user_sid,
					in_re_invitation_id			=> v_invitation_id
				);
				
				--send a msg to top company if top_company_sid <> from_company_sid
				IF NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) <> helper_pkg.GetTopCompanySid THEN
					
					message_pkg.TriggerMessage (
						in_primary_lookup	   		=> chain_pkg.INVITATION_SENT_FROM_B_TO_C,
						in_to_company_sid	   		=> helper_pkg.GetTopCompanySid,
						in_re_company_sid	   		=> in_to_company_sid,
						in_re_user_sid		  		=> in_to_user_sid,
						in_re_secondary_company_sid	=> in_from_company_sid
					);
				END IF;	
			
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||in_invitation_type_id||') event notification not handled');
		END CASE;
		
		-- Migrate any uninvited duplicate companies 
		-- Only being used by rainforest-alliance custom invites. Don't bother changing it to use the region layout for identifying dupes
		FOR uninv IN (
			SELECT u.uninvited_supplier_sid
			  FROM uninvited_supplier u
			  JOIN company c ON u.app_sid = c.app_sid 
			   AND LOWER(helper_pkg.NormaliseCompanyName(u.name)) = LOWER(helper_pkg.NormaliseCompanyName(c.name)) 
			   AND LOWER(c.country_code) = LOWER(u.country_code)
			 WHERE u.app_sid = security_pkg.GetApp
			   AND u.created_as_company_sid IS NULL
			   AND c.pending = 0
			   AND c.deleted = 0
			   AND u.company_sid = in_from_company_sid
			   AND u.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND c.company_sid = in_to_company_sid
		) LOOP
			uninvited_pkg.MigrateUninvitedToCompany(uninv.uninvited_supplier_sid, in_to_company_sid, in_supp_rel_code);
		END LOOP;
 	ELSE
		--we want to start again the relationship (mark deleted = 0) in case a previous invitation had been rejected
		IF in_invitation_type_id = chain_pkg.REQUEST_QNNAIRE_INVITATION THEN
			company_pkg.StartRelationship(
				in_purchaser_company_sid		=> NVL(in_from_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')),
				in_supplier_company_sid			=> in_to_company_sid,
				in_supp_rel_code				=> in_supp_rel_code
			);
		END IF;
	END IF;
	
	--check if this invite has a component_id (ie. it has at least one component questionnaire attached)
	IF in_component_id IS NOT NULL THEN
		SELECT purchased_comp_auto_map 
		  INTO v_auto_map 
		  FROM customer_options;

		v_product_id := purchased_component_pkg.TryGetMappedProduct(in_component_id, in_to_company_sid);
		--no mapping found, auto map if option is set
		
		IF v_product_id = 0 AND v_auto_map = 1 THEN
			--this action also creates a product id
			v_product_id := purchased_component_pkg.AutoMap(in_component_id, in_to_company_sid);
		END IF;			
		--go through questionnaires again, and add component entries for any component questionnaires being sent
		FOR i IN in_qnr_types.FIRST .. in_qnr_types.LAST
		LOOP
			BEGIN
				IF questionnaire_pkg.IsProductQuestionnaireType(in_qnr_types(i)) = 1 THEN
					IF v_product_id = 0 OR v_product_id IS NULL THEN
						--couldn't get a mapping
						-- TODO: Add an "UNMAPPED" state for component questionnaires where they are inactive until mapped to a product by the supplier
						RAISE_APPLICATION_ERROR(-20001, 'Cannot send an invitation with one or more product questionnaires for an unmapped product. (purchased component id: '||in_component_id||' supplier sid: '||in_to_company_sid||' product questionnaire type id: )' || in_qnr_types(i));
					END IF;
					--store the product's pseudo root component
					v_supplier_root_component_id := product_pkg.GetLastRevisionPseudoRootCmpId(v_product_id);
					INSERT INTO invitation_qnr_type_component(invitation_id, questionnaire_type_id, component_id)
						VALUES(v_invitation_id, in_qnr_types(i), v_supplier_root_component_id); 
				END IF;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;
		
	END IF;

	OPEN out_cur FOR
		SELECT 	invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace, 
				expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm, reinvitation_of_invitation_id, lang
		  FROM invitation
		 WHERE invitation_id = v_invitation_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	-- hook to customised system	
	chain_link_pkg.InviteCreated(v_invitation_id, in_from_company_sid, in_to_company_sid, in_to_user_sid);
END;

PROCEDURE GetInvitationForLanding (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qt_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	-- no sec checks - if they know the guid, they've got permission

	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, out_state_cur) THEN
		RETURN;
	END IF;

	-- set the grace period allowance
	UPDATE invitation
	   SET expiration_grace = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = v_invitation_id;

	--fb22010: remove customer options from query, make a separate call wherever is needed
	OPEN out_invitation_cur FOR
		SELECT tc.company_sid to_company_sid, tc.name to_company_name, tu.full_name to_user_name,
			   fc.name from_company_name, fu.full_name from_user_name, obo.company_sid on_behalf_of_company_sid,
			   obo.name on_behalf_of_company_name, tu.registration_status_id, i.guid, tu.email to_user_email,
			   tu.user_name to_user_id, i.lang, CASE WHEN pi.cnt > 0 THEN 1 ELSE 0 END relationship_active
		  FROM invitation i
		  JOIN company tc
		    ON i.app_sid = tc.app_sid
		   AND i.to_company_sid = tc.company_sid
		  JOIN v$chain_user tu
		    ON i.app_sid = tu.app_sid
		   AND i.to_user_sid = tu.user_sid
		  LEFT JOIN company fc
		    ON i.app_sid = fc.app_sid
		   AND i.from_company_sid = fc.company_sid
		  LEFT JOIN v$chain_user fu
		    ON i.app_sid = fu.app_sid
		   AND i.from_user_sid = fu.user_sid
		  LEFT JOIN company obo
		    ON i.app_sid = obo.app_sid
		   AND i.on_behalf_of_company_sid = obo.company_sid
		  LEFT JOIN (
				SELECT pi.from_company_sid, pi.to_company_sid, COUNT(*) cnt
				  FROM invitation pi
				 WHERE pi.invitation_id != v_invitation_id
				   AND pi.invitation_status_id = chain_pkg.ACCEPTED
				 GROUP BY pi.from_company_sid, pi.to_company_sid
				) pi
		    ON i.from_company_sid = pi.from_company_sid
		   AND i.to_company_sid = pi.to_company_sid
		  LEFT JOIN supplier_relationship sr
		    ON i.app_sid = sr.app_sid
		   AND i.from_company_sid = sr.purchaser_company_sid
		   AND i.to_company_sid = sr.supplier_company_sid
		   AND sr.deleted = 0
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.invitation_id = v_invitation_id;

	OPEN out_invitation_qt_cur FOR
		SELECT qt.name
		  FROM invitation_qnr_type iqt
		  JOIN questionnaire_type qt
		    ON iqt.app_sid = qt.app_sid
		   AND iqt.questionnaire_type_id = qt.questionnaire_type_id
		 WHERE iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND iqt.invitation_id = v_invitation_id;
END;

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_state_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	AcceptInvitation(in_guid, in_as_user_sid, v_state_cur);
END;

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_act_id						security_pkg.t_act_id;
BEGIN
	-- this is just a dummy check - it will get properly filled in later
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;

	AcceptInvitation(v_invitation_id, in_as_user_sid, NULL, NULL, NULL, NULL, NULL);
END;


PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD,
	in_language					IN	security.user_table.language%TYPE DEFAULT NULL,
	in_culture					IN	security.user_table.culture%TYPE DEFAULT NULL,
	in_timezone					IN	security.user_table.timezone%TYPE DEFAULT NULL,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	-- no sec checks - if they know the guid, they've got permission
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;
	
	AcceptInvitation(v_invitation_id, v_to_user_sid, in_full_name, in_password, in_language, in_culture, in_timezone);
END;

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE,
	in_password					IN  Security_Pkg.T_USER_PASSWORD,
	in_language					IN	security.user_table.language%TYPE DEFAULT NULL,
	in_culture					IN	security.user_table.culture%TYPE DEFAULT NULL,
	in_timezone					IN	security.user_table.timezone%TYPE DEFAULT NULL
)
AS
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
	v_invitation_type_id		chain_pkg.T_INVITATION_TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_to_company_sid			security_pkg.T_SID_ID;
	v_from_company_sid			security_pkg.T_SID_ID;
	v_on_behalf_of_company_sid	security_pkg.T_SID_ID;
	v_is_company_admin			NUMBER(1);
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE;
	v_approve_stub_registration	company.approve_stub_registration%TYPE;
	v_allow_stub_registration 	company.allow_stub_registration%TYPE;
	v_share_started				BOOLEAN;
	v_has_questionnaire			BOOLEAN := FALSE;
	v_reg_terms_vers			NUMBER(10,5);
	v_share_with_on_behalf_enabled	NUMBER(1, 0) := chain.helper_pkg.IsShareQnrWithOnBehalfEnabled;
	v_share_with_company_sid	security_pkg.T_SID_ID;
	v_share_status				chain_pkg.T_SHARE_STATUS;
BEGIN

	-- get the details
	SELECT invitation_status_id, to_user_sid, to_company_sid, from_company_sid, invitation_type_id, on_behalf_of_company_sid
	  INTO v_invitation_status_id, v_to_user_sid, v_to_company_sid, v_from_company_sid, v_invitation_type_id, v_on_behalf_of_company_sid
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;

	IF v_invitation_type_id = chain_pkg.STUB_INVITATION THEN
		SELECT allow_stub_registration, approve_stub_registration
		  INTO v_allow_stub_registration, v_approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_to_company_sid;

		IF v_allow_stub_registration = chain_pkg.INACTIVE THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing stub registration for invitation id '||in_invitation_id);
		END IF;
	END IF;

	BEGIN
		helper_pkg.LogonUCD(v_to_company_sid);

		IF in_as_user_sid != v_to_user_sid THEN
			company_user_pkg.SetMergedStatus(v_to_user_sid, in_as_user_sid);
		END IF;
		-- set this to null so that i stop trying to use it!
		v_to_user_sid := NULL;
		
		-- activate the company
		company_pkg.ActivateCompany(v_to_company_sid);
		-- add the user to the company
		company_user_pkg.AddUserToCompany(v_to_company_sid, in_as_user_sid);
		IF v_from_company_sid IS NOT NULL THEN
			-- We get here for employee self registation (aka stub registration)
			company_pkg.AddPurchaserFollower(v_from_company_sid, v_to_company_sid, in_as_user_sid);
		END IF;
		
		IF v_invitation_type_id = chain_pkg.STUB_INVITATION AND v_approve_stub_registration = chain_pkg.INACTIVE THEN
			company_user_pkg.ApproveUser(v_to_company_sid, in_as_user_sid);
		END IF;

		-- see if the accepting user is an admin user
		SELECT COUNT(*)
		  INTO v_is_company_admin
		  FROM TABLE(group_pkg.GetMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(v_act_id, v_to_company_sid, chain_pkg.ADMIN_GROUP)))
		 WHERE sid_id = in_as_user_sid;

		IF v_invitation_status_id <> chain_pkg.ACTIVE AND v_invitation_status_id <> chain_pkg.PROVISIONALLY_ACCEPTED THEN
			-- TODO: decide if we want an exception here or not...
			RETURN;
		END IF;

		-- may end up doing a double update on the status, but that's by design
		IF v_invitation_status_id = chain_pkg.ACTIVE THEN

			UPDATE invitation
			   SET invitation_status_id = chain_pkg.PROVISIONALLY_ACCEPTED
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND invitation_id = in_invitation_id;

			IF v_invitation_type_id IN (chain_pkg.QUESTIONNAIRE_INVITATION, chain_pkg.SELF_REG_Q_INVITATION, chain_pkg.NO_QUESTIONNAIRE_INVITATION) THEN
				-- we can activate the relationship now
				company_pkg.ActivateRelationship(v_from_company_sid, v_to_company_sid);
				
				IF v_on_behalf_of_company_sid IS NOT NULL THEN
					company_pkg.ActivateRelationship(v_on_behalf_of_company_sid, v_to_company_sid);
				END IF;
			END IF;

			-- loop round all questionnaire types for this invite 
			FOR i IN (
				SELECT i.to_company_sid, i.to_user_sid, iqt.questionnaire_type_id, iqt.requested_due_dtm, i.from_user_sid, i.from_company_sid, qt.class questionnaire_type_class, i.on_behalf_of_company_sid, iqtc.component_id, qt.security_scheme_id
				  FROM invitation i
				  JOIN invitation_qnr_type iqt ON iqt.app_sid = i.app_sid AND iqt.invitation_id = i.invitation_id
				  JOIN questionnaire_type qt ON iqt.questionnaire_type_id = qt.questionnaire_type_id
				  LEFT JOIN invitation_qnr_type_component iqtc ON iqtc.app_sid = i.app_sid AND iqtc.invitation_id = i.invitation_id AND iqtc.questionnaire_type_id = qt.questionnaire_type_id
				 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND i.invitation_id = in_invitation_id
				   
				-- SELECT i.to_company_sid, i.to_user_sid, iqt.questionnaire_type_id, iqt.requested_due_dtm, i.from_company_sid, qt.class questionnaire_type_class, i.on_behalf_of_company_sid
				  -- FROM invitation i, invitation_qnr_type iqt, questionnaire_type qt
				 -- WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   -- AND i.app_sid = iqt.app_sid
				   -- AND i.app_sid = qt.app_sid
				   -- AND i.invitation_id = in_invitation_id
				   -- AND i.invitation_id = iqt.invitation_id
				   -- AND iqt.questionnaire_type_id = qt.questionnaire_type_id
				   
			) LOOP
				v_has_questionnaire := TRUE;
				
				IF questionnaire_pkg.IsProductQuestionnaireType(i.questionnaire_type_id) = 1 AND i.component_id IS NULL THEN 
					RAISE_APPLICATION_ERROR(-20001, 'No component id found for product questionnaire of type '||i.questionnaire_type_id);
				END IF;
				
				-- check DEFAULT_SHARE_QNR_WITH_ON_BHLF. If it is enabled and on_behalf_company exists THEN share with on_behalf ELSE with company that sent the invitation (top_company)
				SELECT DECODE(v_share_with_on_behalf_enabled, 1, NVL(i.on_behalf_of_company_sid, i.from_company_sid), i.from_company_sid)
				  INTO v_share_with_company_sid
				  FROM DUAL;
				
				BEGIN
					v_questionnaire_id := questionnaire_pkg.InitializeQuestionnaire(i.to_company_sid, i.questionnaire_type_class, i.component_id);
				EXCEPTION
					WHEN chain_pkg.QNR_ALREADY_EXISTS THEN
						v_questionnaire_id := questionnaire_pkg.GetQuestionnaireId(i.to_company_sid, i.questionnaire_type_class, i.component_id);
				END;

				BEGIN
					INSERT INTO questionnaire_invitation
					(questionnaire_id, invitation_id)
					VALUES
					(v_questionnaire_id, in_invitation_id);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN NULL;
				END;
				
				BEGIN
					questionnaire_pkg.StartShareQuestionnaire(i.to_company_sid, v_questionnaire_id, v_share_with_company_sid, i.requested_due_dtm);	

					v_share_started := TRUE;
				EXCEPTION
					WHEN chain_pkg.QNR_ALREADY_SHARED THEN
						--If the share status is rejected we reactivate the questionnaire
						--TODO:we might need a new message as well
						v_share_status := questionnaire_pkg.UNSEC_GetQnnaireShareStatus(v_to_company_sid, v_from_company_sid, i.questionnaire_type_class, i.component_id);
						IF v_share_status = chain_pkg.SHARED_DATA_REJECTED THEN
							questionnaire_pkg.UNSEC_ReactivateQuestionnaire(v_to_company_sid, v_from_company_sid, i.questionnaire_type_class, i.component_id);
						END IF;
						v_share_started := FALSE;
				END;

				IF v_share_started THEN

					message_pkg.TriggerMessage (
						in_primary_lookup           => CASE WHEN i.component_id IS NULL THEN chain_pkg.COMPLETE_QUESTIONNAIRE ELSE chain_pkg.COMP_COMPLETE_QUESTIONNAIRE END,
						in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
						in_to_company_sid           => i.to_company_sid,
						in_to_user_sid              => chain_pkg.FOLLOWERS,
						in_re_company_sid           => v_share_with_company_sid,
						in_re_questionnaire_type_id => i.questionnaire_type_id,
						in_due_dtm					=> i.requested_due_dtm,
						in_re_component_id 			=> i.component_id							
					);
					
					FOR r IN (
						SELECT *
						  FROM v$qnr_security_scheme_summary
						 WHERE security_scheme_id = i.security_scheme_id
					) LOOP
						IF r.action_security_type_id = chain_pkg.AST_USERS THEN
							
							IF r.has_procurer_config = 1 THEN
								BEGIN
									INSERT INTO questionnaire_user
									(questionnaire_id, user_sid, company_function_id, company_sid)
									VALUES
									(v_questionnaire_id, i.from_user_sid, chain_pkg.PROCURER, i.from_company_sid);
								EXCEPTION
									WHEN DUP_VAL_ON_INDEX THEN
										NULL; 
								END;
								
								INSERT INTO questionnaire_user_action
								(questionnaire_id, user_sid, company_function_id, company_sid, questionnaire_action_id)
								SELECT v_questionnaire_id, i.from_user_sid, company_function_id, i.from_company_sid, questionnaire_action_id
								  FROM qnr_security_scheme_config
								 WHERE security_scheme_id = i.security_scheme_id
								   AND action_security_type_id = r.action_security_type_id
								   AND company_function_id = chain_pkg.PROCURER
								 MINUS 
								SELECT questionnaire_id, user_sid, company_function_id, company_sid, questionnaire_action_id
								  FROM questionnaire_user_action;
							END IF;
							
							IF r.has_supplier_config = 1 THEN
								BEGIN
									INSERT INTO questionnaire_user
									(questionnaire_id, user_sid, company_function_id, company_sid)
									VALUES
									(v_questionnaire_id, i.to_user_sid, chain_pkg.SUPPLIER, i.to_company_sid);
								EXCEPTION
									WHEN DUP_VAL_ON_INDEX
										THEN NULL; 
								END;
								
								INSERT INTO questionnaire_user_action
								(questionnaire_id, user_sid, company_function_id, company_sid, questionnaire_action_id)
								SELECT v_questionnaire_id, i.to_user_sid, company_function_id, i.to_company_sid, questionnaire_action_id
								  FROM qnr_security_scheme_config
								 WHERE security_scheme_id = i.security_scheme_id
								   AND action_security_type_id = r.action_security_type_id
								   AND company_function_id = chain_pkg.SUPPLIER
								 MINUS 
								SELECT questionnaire_id, user_sid, company_function_id, company_sid, questionnaire_action_id
								  FROM questionnaire_user_action;
							END IF;
						ELSE
							RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
						END IF;				
					END LOOP;
				
					-- custom security schemes can be applied using this link_pkg call
					chain_link_pkg.QuestionnaireAdded(v_share_with_company_sid, i.to_company_sid, i.to_user_sid, v_questionnaire_id);
					
				END IF;	
			END LOOP;
			
			IF v_has_questionnaire THEN
				-- This was failing on company self-registration
				message_pkg.TriggerMessage (
					in_primary_lookup	   		=> chain_pkg.INVITATION_ACCEPTED,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	   		=> v_from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	   		=> v_to_company_sid,
					in_re_user_sid		  		=> in_as_user_sid
				);
				
				IF v_on_behalf_of_company_sid IS NOT NULL THEN
					message_pkg.TriggerMessage (
						in_primary_lookup	   		=> chain_pkg.INVITATION_ACCEPTED,
						in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
						in_to_company_sid	   		=> v_on_behalf_of_company_sid,
						in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
						in_re_company_sid	   		=> v_to_company_sid,
						in_re_user_sid		  		=> in_as_user_sid
					);
				END IF;
			END IF;
			
			IF v_invitation_type_id = chain_pkg.NO_QUESTIONNAIRE_INVITATION THEN
				message_pkg.TriggerMessage (
					in_primary_lookup	   		=> chain_pkg.INVITATION_ACCEPTED,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	   		=> v_from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	   		=> v_to_company_sid,
					in_re_user_sid		  		=> in_as_user_sid
				);
				
			END IF;
			
			chain_link_pkg.InvitationAccepted(in_invitation_id, v_from_company_sid, v_to_company_sid);
			

			-- if the accepting user is not an admin, we'll need to set an admin message that the invite requires admin approval
			IF v_is_company_admin = 0 THEN
				-- TODO: Set the message (as commented above)
				NULL;
			END IF;
			
			csr.csr_user_pkg.SetLocalisationSettings(v_act_id, in_as_user_sid, in_language, in_culture, in_timezone);
		END IF;
		
		SELECT registration_terms_version
		  INTO v_reg_terms_vers
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

		-- TODO: We should only automatically accept the first user to be invited, subsequent users
		--       should have a workflow process from the existing admin users to make sure they
		--       really are allowed access
		--IF v_is_company_admin = 1 THEN
			UPDATE invitation
			   SET 	invitation_status_id = chain_pkg.ACCEPTED,
					accepted_dtm = SYSDATE, 
					accepted_reg_terms_vers = v_reg_terms_vers /*will be null if no T and C for this application*/
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND invitation_id = in_invitation_id;

			-- TODO: Send a message to the supplier company that the invitation was accepted
			-- TODO: Send a message to the purchaser company that the invitation was accepted
		--END IF;

		IF in_password IS NOT NULL THEN
			company_user_pkg.CompleteRegistration(in_as_user_sid, in_full_name, in_password);
		END IF;
		
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;
	
END;

FUNCTION AcceptAnyActiveInvites(
	in_for_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_guids						chain.T_STRING_LIST :=  chain.T_STRING_LIST();
BEGIN
	
	SELECT guid
	  BULK COLLECT INTO v_guids
	  FROM chain.v$active_invite
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND to_user_sid = in_for_user_sid;
				  
	IF v_guids.count = 0 THEN
		RETURN 0;
	END IF;

	/* No extra security checks since we're just calling AcceptInvitation which should do all the checking */
	FOR i IN 1..v_guids.last LOOP
		
		AcceptInvitation(v_guids(i), in_for_user_sid);
	
	END LOOP;	
	

	RETURN 1;
END;


PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
)
AS
	v_company_sid				security_pkg.T_SID_ID;
	v_user_sid					security_pkg.T_SID_ID;
BEGIN
	IF in_reason NOT IN (chain_pkg.REJECTED_NOT_PARTNER, chain_pkg.REJECTED_NOT_EMPLOYEE, chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.ANOTHER_USER_REGISTERED, chain_pkg.CANNOT_ACCEPT_TERMS) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid invitation rejection reason - '||in_reason);
	END IF;
	
	BEGIN
		helper_pkg.LogonUCD;
		
		-- there's only gonna be one, but this is faster than storing the row and
		-- doing no_data_found checking (and we don't care if nothing's found)
		FOR r IN (
			SELECT *
			  FROM invitation
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND LOWER(guid) = LOWER(in_guid)
			   AND REINVITATION_OF_INVITATION_ID IS NULL
		) LOOP

			-- delete the company if it's inactive and there are no other invitations
			-- TODO: Do we want to include expired invitations to prevent deletion?
			BEGIN
				SELECT company_sid
				  INTO v_company_sid
				  FROM v$company
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND company_sid = r.to_company_sid
				   AND active = chain_pkg.INACTIVE
				   AND company_sid NOT IN (
						SELECT to_company_sid
						  FROM invitation
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND to_company_sid = r.to_company_sid
						   AND invitation_id <> r.invitation_id
						   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
						   AND reinvitation_of_invitation_id IS NULL);
				
				-- terminate the relationship if it is still PENDING
				company_pkg.TerminateRelationship(r.from_company_sid, r.to_company_sid, FALSE);
				
				company_pkg.DeleteCompany(v_company_sid);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- nothing to do
					NULL;
			END;

			-- delete the user if they've not registered and don't have another active/expired invitation
			BEGIN
				SELECT user_sid
				  INTO v_user_sid
				  FROM chain_user
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND user_sid = r.to_user_sid
				   AND registration_status_id = chain_pkg.PENDING
				   AND user_sid NOT IN (
						SELECT to_user_sid
						  FROM invitation
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND to_user_sid = r.to_user_sid
						   AND invitation_id <> r.invitation_id
						   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
						   AND reinvitation_of_invitation_id IS NULL);
				
				company_user_pkg.SetRegistrationStatus(v_user_sid, chain_pkg.REJECTED);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- who cares
					NULL;
			END;

			UPDATE invitation
			   SET invitation_status_id = in_reason
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND invitation_id = r.invitation_id;

			CASE
				WHEN r.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
					-- add message for the purchaser company
					message_pkg.TriggerMessage (
						in_primary_lookup	   		=> chain_pkg.INVITATION_REJECTED,
						in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
						in_to_company_sid	   		=> r.from_company_sid,
						in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
						in_re_company_sid	   		=> r.to_company_sid,
						in_re_user_sid		  		=> r.to_user_sid
					);
					
					chain_link_pkg.InvitationRejected(r.invitation_id, r.from_company_sid, r.to_company_sid, in_reason);

				WHEN r.invitation_type_id = chain_pkg.STUB_INVITATION THEN
					-- do nothing I guess....
					NULL;
				WHEN r.invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION THEN
					-- // TO DO consider messaging later - not sure needed
					
					chain_link_pkg.InvitationRejected(r.invitation_id, r.from_company_sid, r.to_company_sid, in_reason);
					
				WHEN r.invitation_type_id = chain_pkg.NO_QUESTIONNAIRE_INVITATION THEN
				
					message_pkg.TriggerMessage (
						in_primary_lookup	   		=> chain_pkg.INVITATION_REJECTED,
						in_to_company_sid	   		=> r.from_company_sid,
						in_re_company_sid	   		=> r.to_company_sid,
						in_re_user_sid		  		=> r.to_user_sid					
					);
					
				ELSE
					RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||r.invitation_type_id||') event notification not handled');
			END CASE;

		END LOOP;
		
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;
END;

/* It's preferable creating a new function for questionnaire request invitation type */
PROCEDURE AcceptReqQnnaireInvitation(
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_invitation_type_id			chain_pkg.T_INVITATION_TYPE;
	v_invitation_id					invitation.invitation_id%TYPE;
	v_from_company_sid				security_pkg.T_SID_ID;
	v_to_company_sid				security_pkg.T_SID_ID;
	v_invitation_status_id			invitation.invitation_status_id%TYPE;
BEGIN
	
	-- get the details
	SELECT invitation_status_id, invitation_id, to_company_sid, from_company_sid, invitation_type_id
	  INTO v_invitation_status_id, v_invitation_id, v_to_company_sid, v_from_company_sid, v_invitation_type_id
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND LOWER(guid) = LOWER(in_guid)
		AND reinvitation_of_invitation_id IS NULL;
	
	--check the invitation type
	IF v_invitation_type_id NOT IN (chain_pkg.REQUEST_QNNAIRE_INVITATION) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invitation type of the invitation with guid: "' || in_guid || '" is not supported in AcceptReqQnnaireInvitation'); 
	END IF;

	--check if the user belongs to the company that has received the invitation or is superamdin
	IF company_user_pkg.IsRegisteredUserForCompany (v_to_company_sid, in_as_user_sid) = 0 AND security.user_pkg.IsSuperAdmin() = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'User with id: "' || in_as_user_sid || '" is not registered for company with id "' || v_to_company_sid ||'"' ); 
	END IF;
		
	--check invitation status
	IF v_invitation_status_id <> chain_pkg.ACTIVE THEN
		RETURN;
	END IF;
	
	message_pkg.TriggerMessage (
			in_primary_lookup	  	 	=> chain_pkg.INVITATION_ACCEPTED,
			in_secondary_lookup	 		=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> v_to_company_sid,
			in_re_company_sid	  	 	=> v_from_company_sid,
			in_re_user_sid		  		=> SYS_CONTEXT('SECURITY', 'SID')
		);
		
	message_pkg.TriggerMessage (
		in_primary_lookup	  	 	=> chain_pkg.INVITATION_ACCEPTED,
		in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
		in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
		in_to_company_sid	  	 	=> v_from_company_sid,
		in_re_company_sid	  	 	=> v_to_company_sid,
		in_re_user_sid		  		=> SYS_CONTEXT('SECURITY', 'SID')
	);
	
	IF v_from_company_sid <> helper_pkg.GetTopCompanySid THEN
		message_pkg.TriggerMessage (
			in_primary_lookup	   		=> chain_pkg.INVITATION_ACCPTED_FROM_B_TO_C,
			in_to_company_sid	   		=> helper_pkg.GetTopCompanySid,
			in_re_company_sid	   		=> v_to_company_sid,
			in_re_user_sid		  		=> SYS_CONTEXT('SECURITY', 'SID'),
			in_re_secondary_company_sid	=> v_from_company_sid
		);
	END IF;
	
	--update ALL the active invitation from this purchaser
	--(normally it should be only one, there is only a case a new invitation to have been sent to a different company admin)
	UPDATE invitation
	   SET invitation_status_id = chain_pkg.ACCEPTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND from_company_sid = v_from_company_sid
	   AND to_company_sid = v_to_company_sid
	   AND invitation_status_id = chain_pkg.ACTIVE;
			
	--establish relationship if does not exist
	IF NOT company_pkg.IsSupplier(v_from_company_sid, v_to_company_sid) THEN
		company_pkg.UNSEC_EstablishRelationship(
			in_purchaser_company_sid	=>  v_from_company_sid,
			in_supplier_company_sid		=>  v_to_company_sid,
			in_trigger_message			=> 	1 --triggers an established message for all 3 companies
		);	
	END IF;
	
	--call to link_pkg
	chain_link_pkg.AcceptReqQnnaireInvitation(v_from_company_sid, v_to_company_sid);
	   
END; 


/* It's preferable creating a new function for questionnaire request invitation type */
PROCEDURE RejectReqQnnaireInvitation(
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_invitation_type_id			chain_pkg.T_INVITATION_TYPE;
	v_invitation_id					invitation.invitation_id%TYPE;	
	v_from_company_sid				security_pkg.T_SID_ID;
	v_to_company_sid				security_pkg.T_SID_ID;
	v_invitation_status_id			invitation.invitation_status_id%TYPE;
BEGIN
	
	-- get the details
	SELECT invitation_status_id, invitation_id, to_company_sid, from_company_sid, invitation_type_id
	  INTO v_invitation_status_id, v_invitation_id, v_to_company_sid, v_from_company_sid, v_invitation_type_id
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(guid) = LOWER(in_guid);
	   
	--check the invitation type
	IF v_invitation_type_id NOT IN (chain_pkg.REQUEST_QNNAIRE_INVITATION) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invitation type of the invitation with guid: "' || in_guid || '" is not supported in RejectReqQnnaireInvitation'); 
	END IF;

	--check if the user belongs to the company that has received the invitation or is superadmin
	IF company_user_pkg.IsRegisteredUserForCompany(v_to_company_sid, in_as_user_sid) = 0 AND security.user_pkg.IsSuperAdmin() = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'User with id: "' || in_as_user_sid || '" is not registered for company with id "' || v_to_company_sid ||'"' ); 
	END IF;
		
	--check invitation status
	IF v_invitation_status_id <> chain_pkg.ACTIVE THEN
		RETURN;
	END IF;
	
	--we ONLY want to terminate (mark as deleted) the inactive relationships
	IF NOT company_pkg.IsSupplier(v_from_company_sid, v_to_company_sid) THEN
		company_pkg.TerminateRelationship(v_from_company_sid, v_to_company_sid, FALSE);
	END IF;
	
	--update ALL the active invitation from this purchaser
	--(normally it should be only one, there is only the case a new invitation to have been sent to a different company admin)
	UPDATE invitation
	   SET invitation_status_id = chain_pkg.REJECTED_QNNAIRE_REQ
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND from_company_sid = v_from_company_sid
	   AND to_company_sid = v_to_company_sid
	   AND invitation_status_id = chain_pkg.ACTIVE;
	
	--send a msg to purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup	   		=> chain_pkg.INVITATION_REJECTED,
		in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid	   		=> v_from_company_sid,
		in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
		in_re_company_sid	   		=> v_to_company_sid,
		in_re_user_sid		  		=> in_as_user_sid
	);
	
	--send a msg to supplier
	message_pkg.TriggerMessage (
		in_primary_lookup	   		=> chain_pkg.INVITATION_REJECTED,
		in_secondary_lookup	 		=> chain_pkg.SUPPLIER_MSG,
		in_to_company_sid	   		=> v_to_company_sid,
		in_re_company_sid	   		=> v_from_company_sid,
		in_re_user_sid		  		=> in_as_user_sid
	);
	
	--send a msg to top company if top_company_sid <> purchaser_sid	
	IF v_from_company_sid <> helper_pkg.GetTopCompanySid THEN
		message_pkg.TriggerMessage (
		in_primary_lookup	   		=> chain_pkg.INVITATION_RJECTED_FROM_B_TO_C,
		in_to_company_sid	   		=> helper_pkg.GetTopCompanySid,
		in_re_company_sid	   		=> v_to_company_sid,
		in_re_user_sid		  		=> in_as_user_sid,
		in_re_secondary_company_sid	=> v_from_company_sid
	);
	END IF;	
	
END; 


FUNCTION CanAcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	-- hmmm - this is a bit strange, but we may want to allow this to succeed if there's a problem with the guid
	-- so that we can handle the errors appropriately
	in_guid_error_val			IN  NUMBER
) RETURN NUMBER
AS
	v_dummy						security_pkg.T_OUTPUT_CUR;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, v_dummy) THEN
		RETURN in_guid_error_val;
	END IF;

	RETURN CanAcceptInvitation(v_invitation_id, in_as_user_sid);
END;

/*** not to be called unless external validity checks have been done ***/
FUNCTION CanAcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT to_user_sid
	  INTO v_to_user_sid
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;


	IF v_to_user_sid = in_as_user_sid OR company_user_pkg.GetRegistrationStatus(v_to_user_sid) = chain_pkg.PENDING THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;


FUNCTION GetInvitationId (
	in_guid						IN  invitation.guid%TYPE
) RETURN invitation.invitation_id%TYPE
AS
	v_cur						security_pkg.T_OUTPUT_CUR;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	IF GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, v_cur) THEN
		RETURN v_invitation_id;
	END IF;

	RETURN NULL;
END;

PROCEDURE GetSupplierInvitationSummary (
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	out_invite_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_questionnaire_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count						NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_supplier_sid, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading suppliers');
	END IF;
	
	UpdateExpirations;
	
	OPEN out_invite_cur FOR
		SELECT csru.csr_user_sid user_sid, i.*, csru.*, c.*
		  FROM invitation i, csr.csr_user csru, company c
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = csru.app_sid
		   AND i.app_sid = c.app_sid
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.to_company_sid = in_supplier_sid
		   AND i.to_company_sid = c.company_sid
		   AND i.to_user_sid = csru.csr_user_sid;
	
	OPEN out_questionnaire_cur FOR
		SELECT csru.csr_user_sid user_sid, i.*, csru.*, iqt.*, qt.*
		  FROM invitation i, invitation_qnr_type iqt, questionnaire_type qt, csr.csr_user csru
	     WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = csru.app_sid
		   AND i.app_sid = iqt.app_sid
		   AND i.app_sid = qt.app_sid
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.to_company_sid = in_supplier_sid
		   AND i.invitation_id = iqt.invitation_id
		   AND iqt.added_by_user_sid = csru.csr_user_sid
		   AND iqt.questionnaire_type_id = qt.questionnaire_type_id;
END;

PROCEDURE GetToCompanySidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
)
AS
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN
	SELECT invitation_id
	  INTO v_invitation_id
	  FROM invitation
	 WHERE LOWER(guid) = LOWER(in_guid)
	   AND reinvitation_of_invitation_id IS NULL
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT to_company_sid
	  INTO out_company_sid
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND invitation_id = v_invitation_id;	  
END;

-- Security checks - you can't do this unless you can read the suppliers
PROCEDURE GetInviteDataFromId (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_to_company_sid			security_pkg.T_SID_ID;
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
	v_invitation_type_id		invitation.invitation_type_id%TYPE;
	v_supp_rel_code				supplier_relationship.supp_rel_code%TYPE;
	v_key						supplier_relationship.virtually_active_key%TYPE;
BEGIN

	BEGIN
		SELECT to_company_sid, invitation_status_id, invitation_type_id
		  INTO v_to_company_sid, v_invitation_status_id, v_invitation_type_id
		  FROM invitation
		 WHERE app_sid = security_pkg.GetApp
		   AND invitation_id = in_invitation_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RAISE_APPLICATION_ERROR(-20001, 'No invite found with id ' || in_invitation_id);	
	END;
	
	company_pkg.ActivateVirtualRelationship(v_to_company_sid, v_key);
	
	IF NOT capability_pkg.CheckCapability(v_to_company_sid, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading invite for invitation id ' || in_invitation_id);
	END IF;

	company_pkg.DeactivateVirtualRelationship(v_key);
	
	BEGIN
		SELECT supp_rel_code
		  INTO v_supp_rel_code
		  FROM supplier_relationship 
		 WHERE app_sid = security_pkg.GetApp
		   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND supplier_company_sid = v_to_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 	
			RAISE_APPLICATION_ERROR(-20001, 'Supplier relationship does not exist - relationship expected when an invite '|| in_invitation_id ||' exists');	
	END;
	   
	OPEN out_cur FOR 
		SELECT v_to_company_sid to_company_sid, v_invitation_status_id invitation_status_id, v_supp_rel_code supp_rel_code, v_invitation_type_id invitation_type_id
		  FROM dual;
		
END;

PROCEDURE GetToUserSidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_user_sid				OUT security_pkg.T_SID_ID
)
AS
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN
	SELECT invitation_id INTO v_invitation_id FROM invitation WHERE LOWER(guid) = LOWER(in_guid) AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT to_user_sid
	  INTO out_user_sid
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND invitation_id = v_invitation_id;	  
END;

PROCEDURE ExtendExpiredInvitations(
	in_expiration_dtm invitation.expiration_dtm%TYPE
)
AS
BEGIN
	-- Temporary SP for Maersk to extend their own invitations because I'm fed up with having to do it for them.

	-- Security is enforced on the /maersk/site/temp/extendinvitations.acds URL via secmgr3.

	UPDATE chain.invitation SET invitation_status_id = 1, expiration_dtm = in_expiration_dtm
         WHERE invitation_status_id = 2 AND expiration_dtm < sysdate AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SearchInvitations (
	in_search				IN	VARCHAR2,
	in_invitation_status_id	IN	invitation.invitation_status_id%TYPE,
	in_from_user_sid		IN	security_pkg.T_SID_ID, -- TODO: Currently this is NULL for anyone or NOT NULL for [Me]
	in_to_user_sid			IN	security_pkg.T_SID_ID, -- Used to pull out invites to a single user
	in_sent_dtm_from		IN	invitation.sent_dtm%TYPE,
	in_sent_dtm_to			IN	invitation.sent_dtm%TYPE,
	in_invitation_type_ids	IN	security_pkg.T_SID_IDS,
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_row_count			OUT	INTEGER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results					T_NUMERIC_TABLE := T_NUMERIC_TABLE();
	v_invitation_type_ids		T_NUMBER_LIST := T_NUMBER_LIST();
	v_allowed_inv_type_ids		T_NUMBER_LIST DEFAULT GetAllowedInvitationTypes_;
	v_passed_inv_type_ids		security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_invitation_type_ids);
BEGIN	
	-- Can only search for all users invites if they are an admin or have the v_inv_mgr_full_access flag on (=1)
	IF in_from_user_sid IS NULL AND NOT HasFullInviteListAccessBool THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to search for invitations for all users');
	END IF;

	-- Filter the received invitation types so only allowed ones remain
	SELECT t.COLUMN_VALUE
	  BULK COLLECT INTO v_invitation_type_ids
	  FROM TABLE(v_allowed_inv_type_ids) t
	  JOIN TABLE(v_passed_inv_type_ids) tt ON t.COLUMN_VALUE = tt.COLUMN_VALUE;

	-- Find all IDs that match the search criteria
	SELECT T_NUMERIC_ROW(invitation_id, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT i.invitation_id
		  FROM invitation i --TODO - should this be in a view
		  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
		  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
		  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid -- Not using views as filters out rejected invitations as their details become deleted
		  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
		  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
		  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
		  JOIN TABLE(v_invitation_type_ids) it ON i.invitation_type_id = it.COLUMN_VALUE
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (LOWER(fcu.full_name) LIKE v_search
				OR LOWER(tcsru.full_name) LIKE v_search
				OR LOWER(tc.name) LIKE v_search 
				OR LOWER(tcsru.email) LIKE v_search)
		   AND (in_from_user_sid IS NULL OR from_user_sid = SYS_CONTEXT('SECURITY', 'SID') )
		   AND (in_to_user_sid IS NULL OR to_user_sid = in_to_user_sid )
		   AND (in_invitation_status_id IS NULL
					OR in_invitation_status_id = i.invitation_status_id
					OR (in_invitation_status_id = chain_pkg.ACCEPTED AND i.invitation_status_id = chain_pkg.PROVISIONALLY_ACCEPTED)
					OR (in_invitation_status_id = chain_pkg.REJECTED_NOT_EMPLOYEE AND i.invitation_status_id IN (chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.CANNOT_ACCEPT_TERMS)))
		   AND (in_sent_dtm_from IS NULL OR in_sent_dtm_from <= i.sent_dtm)
		   AND (in_sent_dtm_to IS NULL OR in_sent_dtm_to+1 >= i.sent_dtm)
		   AND reinvitation_of_invitation_id IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page in the order specified
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT i.*, istat.description invitation_status, fc.name from_company_name, fcu.full_name from_full_name,
				   fcu.email from_email, tc.name to_company_name, tcsru.full_name to_full_name, tcsru.email to_email, tc.deleted company_deleted,
				   row_number() OVER (ORDER BY 
						CASE
							WHEN in_sort_by = 'sentDtm' AND in_sort_dir = 'DESC' THEN to_char(i.sent_dtm, 'yyyy-mm-dd HH24:MI:SS')
							WHEN in_sort_by = 'toEmail' AND in_sort_dir = 'DESC' THEN LOWER(tcsru.email)
							WHEN in_sort_by = 'toCompanyName' AND in_sort_dir = 'DESC' THEN LOWER(tc.name)
							WHEN in_sort_by = 'toFullName' AND in_sort_dir = 'DESC' THEN LOWER(tcsru.full_name)
							WHEN in_sort_by = 'fromFullName' AND in_sort_dir = 'DESC' THEN LOWER(fcu.full_name)
							WHEN in_sort_by = 'invitationStatusId' AND in_sort_dir = 'DESC' THEN to_char(i.invitation_status_id)
						END DESC,
						CASE
							WHEN in_sort_by = 'sentDtm' AND in_sort_dir = 'ASC' THEN to_char(i.sent_dtm, 'yyyy-mm-dd HH24:MI:SS')
							WHEN in_sort_by = 'toEmail' AND in_sort_dir = 'ASC' THEN LOWER(tcsru.email)
							WHEN in_sort_by = 'toCompanyName' AND in_sort_dir = 'ASC' THEN LOWER(tc.name)
							WHEN in_sort_by = 'toFullName' AND in_sort_dir = 'ASC' THEN LOWER(tcsru.full_name)
							WHEN in_sort_by = 'fromFullName' AND in_sort_dir = 'ASC' THEN LOWER(fcu.full_name)
							WHEN in_sort_by = 'invitationStatusId' AND in_sort_dir = 'ASC' THEN to_char(i.invitation_status_id)
						END ASC 
				   ) rn
			  FROM invitation i --TODO - should this be in a view
			  JOIN TABLE(v_results) r ON i.invitation_id = r.item
			  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
			  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
			  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid
			  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
			  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
			  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ORDER BY rn
		) sub
		 WHERE ((in_start IS NULL) OR (rn-1 BETWEEN in_start AND in_start + in_page_size - 1));
END;

PROCEDURE DownloadInvitations (
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_allowed_inv_type_ids			T_NUMBER_LIST DEFAULT GetAllowedInvitationTypes_;
BEGIN
	OPEN out_cur FOR
		SELECT tcsru.full_name recipient_name, tcsru.email recipient_email, tc.name company, fcu.full_name invited_by,
			   i.sent_dtm invite_sent_date, 
			   NVL2(reinvitation_of_invitation_id, 'Yes', 'No') has_been_resent,
			   DECODE(MAX(i.sent_dtm) OVER (PARTITION BY tcsru.email), i.sent_dtm, 'Yes', 'No') is_latest_invite_for_user,
			   istat.description status, rs.description user_registration_status
		  FROM invitation i --TODO - should this be in a view
		  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
		  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
		  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid
		  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
		  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
		  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
		  JOIN registration_status rs on (rs.registration_status_id = tcu.registration_status_id)
		  JOIN TABLE(v_allowed_inv_type_ids) t ON i.invitation_type_id = t.column_value
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ((HasFullInviteListAccess = 1) OR (i.from_user_sid = SYS_CONTEXT('SECURITY', 'SID')))
 	  ORDER BY sent_dtm DESC;
END;

PROCEDURE CancelInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE
)
AS
BEGIN
	CancelInvitation(in_invitation_id, 0);
END;

PROCEDURE CancelInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	in_suppress_cancel_err	IN	NUMBER							-- we cancel the previous invitation when resending to a new user and thi
)
AS
	v_row_count 					INTEGER;
	v_invite_from_user_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT capability_pkg.CheckPotentialCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE)
	   AND NOT capability_pkg.CheckPotentialCapability(chain_pkg.SEND_INVITE_ON_BEHALF_OF) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_row_count
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED);

	IF v_row_count <> 1 AND in_suppress_cancel_err = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot cancel an invitation that is not in an active state');
	END IF;
	   
	-- allow the cancel if 
	--	it's my invite
	--  I am an admin
	--	the inv_mgr_norm_user_full_access flag is "on" (==1)
	SELECT from_user_sid 
	  INTO v_invite_from_user_sid
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	
	
	IF NOT ((v_invite_from_user_sid = SYS_CONTEXT('SECURITY', 'SID')) OR (HasFullInviteListAccessBool)) THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You only have permission to cancel your own invitations');
	END IF;

	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED, cancelled_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
		   cancelled_dtm = SYSDATE
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED);
END;

PROCEDURE ReSendInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id			invitation.invitation_id%TYPE;
	v_from_company_sid		security_pkg.T_SID_ID;
	v_to_company_sid		security_pkg.T_SID_ID;
	v_expiration_life_days	NUMBER;
	v_invite_from_user_sid	security_pkg.T_SID_ID;
	v_invite_to_user_sid	security_pkg.T_SID_ID;
	v_invitation_type_id	invitation.invitation_type_id%TYPE;
	v_found_inv_type_id		NUMBER;
	v_allowed_inv_type_ids	T_NUMBER_LIST DEFAULT GetAllowedInvitationTypes_;
BEGIN
	-- allow the resend if 
	--	it's my invite
	--  I am an admin
	--	the inv_mgr_norm_user_full_access flag is "on" (==1)
	SELECT from_user_sid, to_company_sid, from_company_sid , to_user_sid, invitation_type_id
	  INTO v_invite_from_user_sid, v_to_company_sid, v_from_company_sid, v_invite_to_user_sid, v_invitation_type_id
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- See if invitation type is an allowed one
	SELECT COUNT(*)
	  INTO v_found_inv_type_id
	  FROM TABLE(v_allowed_inv_type_ids)
	 WHERE column_value = v_invitation_type_id;

	IF v_found_inv_type_id = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied re-sending invite');
	END IF;
	
	IF NOT ((v_invite_from_user_sid = SYS_CONTEXT('SECURITY', 'SID')) OR (HasFullInviteListAccessBool)) THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You only have permission to re-send your own invitations');
	END IF;
	
	-- check if the user has been deleted (FB34308)
	IF company_user_pkg.IsUserMarkedAsDeleted(v_invite_to_user_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_INVIT_USER_IS_DELETED, 'The account of the invitation recipient "' || v_invite_to_user_sid || '" is deleted. The invitation cannot be sent.');
	END IF;	
	
	-- we'll resend from the logged on user
	v_invite_from_user_sid := SYS_CONTEXT('SECURITY', 'SID');

	
	SELECT invitation_id_seq.NEXTVAL
	  INTO v_invitation_id
	  FROM dual;

	-- Set status of origainl invitation to cancelled if it is active
	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED,
	       cancelled_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
	       cancelled_dtm = SYSDATE
	 WHERE invitation_id = in_invitation_id
	   AND invitation_status_id = chain_pkg.ACTIVE
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT invitation_expiration_days 
	  INTO v_expiration_life_days
	  FROM customer_options;

	--unique index (guid, nvl2(reinvitation_of_invitation_id, invitation_id, 0)) work-around  
	--set old invitation's reinvitation_of_invitation_id = invitation_id
	--copy original invitation into a new invitation
	--set old invitation's reinvitation_of_invitation_id = new invitation_id
	UPDATE invitation
	   SET reinvitation_of_invitation_id = invitation_id
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	--copy original invitation into a new invitation
	INSERT INTO invitation (app_sid, invitation_id, from_company_sid, from_user_sid,
		to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace, expiration_dtm,
		invitation_status_id, invitation_type_id, lang, on_behalf_of_company_sid)
	SELECT SYS_CONTEXT('SECURITY', 'APP'), v_invitation_id,
		   from_company_sid, -- should we use SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') or original here?
		   v_invite_from_user_sid,
		   to_company_sid, to_user_sid, SYSDATE, guid, expiration_grace,
		   SYSDATE + v_expiration_life_days, chain_pkg.ACTIVE, invitation_type_id, lang, on_behalf_of_company_sid
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE invitation
	   SET reinvitation_of_invitation_id = v_invitation_id
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	--todo: what about components?
	INSERT INTO invitation_qnr_type (app_sid, invitation_id, questionnaire_type_id, added_by_user_sid, requested_due_dtm)
	SELECT SYS_CONTEXT('SECURITY', 'APP'), v_invitation_id, iqt.questionnaire_type_id, SYS_CONTEXT('SECURITY', 'SID'),
		   --TODO: this could cause inconsistencies between maersk task.dueDate and message.dueDate, if the offsets are different. 
		   --eg: Right now there is hardcoded '7' offset in maersk\web\chain\questionnaireInvitation.js when the invitation is sent the 1st time
		   --the customer option v_expiration_life_days could be different though
		   SYSDATE + NVL(qt.default_overdue_days, v_expiration_life_days)
	  FROM invitation_qnr_type iqt
	  JOIN questionnaire_type qt ON qt.questionnaire_type_id = iqt.questionnaire_type_id
	 WHERE invitation_id = in_invitation_id
	   AND iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	INSERT INTO invitation_qnr_type_component(invitation_id, questionnaire_type_id, component_id)
	SELECT v_invitation_id, questionnaire_type_id, component_id
	  FROM invitation_qnr_type_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;
	   
	-- Trigger
	chain_link_pkg.InviteCreated(v_invitation_id, v_from_company_sid, v_to_company_sid, v_invite_from_user_sid);

	OPEN out_cur FOR
		SELECT app_sid, invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid,
		       expiration_grace, expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm,
		       reinvitation_of_invitation_id, accepted_reg_terms_vers, accepted_dtm, on_behalf_of_company_sid, lang, batch_job_id
		  FROM invitation
		 WHERE invitation_id = v_invitation_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetQnrTypesForInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qt.app_sid, qt.questionnaire_type_id, qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, qt.db_class,
		       qt.group_name, qt.position, qt.active, qt.requires_review, qt.reminder_offset_days, qt.enable_reminder_alert,
		       qt.enable_overdue_alert, qt.security_scheme_id, qt.can_be_overdue, qt.default_overdue_days, qt.procurer_can_review,
		       qt.expire_after_months, qt.auto_resend_on_expiry, qt.is_resendable, qt.enable_status_log, qt.enable_transition_alert
		  FROM questionnaire_type qt
		  JOIN invitation_qnr_type iqt ON iqt.questionnaire_type_id = qt.questionnaire_type_id AND iqt.app_sid = qt.app_sid
		 WHERE iqt.invitation_id = in_invitation_id
		   AND iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION CheckQnrTypeExists (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	in_questionnaire_type_id	IN	invitation_qnr_type.questionnaire_type_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	FOR r in (
		SELECT 1
		  FROM dual
		 WHERE EXISTS(SELECT 1 FROM invitation_qnr_type WHERE invitation_id = in_invitation_id AND questionnaire_type_id = in_questionnaire_type_id)
	) LOOP
		RETURN TRUE;
	END LOOP;
	RETURN FALSE;
END;

PROCEDURE GetInvitationStatuses (
	in_for_filter				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT invitation_status_id id,
			   CASE WHEN in_for_filter = 1 THEN filter_description ELSE description END description
		  FROM invitation_status
		 WHERE (in_for_filter <> 1
			OR (in_for_filter=1
		   AND filter_description IS NOT NULL))
		   AND invitation_status_id != chain_pkg.NOT_INVITED;
END;

FUNCTION GetActiveOrAcceptedCount_UNSEC (
	in_to_company_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count				NUMBER(10);
BEGIN
	-- No sec check as this is getting called on invitation expiration where the logged in
	-- user might not have permissions. We do, however, need to fix the way invitations expire
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND to_company_sid = in_to_company_sid
	   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.ACCEPTED);
	
	RETURN v_count;
END;

PROCEDURE GetQnrInvitableCompanyTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_check_table				T_PERMISSIBLE_TYPES_TABLE;
BEGIN
	IF helper_pkg.UseTraditionalCapabilities THEN
		IF capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
			--todo: are we still supporting no company-type capabilities?
			SELECT T_PERMISSIBLE_TYPES_ROW(NULL, NULL, company_type_id, NULL)
			  BULK COLLECT INTO v_check_table
			  FROM company_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
	ELSE
		v_check_table := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.SEND_QUESTIONNAIRE_INVITE);
	END IF;
	
	OPEN out_cur FOR
		SELECT ct.company_type_id
		  FROM company_type ct, TABLE(v_check_table) x
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.company_type_id = x.secondary_company_type_id
		 ORDER BY position;
END;

PROCEDURE GetCmpnyInvitableCompanyTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_check_table			T_PERMISSIBLE_TYPES_TABLE;
BEGIN
	IF helper_pkg.UseTraditionalCapabilities THEN
		IF capability_pkg.CheckCapability(chain_pkg.SEND_COMPANY_INVITE) THEN
			--todo: are we still supporting no company-type capabilities?
			SELECT T_PERMISSIBLE_TYPES_ROW(NULL, NULL, company_type_id, NULL)
			  BULK COLLECT INTO v_check_table
			  FROM company_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
	ELSE
		v_check_table := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.SEND_COMPANY_INVITE);

	END IF;
	
	OPEN out_cur FOR
		SELECT ct.company_type_id
		  FROM company_type ct, TABLE(v_check_table) x
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.company_type_id = x.secondary_company_type_id
		 ORDER BY position;
END;


PROCEDURE GetInviteOnBehalfOfs (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_check_table			T_PERMISSIBLE_TYPES_TABLE;
BEGIN
	IF helper_pkg.UseTraditionalCapabilities THEN
		v_check_table := T_PERMISSIBLE_TYPES_TABLE();
	ELSE
		v_check_table := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.QNR_INVITE_ON_BEHALF_OF);
	END IF;
	
	OPEN out_cur FOR
		SELECT secondary_company_type_id, tertiary_company_type_id
		  FROM TABLE(v_check_table) x, company_type ct2, company_type ct3
		 WHERE ct2.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct2.app_sid = ct3.app_sid
		   AND ct2.company_type_id = x.secondary_company_type_id
		   AND ct3.company_type_id = x.tertiary_company_type_id
		 ORDER BY ct2.position, ct3.position;
END;

PROCEDURE GetLatestInvitation_ (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	out_invitation_status_id	OUT invitation.invitation_status_id%TYPE,
	out_invitation_type_id		OUT invitation.invitation_type_id%TYPE
)
AS
BEGIN
	SELECT invitation_status_id, invitation_type_id
	  INTO out_invitation_status_id, out_invitation_type_id
	  FROM ( --TODO: Replace with the view
		SELECT 	DECODE(invitation_status_id,
					6, 7,--chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.REJECTED_NOT_EMPLOYEE
					4, 5,--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
					invitation_status_id) invitation_status_id,
				invitation_type_id,
				ROW_NUMBER() OVER (PARTITION BY to_company_sid ORDER BY DECODE(invitation_status_id, 
					5, 1,--chain_pkg.ACCEPTED, 1,
					4, 1,--chain_pkg.PROVISIONALLY_ACCEPTED, 1,
					1, 2,--chain_pkg.ACTIVE, 2,
					2, 3, --chain_pkg.EXPIRED, 3,
					3, 3, --chain_pkg.CANCELLED, 3,
					6, 3, --chain_pkg.REJECTED_NOT_EMPLOYEE, 3,
					7, 3 --chain_pkg.REJECTED_NOT_SUPPLIER, 3
				), sent_dtm DESC) rn
		  FROM invitation
		 WHERE to_company_sid = in_to_company_sid
		)
	 WHERE rn = 1;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		NULL;
END;

FUNCTION IsLatestInvitationRejected(
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_invitation_type_id	    IN invitation.invitation_type_id%TYPE	
) RETURN NUMBER
AS
	v_invitation_status_id	invitation.invitation_status_id%TYPE;
	v_invitation_type_id 	invitation.invitation_type_id%TYPE;
BEGIN
	GetLatestInvitation_(in_to_company_sid, v_invitation_status_id, v_invitation_type_id);
	
	IF in_invitation_type_id = v_invitation_type_id AND v_invitation_status_id IN (chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.REJECTED_NOT_EMPLOYEE) THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

PROCEDURE AddInvTypeIfCheckCapability_ (
	in_invitation_type			IN chain_pkg.T_INVITATION_TYPE,
	in_capability				IN chain_pkg.T_CAPABILITY,
	inout_invitation_type_ids	IN OUT T_NUMBER_LIST
)
AS
	v_perm_table			T_PERMISSIBLE_TYPES_TABLE;
	v_cnt					NUMBER;
BEGIN
	SELECT COUNT(1)
	  INTO v_cnt
	  FROM TABLE(inout_invitation_type_ids) t
	 WHERE t.COLUMN_VALUE = in_invitation_type;
	
	-- Don't add the invitation type if it was already added
	IF v_cnt > 0 THEN
		RETURN;
	END IF;

	v_perm_table := chain.type_capability_pkg.GetPermissibleCompanyTypes(
             in_company_sid => sys_context('security', 'chain_company'),
             in_capability => in_capability
		);
		
	IF v_perm_table.COUNT > 0 THEN
		inout_invitation_type_ids.extend;
		inout_invitation_type_ids(inout_invitation_type_ids.last) := in_invitation_type;
	END IF;
END;

FUNCTION GetAllowedInvitationTypes_
RETURN T_NUMBER_LIST
AS 
	v_invitation_type_ids	T_NUMBER_LIST := T_NUMBER_LIST();
BEGIN
	
	AddInvTypeIfCheckCapability_(chain_pkg.QUESTIONNAIRE_INVITATION, chain_pkg.SEND_QUESTIONNAIRE_INVITE, v_invitation_type_ids);
	AddInvTypeIfCheckCapability_(chain_pkg.QUESTIONNAIRE_INVITATION, chain_pkg.SEND_INVITE_ON_BEHALF_OF, v_invitation_type_ids);
	AddInvTypeIfCheckCapability_(chain_pkg.QUESTIONNAIRE_INVITATION, chain_pkg.QNR_INVITE_ON_BEHALF_OF, v_invitation_type_ids);
	AddInvTypeIfCheckCapability_(chain_pkg.QUESTIONNAIRE_INVITATION, chain_pkg.QNR_INV_ON_BEHLF_TO_EXIST_COMP, v_invitation_type_ids);
	
	AddInvTypeIfCheckCapability_(chain_pkg.NO_QUESTIONNAIRE_INVITATION, chain_pkg.SEND_COMPANY_INVITE, v_invitation_type_ids);
	
	AddInvTypeIfCheckCapability_(chain_pkg.REQUEST_QNNAIRE_INVITATION, chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB, v_invitation_type_ids);
	AddInvTypeIfCheckCapability_(chain_pkg.REQUEST_QNNAIRE_INVITATION, chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS, v_invitation_type_ids);
	
	RETURN v_invitation_type_ids;
END;

PROCEDURE GetAllowedInvitationTypes (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_type_ids	T_NUMBER_LIST := GetAllowedInvitationTypes_;
BEGIN
	
	OPEN out_cur FOR
		SELECT invitation_type_id, description
		  FROM invitation_type
		 WHERE invitation_type_id in (select COLUMN_VALUE from TABLE(v_invitation_type_ids));
END;

PROCEDURE GetInvitationLanguage (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_lang					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_lang						VARCHAR2(10);
BEGIN
	BEGIN
		SELECT lang
		  INTO v_lang
		  FROM invitation
		 WHERE app_sid = security_pkg.GetApp
		   AND invitation_id = in_invitation_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RAISE_APPLICATION_ERROR(-20001, 'No invite found with id ' || in_invitation_id);	
	END;
		
	OPEN out_lang FOR
		SELECT v_lang lang FROM dual;
END;

PROCEDURE GetInvitationLanguage (
	in_guid						IN	invitation.guid%TYPE,
	out_lang					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_lang						VARCHAR2(10);
BEGIN
	BEGIN
		SELECT lang
		  INTO v_lang
		  FROM invitation
		 WHERE app_sid = security_pkg.GetApp
		   AND LOWER(guid) = LOWER(in_guid)
		   AND reinvitation_of_invitation_id IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RAISE_APPLICATION_ERROR(-20001, 'No invite found with guid ' || in_guid);	
	END;
		
	OPEN out_lang FOR
		SELECT v_lang lang FROM dual;
END;

PROCEDURE GetInvitationsSentToCompany (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_invitation_status_id		IN	invitation.invitation_status_id%TYPE, --optional, only get invitations in a specific status
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF in_invitation_status_id = chain_pkg.EXPIRED THEN --when looking for expired invitations only return those that have not been resent already
		OPEN out_cur FOR
			SELECT app_sid, invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid,
			       expiration_grace, expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm,
			       reinvitation_of_invitation_id, accepted_reg_terms_vers, accepted_dtm, on_behalf_of_company_sid, lang, batch_job_id
			  FROM invitation
			 WHERE to_company_sid = in_to_company_sid
			   AND invitation_status_id =  chain_pkg.EXPIRED
			   AND reinvitation_of_invitation_id IS NULL;
	ELSE
		OPEN out_cur FOR
			SELECT app_sid, invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid,
			       expiration_grace, expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm,
			       reinvitation_of_invitation_id, accepted_reg_terms_vers, accepted_dtm, on_behalf_of_company_sid, lang, batch_job_id
			  FROM invitation
			 WHERE to_company_sid = in_to_company_sid
			   AND (in_invitation_status_id = NULL OR invitation_status_id = in_invitation_status_id);
	END IF;
END;

PROCEDURE StartBatch (
	in_personal_msg				IN	invitation_batch.personal_msg%TYPE,
	in_cc_from_user				IN	invitation_batch.cc_from_user%TYPE,
	in_cc_others				IN	invitation_batch.cc_others%TYPE,
	in_std_alert_type_id		IN	invitation_batch.std_alert_type_id%TYPE,
	in_lang						IN  invitation_batch.lang%TYPE DEFAULT NULL,
	out_batch_job_id			OUT	invitation_batch.batch_job_id%TYPE
)
AS
BEGIN
	-- No permissions. We check the permissions for adding invitations to the batch
	
	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_CHAIN_INVITATION,
		out_batch_job_id => out_batch_job_id
	);
	
	INSERT INTO invitation_batch (batch_job_id, personal_msg, cc_from_user, cc_others, std_alert_type_id, lang)
	VALUES (out_batch_job_id, in_personal_msg, in_cc_from_user, in_cc_others, in_std_alert_type_id, in_lang);
END;

PROCEDURE GetBatchJob (
	in_batch_job_id				IN	invitation_batch.batch_job_id%TYPE,
	out_batch_job_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qnr_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_count			NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied running invitation_pkg.GetBatchJob. This can only be ran by built in administrator for batch processes');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_invitation_count
	  FROM invitation
	 WHERE batch_job_id = in_batch_job_id
	   AND sent_dtm IS NULL;
	
	OPEN out_batch_job_cur FOR
		SELECT ib.app_sid, ib.batch_job_id, ib.personal_msg, ib.cc_from_user, ib.cc_others,
			   v_invitation_count invitation_count, co.support_email, co.invite_from_name_addendum,
			   co.allow_cc_on_invite, ib.std_alert_type_id,
			   CASE WHEN eua.cnt > 0 THEN 1 ELSE 0 END has_existing_user_alert_type
		  FROM invitation_batch ib
		  JOIN customer_options co ON ib.app_sid = co.app_sid
		  LEFT JOIN (
			SELECT cat.app_sid, count(*) cnt
			  FROM csr.customer_alert_type cat
			  JOIN csr.alert_template at ON cat.customer_alert_type_id = at.customer_alert_type_id
			 WHERE cat.std_alert_type_id = 5010 -- ExistingUserQuestionnaireInvitationAlert
			 GROUP BY cat.app_sid
		  ) eua ON ib.app_sid = eua.app_sid
		 WHERE ib.batch_job_id = in_batch_job_id;
	
	OPEN out_invitation_cur FOR
		SELECT i.invitation_id, i.guid, i.expiration_dtm, i.lang, i.to_user_sid, tc.name to_company_name,
			   fu.full_name from_user_name, fu.friendly_name from_friendly_name, fu.job_title from_job_title,
			   fu.email from_user_email, fc.name from_company_name, fcc.cc_list from_company_cc_list,
			   tu.registration_status_id to_user_registation_status_id
		  FROM invitation i
		  JOIN company tc ON i.to_company_sid = tc.company_sid
		  JOIN csr.csr_user fu ON i.from_user_sid = fu.csr_user_sid
		  JOIN company fc ON i.from_company_sid = fc.company_sid
		  JOIN chain_user tu ON i.to_user_sid = tu.user_sid
		  LEFT JOIN (
			SELECT company_sid, csr.stragg(email) cc_list
			  FROM company_cc_email
			 GROUP BY company_sid
		  ) fcc ON fc.company_sid = fcc.company_sid
		 WHERE i.batch_job_id = in_batch_job_id
		   AND i.sent_dtm IS NULL;
	
	OPEN out_invitation_qnr_cur FOR
		SELECT iqt.invitation_id, iqt.questionnaire_type_id, qt.name
		  FROM invitation i 
		  JOIN invitation_qnr_type iqt ON i.invitation_id = iqt.invitation_id and i.app_sid = iqt.app_sid
		  JOIN questionnaire_type qt ON iqt.questionnaire_type_id = qt.questionnaire_type_id and iqt.app_sid = qt.app_sid
		 WHERE i.batch_job_id = in_batch_job_id
		   AND i.sent_dtm IS NULL;
END;


PROCEDURE MarkInvitationSent (
	in_invitation_id			IN	invitation.invitation_id%TYPE
)
AS
	v_batch_job_id		invitation.batch_job_id%TYPE;
	v_sent				NUMBER;
	v_total				NUMBER;
BEGIN
	UPDATE invitation
	   SET sent_dtm = SYSDATE
	 WHERE invitation_id = in_invitation_id
	RETURNING batch_job_id INTO v_batch_job_id;
	COMMIT;
	
	IF v_batch_job_id IS NOT NULL THEN
		SELECT count(sent_dtm), count(*)
		  INTO v_sent, v_total
		  FROM invitation
		 WHERE batch_job_id = v_batch_job_id;
		
		csr.batch_job_pkg.SetProgress(v_batch_job_id, v_sent, v_total);
	END IF;
END;

FUNCTION TryGetComponentId(
	in_invitation_id	IN	invitation.invitation_id%TYPE,
	out_component_id	OUT	component.component_id%TYPE
)RETURN NUMBER
AS
	v_found NUMBER;
BEGIN	
	BEGIN
		SELECT component_id
		  INTO out_component_id
		  FROM invitation_qnr_type_component
		 WHERE app_sid = security_pkg.getApp
		   AND invitation_id = in_invitation_id;
		   
		   v_found := 1;
	EXCEPTION   
		WHEN NO_DATA_FOUND THEN
			v_found := 0;
	END;
	
	RETURN v_found;
END;

-- Called by scheduled task
PROCEDURE GetExpiryAlerts (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
--this is called without an app_sid, should get all invitations from all sites that need to send an expiry reminder alert
	OPEN out_cur FOR
		SELECT i.app_sid app_sid, i.invitation_id invitation_id, 
				to_user.csr_user_sid to_user_sid, to_user.full_name to_name, to_user.friendly_name to_friendly_name, to_user.email to_email, 
				to_company.name to_company_name, to_company.company_sid to_company_sid,
				from_user.csr_user_sid from_user_sid, from_user.full_name from_name, from_user.friendly_name from_friendly_name, 
				from_user.email from_email, from_user.job_title from_jobtitle, from_company.name from_company_name, from_company.company_sid from_company_sid,
				i.expiration_dtm expiration_dtm, i.guid guid, co.support_email
		  FROM invitation i
		  JOIN customer_options co ON i.app_sid = co.app_sid 
		  JOIN company from_company ON i.from_company_sid = from_company.company_sid AND i.app_sid = from_company.app_sid
		  JOIN company to_company ON i.to_company_sid = to_company.company_sid AND i.app_sid = to_company.app_sid
		  JOIN csr.csr_user from_user ON i.from_user_sid = from_user.csr_user_sid AND i.app_sid = from_user.app_sid
		  JOIN csr.csr_user to_user ON i.to_user_sid = to_user.csr_user_sid AND i.app_sid = to_user.app_sid	 
		 WHERE co.invitation_expiration_rem = 1
		   AND i.expiration_dtm - co.invitation_expiration_rem_days <= SYSDATE
		   AND i.invitation_status_id = chain_pkg.ACTIVE -- only active invitations, no expired, rejected or accepted
		   AND accepted_dtm IS NULL --don't send reminders for accepted invitations
		   AND reminder_sent = 0; --we only send the reminder once
END;

-- Called by scheduled task
PROCEDURE MarkExpiryAlertSent (
	in_invitation_id	IN	invitation.invitation_id%TYPE
)
AS
BEGIN
	UPDATE invitation
	   SET reminder_sent = 1
	 WHERE invitation_id = in_invitation_id;
	COMMIT;
END;

END invitation_pkg;
/
