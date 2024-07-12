-- Please update version.sql too -- this keeps clean builds in sync
define version=1367
@update_header

declare
	v_old	clob;
begin
	v_old := 
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
		'<p>'||
		'<p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>';

	update csr.default_alert_template_body
	   set body_html =
			'<template><p>Hello,</p>'||
			'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
			'<p/>'||
			'<p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
			'<p>To view the data and take further action, please go to this web page:</p>'||
			'<p><mergefield name="SHEET_URL"/></p>'||
			'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>'
	  where dbms_lob.compare(body_html, v_old) = 0;

	update csr.alert_template_body
	   set body_html =
			'<template><p>Hello,</p>'||
			'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
			'<p/>'||
			'<p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
			'<p>To view the data and take further action, please go to this web page:</p>'||
			'<p><mergefield name="SHEET_URL"/></p>'||
			'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>'
	  where dbms_lob.compare(body_html, v_old) = 0;
end;
/

@update_tail
