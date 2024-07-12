set serveroutput on;
begin
	dbms_output.put_line('CSRIMP Sessions');
	dbms_output.put_line('===============');
	for r in (select * from csrimp.csrimp_session) loop
		dbms_output.put_line('Session Id: ' || r.csrimp_session_id || chr(9) || '  Host: ' || r.host);
	end loop;
	dbms_output.put_line('===============');
END;
/

PROMPT Enter the session id, or 0 for all sessions

declare
	v_session						number;
begin
	v_session := &&1;

	if  v_session = 0 then
		dbms_output.put_line('Cleaning all csrimp sessions...');
		for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION' and temporary='N') loop
			dbms_output.put_line('tab '||r.table_name);
			begin
			execute immediate 'truncate table csrimp.'||r.table_name;
			exception
				when others then
				execute immediate 'delete from csrimp.' || r.table_name;
			end;
		end loop;
		dbms_output.put_line('Cleaning sessions');
		delete from csrimp.csrimp_session;
	ELSE 
		dbms_output.put_line('Cleaning csrimp session ' || v_session || '...');
		for r in (select table_name 
					from all_tables 
				   where owner = 'CSRIMP' 
				     and table_name != 'CSRIMP_SESSION'
					 and temporary = 'N')  loop
			dbms_output.put_line(r.table_name);
			execute immediate 'delete from csrimp.' || r.table_name || ' where csrimp_session_id=' || v_session;
		end loop;
		dbms_output.put_line('Cleaning session');
		delete from csrimp.csrimp_session where csrimp_session_id = v_session;

		/*
		
		There may be other leftover things, depending on how far it got during the last attempt.
		
		-- Mail boxes
		ALTER TABLE MAIL.MAILBOX DISABLE CONSTRAINT FK_MAILBOX_MAILBOX_PARENT;
		delete from MAIL.ACCOUNT where email_address IN ('<site>@credit360.com', '<site>_tracker@credit360.com');
		delete from mail.account_alias where email_address IN ('<site>@credit360.com', '<site>_tracker@credit360.com');
		delete from MAIL.MAILBOX where PARENT_SID IN (select mailbox_sid from mail.mailbox where mailbox_name IN ('<site>@credit360.com', '<site>_tracker@credit360.com'));
		delete from MAIL.MAILBOX where mailbox_name IN ('<site>@credit360.com', '<site>_tracker@credit360.com');
		ALTER TABLE MAIL.MAILBOX ENABLE CONSTRAINT FK_MAILBOX_MAILBOX_PARENT;

		DELETE from SO's Mail/Accounts and Mail/Folders for ('<site>@credit360.com', '<site>_tracker@credit360.com')
		(also easy to do with secmgr).

		-- Client schema
		DROP USER name CASCADE;
		(also easy to do with sqldev)
		
		*/

	end if;
	commit;
end;
/
