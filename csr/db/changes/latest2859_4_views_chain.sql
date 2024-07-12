CREATE OR REPLACE VIEW CHAIN.v$active_invite AS
	SELECT app_sid, invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace,
	       expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm, reinvitation_of_invitation_id,
	       accepted_reg_terms_vers, accepted_dtm, on_behalf_of_company_sid, lang, batch_job_id
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id = 1
;

CREATE OR REPLACE VIEW CHAIN.v$message_definition AS
	SELECT dmd.message_definition_id,  
	       NVL(md.message_template, dmd.message_template) message_template,
	       NVL(md.message_priority_id, dmd.message_priority_id) message_priority_id,
	       dmd.repeat_type_id,
	       dmd.addressing_type_id,
	       NVL(md.completion_type_id, dmd.completion_type_id) completion_type_id,
	       NVL(md.completed_template, dmd.completed_template) completed_template,
	       NVL(md.helper_pkg, dmd.helper_pkg) helper_pkg,
	       NVL(md.css_class, dmd.css_class) css_class
	  FROM default_message_definition dmd, (
	          SELECT app_sid, message_definition_id, message_template, message_priority_id, completed_template, helper_pkg, css_class, completion_type_id
	            FROM message_definition
	           WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	       ) md
	 WHERE dmd.message_definition_id = md.message_definition_id(+)
;

CREATE OR REPLACE VIEW CHAIN.v$message_param AS
	SELECT dmp.message_definition_id,  
		   dmp.param_name,
		   NVL(mp.value, dmp.value) value,
		   NVL(mp.href, dmp.href) href,
		   NVL(mp.css_class, dmp.css_class) css_class
	  FROM default_message_param dmp, (
	  		SELECT app_sid, message_definition_id, param_name, value, href, css_class
	  		  FROM message_param 
	  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   ) mp
	 WHERE dmp.message_definition_id = mp.message_definition_id(+)
	   AND dmp.param_name = mp.param_name(+)
;

CREATE OR REPLACE VIEW CHAIN.v$alert_entry_template AS
SELECT * FROM (
    SELECT co.app_sid, 
           aet.alert_entry_type_id,
           NVL(caet.template_name, aet.template_name) template_name,
           NVL(caet.template, aet.template) template
      FROM chain.alert_entry_template aet
      JOIN chain.customer_options co
        ON SYS_CONTEXT('SECURITY','APP') = co.app_sid OR SYS_CONTEXT('SECURITY','APP') IS NULL  
      LEFT JOIN chain.customer_alert_entry_template caet
        ON aet.alert_entry_type_id = caet.alert_entry_type_id
       AND aet.template_name = caet.template_name
       AND caet.app_sid = co.app_sid
    UNION
    SELECT app_sid, alert_entry_type_id, template_name, template
      FROM chain.customer_alert_entry_template
    );
	
