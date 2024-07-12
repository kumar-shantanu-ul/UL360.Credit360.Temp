-- Please update version.sql too -- this keeps clean builds in sync
define version=912
@update_header

alter table csr.csr_user add (created_dtm date default sysdate);


update csr.csr_user set created_dtm = null;

-- series of best guesses
declare
	v_cnt number(10) := 0;
begin
	for r in (
		select object_sid, audit_date from csr.audit_Log where description = 'User created' and audit_type_Id = 5
	)
	loop
		update csr.csr_user set created_dtm = r.audit_date where csr_user_sid = r.object_sid;
		v_cnt := v_cnt + sql%rowcount;
	end loop;
	dbms_output.put_line(v_cnt);
end;
/

declare
	v_cnt number(10) := 0;
begin
	for r in (
		select object_sid, min(audit_date)dtm from csr.audit_Log group by object_sid
	)
	loop
		update csr.csr_user set created_dtm = r.dtm where csr_user_sid = r.object_sid and created_dtm is null;
		v_cnt := v_cnt + sql%rowcount;
	end loop;
	dbms_output.put_line(v_cnt);
end;
/


update csr.csr_user set created_dtm = sysdate where created_dtm is null;

alter table csr.csr_user modify created_Dtm not null;

CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.region_mount_point_sid, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

@..\diary_body
@..\csr_user_body

@update_tail
