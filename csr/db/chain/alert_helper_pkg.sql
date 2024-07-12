CREATE OR REPLACE PACKAGE CHAIN.alert_helper_pkg
IS

HEADER_TEMPLATE						CONSTANT NUMBER := 1;
FOOTER_TEMPLATE						CONSTANT NUMBER := 2;


PROCEDURE GetPartialTemplates (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	out_partial_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
);

PROCEDURE SavePartialTemplate (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	in_partial_template_type_id			IN	alert_partial_template.partial_template_type_id%TYPE,
	in_partial_html					IN	alert_partial_template.partial_html%TYPE,
	in_params						IN	T_STRING_LIST
);

PROCEDURE SyncPartialTemplateHtml (
	in_from_std_alert_type_id		IN	alert_partial_template.alert_type_id%TYPE,
	in_to_std_alert_type_id			IN	alert_partial_template.alert_type_id%TYPE,
	in_partial_template_type_id		IN	alert_partial_template.partial_template_type_id%TYPE
);

END alert_helper_pkg;
/