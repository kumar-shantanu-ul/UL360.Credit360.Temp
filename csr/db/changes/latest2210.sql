-- Please update version.sql too -- this keeps clean builds in sync
define version=2210
@update_header

ALTER TABLE CSR.ROUTE_STEP_USER ADD (
	DECLINED_SENT_DTM	DATE
);

-- New alert types
DECLARE
	v_default_alert_frame_id	NUMBER;
	v_edited_alert_type_id		NUMBER := 63;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (std_alert_type_id, description, send_trigger, sent_from)
			VALUES(v_edited_alert_type_id, 'Corporate Reporter questions declined',
				'Sent when a user declines a question which they have been assigned.',
				'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			);

	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);

	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'BY_FULL_NAME', 'By full name', 'The full name of the user who declined the question', 4);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'BY_FRIENDLY_NAME', 'By friendly name', 'The friendly name of the user who declined the question', 5);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'BY_EMAIL', 'By e-mail', 'The e-mail address of the user who declined the question', 6);

	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
	
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'ROUTE_STEP_ID', 'Route Step Id', 'The Route Step that was declined', 8);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'SECTION_SID', 'Section Id', 'The Section containing the question that was declined', 9);
	
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'MODULE_TITLE', 'Framework Title', 'The Framework containing the question that was declined', 10);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 1, 'SECTION_TITLE', 'Section Title', 'The Section containing the question that was declined', 11);



	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.DEFAULT_ALERT_FRAME;
	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE
		(std_alert_type_id, default_alert_frame_id, send_type) 
	VALUES
		(v_edited_alert_type_id, v_default_alert_frame_id, 'manual');

	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE_BODY (STD_ALERT_TYPE_ID,LANG,SUBJECT,BODY_HTML,ITEM_HTML) VALUES (v_edited_alert_type_id,'en',
		'<template>Questions have been declined in CRedit360</template>',
		'<template>
		<p>Hello <mergefield name="TO_FULL_NAME"/>,</p>
		<p>The following questions have been declined by the assigned user and returned to the previous step. The user has been removed from the route.</p>
		<ul>
            		<mergefield name="ITEMS"/>
		</ul>
		<p>To view the changes, please go to this web page:</p>
		<p><mergefield name="MANAGE_QUESTIONS_LINK"/></p>
		<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template><li>Framework <mergefield name="MODULE_TITLE"/>, Section <mergefield name="SECTION_TITLE"/> - declined by <mergefield name="BY_FULL_NAME"/> (<mergefield name="BY_EMAIL"/>)</li></template>'
		);

	-- add new alert to all customers that use flow on sections
	
	FOR r IN (
		SELECT DISTINCT app_sid 
		  FROM csr.section_module
		 WHERE flow_sid IS NOT NULL
	)
	LOOP
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_edited_alert_type_id);

			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT r.app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
			  FROM csr.alert_frame af
			  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = r.app_sid
			   AND cat.std_alert_type_id IN (v_edited_alert_type_id)
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;
			
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT r.app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM csr.default_alert_template_body d
			  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id IN (v_edited_alert_type_id)
			   AND d.lang='en'
			   AND t.application_sid = r.app_sid
			   AND cat.app_sid = r.app_sid;

		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;

EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
	NULL;
END;

/

@../csr_data_pkg
@../section_pkg
@../section_body

@update_tail
