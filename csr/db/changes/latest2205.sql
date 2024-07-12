-- Please update version.sql too -- this keeps clean builds in sync
define version=2205
@update_header

CREATE TABLE CSR.DELEGATION_EDITED_ALERT (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	delegation_edit_alert_id			NUMBER(10) NOT NULL,
	notify_user_sid						NUMBER(10) NOT NULL,
	raised_by_user_sid					NUMBER(10) NOT NULL,
	sheet_id							NUMBER(10) NOT NULL,
	CONSTRAINT pk_delegation_edit_alert PRIMARY KEY (app_sid, delegation_edit_alert_id)
	USING INDEX,
	CONSTRAINT fk_deleg_edit_alrt_notify_user FOREIGN KEY (app_sid, notify_user_sid)
	REFERENCES CSR.CSR_USER(app_sid, csr_user_sid),
	CONSTRAINT fk_deleg_edit_alrt_raised_user FOREIGN KEY (app_sid, raised_by_user_sid)
	REFERENCES CSR.CSR_USER(app_sid, csr_user_sid),
	CONSTRAINT fk_deleg_edit_alrt_sheet 	  FOREIGN KEY (app_sid, sheet_id)
	REFERENCES CSR.SHEET(app_sid, sheet_id)
);

CREATE INDEX    CSR.IX_DELEG_EDIT_ALRT_NOTIFY_USER ON CSR.DELEGATION_EDITED_ALERT(app_sid, notify_user_sid);
CREATE INDEX    CSR.IX_DELEG_EDIT_ALRT_RAISED_USER ON CSR.DELEGATION_EDITED_ALERT(app_sid, raised_by_user_sid);
CREATE INDEX    CSR.IX_DELEG_EDIT_ALERT_SHEET      ON CSR.DELEGATION_EDITED_ALERT(app_sid, sheet_id);
CREATE SEQUENCE CSR.DELEG_EDIT_ALERT_ID_SEQ;

-- New alert types
DECLARE
	v_default_alert_frame_id	NUMBER;
	v_edited_alert_type_id		NUMBER := 62;
BEGIN

	/* RLS */
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'DELEGATION_EDITED_ALERT',
		policy_name     => 'DELEG_EDITED_ALERT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );

	INSERT INTO CSR.STD_ALERT_TYPE (std_alert_type_id, description, send_trigger, sent_from) 
			VALUES(v_edited_alert_type_id, 'Delegation edited', 
				'Sent when an approver approves a sheet which they have edited first.',
				'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			);

	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'FROM_NAME', 'From name', 'The full name of the user raising the alert', 1);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'FROM_EMAIL', 'From email', 'The email of the user raising the alert', 2);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delgation involved', 3);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'SHEET_LINK', 'Sheet URL', 'Link to the sheet', 4);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 5);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 6);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 7);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_edited_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 8);
	
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.DEFAULT_ALERT_FRAME;
	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE
		(std_alert_type_id, default_alert_frame_id, send_type) 
	VALUES 
		(v_edited_alert_type_id, v_default_alert_frame_id, 'manual');		

	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE_BODY (STD_ALERT_TYPE_ID,LANG,SUBJECT,BODY_HTML,ITEM_HTML) VALUES (v_edited_alert_type_id,'en',
		'<template>A delegation you are involved with has been edited in CRedit360</template>',
		'<template>
		<p>Hello,</p>
		<p>You are receiving this email because a delegation you are involved in has been edited before approval.</p>
		<p><mergefield name="FROM_NAME" /> (<mergefield name="FROM_EMAIL" />) has edited the delegation <mergefield name="DELEGATION_NAME" />.</p>
		<p>To view the changes, please go to this web page:</p>
		<p><mergefield name="SHEET_URL" /></p>
		<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template/>'
		);
END;	

/

@../csr_data_pkg
@../sheet_pkg
@../sheet_body

@update_tail
