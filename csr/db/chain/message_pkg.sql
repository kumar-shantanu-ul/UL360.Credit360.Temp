CREATE OR REPLACE PACKAGE  CHAIN.message_pkg
IS

/**********************************************************************************
	INTERNAL FUNCTIONS
	
	These methods should not be widely used and are provided publicly for setup convenience
**********************************************************************************/

FUNCTION Lookup (
	in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE;

FUNCTION Lookup (
	in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE;


/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Creates or updates a message
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_message_template	The template text to use
 * @param in_repeat_type		Defines how create the message in the event that it already exists
 * @param in_priority			The priority of the message
 * @param in_addressing_type	Defines who the message should be delivered to
 * @param in_completion_type	Defines the method that will be used to complete this message
 * @param in_completed_template	Additional information to display once the message is marked as completed
 * @param in_helper_pkg			The pkg that will be called when this message is opened or completed
 * @param in_css_class			The css class that wraps the message
 */
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
);

/**
 * Creates or updates a message parameter
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_param_name			The message parameter name (camelCase, must conform to [a-z][A-Z][0-9])
 * @param in_css_class			The css class to wrap the parameter in (this is only applied at the top template level - i.e. nested parameters will be not be wrapped)
 * @param in_href				The href for a link. Links are not used if this is null
 * @param in_value				The innerHTML of the link (if href is not null) or span
 *
 * NOTES:
 * 	1. top level template parameters are essentially xtemplate formatted as:
 *
 *		{paramName}->{paramName:OPEN}{paramName:VALUE}{paramName:CLOSE}
 *
 *		{paramName:OPEN} -> <span class="{cssClass}">
 *								<tpl if="href">
 *									<a href="{href}">
 *								</tpl>
 *						
 *		{paramName:VALUE} ->	{value}
 *
 *		{paramName:CLOSE} -> 	<tpl if="href">
 *									</a>
 *								</tpl>
 *							</span>
 *
 * 	2. subsequent level parameters are formatted using:
 *		
 *		{paramName} -> {value}
 *
 * This allows us to keep translations in-line in the template, but still use single parameter definitions as needed.
 */
PROCEDURE DefineMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL	
);


/**********************************************************************************
	APPLICATION MANAGEMENT
	
	These methods act on data at an application level
**********************************************************************************/

/**
 * Creates or updates an application level message override
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_message_template	Overrides the template text to use
 * @param in_priority			Overrides the priority of the message
 * @param in_addressing_type	Overrides who the message should be delivered to
 * @param in_completed_template	Overrides additional information to display once the message is marked as completed
 * @param in_helper_pkg			Overrides the pkg that will be called when this message is opened or completed
 * @param in_css_class			Overrides the css class that wraps the message
 * @param in_completion_type	Overrides the method that will be used to complete this message
 */
PROCEDURE OverrideMessageDefinition (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE	DEFAULT NULL,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT NULL,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL,
	in_completion_type			In  message_definition.completion_type_id%TYPE 	DEFAULT NULL
);

/**
 * Creates or updates an application level message parameter override
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_param_name			The message parameter name (camelCase, must conform to [a-z][A-Z][0-9])
 * @param in_css_class			Overrides the css class to wrap the parameter in (this is only applied at the top template level - i.e. nested parameters will be not be wrapped)
 * @param in_href				Overrides the href for a link. Links are not used if this is null
 * @param in_value				Overrides the innerHTML of the link (if href is not null) or span
 *
 * NOTE: See above for notes on how parameters are applied
 */
PROCEDURE OverrideMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL
);

/**********************************************************************************
	COMMON METHODS
	
	These are the core methods for sending a message
**********************************************************************************/

/**
 * Creates a recipient box for the company_sid, user_sid combination
 *
 * @param in_company_sid		The company_sid to create the box for
 * @param in_user_sid			The user_sid to create the box for
 * @return recipient_id			The new recipient id
 */
FUNCTION CreateRecipient (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE;

/**
 * Triggers a message (triggering is determined by the message definition repeate type)
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 * @param in_due_dtm			A timestamp that will be used in the notes of the message.
 * @param in_system_wide		1 if message is for a system-wide transaction i.e. does not relate to the current logged in company (e.g. expiring invitations). This relaxes the permissions for getting supplier followers.
 * @param in_re_secondary_company_sid The secondary company that the message is about
 * @param in_re_invitation_id The invitation that the message is about
 *
 *	NOTE: the in_due_dtm is only used as a visual aid for the user, and DOES NOT
 *		automatically trigger additional notifications if passed without completion.
 */
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
);

/**
 * Completes a message if it is completable and is not already completed. Raises an error if it is not found
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_secondary_company_sid		The other company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
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
);

/**
 * Completes all messages if they are completable and is not already completed but will not raise an error if it is not found
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_secondary_company_sid		The other company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
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
);

/**
 * Deletes all messages if they are completable and is not already completed but will not raise an error if it is not found
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_secondary_company_sid		The other company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
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
);

/**
 * Completes a message if it is completable and is not already completed
 *
 * @param in_message_id			The id of the message to complete
 */
PROCEDURE CompleteMessageById (
	in_message_id				IN  message.message_id%TYPE
);

/**
 * Finds the most recent message which matches the parameters provided. 
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
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
RETURN message%ROWTYPE;

/**
 * Gets all messages for the current user, current company
 *
 * @param in_to_company_sid				The company to get the messages for
 * @param in_to_user_sid				The user to get the messages for
 * @param in_filter_for_priority		Set to non-zero to get remove messages that are needing completion, grouped by the highest priority
 * @param in_filter_for_pure_messages	Set to non-zero to get remove messages that are not needing completion
 * @param in_page_size					The page size - 0 to get all
 * @param in_page						The page number (ignored if page_size is 0)
 * @param out_stats_cur					The stats used for paging
 * @param out_message_cur				The message details
 * @param out_message_param_cur			The message definition parameters
 * @param out_company_cur				Companies that are involved in these messages
 * @param out_user_cur					Users that are involved in these messages
 * @param out_questionnaire_type_cur	Questionnaire types that are involved in these messages
 * @param out_component_cur				Components that are involved in these messages
 * @param out_invitation_cur			Invitations that are involved in these messages
 * @param out_audit_request_cur			Invitations that are involved in these messages
 */
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
);

/**
 * Gets a message by id
 *
 * @param in_message_id			The id of the message to retrieve
 */
FUNCTION GetMessage (
	in_message_id				IN  message.message_id%TYPE
) RETURN message%ROWTYPE;

PROCEDURE GetMessage (
	in_message_id					IN	message.message_id%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,	
	out_message_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_invitation_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_audit_request_cur			OUT security_pkg.T_OUTPUT_CUR
);

-- compatibility alias
PROCEDURE GetMessage (
	in_message_id					IN	message.message_id%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,	
	out_message_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_invitation_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets a message defintion id by primary and secondary lookup
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 */
FUNCTION GetMessageDefintionId (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message.message_definition_id%TYPE;

PROCEDURE CopyCompanyFollowerMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_re_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE RemoveCompanyFollowerMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_re_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE GenerateActionMessageAlerts;

END message_pkg;
/

