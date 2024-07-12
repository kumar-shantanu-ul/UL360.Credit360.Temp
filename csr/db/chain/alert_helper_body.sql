CREATE OR REPLACE PACKAGE BODY CHAIN.alert_helper_pkg
IS


PROCEDURE GetPartialTemplates (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	out_partial_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT capability_pkg.CheckPotentialCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE)
	   AND NOT capability_pkg.CheckPotentialCapability(chain_pkg.SEND_INVITE_ON_BEHALF_OF) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing partial templates');
    END IF;
	
	OPEN out_partial_cur FOR
		SELECT app_sid, alert_type_id, partial_template_type_id, lang, partial_html
		  FROM alert_partial_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_type_id = in_alert_type_id
		   AND lang = in_lang;
	
	OPEN out_params_cur FOR
		SELECT app_sid, alert_type_id, partial_template_type_id, field_name
		  FROM alert_partial_template_param
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_type_id = in_alert_type_id;
END;

PROCEDURE SavePartialTemplate (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	in_partial_template_type_id		IN	alert_partial_template.partial_template_type_id%TYPE,
	in_partial_html					IN	alert_partial_template.partial_html%TYPE,
	in_params						IN	T_STRING_LIST
)
AS
BEGIN

	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SavePartialTemplate can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO alert_partial_template
			(alert_type_id, lang, partial_template_type_id, partial_html)
		VALUES
			(in_alert_type_id, in_lang, in_partial_template_type_id, in_partial_html);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE alert_partial_template
			   SET partial_html=in_partial_html
			 WHERE app_sid=SYS_CONTEXT('SECURITY', 'APP')
			   AND alert_type_id=in_alert_type_id
			   AND lang=in_lang
			   AND partial_template_type_id=in_partial_template_type_id;
	END;
	
	
	-- Remove all and add again - safe to do at the moment as nothing references the params table
	-- Also runs for each language which isn't v efficient or clever but is simpler and I think
	-- it's justified when we only have one client that will be using this and we'll need to run
	-- a script to change their default partial templates
	DELETE FROM alert_partial_template_param
	 WHERE app_sid=SYS_CONTEXT('SECURITY', 'APP')
	   AND alert_type_id=in_alert_type_id
	   AND partial_template_type_id=in_partial_template_type_id;
	
	FOR i IN in_params.FIRST .. in_params.LAST
	LOOP
		INSERT INTO alert_partial_template_param (alert_type_id, partial_template_type_id, field_name)
		VALUES (in_alert_type_id, in_partial_template_type_id, in_params(i));
	END LOOP;
	
END;

-- The implementation for this was odd - in that header / footer alert types were set up - then never used and all edits have to be done by devs. 
-- Rather than doscarding these alert types (as they probably should have been) I'm going to write a "sync" function - so at least Imp can update them then dev can sync them
-- I have to write this anyway as Imp have updated the header / footer alert type - so I''m going to use what they''ve done
PROCEDURE SyncPartialTemplateHtml (
	in_from_std_alert_type_id		IN	alert_partial_template.alert_type_id%TYPE,
	in_to_std_alert_type_id			IN	alert_partial_template.alert_type_id%TYPE,
	in_partial_template_type_id		IN	alert_partial_template.partial_template_type_id%TYPE
)
AS
	v_params						T_STRING_LIST := T_STRING_LIST();
	
	v_customer_from_alert_type_id	csr.alert_template_body.customer_alert_type_id%TYPE;
	v_lang	 						csr.alert_template_body.lang%TYPE;
	v_subject						csr.alert_template_body.subject%TYPE;
	v_body_html						csr.alert_template_body.body_html%TYPE; 
	v_item_html						csr.alert_template_body.item_html%TYPE; 
		
	c_cur							SYS_REFCURSOR;
	c_frames_cur					SYS_REFCURSOR;
	c_bodies_cur					SYS_REFCURSOR;
	c_params_cur					SYS_REFCURSOR;
	
	i								NUMBER := 0;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SyncPartialTemplate can only be run as BuiltIn/Administrator');
	END IF;

	csr.alert_pkg.GetTemplateForStdAlertType(in_from_std_alert_type_id, c_cur, c_frames_cur, c_bodies_cur, c_params_cur);
	
	-- just use whatever params are set up already
	FOR r IN (
		SELECT field_name 
		  FROM alert_partial_template_param
		 WHERE alert_type_id = in_to_std_alert_type_id
		   AND partial_template_type_id = in_partial_template_type_id
		   AND app_sid = security_pkg.getApp
	) 
	LOOP
		v_params.extend(1);
		v_params(v_params.COUNT) := r.field_name;	
	END LOOP;
	
	-- set body for each lang
	LOOP 
		FETCH c_bodies_cur INTO v_customer_from_alert_type_id, v_lang, v_subject, v_body_html, v_item_html;					
		EXIT WHEN c_bodies_cur%NOTFOUND;
		SavePartialTemplate(in_to_std_alert_type_id, v_lang, in_partial_template_type_id, v_body_html, v_params);
	END LOOP;
	CLOSE c_bodies_cur;
		   
END;

END alert_helper_pkg;
/
