-- Please update version.sql too -- this keeps clean builds in sync
define version=541
@update_header

declare
v_count number;
begin

select count(*) into v_count from csr.default_alert_frame;

if v_count = 0 then
	INSERT INTO csr.default_alert_frame (default_alert_frame_id, name) VALUES (default_alert_frame_id_seq.nextval, 'Default');
end if;

select count(*) into v_count from csr.default_alert_frame_body;

if v_count = 0 then
	INSERT INTO csr.default_alert_frame_body (default_alert_frame_id, lang, html) VALUES (default_alert_frame_id_seq.currval, 'en-gb',
		'<template>'||
		'<table width="700">'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #C4D9E9;margin-bottom:20px;padding-bottom:10px;">CRedit360 Sustainability data management application</div>'||
		'<table border="0">'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;"><mergefield name="BODY" /></td>'||
		'</tr>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #C4D9E9;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#C4D9E9;text-decoration:none;">our support team</a></div>'||
		'</td>'||
		'</tr>'||
		'</table>'||
		'</template>');
end if;

select count(*) into v_count from csr.default_alert_template;

if v_count = 0 then
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (1, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (2, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (3, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (4, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (5, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (20, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (21, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (22, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (23, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (24, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (25, default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (26, default_alert_frame_id_seq.currval, 'manual');
end if;

end;
/

@update_tail
