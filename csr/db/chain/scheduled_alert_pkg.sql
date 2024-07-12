CREATE OR REPLACE PACKAGE  CHAIN.scheduled_alert_pkg
IS

/*******************************************************************
	Other Chain jobs running on this task
*******************************************************************/

PROCEDURE RunChainJobs;

/*******************************************************************
	Alert entry type setup
*******************************************************************/

/* Use this to create a base template inherited for all apps for this alert entry type */
PROCEDURE SetTemplate(
	in_alert_entry_type		IN chain_pkg.T_ALERT_ENTRY_TYPE,
	in_template_name		IN alert_entry_template.template_name%TYPE,
	in_template				IN alert_entry_template.template%TYPE
);

/* Use this to create overrides or customer only templates */
PROCEDURE SetCustomerTemplate(
	in_alert_entry_type		IN chain_pkg.T_ALERT_ENTRY_TYPE,
	in_template_name		IN alert_entry_template.template_name%TYPE,
	in_template				IN alert_entry_template.template%TYPE
);

PROCEDURE UpdateUserSettings (
	in_alert_entry_type_id	IN	chain.alert_entry_type.alert_entry_type_id%TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_enabled				IN  chain.user_alert_entry_type.enabled%TYPE DEFAULT NULL,
	in_schedule_xml			IN	chain.user_alert_entry_type.schedule_xml%TYPE DEFAULT NULL
);

PROCEDURE UpdateClientSettings (
	in_alert_entry_type_id					IN	chain.alert_entry_type.alert_entry_type_id%TYPE,
	in_enabled								IN  chain.customer_alert_entry_type.enabled%TYPE DEFAULT NULL,
	in_schedule_xml							IN	chain.customer_alert_entry_type.schedule_xml%TYPE DEFAULT NULL,
	in_important_section_template			IN	chain.customer_alert_entry_type.important_section_template%TYPE DEFAULT NULL,
	in_company_section_template				IN	chain.customer_alert_entry_type.company_section_template%TYPE DEFAULT NULL,
	in_user_section_template				IN	chain.customer_alert_entry_type.user_section_template%TYPE DEFAULT NULL,
	in_generator_sp							IN	chain.customer_alert_entry_type.generator_sp%TYPE DEFAULT NULL,
	in_force_disable						IN 	chain.customer_alert_entry_type.force_disable%TYPE DEFAULT NULL
);
	
/*******************************************************************
	To be called by scheduler
*******************************************************************/

PROCEDURE GenerateRecipientTable;

PROCEDURE GenerateAlertEntries(
	in_alert_entry_type_id	IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOutstandingAlertRecipients (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/* the send_dtm that we set here will actually show the date/time this alert was added to the std batch list, not when it was actually sent */
PROCEDURE MarkAlertSent (
	in_scheduled_alert_id	IN chain.scheduled_alert.scheduled_alert_id%TYPE
);

PROCEDURE SendingScheduledAlertTo (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_alert_entry_type_id	IN	chain.alert_entry_type.alert_entry_type_id%TYPE,
	out_scheduled_alert_id	OUT chain.scheduled_alert.scheduled_alert_id%TYPE,
	out_entries_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_params_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertSchedules (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAppAlertSettings (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertEntryTemplates (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertEntryTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/*******************************************************************
	To be called by scheduled alerts implementations
*******************************************************************/

--Sets an entry against the company/user, using the specified type and template
FUNCTION SetAlertEntry(
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_template_name		IN  alert_entry.template_name%TYPE,
	in_occurred_dtm			IN  alert_entry.occurred_dtm%TYPE,
	in_priority				IN	alert_entry.priority%TYPE DEFAULT 0,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_message_id			IN  chain.message.message_id%TYPE DEFAULT NULL
) RETURN alert_entry.alert_entry_id%TYPE;

--Sets a parameter against the specified entry
PROCEDURE SetAlertParam(
	in_alert_entry_id		IN	alert_entry.alert_entry_id%TYPE,
	in_name					IN	alert_entry_param.name%TYPE,
	in_value				IN	alert_entry_param.value%TYPE
);


/**********************************************************************
	Review alert
**********************************************************************/

PROCEDURE CreateReviewAlert (
	in_to_company_sid			IN	security_pkg.T_SID_ID,
	in_from_company_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetReviewAlerts (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MarkReviewAlertSent (
	in_review_alert_id			IN	review_alert.review_alert_id%TYPE
);


/**********************************************************************
	Product Company alert
**********************************************************************/

PROCEDURE CreateProductCompanyAlert (
	in_company_product_id		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetProductCompanyAlerts (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MarkProductCompanyAlertSent (
	in_alert_id					IN	product_company_alert.alert_id%TYPE
);

END scheduled_alert_pkg;
/

