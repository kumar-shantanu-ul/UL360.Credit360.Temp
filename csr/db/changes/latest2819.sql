-- Please update version.sql too -- this keeps clean builds in sync
define version=2819
define minor_version=0
@update_header

declare
	v_ver number;
begin
	select db_version into v_ver from mail.version;
	if v_ver NOT IN (31,32) then
		raise_application_error(-20001, 'Mail schema is not version 31 or 32');
	end if;
end;
/

declare
	v_cnt number;
begin
	select count(*) into v_cnt from all_indexes where owner='MAIL' and index_name='IX_ACCOUNT_ACCOUNT_SID_EMAIL';
	if v_cnt = 0 then
		execute immediate 'create index mail.ix_account_account_sid_email on mail.account (account_sid, email_address)';
	end if;
	select count(*) into v_cnt from all_indexes where owner='MAIL' and index_name='IX_FULLTEXT_INDEX_MAILBOX_SID';
	if v_cnt = 0 then
		execute immediate 'create index mail.ix_fulltext_index_mailbox_sid on mail.fulltext_index (mailbox_sid)';
	end if;
end;
/	

update mail.version set db_version=32;

@update_tail
