-- Please update version.sql too -- this keeps clean builds in sync
define version=1383
@update_header

alter table csr.flow_transition_alert add constraint FK_FL_TR_ALRT_CUST_ALRT_TYPE
foreign key (app_sid, customer_alert_type_id) references csr.customer_alert_type (app_sid, customer_alert_type_id);

BEGIN
	UPDATE csr.std_alert_type
	   SET description = 'Inbound e-mail processing failure',
	   	   send_trigger = 'A form that was e-mailed in was not processed correctly.'
	 WHERE std_alert_type_id = 41;
  
	UPDATE csr.std_alert_type
	   SET description = 'Inbound e-mail processed successfully',
	   	   send_trigger = 'A form that was e-mailed in was processed correctly.' 
	 WHERE std_alert_type_id = 42;

	UPDATE csr.std_alert_type_param
	   SET description = 'Subject of received e-mail',
	       help_text = 'Inbound e-mail subject'
	 WHERE std_alert_type_id = 41 and display_pos = 7;

	UPDATE csr.std_alert_type_param
	   SET description = 'Subject of received e-mail',
	       help_text = 'Inbound e-mail subject'
	 WHERE std_alert_type_id = 42 and display_pos = 8;

	UPDATE csr.default_alert_template_body
	   SET subject = '<template><mergefield name="TABLE_DESCRIPTION"/> form you submitted by e-mail failed</template>',
	   	   body_html = '<template><p>Hello,</p>'||
				'<p>Thank you for your e-mail entitled "<mergefield name="SUBJECT_RCVD"/>"</p>'||
				'<p>We were unable to process this for the following reasons:</p>'||
				'<p><mergefield name="ERRORS"/></p>'||
				'</template>'
	 WHERE lang = 'en' and std_alert_type_id = 41;
	
	UPDATE csr.default_alert_template_body
	   SET subject = '<template><mergefield name="TABLE_DESCRIPTION"/> form you submitted by e-mail was processed successfully</template>',
	   	   body_html = '<template><p>Hello,</p>'||
				'<p>Thank you for your e-mail entitled "<mergefield name="SUBJECT_RCVD"/>"</p>'||
				'<p>It was processed successfully. Your reference is <mergefield name="REF"/>.</p>'||
				'</template>'
	 WHERE lang = 'en' and std_alert_type_id = 42;
END;
/

@update_tail
