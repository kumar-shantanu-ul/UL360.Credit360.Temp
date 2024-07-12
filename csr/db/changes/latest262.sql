-- Please update version.sql too -- this keeps clean builds in sync
define version=262
@update_header

DECLARE
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(
	21, 
	'Self register validate e-mail addreess', 
	'<params>' ||
		'<param name="FROM_NAME"/>' ||
		'<param name="FROM_EMAIL"/>' ||
		'<param name="TO_NAME"/>' ||
		'<param name="TO_EMAIL"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="GUID"/>' ||
		'<param name="URL"/>' ||
	'</params>');
	--
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(
	22, 
	'Self register notify administrator', 
	'<params>' ||
		'<param name="FROM_NAME"/>' ||
		'<param name="FROM_EMAIL"/>' ||
		'<param name="TO_FULL_NAME"/>' ||
		'<param name="TO_EMAIL"/>' ||
		'<param name="USER_NAME"/>' ||
		'<param name="USER_FULL_NAME"/>' ||
		'<param name="USER_EMAIL"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="URL"/>' ||
	'</params>');
	--
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(
	23, 
	'Self register account approval', 
	'<params>' ||
		'<param name="FROM_NAME"/>' ||
		'<param name="FROM_EMAIL"/>' ||
		'<param name="TO_NAME"/>' ||
		'<param name="TO_EMAIL"/>' ||
	'</params>');
	--
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(
	24, 
	'Self register account rejection', 
	'<params>' ||
		'<param name="FROM_NAME"/>' ||
		'<param name="FROM_EMAIL"/>' ||
		'<param name="TO_NAME"/>' ||
		'<param name="TO_EMAIL"/>' ||
	'</params>');
	--
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(
	25, 
	'Password reset', 
	'<params>' ||
		'<param name="FROM_NAME"/>' ||
		'<param name="FROM_EMAIL"/>' ||
		'<param name="TO_NAME"/>' ||
		'<param name="TO_EMAIL"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="GUID"/>' ||
		'<param name="URL"/>' ||
	'</params>');
	--
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(
	26, 
	'Account disabled (password reset)', 
	'<params>' ||
		'<param name="FROM_NAME"/>' ||
		'<param name="FROM_EMAIL"/>' ||
		'<param name="USER_NAME"/>' ||
		'<param name="FULL_NAME"/>' ||
		'<param name="EMAIL"/>' ||
	'</params>');
	--
	-- All customers require the new alerts
	INSERT INTO csr.customer_alert_type (alert_type_id, app_Sid) SELECT 21, app_sid FROM csr.customer;
	INSERT INTO csr.customer_alert_type (alert_type_id, app_Sid) SELECT 22, app_sid FROM csr.customer;
	INSERT INTO csr.customer_alert_type (alert_type_id, app_Sid) SELECT 23, app_sid FROM csr.customer;
	INSERT INTO csr.customer_alert_type (alert_type_id, app_Sid) SELECT 24, app_sid FROM csr.customer;
	INSERT INTO csr.customer_alert_type (alert_type_id, app_Sid) SELECT 25, app_sid FROM csr.customer;
	INSERT INTO csr.customer_alert_type (alert_type_id, app_Sid) SELECT 26, app_sid FROM csr.customer;
	--
		-- Insert the defasult mail text
		INSERT INTO csr.alert_template (mail_from_name, mail_subject, once_only, active, mime_type, alert_type_id, app_sid, mail_body)
		  (SELECT
		  	'#FROM_NAME#', 
		  	'Activate your account', 
		  	0, 1, 'text/plain', 21, app_sid, 
			'<div>' || CHR(13) || CHR(10) ||
				'To validate your e-mail address and activate your account please click on the link below or copy and paste it into your web browser.' || CHR(13) || CHR(10) ||
				'<br/>' || CHR(13) || CHR(10) ||
				'<a href="#URL#">#URL#</a>' || CHR(13) || CHR(10) ||
			'</div>'
		   FROM CUSTOMER);
		--
		INSERT INTO csr.alert_template (mail_from_name, mail_subject, once_only, active, mime_type, alert_type_id, app_sid, mail_body)
		  (SELECT
		  	'#FROM_NAME#', 
		  	'New user account requested', 
		  	0, 1, 'text/plain', 22, app_sid, 
			'<div>' || CHR(13) || CHR(10) ||
				'The following user has requested an account:<br/>' || CHR(13) || CHR(10) ||
				'Username: #USER_NAME#<br/>' || CHR(13) || CHR(10) ||
				'Full Name: #USER_FULL_NAME#<br/>' || CHR(13) || CHR(10) ||
				'E-mail address: #USER_EMAIL#<br/>' || CHR(13) || CHR(10) ||
				'<br/>' || CHR(13) || CHR(10) ||
				'You can view and approve uers account requests using the following link:<br/>' || CHR(13) || CHR(10) ||
				'<br/>' || CHR(13) || CHR(10) ||
				'<a href="#URL#">#URL#</a>' || CHR(13) || CHR(10) ||
			'</div>'
		   FROM CUSTOMER);
		--
		INSERT INTO csr.alert_template (mail_from_name, mail_subject, once_only, active, mime_type, alert_type_id, app_sid, mail_body)
		  (SELECT
		  	'#FROM_NAME#', 
		  	'Your account has been approved', 
		  	0, 1, 'text/plain', 23, app_sid, 
			'<div>' || CHR(13) || CHR(10) ||
				'Your account has been approved, you login using the following link:' || CHR(13) || CHR(10) ||
				'<br/>' || CHR(13) || CHR(10) ||
				'<a href="#URL#">#URL#</a>' || CHR(13) || CHR(10) ||
			'</div>'
		   FROM CUSTOMER);
		--
		INSERT INTO csr.alert_template (mail_from_name, mail_subject, once_only, active, mime_type, alert_type_id, app_sid, mail_body)
		  (SELECT
		  	'#FROM_NAME#', 
		  	'Account request rejected', 
		  	0, 1, 'text/plain', 24, app_sid, 
			'<div>' || CHR(13) || CHR(10) ||
				'Your request for an account has been rejected.' || CHR(13) || CHR(10) ||
			'</div>'
		   FROM CUSTOMER);
		--
	-- Insert the default text for the password reminder alert
	INSERT INTO csr.alert_template (mail_from_name, mail_subject, once_only, active, mime_type, alert_type_id, app_sid, mail_body) 
		SELECT '#FROM_NAME#', 'Reset Password.', 0, 1, 'text/plain', 25, app_sid,
			'<div>' || CHR(13) || CHR(10) ||
				'To reset your password click on the link or copy and paste it into your web browser.' || CHR(13) || CHR(10) ||
				'<br/><br/>' || CHR(13) || CHR(10) ||
				'<a href="#URL#">#URL#</a>' || CHR(13) || CHR(10) ||
				'<br/><br/>' || CHR(13) || CHR(10) ||
				'You have 60 minutes before this link expires.' || CHR(13) || CHR(10) ||
			'</div>'
		  FROM csr.customer
		;
	--
	INSERT INTO csr.alert_template (mail_from_name, mail_subject, once_only, active, mime_type, alert_type_id, app_sid, mail_body) 
		SELECT '#FROM_NAME#', 'Reset Password.', 0, 1, 'text/plain', 26, app_sid,
			'<div>' || CHR(13) || CHR(10) ||
				'You cannot reset your password as your user account has been disabled, perhaps because you have not logged in for some time.' || CHR(13) || CHR(10) ||
				'<br/><br/>' || CHR(13) || CHR(10) ||
				'Please contact support@credit360.com or your local CRedit360 administrator for help.' || CHR(13) || CHR(10) ||
			'</div>'
		  FROM csr.customer
		;
END;
/

COMMIT;

@update_tail
