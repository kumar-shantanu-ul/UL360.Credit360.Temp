-- Please update version.sql too -- this keeps clean builds in sync
define version=2552
@update_header

BEGIN
	UPDATE
	CSR.ALERT_TEMPLATE_BODY
	SET SUBJECT = '<template>Empty subject</template>'
	WHERE dbms_lob.substr(SUBJECT, 30, 1) = '<template></template>';

	UPDATE
	CSR.ALERT_TEMPLATE_BODY
	SET body_html = '<template>Empty body</template>'
	WHERE dbms_lob.substr(body_html, 30, 1) = '<template></template>';
END;
/

set serveroutput on
declare
	v_x xmltype;
begin
	for r in (select * from csr.alert_template_body where app_sid=10771034 and customer_alert_type_id=1909 and lang='en') loop
		begin
			v_x := xmltype(r.subject);
		exception
			when others then
				dbms_output.put_line('subject for app='||r.app_sid||',cat_id='||r.customer_alert_type_id||',lang='||r.lang||': '||sqlerrm||', html='||r.subject);
		end;
		begin
			v_x := xmltype(r.body_html);
		exception
			when others then
				dbms_output.put_line('body_html for app='||r.app_sid||',cat_id='||r.customer_alert_type_id||',lang='||r.lang||': '||sqlerrm||', html='||r.body_html);
		end;
	end loop;
end;
/


ALTER TABLE CSR.ALERT_TEMPLATE_BODY ADD CONSTRAINT CHK_SUBJECT_NOT_EMPTY CHECK (EXTRACT(XMLTYPE(SUBJECT),'/template/text()') IS NOT NULL OR EXTRACT(XMLTYPE(SUBJECT),'/template/*') IS NOT NULL);
ALTER TABLE CSR.ALERT_TEMPLATE_BODY ADD CONSTRAINT CHK_BODY_NOT_EMPTY CHECK (EXTRACT(XMLTYPE(BODY_HTML),'/template/text()') IS NOT NULL OR EXTRACT(XMLTYPE(BODY_HTML),'/template/*') IS NOT NULL);

@update_tail
