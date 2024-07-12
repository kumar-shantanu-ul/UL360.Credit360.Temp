-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=6
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
UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE'||unistr('\2122')||' Platform by UL EHS Sustainability</div>'||
		'<mergefield name="BODY" /><br />' ||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#007987;text-decoration:none;">our support team</a>.</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
