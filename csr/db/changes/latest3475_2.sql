-- Please update version.sql too -- this keeps clean builds in sync
define version=3475
define minor_version=2
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
	UPDATE csr.default_alert_frame_body
	   SET html = 
		'<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #CA0123;margin-bottom:20px;padding-bottom:10px;">'||
		'<img src="https://resource.credit360.com/csr/shared/branding/images/ul-solutions-logo-red.png" style="height:4em;" />'||
		'</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #CA0123;margin-top:20px;padding-top:10px;padding-bottom:10px;"></div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>'
	;

	UPDATE csr.default_alert_template_body
	   SET subject = '<template>New issue raised for your attention</template>'
	 WHERE std_alert_type_id = 17;
	
	UPDATE csr.default_alert_template_body
	   SET subject = '<template>Issue Summary<br /></template>'
	 WHERE std_alert_type_id = 18;
END;
/

DECLARE
	v_app_sid NUMBER;
BEGIN
	-- SupplierCarbon specific
	v_app_sid := 74343586;

	UPDATE csr.alert_template_body
	   SET subject = '<template>New issue raised for your attention</template>'
	 WHERE app_sid = v_app_sid
	   AND customer_alert_type_id = 80057;

	UPDATE csr.alert_template_body
	   SET subject = '<template>Issue Summary<br /></template>'
	 WHERE app_sid = v_app_sid
	   AND customer_alert_type_id = 80058;

	UPDATE csr.alert_frame_body
	   SET html = 
		'<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #CA0123;margin-bottom:20px;padding-bottom:10px;">'||
		'<img src="https://resource.credit360.com/csr/shared/branding/images/ul-solutions-logo-red.png" style="height:4em;" />'||
		'</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #CA0123;margin-top:20px;padding-top:10px;padding-bottom:10px;"></div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>'
	 WHERE app_sid = v_app_sid;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail