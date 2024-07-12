CREATE OR REPLACE PACKAGE BODY SUPPLIER.message_pkg
IS

-- private
PROCEDURE AssertCanReadSupplierCompanies
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		security_pkg.GetAct(), 
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct(), security_pkg.GetApp(), 'Supplier/Companies'), 
		security_pkg.PERMISSION_READ
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading companies container');
	END IF;
END;

/***************************************************************************
	INTERNAL - No sec checks, expected that COMPANY_SID is set in context
****************************************************************************/
PROCEDURE CreateMessage_ (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_company_sid		IN  security_pkg.T_SID_ID,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid_1			IN  security_pkg.T_SID_ID,
	in_user_sid_2			IN  security_pkg.T_SID_ID,
	in_contact_id			IN  contact.contact_id%TYPE,
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	in_supplier_company_sid IN  security_pkg.T_SID_ID,
	in_procurer_company_sid IN  security_pkg.T_SID_ID
)
AS
	v_to_group_sid			security_pkg.T_SID_ID;
	v_to_company_sid		security_pkg.T_SID_ID DEFAULT NVL(in_to_company_sid, company_pkg.GetCompany);
BEGIN
	-- we could set up a validation system to ensure that the correct 
	-- params are passed through for the specific message_type, but 
	-- for now we're going to skip that.as I'm not sure it would be useful
	-- (the only case would be as a development helper - once the call is set, it shouldn't change)
	
	-- if a group type is specified, get the corresponding sid
	IF in_to_group_type IS NOT NULL THEN
		company_group_pkg.GetGroupSid(in_to_group_type, v_to_company_sid, v_to_group_sid);
	END IF;
	
	-- set the core message
	INSERT INTO message 
	(message_id, message_template_id, company_sid, user_sid, group_sid, msg_dtm)
	VALUES
	(message_id_seq.NEXTVAL, in_message_tpl_id, v_to_company_sid, in_to_user_sid, v_to_group_sid, SYSDATE); 
	
	-- if a user sid or two has been provided, stuff them into the user table
	IF in_user_sid_1 IS NOT NULL THEN
		INSERT INTO message_user 
		(message_id, user_sid) 
		VALUES 
		(message_id_seq.CURRVAL, in_user_sid_1);
				
		IF in_user_sid_2 IS NOT NULL THEN
			INSERT INTO message_user 
			(message_id, entry_index, user_sid) 
			VALUES 
			(message_id_seq.CURRVAL, 1, in_user_sid_2);
		END IF;	
	END IF;
	
	-- insert the contact data
	IF in_contact_id IS NOT NULL THEN
		INSERT INTO message_contact
		(message_id, contact_id, owner_company_sid)
		VALUES
		(message_id_seq.CURRVAL, in_contact_id, v_to_company_sid);
	END IF;
	
	-- insert the questionnaire data
	IF in_questionnaire_id IS NOT NULL THEN
		INSERT INTO message_questionnaire
		(message_id, chain_questionnaire_id)
		VALUES
		(message_id_seq.CURRVAL, in_questionnaire_id);
	END IF;
	
	-- insert the supplier information
	IF in_supplier_company_sid IS NOT NULL THEN
		INSERT INTO message_procurer_supplier
		(message_id, procurer_company_sid, supplier_company_sid)
		VALUES
		(message_id_seq.CURRVAL, v_to_company_sid, in_supplier_company_sid);
	END IF;
	
	-- inser the procurer information
	IF in_procurer_company_sid IS NOT NULL THEN
		INSERT INTO message_procurer_supplier
		(message_id, procurer_company_sid, supplier_company_sid)
		VALUES
		(message_id_seq.CURRVAL, in_procurer_company_sid, v_to_company_sid);
	END IF;
END;

/***************************************************************************
	PUBLIC
****************************************************************************/

-- MTF_TEXT_ONLY
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE
)
AS
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	AssertCanReadSupplierCompanies;

	CreateMessage_(
		in_message_tpl_id, null, in_to_user_sid, in_to_group_type,
		null, null, null,
		null, null, null
	);
END;

-- MTF_USER_COMPANY
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	AssertCanReadSupplierCompanies;

	CreateMessage_(
		in_message_tpl_id, null, in_to_user_sid, in_to_group_type,
		in_user_sid, null, null,
		null, null, null
	);
END;

-- MTF_USER_USER_COMPANY
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid_1			IN  security_pkg.T_SID_ID,
	in_user_sid_2			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	AssertCanReadSupplierCompanies;

	CreateMessage_(
		in_message_tpl_id, null, in_to_user_sid, in_to_group_type,
		in_user_sid_1, in_user_sid_2, null,
		null, null, null
	);
END;

-- MTF_USER_CONTACT_QNAIRE, MTF_USER_SUPPLIER_QNAIRE, MTF_USER_PROCURER_QNAIRE
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_company_sid		IN  security_pkg.T_SID_ID,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	in_id					IN  security_pkg.T_SID_ID,
	in_id_type				IN  T_MESSAGE_ID_TYPE
)
AS
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	AssertCanReadSupplierCompanies;

	CASE
		WHEN in_id_type = MIDT_CONTACT THEN
			CreateMessage_(
				in_message_tpl_id, in_to_company_sid, in_to_user_sid, in_to_group_type,
				in_user_sid, null, in_id,
				in_questionnaire_id, null, null
			);
		WHEN in_id_type = MIDT_PROCURER THEN
			CreateMessage_(
				in_message_tpl_id, in_to_company_sid, in_to_user_sid, in_to_group_type,
				in_user_sid, null, null,
				in_questionnaire_id, null, in_id
			);
		WHEN in_id_type = MIDT_SUPPLIER THEN
			CreateMessage_(
				in_message_tpl_id, in_to_company_sid, in_to_user_sid, in_to_group_type,
				in_user_sid, null, null,
				in_questionnaire_id, in_id, null
			);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown MIDT '||in_id_type);
	END CASE;
END;

PROCEDURE GetMessages (
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID DEFAULT security_pkg.GetSid;
	v_company_sid				security_pkg.T_SID_ID DEFAULT company_pkg.GetCompany;
	v_app_sid					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	AssertCanReadSupplierCompanies;

	OPEN out_cur FOR
		SELECT * FROM (
			SELECT m.*, rownum r FROM (
				SELECT * FROM (
					-- restrict messages for users that have not been authorized to messages that are directed explicitly to them --
					SELECT m.*
					  FROM v$message m, company_user cu
					 WHERE cu.app_sid = v_app_sid
					   AND cu.company_sid = v_company_sid
					   AND cu.csr_user_sid = v_user_sid
					   AND cu.pending_company_authorization = company_user_pkg.USER_IS_NOT_AUTHORIZED
					   AND m.app_sid = cu.app_sid
					   AND m.company_sid = cu.company_sid
					   AND m.user_sid = cu.csr_user_sid
					UNION    
					-- get messages for me, or general for my company, if I am an authorized user --
					SELECT m.*
					  FROM v$message m, company_user cu
					 WHERE cu.app_sid = v_app_sid
					   AND cu.company_sid = v_company_sid
					   AND cu.csr_user_sid = v_user_sid
					   AND cu.pending_company_authorization = company_user_pkg.USER_IS_AUTHORIZED
					   AND m.app_sid = cu.app_sid
					   AND m.company_sid = cu.company_sid
					   AND (m.user_sid = cu.csr_user_sid OR m.user_sid IS NULL)
					   --AND m.group_sid IS NULL
					UNION
					-- get messages for group which I am a member of, if I am an authorized user --
					SELECT m.*
					  FROM v$message m, company_user cu, security.group_members gm
					 WHERE cu.app_sid = v_app_sid
					   AND cu.company_sid = v_company_sid
					   AND cu.csr_user_sid = v_user_sid
					   AND cu.pending_company_authorization = company_user_pkg.USER_IS_AUTHORIZED
					   AND m.app_sid = cu.app_sid
					   AND m.company_sid = cu.company_sid
					   --AND m.user_sid IS NULL
					   AND gm.group_sid_id = m.group_sid
					   AND gm.member_sid_id = cu.csr_user_sid
				)
				ORDER BY msg_dtm DESC, message_id DESC
			) m
			WHERE rownum < ((in_page * in_page_size) + 1) 
		)
		WHERE r >= (((in_page - 1) * in_page_size) + 1); 
END;

END message_pkg;
/
