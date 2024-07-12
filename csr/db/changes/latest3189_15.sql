-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.customer
	   SET alert_mail_address = 'no-reply@cr360.com'
	 WHERE (LOWER(alert_mail_address) = 'support@credit360.com' OR LOWER(alert_mail_address) = 'support@cr360.com');

	UPDATE csr.std_alert_type
	   SET sent_from = REPLACE(sent_from, 'support@credit360.com', 'no-reply@cr360.com')
	 WHERE sent_from LIKE '%support@credit360.com%';
	 
	UPDATE chain.customer_options
	   SET support_email = 'no-reply@cr360.com'
	 WHERE (LOWER(support_email) = 'support@credit360.com' OR LOWER(support_email) = 'support@cr360.com');

	UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE'||unistr('\2122')||' Platform by UL EHS Sustainability</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY'||CHR(38)||'amp;text=Message+body'||CHR(38)||'amp;lang=en"></img>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">'||
		'</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../enable_body
@../saml_body
@../chain/setup_body

@update_tail
