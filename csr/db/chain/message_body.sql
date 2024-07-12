CREATE OR REPLACE PACKAGE BODY CHAIN.message_pkg
IS

TYPE MESSAGE_TABLE IS TABLE OF MESSAGE%ROWTYPE;

DIRECT_TO_USER				CONSTANT NUMBER := 0;
TO_ENTIRE_COMPANY			CONSTANT NUMBER := 1;
TO_OTHER_COMPANY_USER		CONSTANT NUMBER := 2;

/**********************************************************************************
	PRIVATE FUNCTIONS
**********************************************************************************/
FUNCTION GetDefinition (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE
) RETURN v$message_definition%ROWTYPE
AS
	v_dfn						v$message_definition%ROWTYPE;
BEGIN
	-- Grab the definition data
	SELECT *
	  INTO v_dfn
	  FROM v$message_definition
	 WHERE message_definition_id = in_message_definition_id;

	RETURN v_dfn;
END;

PROCEDURE CreateDefaultMessageParam (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_param_name				IN  message_param.param_name%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO default_message_param
		(message_definition_id, param_name, lower_param_name)
		VALUES
		(in_message_definition_id, in_param_name, LOWER(in_param_name));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
END;

PROCEDURE CreateDefinitionOverride (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO message_definition
		(message_definition_id)
		VALUES
		(in_message_definition_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION GetRecipientId (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE
AS
	v_r_id						recipient.recipient_id%TYPE;
BEGIN
	-- try to get the recipient id
	BEGIN	
		SELECT recipient_id
		  INTO v_r_id
		  FROM recipient
		 WHERE NVL(to_company_sid, 0) = NVL(in_company_sid, 0)
		   AND NVL(to_user_sid, 0) = NVL(in_user_sid, 0);
	EXCEPTION
		-- if we don't have an id for this combination, create one
		WHEN NO_DATA_FOUND THEN
			v_r_id := CreateRecipient(in_company_sid, in_user_sid);
	END;

	RETURN v_r_id;
END;

FUNCTION FindMessage_ (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_secondary_company_sid	IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_re_invitation_id			IN  message.re_invitation_id%TYPE				DEFAULT NULL,
	in_re_audit_request_id		IN  message.re_audit_request_id%TYPE			DEFAULT NULL,
	in_completed				IN	BOOLEAN										DEFAULT NULL
)
RETURN message%ROWTYPE
AS
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(in_message_definition_id);
	v_msg						message%ROWTYPE;
	v_message_id				message.message_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_completed					NUMBER := CASE WHEN in_completed IS NULL THEN NULL WHEN in_completed THEN 1 ELSE 0 END;
BEGIN
	IF in_to_user_sid <> chain_pkg.FOLLOWERS THEN
		v_to_user_sid := in_to_user_sid;
	END IF;
	
	IF v_to_user_sid IS NULL AND in_to_company_sid IS NULL THEN
		RETURN v_msg;
	END IF;	
	
	SELECT MAX(message_id)
	  INTO v_message_id
	  FROM (
		SELECT m.message_id
		  FROM message_recipient mr
		  JOIN message m ON mr.app_sid = m.app_sid AND mr.message_id = m.message_id
		  JOIN recipient r ON mr.app_sid = r.app_sid AND mr.recipient_id = r.recipient_id
		  JOIN message_refresh_log mrl ON m.app_sid = mrl.app_sid AND m.message_id = mrl.message_id
		 WHERE m.message_definition_id = in_message_definition_id
		   AND (v_to_user_sid IS NULL OR r.to_user_sid = v_to_user_sid)
		   AND NVL(r.to_company_sid, 0) 			= NVL(in_to_company_sid, 0)
		   AND NVL(m.re_company_sid, 0) 			= NVL(in_re_company_sid, 0)
		   AND NVL(m.re_secondary_company_sid, 0)	= NVL(in_re_secondary_company_sid, 0)
		   AND NVL(m.re_user_sid, 0) 				= NVL(in_re_user_sid, 0)
		   AND NVL(m.re_questionnaire_type_id, 0)	= NVL(in_re_questionnaire_type_id, 0)
		   AND NVL(m.re_component_id, 0) 			= NVL(in_re_component_id, 0)
		   AND NVL(m.re_invitation_id, 0) 			= NVL(in_re_invitation_id, 0)
		   AND NVL(m.re_audit_request_id, 0)		= NVL(in_re_audit_request_id, 0)
		   AND (v_completed IS NULL
			OR (v_completed = 1 AND m.completed_dtm IS NOT NULL)
			OR (v_completed = 0 AND m.completed_dtm IS NULL))
		 ORDER BY mrl.refresh_dtm DESC
	   )
	 WHERE rownum = 1;
		
	RETURN GetMessage(v_message_id);
END;

FUNCTION FindMessages_ (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_secondary_company_sid	IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_re_invitation_id			IN  message.re_invitation_id%TYPE				DEFAULT NULL,
	in_re_audit_request_id		IN  message.re_audit_request_id%TYPE			DEFAULT NULL,
	in_completed				IN	BOOLEAN										DEFAULT NULL
)
RETURN MESSAGE_TABLE
AS
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(in_message_definition_id);
	v_message_id				message.message_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_completed					NUMBER := CASE WHEN in_completed IS NULL THEN NULL WHEN in_completed THEN 1 ELSE 0 END;
	v_tbl						MESSAGE_TABLE;
BEGIN
	IF in_to_user_sid <> chain_pkg.FOLLOWERS THEN
		v_to_user_sid := in_to_user_sid;
	END IF;
	
	IF v_to_user_sid IS NULL AND in_to_company_sid IS NULL THEN
		RETURN v_tbl;
	END IF;
	
	SELECT *
	  BULK COLLECT INTO v_tbl
	  FROM message
	 WHERE message_id IN (
		SELECT message_id
		  FROM v$message_recipient
		 WHERE message_definition_id = in_message_definition_id
		   AND (v_to_user_sid IS NULL OR to_user_sid = v_to_user_sid)
		   AND NVL(to_company_sid, 0) 			= NVL(in_to_company_sid, 0)
		   AND NVL(re_company_sid, 0) 			= NVL(in_re_company_sid, 0)
		   AND NVL(re_secondary_company_sid, 0)	= NVL(in_re_secondary_company_sid, 0)
		   AND NVL(re_user_sid, 0) 				= NVL(in_re_user_sid, 0)
		   AND NVL(re_questionnaire_type_id, 0) = NVL(in_re_questionnaire_type_id, 0)
		   AND NVL(re_component_id, 0) 			= NVL(in_re_component_id, 0)
		   AND NVL(re_invitation_id, 0) 		= NVL(in_re_invitation_id, 0)
		   AND NVL(re_audit_request_id, 0)		= NVL(in_re_audit_request_id, 0)
		   AND (v_completed IS NULL
			OR (v_completed = 1 AND completed_dtm IS NOT NULL)
			OR (v_completed = 0 AND completed_dtm IS NULL))
	   );
	
	RETURN v_tbl;
END;

FUNCTION GetUserRecipientIds (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
) RETURN T_NUMERIC_TABLE
AS
	v_vals 						T_NUMERIC_TABLE;
BEGIN
	SELECT T_NUMERIC_ROW(recipient_id, addressed_to)
	  BULK COLLECT INTO v_vals
	  FROM (
	  		SELECT recipient_id, DIRECT_TO_USER addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid = in_user_sid
			   AND (to_company_sid IS NULL OR to_company_sid = in_company_sid)
			 UNION ALL
			SELECT recipient_id, TO_ENTIRE_COMPANY addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid IS NULL
			   AND to_company_sid = in_company_sid
			 UNION ALL
			SELECT recipient_id, TO_OTHER_COMPANY_USER addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid <> in_user_sid
			   AND to_company_sid = in_company_sid
	  );

	RETURN v_vals;
END;



/**********************************************************************************
	INTERNAL FUNCTIONS
**********************************************************************************/
FUNCTION Lookup (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE
AS
BEGIN
	RETURN Lookup(in_primary_lookup, chain_pkg.NONE_IMPLIED);
END;

FUNCTION Lookup (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE
AS
	v_dfn_id					message_definition.message_definition_id%TYPE;
BEGIN
	SELECT message_definition_id
	  INTO v_dfn_id
	  FROM message_definition_lookup
	 WHERE primary_lookup_id = in_primary_lookup
	   AND secondary_lookup_id = in_secondary_lookup;
	
	RETURN v_dfn_id;
END;


/**********************************************************************************
	GLOBAL MANAGEMENT
**********************************************************************************/
PROCEDURE DefineMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE,
	in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
	in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
	in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessage can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO message_definition_lookup
		(message_definition_id, primary_lookup_id, secondary_lookup_id)
		VALUES
		(message_definition_id_seq.nextval, in_primary_lookup, in_secondary_lookup)
		RETURNING message_definition_id INTO v_dfn_id;
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			v_dfn_id := Lookup(in_primary_lookup, in_secondary_lookup);
	END;
	
	BEGIN
		INSERT INTO default_message_definition
		(message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES
		(v_dfn_id, in_message_template, in_priority, in_repeat_type, in_addressing_type, in_completion_type, in_completed_template, in_helper_pkg, in_css_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE default_message_definition
			   SET message_template = in_message_template, 
			       message_priority_id = in_priority, 
			       repeat_type_id = in_repeat_type, 
			       addressing_type_id = in_addressing_type, 
			       completion_type_id = in_completion_type, 
			       completed_template = in_completed_template, 
			       helper_pkg = in_helper_pkg,
			       css_class = in_css_class
			 WHERE message_definition_id = v_dfn_id;
	END;
END;

PROCEDURE DefineMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE DEFAULT NULL,
	in_href						IN  message_param.href%TYPE DEFAULT NULL,
	in_value					IN  message_param.value%TYPE DEFAULT NULL	
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessageParam can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefaultMessageParam(v_dfn_id, in_param_name);
	
	UPDATE default_message_param
	   SET value = in_value, 
	       href = in_href, 
	       css_class = in_css_class
	 WHERE message_definition_id = v_dfn_id
	   AND param_name = in_param_name;
END;

/**********************************************************************************
	APPLICATION MANAGEMENT
**********************************************************************************/
PROCEDURE OverrideMessageDefinition (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE	DEFAULT NULL,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT NULL,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL,
	in_completion_type			In  message_definition.completion_type_id%TYPE 	DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideMessageDefinition can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefinitionOverride(v_dfn_id);
	
	UPDATE message_definition
	   SET message_template = in_message_template, 
	       message_priority_id = in_priority, 
	       completed_template = in_completed_template, 
	       helper_pkg = in_helper_pkg, 
	       css_class = in_css_class,
	       completion_type_id = in_completion_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND message_definition_id = v_dfn_id;
	
	-- Reset any parameters previously set up to defaults as there's no other way to do this other than manually
	-- But it means if you want to change the text you'll need to redefine the parameters
	DELETE FROM message_param
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND message_definition_id = v_dfn_id;
	
END;

PROCEDURE OverrideMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideMessageDefinition can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefaultMessageParam(v_dfn_id, in_param_name);
	CreateDefinitionOverride(v_dfn_id);
	
	BEGIN
		INSERT INTO message_param
		(message_definition_id, param_name, value, href, css_class)
		VALUES
		(v_dfn_id, in_param_name, in_value, in_href, in_css_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE message_param
			   SET value = in_value, 
			       href = in_href, 
			       css_class = in_css_class
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND message_definition_id = v_dfn_id
			   AND param_name = in_param_name;    
	END;
END;

/**********************************************************************************
	PUBLIC METHODS
**********************************************************************************/
FUNCTION CreateRecipient (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE
AS
	v_r_id						recipient.recipient_id%TYPE;
BEGIN
	INSERT INTO recipient
	(recipient_id, to_company_sid, to_user_sid)
	VALUES
	(recipient_id_seq.NEXTVAL, in_company_sid, in_user_sid)
	RETURNING recipient_id INTO v_r_id;
	
	RETURN v_r_id;
END;

PROCEDURE TriggerMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_due_dtm					IN  message.due_dtm%TYPE						DEFAULT NULL,
	in_system_wide				IN  NUMBER										DEFAULT 0,
	in_re_secondary_company_sid	IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_invitation_id			IN  message.re_invitation_id%TYPE				DEFAULT NULL,
	in_re_audit_request_id		IN  message.re_audit_request_id%TYPE			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(v_dfn_id);
	v_msg						message%ROWTYPE;
	v_msg_id					message.message_id%TYPE;
	v_r_id						recipient.recipient_id%TYPE;
	v_find_by_user_sid			security_pkg.T_SID_ID;	
	v_to_users					T_NUMBER_LIST;
	v_cnt						NUMBER;
BEGIN
	
	---------------------------------------------------------------------------------------------------
	-- validate message addressing

	IF v_dfn.addressing_type_id = chain_pkg.USER_ADDRESS THEN
		IF in_to_company_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid cannot be set for USER_ADDRESS messages');
		ELSIF in_to_user_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid must be set for USER_ADDRESS messages');
		END IF;
	ELSIF v_dfn.addressing_type_id = chain_pkg.COMPANY_ADDRESS THEN
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for COMPANY_ADDRESS messages');
		ELSIF in_to_user_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid cannot be set for COMPANY_ADDRESS messages');
		END IF;
	ELSE
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for COMPANY_USER_ADDRESS messages');
		ELSIF in_to_user_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid must be set for COMPANY_USER_ADDRESS messages');
		END IF;
	END IF;	
	
	---------------------------------------------------------------------------------------------------
	-- manage pseudo user codes
	IF in_to_user_sid = chain_pkg.FOLLOWERS THEN
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for FOLLOWERS psuedo addressed messages');
		ELSIF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Re company sid must be set for FOLLOWERS psuedo addressed messages');
		END IF;
		
		--todo: check if in_re_second_company_sid is not null, users should be followers of both re_company_sid, in_re_second_company_sid
		--in_re_second_company_sid should be null for SUPPLIER_MSG
		--re_company_sid should be not null when in_re_second_company_sid is not null
		IF in_secondary_lookup = chain_pkg.SUPPLIER_MSG THEN
			v_to_users := company_pkg.GetPurchaserFollowers(in_re_company_sid, in_to_company_sid);
		ELSIF in_secondary_lookup = chain_pkg.PURCHASER_MSG AND in_system_wide=chain_pkg.INACTIVE THEN
			v_to_users := company_pkg.GetSupplierFollowers(in_to_company_sid, in_re_company_sid);
		ELSIF in_secondary_lookup = chain_pkg.PURCHASER_MSG AND in_system_wide=chain_pkg.ACTIVE THEN
			v_to_users := company_pkg.GetSupplierFollowersNoCheck(in_to_company_sid, in_re_company_sid);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Secondary lookup must be specified as SUPPLIER_MSG or PURCHASER_MSG for FOLLOWERS psuedo addressed messages');
		END IF;
		
		IF v_to_users IS NULL OR v_to_users.COUNT = 0 THEN
			--RAISE_APPLICATION_ERROR(-20001, 'TODO: figure out how we deal with messages addressed followers when no followers exist: msg_def_id='||v_dfn_id||', in_to_company_sid='||in_to_company_sid||', in_to_user_sid='||in_to_user_sid||', in_re_company_sid='||in_re_company_sid||', in_re_user_sid='||in_re_user_sid||', in_re_questionnaire_type_id='||in_re_questionnaire_type_id||', in_re_component_id='||in_re_component_id);
			-- lets' try to use the UCD as default
			BEGIN
				helper_pkg.LogonUCD;
				v_to_users.extend(1);
				v_to_users(v_to_users.COUNT) := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon');
				helper_pkg.RevertLogonUCD;
			EXCEPTION
				WHEN OTHERS THEN
					helper_pkg.RevertLogonUCD;
					RAISE;
			END;
		END IF;
				
	ELSIF in_to_user_sid IS NOT NULL THEN
		
		v_to_users := T_NUMBER_LIST(in_to_user_sid);
		v_find_by_user_sid := in_to_user_sid;
		
	ELSE
		
		v_to_users := T_NUMBER_LIST(NULL);
		
	END IF;
	
	---------------------------------------------------------------------------------------------------
	-- get the message if it exists already 
	v_msg := FindMessage_(
		in_message_definition_id 	=> v_dfn_id, 
		in_to_company_sid 			=> in_to_company_sid, 
		in_to_user_sid 				=> v_find_by_user_sid, 
		in_re_company_sid 			=> in_re_company_sid, 
		in_re_secondary_company_sid => in_re_secondary_company_sid,
		in_re_user_sid 				=> in_re_user_sid, 
		in_re_questionnaire_type_id => in_re_questionnaire_type_id, 
		in_re_component_id 			=> in_re_component_id,
		in_re_invitation_id			=> in_re_invitation_id,
		in_re_audit_request_id		=> in_re_audit_request_id
	);

	---------------------------------------------------------------------------------------------------
	-- apply repeatability
	IF v_msg.message_id IS NOT NULL THEN
		IF v_dfn.repeat_type_id = chain_pkg.NEVER_REPEAT THEN	

			IF v_msg.message_id IS NOT NULL THEN 
				RETURN;
			END IF;
		
		ELSIF v_dfn.repeat_type_id = chain_pkg.REPEAT_IF_CLOSED THEN

			IF v_msg.completed_dtm IS NULL THEN
				RETURN;
			END IF;

		ELSIF v_dfn.repeat_type_id = chain_pkg.REFRESH_OR_REPEAT THEN

			IF v_msg.completed_dtm IS NULL THEN
				
				INSERT INTO message_refresh_log
				(message_id, refresh_index)
				SELECT message_id, MAX(refresh_index) + 1
				  FROM message_refresh_log
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND message_id = v_msg.message_id
				 GROUP BY message_id;
				
				DELETE FROM user_message_log
				 WHERE message_id = v_msg.message_id;
			
				chain_link_pkg.MessageRefreshed(in_to_company_sid, v_msg.message_id, v_dfn_id);
				
				RETURN;

			END IF;
		
		END IF;
	END IF;

	---------------------------------------------------------------------------------------------------
	-- create the message entry 
	
	INSERT INTO message
	(message_id, message_definition_id, re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, due_dtm, re_secondary_company_sid, re_invitation_id, re_audit_request_id)
	VALUES
	(message_id_seq.NEXTVAL, v_dfn_id, in_re_company_sid, in_re_user_sid, in_re_questionnaire_type_id, in_re_component_id, in_due_dtm, in_re_secondary_company_sid, in_re_invitation_id, in_re_audit_request_id)
	RETURNING message_id INTO v_msg_id;

	SELECT COUNT(*) INTO v_cnt FROM chain_user WHERE user_sid = SYS_CONTEXT('SECURITY','SID');
	
	-- you can't do this during setup - e.g. creating the first company as no user is logged on that is in chain_user - throws ref integrity error
	IF v_cnt > 0 THEN	
		INSERT INTO message_refresh_log
		(message_id, refresh_index)
		VALUES
		(v_msg_id, 0);
	END IF;
	
	FOR i IN v_to_users.FIRST .. v_to_users.LAST
	LOOP
		v_r_id := GetRecipientId(v_msg_id, in_to_company_sid, v_to_users(i));

		INSERT INTO message_recipient
		(message_id, recipient_id)
		VALUES
		(v_msg_id, v_r_id);
		
	END LOOP;
	
	chain_link_pkg.MessageCreated(in_to_company_sid, v_msg_id, v_dfn_id);
END;

PROCEDURE CompleteMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_secondary_company_sid	IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_re_audit_request_id		IN  message.re_audit_request_id%TYPE			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_msg						message%ROWTYPE;
BEGIN
	v_msg := FindMessage_(
		in_message_definition_id 	=> v_dfn_id, 
		in_to_company_sid 			=> in_to_company_sid, 
		in_to_user_sid 				=> in_to_user_sid, 
		in_re_company_sid 			=> in_re_company_sid, 
		in_re_secondary_company_sid => in_re_secondary_company_sid,
		in_re_user_sid 				=> in_re_user_sid, 
		in_re_questionnaire_type_id => in_re_questionnaire_type_id, 
		in_re_component_id 			=> in_re_component_id,
		in_re_audit_request_id		=> in_re_audit_request_id
	);
	
	IF v_msg.message_id IS NULL THEN
		-- crazy long message because if it blows up, it will be tough to figure out why - this may help...
		RAISE_APPLICATION_ERROR(-20001, 'Message could not be completed because it was not found: msg_def_id='||v_dfn_id||', in_to_company_sid='||in_to_company_sid||', in_to_user_sid='||in_to_user_sid||', in_re_company_sid='||in_re_company_sid||', in_re_user_sid='||in_re_user_sid||', in_re_questionnaire_type_id='||in_re_questionnaire_type_id||', in_re_component_id='||in_re_component_id||', in_re_audit_request_id='||in_re_audit_request_id);
	END IF;
	
	CompleteMessageById(v_msg.message_id);
	
END;

PROCEDURE CompleteMessageIfExists (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_secondary_company_sid	IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_re_audit_request_id		IN  message.re_audit_request_id%TYPE			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_msgs						message_table;
BEGIN
	v_msgs := FindMessages_(
		in_message_definition_id 	=>	v_dfn_id, 
		in_to_company_sid 			=>	in_to_company_sid, 
		in_to_user_sid 				=>	in_to_user_sid, 
		in_re_company_sid 			=>	in_re_company_sid,
		in_re_secondary_company_sid =>	in_re_secondary_company_sid,
		in_re_user_sid 				=>	in_re_user_sid, 
		in_re_questionnaire_type_id =>	in_re_questionnaire_type_id, 
		in_re_component_id 			=>	in_re_component_id,
		in_re_audit_request_id		=>	in_re_audit_request_id,
		in_completed				=>	FALSE
	);
	
	FOR i IN 1..v_msgs.count() LOOP
		CompleteMessageById(v_msgs(i).message_id);
	END LOOP;
	
END;

PROCEDURE DeleteMessageById (
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	UPDATE alert_entry
	   SET message_id = NULL
	 WHERE message_id = in_message_id;
	
	DELETE FROM user_message_log
	 WHERE message_id = in_message_id;
	
	DELETE FROM message_refresh_log
	 WHERE message_id = in_message_id;
	
	DELETE FROM message_recipient
	 WHERE message_id = in_message_id;
	
	DELETE FROM message
	 WHERE message_id = in_message_id;
END;

PROCEDURE DeleteMessageIfIncomplete (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_secondary_company_sid	IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_re_audit_request_id		IN  message.re_audit_request_id%TYPE			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_msgs						message_table;
BEGIN
	v_msgs := FindMessages_(
		in_message_definition_id 	=>	v_dfn_id, 
		in_to_company_sid 			=>	in_to_company_sid, 
		in_to_user_sid 				=>	in_to_user_sid, 
		in_re_company_sid 			=>	in_re_company_sid,
		in_re_secondary_company_sid =>	in_re_secondary_company_sid,
		in_re_user_sid 				=>	in_re_user_sid, 
		in_re_questionnaire_type_id =>	in_re_questionnaire_type_id, 
		in_re_component_id 			=>	in_re_component_id,
		in_re_audit_request_id		=>	in_re_audit_request_id,
		in_completed				=>	FALSE
	);
	
	FOR i IN 1..v_msgs.count() LOOP
		DeleteMessageById(v_msgs(i).message_id);
	END LOOP;
	
END;

PROCEDURE CompleteMessageById (
	in_message_id				IN  message.message_id%TYPE
)
AS
	v_to_company_sid			security_pkg.T_SID_ID;
BEGIN
	
	UPDATE message
	   SET completed_dtm = SYSDATE,
	       completed_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND message_id = in_message_id
	   AND message_definition_id IN (
	   		SELECT message_definition_id
	   		  FROM v$message_definition
	   		 WHERE completion_type_id <> chain_pkg.NO_COMPLETION
	   		);	

	IF SQL%ROWCOUNT > 0 THEN
		SELECT MAX(r.to_company_sid) -- there may be 0 or more entries, but all have the same company sid
		  INTO v_to_company_sid
		  FROM recipient r, message_recipient mr
		 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mr.app_sid = r.app_sid
		   AND mr.recipient_id = r.recipient_id
		   AND mr.message_id = in_message_id;		   
		
		chain_link_pkg.MessageCompleted(v_to_company_sid, in_message_id);
	END IF;
END;

FUNCTION FindMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_completed				IN	BOOLEAN										DEFAULT NULL
)
RETURN message%ROWTYPE
AS
BEGIN
	RETURN FindMessage_(
		in_message_definition_id 	=>	Lookup(in_primary_lookup, in_secondary_lookup), 
		in_to_company_sid 			=>	in_to_company_sid, 
		in_to_user_sid 				=>	in_to_user_sid, 
		in_re_company_sid 			=>	in_re_company_sid, 
		in_re_secondary_company_sid =>	NULL,
		in_re_user_sid 				=>	in_re_user_sid, 
		in_re_questionnaire_type_id =>	in_re_questionnaire_type_id, 
		in_re_component_id 			=>	in_re_component_id,
		in_completed 				=>	in_completed
	);
END;

-- compatibility alias
PROCEDURE GetMessage (
	in_message_id					IN	message.message_id%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID, --this is needed because some messages have multiple recipients
	out_message_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_invitation_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy_cur						security_pkg.T_OUTPUT_CUR;
BEGIN
	GetMessage(in_message_id, in_user_sid, out_message_cur, out_message_param_cur,
				out_company_cur, out_user_cur, out_questionnaire_type_cur,
				out_component_cur, out_invitation_cur, v_dummy_cur);
END;

PROCEDURE GetMessage (
	in_message_id					IN	message.message_id%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID, --this is needed because some messages have multiple recipients
	out_message_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_invitation_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_audit_request_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	OPEN out_message_cur FOR
		SELECT m.message_id, m.message_definition_id, md.message_template, md.completion_type_id, m.completed_by_user_sid, 
			   md.completed_template, md.css_class, mr.to_company_sid, mr.to_user_sid, 
			   m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid, 
			   m.re_questionnaire_type_id, m.re_component_id, m.re_invitation_id, m.re_audit_request_id,
			   m.completed_dtm, m.created_dtm, m.last_refreshed_dtm, m.last_refreshed_by_user_sid, m.due_dtm, SYSDATE now_dtm,
			   CASE WHEN mr.to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
			   		 AND m.completed_dtm IS NULL 
			   		 AND md.completion_type_id = chain_pkg.ACKNOWLEDGE 
			   		THEN 1 
			   		ELSE 0 
			   		 END requires_acknowledge
		  FROM v$message m
		  JOIN v$message_definition md
			ON m.message_definition_id = md.message_definition_id
		  JOIN v$message_recipient mr
		    ON mr.message_id = m.message_id
		   AND (mr.to_user_sid = in_user_sid OR mr.to_user_sid IS NULL) --some messages are sent to a company instead of a user
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')	   
		   AND m.message_id = in_message_id;
		   
	OPEN out_message_param_cur FOR
		SELECT vmp.message_definition_id, vmp.param_name, vmp.value, vmp.href, vmp.css_class
		  FROM v$message_param vmp
		  JOIN v$message vm
		    ON vmp.message_definition_id = vm.message_definition_id
		 WHERE vm.message_id = in_message_id;
		 
	OPEN out_company_cur FOR
		SELECT company_sid, name 
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid IN (
		   		SELECT to_company_sid FROM v$message_recipient WHERE message_id = in_message_id
		   		 UNION ALL
		   		SELECT re_company_sid FROM v$message_recipient WHERE message_id = in_message_id
				 UNION ALL
		   		SELECT re_secondary_company_sid FROM v$message_recipient WHERE message_id = in_message_id
		   	   );

	OPEN out_user_cur FOR
		SELECT csr_user_sid user_sid, full_name
		  FROM csr.csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid  IN (
		   		SELECT to_user_sid FROM v$message_recipient WHERE message_id = in_message_id
		   		 UNION ALL
		   		SELECT re_user_sid FROM v$message_recipient WHERE message_id = in_message_id
		   		 UNION ALL
		   		SELECT completed_by_user_sid FROM v$message_recipient WHERE message_id = in_message_id
		   		 UNION ALL
		   		SELECT last_refreshed_by_user_sid FROM v$message_recipient WHERE message_id = in_message_id
		   	   );
		
	OPEN out_questionnaire_type_cur FOR
		SELECT questionnaire_type_id, name, edit_url, view_url
		  FROM questionnaire_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id IN (
		 		SELECT re_questionnaire_type_id FROM v$message_recipient WHERE message_id = in_message_id
		 	   );

	OPEN out_component_cur FOR
		SELECT component_id, description
		  FROM component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id IN (
		 		SELECT re_component_id FROM v$message_recipient WHERE message_id = in_message_id
		 	   );
			   
	OPEN out_invitation_cur FOR
		SELECT invitation_id, guid
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id IN (
		 		SELECT re_invitation_id FROM v$message_recipient WHERE message_id = in_message_id
		 	   );

	OPEN out_audit_request_cur FOR
		SELECT audit_request_id, audit_sid, audit_label
		  FROM v$audit_request
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND audit_request_id IN (
		 		SELECT re_audit_request_id FROM v$message_recipient WHERE message_id = in_message_id
		 	   );
			   
END;

PROCEDURE GetMessages (
	in_to_company_sid				IN  security_pkg.T_SID_ID,
	in_to_user_sid					IN  security_pkg.T_SID_ID,
	in_filter_for_priority			IN  NUMBER,
	in_filter_for_pure_messages		IN  NUMBER,
	in_filter_for_to_do_messages	IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_page							IN  NUMBER,
	out_stats_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_message_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_invitation_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_audit_request_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_recipient_ids				T_NUMERIC_TABLE DEFAULT GetUserRecipientIds(in_to_company_sid, in_to_user_sid);
	v_user_level_messaging		company.user_level_messaging%TYPE;
	v_has_show_stoppers			NUMBER(10);
	v_page						NUMBER(10) DEFAULT in_page;
	v_count						NUMBER(10);
	v_ms_tbl					T_MESSAGE_SEARCH_TABLE;
	v_qnr_prim_lookups			chain.T_NUMBER_LIST := chain.T_NUMBER_LIST(chain_pkg.COMPLETE_QUESTIONNAIRE, chain_pkg.QUESTIONNAIRE_SUBMITTED, chain_pkg.QUESTIONNAIRE_APPROVED,	
								chain_pkg.QUESTIONNAIRE_OVERDUE, chain_pkg.QUESTIONNAIRE_REJECTED, chain_pkg.QUESTIONNAIRE_RETURNED, chain_pkg.QNR_SUBMITTED_NO_REVIEW,
								chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, chain_pkg.COMP_QUESTIONNAIRE_APPROVED, chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
								chain_pkg.COMP_QUESTIONNAIRE_REJECTED, chain_pkg.COMP_QUESTIONNAIRE_RETURNED, chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW);				
BEGIN
	
	-- TODO: turn this and the following query back into a single query
	INSERT INTO tt_message_search
	(	message_id, message_definition_id, to_company_sid, to_user_sid, 
		re_company_sid, re_secondary_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, 
		re_invitation_id, re_audit_request_id, completed_by_user_sid, last_refreshed_by_user_sid, order_by_dtm
	)
	SELECT m.message_id, m.message_definition_id, in_to_company_sid, 
			CASE WHEN md.addressing_type_id = chain_pkg.USER_ADDRESS THEN m.to_user_sid ELSE NULL END, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			m.re_invitation_id, m.re_audit_request_id, m.completed_by_user_sid, m.last_refreshed_by_user_sid,
			CASE WHEN m.completed_dtm IS NOT NULL AND m.completed_dtm > m.last_refreshed_dtm THEN m.completed_dtm ELSE m.last_refreshed_dtm END
	  FROM v$message_recipient m, v$message_definition md, TABLE(v_recipient_ids) r
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.recipient_id = r.item
	   AND m.message_definition_id = md.message_definition_id
	   AND md.message_priority_id <> chain_pkg.HIDDEN
	   AND (
			   -- the message is privately addressed to the user
			   (md.addressing_type_id = chain_pkg.USER_ADDRESS 			AND r.pos = DIRECT_TO_USER)
			   -- the message is addressed to the entire company
			OR (md.addressing_type_id = chain_pkg.COMPANY_ADDRESS 		AND r.pos = TO_ENTIRE_COMPANY)
				-- the message is address to the comapny and user 
			OR (md.addressing_type_id = chain_pkg.COMPANY_USER_ADDRESS 	AND r.pos = DIRECT_TO_USER)
				-- we're not using user level addressing, and the messsage is addressed to the company, but another user within the company
	   	   );
	
	-- remove any messages that:
	-- 		1. involve deleted companies 
	--		2. require completion 
	-- 		3. have not been completed
	--		4. are not invitation rejection messages
	DELETE FROM tt_message_search
	 WHERE message_id IN (
	 	SELECT m.message_id
	 	  FROM message m, v$message_definition md, company c, company c2, message_definition_lookup mdl
	 	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND m.message_definition_id = md.message_definition_id
	 	   AND m.message_definition_id = mdl.message_definition_id
	 	   AND m.re_company_sid = c.company_sid
	 	   AND m.re_secondary_company_sid = c2.company_sid (+)
	 	   AND c.deleted = chain_pkg.DELETED
	 	   AND c2.deleted (+) = chain_pkg.DELETED
	 	   AND md.completion_type_id IN (chain_pkg.ACKNOWLEDGE, chain_pkg.CODE_ACTION)
	 	   AND m.completed_dtm IS NULL
	 	   AND mdl.primary_lookup_id <> chain_pkg.INVITATION_REJECTED
	 );
	
	SELECT NVL(MIN(user_level_messaging), chain_pkg.INACTIVE)
	  INTO v_user_level_messaging
	  FROM v$company
	 WHERE company_sid = in_to_company_sid;
	 
	IF v_user_level_messaging = chain_pkg.INACTIVE THEN
		-- TODO: turn this and the previous query back into a single query
		INSERT INTO tt_message_search
		(	message_id, message_definition_id, to_company_sid, to_user_sid, 
			re_company_sid, re_secondary_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, 
			completed_by_user_sid, last_refreshed_by_user_sid, order_by_dtm
		)
		SELECT m.message_id, m.message_definition_id, in_to_company_sid, NULL, 
				m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
				m.completed_by_user_sid, m.last_refreshed_by_user_sid, 
			CASE WHEN m.completed_dtm IS NOT NULL AND m.completed_dtm > m.last_refreshed_dtm THEN m.completed_dtm ELSE m.last_refreshed_dtm END
		  FROM v$message m, v$message_definition md
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.message_definition_id = md.message_definition_id
		   AND md.message_priority_id <> chain_pkg.HIDDEN
		   AND md.addressing_type_id = chain_pkg.COMPANY_USER_ADDRESS 	
		   AND m.message_id NOT IN (SELECT message_id FROM tt_message_search)
		   AND m.message_id IN (
				SELECT mr.message_id
				  FROM message_recipient mr, TABLE(v_recipient_ids) r
				 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND mr.recipient_id = r.item
				   AND r.pos = TO_OTHER_COMPANY_USER
			); 
	END IF;
	
	IF in_filter_for_priority <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE completed_by_user_sid IS NOT NULL;
			 
		--TODO: don't we also need to clear the deleted related companies from the priority list?
		
		DELETE FROM tt_message_search
		 WHERE message_definition_id IN (
		 	SELECT message_definition_id
		 	  FROM v$message_definition
		 	 WHERE completion_type_id = chain_pkg.NO_COMPLETION
		 );
		
		SELECT COUNT(*)
		  INTO v_has_show_stoppers
		  FROM tt_message_search ms, v$message_definition md
		 WHERE ms.message_definition_id = md.message_definition_id 
		   AND md.message_priority_id = chain_pkg.SHOW_STOPPER;
		
		IF v_has_show_stoppers > 0 THEN
			DELETE FROM tt_message_search
			 WHERE message_definition_id NOT IN (
				SELECT message_definition_id
				  FROM v$message_definition
				 WHERE message_priority_id = chain_pkg.SHOW_STOPPER
		 		);		
		END IF;
				
		FOR r IN (
			SELECT tt.message_id, mdl.secondary_lookup_id, q.questionnaire_id
			  FROM tt_message_search tt
			  JOIN message_definition_lookup mdl ON tt.message_definition_id = mdl.message_definition_id  
			  JOIN TABLE(v_qnr_prim_lookups) qmpl ON mdl.primary_lookup_id = qmpl.column_value --filtering by primary lookup might seem overzealous, leave it for clarity
			  JOIN questionnaire q ON tt.re_questionnaire_type_id = q.questionnaire_type_id
			 WHERE tt.re_questionnaire_type_id IS NOT NULL
			   AND mdl.secondary_lookup_id IN (chain_pkg.PURCHASER_MSG, chain_pkg.SUPPLIER_MSG)		
			   AND q.company_sid = DECODE(mdl.secondary_lookup_id, chain_pkg.PURCHASER_MSG, tt.re_company_sid, tt.to_company_sid)
			   AND (tt.re_component_id = q.component_id OR tt.re_component_id IS NULL AND q.component_id IS NULL)			   
		)
		LOOP
			IF r.secondary_lookup_id = chain_pkg.PURCHASER_MSG THEN
				IF NOT questionnaire_security_pkg.CheckPermission(r.questionnaire_id, chain_pkg.QUESTIONNAIRE_APPROVE) THEN
					DELETE FROM tt_message_search
					 WHERE message_id = r.message_id;
				END IF;
			ELSIF r.secondary_lookup_id = chain_pkg.SUPPLIER_MSG THEN
				IF NOT questionnaire_security_pkg.CheckPermission(r.questionnaire_id, chain_pkg.QUESTIONNAIRE_SUBMIT) THEN
					DELETE FROM tt_message_search
					 WHERE message_id = r.message_id;
				END IF;
			END IF;
		END LOOP;
	END IF;

	IF in_filter_for_pure_messages <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE completed_by_user_sid IS NULL
		   AND message_definition_id NOT IN (
		   	SELECT message_definition_id
			  FROM v$message_definition
		 	 WHERE completion_type_id = chain_pkg.NO_COMPLETION
		   );
	END IF;
	
	IF in_filter_for_to_do_messages <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE message_definition_id NOT IN (
		   	SELECT message_definition_id
			  FROM v$message_definition
		 	 WHERE message_priority_id = chain_pkg.TO_DO_LIST
		   );
	ELSE
		-- TO DO messages are not shown except when filtered for specifically
		DELETE FROM tt_message_search
		 WHERE message_definition_id IN (
		   	SELECT message_definition_id
			  FROM v$message_definition
		 	 WHERE message_priority_id = chain_pkg.TO_DO_LIST
		   );	
	END IF;
	
	--todo: CheckPermissionSQL function in SQL might cause a dml exception (when TT_USER_GROUPS is empty)
	--either call FillUserGroups explicitly or check questionnaire permissions in a loop 
	
	--Clear messages related to questionnaires the user has no view permission on (that also includes questionnaires for deleted companies as the permission check will fail)
	--Use message_definition_lookup to infer the owner company sid of the questionnaire based on the secondary lookup
	--For purchaser_msg use re_company_sid, for supplier_msg use to_company_sid
	DELETE FROM tt_message_search
	 WHERE message_id IN(
		SELECT tt.message_id
		  FROM tt_message_search tt
		  JOIN message_definition_lookup mdl ON tt.message_definition_id = mdl.message_definition_id  
		  JOIN TABLE(v_qnr_prim_lookups) qmpl ON mdl.primary_lookup_id = qmpl.column_value --filtering by primary lookup might seem overzealous, leave it for clarity
		 WHERE tt.re_questionnaire_type_id IS NOT NULL
		   AND mdl.secondary_lookup_id IN (chain_pkg.PURCHASER_MSG, chain_pkg.SUPPLIER_MSG)
		   AND NOT EXISTS(
				SELECT 1 
				  FROM chain.questionnaire q
				 WHERE q.company_sid = DECODE(mdl.secondary_lookup_id, chain_pkg.PURCHASER_MSG, tt.re_company_sid, tt.to_company_sid)
				   AND tt.re_questionnaire_type_id = q.questionnaire_type_id
				   AND (tt.re_component_id = q.component_id OR tt.re_component_id IS NULL AND q.component_id IS NULL)
				   AND questionnaire_security_pkg.CheckPermissionSQL(q.questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) = 1
		   )
	 );
	 
	SELECT COUNT(*)
	  INTO v_count
	  FROM tt_message_search;
	
	OPEN out_stats_cur FOR
		SELECT v_count total_rows FROM DUAL;

	IF in_page_size > 0 THEN
		IF in_page < 1 THEN
			v_page := 1;
		END IF;
		
		DELETE FROM tt_message_search
		 WHERE message_id NOT IN (
			SELECT message_id
			  FROM (
				SELECT message_id, rownum rn
				  FROM (
					SELECT message_id
					  FROM tt_message_search
					 ORDER BY CASE WHEN in_filter_for_priority = 0 THEN order_by_dtm END DESC,
							  CASE WHEN in_filter_for_priority = 0 THEN re_questionnaire_type_id END DESC,
							  CASE WHEN in_filter_for_priority = 0 THEN message_id END ASC,
							  CASE WHEN in_filter_for_priority != 0 THEN order_by_dtm END DESC,--ASC,
							  CASE WHEN in_filter_for_priority != 0 THEN re_questionnaire_type_id END ASC,
							  CASE WHEN in_filter_for_priority != 0 THEN message_id END DESC
					)
			  )
			 WHERE rn > in_page_size * (v_page - 1)
			   AND rn <= in_page_size * v_page
		 );		 
	END IF;


	UPDATE tt_message_search o
	   SET viewed_dtm = (
	   		SELECT viewed_dtm
	   		  FROM user_message_log i
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND i.message_id = o.message_id
  		);
	
	INSERT INTO user_message_log
	(message_id, user_sid, viewed_dtm)
	SELECT message_id, SYS_CONTEXT('SECURITY', 'SID'), SYSDATE
	  FROM tt_message_search
	 WHERE message_id NOT IN (
	 	SELECT message_id
	 	  FROM user_message_log
	 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 );	 
	
	SELECT T_MESSAGE_SEARCH_ROW(
		message_id,
		message_definition_id,
		to_company_sid,
		to_user_sid,
		re_company_sid,
		re_user_sid,
		re_questionnaire_type_id,
		re_component_id,
		order_by_dtm,
		last_refreshed_by_user_sid,
		completed_by_user_sid,
		viewed_dtm,
		re_secondary_company_sid,
		re_invitation_id,
		re_audit_request_id
	)
	  BULK COLLECT INTO v_ms_tbl
	  FROM (
		SELECT
			message_id,
			message_definition_id,
			to_company_sid,
			to_user_sid,
			re_company_sid,
			re_user_sid,
			re_questionnaire_type_id,
			re_component_id,
			order_by_dtm,
			last_refreshed_by_user_sid,
			completed_by_user_sid,
			viewed_dtm,
			re_secondary_company_sid,
			re_invitation_id,
			re_audit_request_id
		FROM tt_message_search
	);
		
	OPEN out_message_cur FOR
		SELECT m.message_id, m.message_definition_id, md.message_template, md.completion_type_id, m.completed_by_user_sid, 
			   md.completed_template, md.css_class, ms.to_company_sid, ms.to_user_sid, 
			   m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid,
			   m.re_questionnaire_type_id, m.re_component_id, m.re_invitation_id, m.re_audit_request_id,
			   m.completed_dtm, m.created_dtm, m.last_refreshed_dtm, m.last_refreshed_by_user_sid, m.due_dtm, SYSDATE now_dtm,
			   CASE WHEN in_to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
			   		 AND m.completed_dtm IS NULL 
			   		 AND md.completion_type_id = chain_pkg.ACKNOWLEDGE 
			   		THEN 1 
			   		ELSE 0 
			   		 END requires_acknowledge
		  FROM v$message m
		  JOIN v$message_definition md ON m.message_definition_id = md.message_definition_id
		  JOIN TABLE(v_ms_tbl) ms ON m.message_id = ms.message_id
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY CASE WHEN in_filter_for_priority = 0 THEN ms.order_by_dtm END DESC,
				  CASE WHEN in_filter_for_priority = 0 THEN m.re_questionnaire_type_id END DESC,
				  CASE WHEN in_filter_for_priority = 0 THEN ms.message_id END ASC,
				  CASE WHEN in_filter_for_priority != 0 THEN ms.order_by_dtm END DESC,--ASC,
				  CASE WHEN in_filter_for_priority != 0 THEN m.re_questionnaire_type_id END ASC,
				  CASE WHEN in_filter_for_priority != 0 THEN ms.message_id END DESC;
		   
	OPEN out_message_param_cur FOR
		SELECT message_definition_id, param_name, value, href, css_class
		  FROM v$message_param 
		 WHERE message_definition_id IN (
		 		SELECT message_definition_id FROM TABLE(v_ms_tbl)
		 	   );
		 
	OPEN out_company_cur FOR
		SELECT company_sid, name 
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid IN (
		   		SELECT to_company_sid FROM TABLE(v_ms_tbl)
		   		 UNION ALL
		   		SELECT re_company_sid FROM TABLE(v_ms_tbl)
				 UNION ALL
		   		SELECT re_secondary_company_sid FROM TABLE(v_ms_tbl)
		   	   );

	OPEN out_user_cur FOR
		SELECT csr_user_sid user_sid, full_name
		  FROM csr.csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid  IN (
		   		SELECT to_user_sid FROM TABLE(v_ms_tbl)
		   		 UNION ALL
		   		SELECT re_user_sid FROM TABLE(v_ms_tbl)
		   		 UNION ALL
		   		SELECT completed_by_user_sid FROM TABLE(v_ms_tbl)
		   		 UNION ALL
		   		SELECT last_refreshed_by_user_sid FROM TABLE(v_ms_tbl)
		   	   );
		
	OPEN out_questionnaire_type_cur FOR
		SELECT questionnaire_type_id, name, edit_url, view_url
		  FROM questionnaire_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id IN (
		 		SELECT re_questionnaire_type_id FROM TABLE(v_ms_tbl)
		 	   );

	OPEN out_component_cur FOR
		SELECT component_id, description
		  FROM component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id IN (
		 		SELECT re_component_id FROM TABLE(v_ms_tbl)
		 	   );
			   
	OPEN out_invitation_cur FOR
		SELECT invitation_id, guid
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id IN (
		 		SELECT re_invitation_id FROM TABLE(v_ms_tbl)
		 	   );

	OPEN out_audit_request_cur FOR
		SELECT audit_request_id, audit_sid, audit_label
		  FROM v$audit_request
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND audit_request_id IN (
		 		SELECT re_audit_request_id FROM TABLE(v_ms_tbl)
		 	   );
			   
END;

FUNCTION GetMessage (
	in_message_id				IN  message.message_id%TYPE
) RETURN message%ROWTYPE
AS
	v_msg						message%ROWTYPE;
BEGIN
	BEGIN
		SELECT *
		  INTO v_msg
		  FROM message
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND message_id = in_message_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_msg;
END;


FUNCTION GetMessageDefintionId (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message.message_definition_id%TYPE
AS
	v_msg_def_id						message_definition.message_definition_id%TYPE := -1;
BEGIN
	BEGIN
		SELECT md.message_definition_id
		  INTO v_msg_def_id
		  FROM message_definition md, message_definition_lookup mdl
		 WHERE md.message_definition_id = mdl.message_definition_id
		   AND mdl.primary_lookup_id = in_primary_lookup
		   AND mdl.secondary_lookup_id = in_secondary_lookup;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_msg_def_id;
END;


PROCEDURE CopyCompanyFollowerMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_re_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
	v_recipient_id				recipient.recipient_id%TYPE;
BEGIN
	v_recipient_id := message_pkg.GetRecipientId(NULL, in_to_company_sid, in_user_sid);
	
	INSERT INTO message_recipient (message_id, recipient_id)
	SELECT DISTINCT message_id, v_recipient_id
	  FROM v$message_recipient
	 WHERE app_sid = security_pkg.GetApp
	   AND re_company_sid = in_re_company_sid
	   AND to_company_sid = in_to_company_sid
	   AND message_id NOT IN (SELECT message_id FROM message_recipient WHERE recipient_id = v_recipient_id);
END;

PROCEDURE RemoveCompanyFollowerMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_re_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM message_recipient 
	 WHERE (app_sid, message_id, recipient_id) IN (
	 		SELECT mr.app_sid, mr.message_id, mr.recipient_id
	 		  FROM message m, message_recipient mr, recipient r
	 		 WHERE mr.app_sid = security_pkg.GetApp
	 		   AND mr.app_sid = m.app_sid
	 		   AND mr.app_sid = r.app_sid
	 		   AND mr.message_id = m.message_id
	 		   AND mr.recipient_id = r.recipient_id
	 		   AND m.re_company_sid = in_re_company_sid
	 		   AND r.to_company_sid = in_to_company_sid
	 		   AND r.to_user_sid = in_user_sid
	 	);
END;

/* Generator SP for ActionMessage Scheduled alerts */
PROCEDURE GenerateActionMessageAlerts
AS
	v_alert_entry_id		chain.alert_entry.alert_entry_id%TYPE;
BEGIN

FOR r IN (
	SELECT m.message_id, mr.to_user_sid, mr.to_company_sid, m.last_refreshed_dtm 
	  FROM chain.v$message m
	  JOIN chain.v$message_definition md
		ON m.message_definition_id = md.message_definition_id
	  JOIN chain.v$message_recipient mr
		ON m.message_id = mr.message_id
	  JOIN csr.v$csr_user csru
		ON mr.to_user_sid = csru.csr_user_sid
	   AND csru.csr_user_sid NOT IN ( SELECT csr_user_sid FROM csr.superadmin )
	 WHERE md.completion_type_id = chain_pkg.CODE_ACTION
	   AND m.completed_dtm IS NULL
	   AND md.message_priority_id != chain_pkg.HIDDEN  ) LOOP
	   
	   IF r.to_user_sid IS NOT NULL THEN
		v_alert_entry_id := chain.scheduled_alert_pkg.SetAlertEntry(chain_pkg.ACTION_MESSAGE, r.to_user_sid, 'DEFAULT_MESSAGE_LIST', r.last_refreshed_dtm, 0, r.to_company_sid, r.message_id);
	   ELSIF r.to_user_sid IS NULL AND r.to_company_sid IS NOT NULL THEN
		/* some messages are addressed to the entire company, so if to_user is null but to_company isn't, assume it is meant for all users of to_company */
		FOR ru IN (
			SELECT cu.user_sid
			FROM chain.v$company_user cu
			JOIN csr.v$csr_user csru
			  ON cu.user_sid = csru.csr_user_sid
			 AND csru.csr_user_sid NOT IN ( SELECT csr_user_sid FROM csr.superadmin )
			WHERE cu.company_sid = r.to_company_sid ) LOOP
			  v_alert_entry_id := chain.scheduled_alert_pkg.SetAlertEntry(chain_pkg.ACTION_MESSAGE, ru.user_sid, 'DEFAULT_MESSAGE_LIST', r.last_refreshed_dtm, 0, r.to_company_sid, r.message_id);		
		END LOOP;
	   END IF;
	   
	END LOOP;
	
END;

END message_pkg;
/
