-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
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
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#007987;text-decoration:none;">our support team</a>.</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';

	UPDATE csr.alert_frame_body
	   SET html = REPLACE(html, 'PURE™', 'PURE'||unistr('\2122'))
	 WHERE html LIKE '%PURE™%';

END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
