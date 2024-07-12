-- Please update version.sql too -- this keeps clean builds in sync
define version=212
@update_header

CREATE GLOBAL TEMPORARY TABLE temp_doc_id
(
	doc_id				NUMBER(10,0)
) ON COMMIT DELETE ROWS;

declare
	v_cnt number(10);
begin
	select count(*) into v_cnt 
	  from csr_user 
	 where csr_user_sid = security_pkg.sid_builtin_administrator;
	if v_cnt = 0 then
		INSERT INTO CSR_USER 
			(app_sid, csr_user_sid, user_name, full_NAME, friendly_name, email, region_mount_point_sid, indicator_mount_point_sid, guid)
		VALUES 
			(0, security_pkg.SID_BUILTIN_ADMINISTRATOR, 'builtinadministrator', 'Builtin Administrator', 
			 'Builtin Administrator', 'support@credit360.com', null, null,  'A3B4FB4B-BC13-53A3-8714-95640E79CA8A'); -- hard-coded GUID so csrexp will move it nicely
	end if;
	
	select count(*) into v_cnt 
	  from csr_user 
	 where csr_user_sid = security_pkg.sid_builtin_guest;
	if v_cnt = 0 then
		INSERT INTO CSR_USER 
			(app_sid, csr_user_sid, user_name, full_NAME, friendly_name, email, region_mount_point_sid, indicator_mount_point_sid, guid)
		VALUES 
			(0, security_pkg.SID_BUILTIN_GUEST, 'guest', 'Guest', 
			 'Guest', 'support@credit360.com', null, null,  '77646D7A-A70E-E923-2FF6-2FD960873984'); -- hard-coded GUID so csrexp will move it nicely
	end if;
end;
/

@..\doc_pkg
@..\doc_folder_pkg
@..\doc_body
@..\doc_folder_body

@update_tail

