whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

prompt *****************************************************************
prompt * Ensure you look at this script carefully before running it,   *
prompt * check the output and commit the first block result only after *
prompt * inspecting the output                                         *
prompt *****************************************************************
exit
set serveroutput on

-- more renaming mailbox horror
declare
	v_root_mailbox_sid 		number;
	v_account_sid			number;
	v_mailbox_name			varchar2(255);
begin
	dbms_output.enable(null);
	security.user_pkg.LogonAdmin;
	for r in (select * from mail.account where email_address not in (
		'ferne@credit360.com', 'ferne.shaw@credit360.com')) loop
		begin
			select mailbox_name
			  into v_mailbox_name
			  from mail.mailbox
			 where mailbox_sid = r.root_mailbox_sid;
			if v_mailbox_name != r.email_address then
				security.security_pkg.debugmsg(r.email_address || ' has an incorrectly named root folder ' || v_mailbox_name);
				dbms_output.put_line(r.email_address || ' has an incorrectly named root folder ' || v_mailbox_name);
				update mail.mailbox
				   set mailbox_name = r.email_address
				 where mailbox_sid = r.root_mailbox_sid;
			end if;
		exception
			when no_data_found then
				security.security_pkg.debugmsg(r.email_address || ' has no root mailbox folder');
				dbms_output.put_line(r.email_address || ' has no root mailbox folder');
		end;
	end loop;
	for r in (select m.mailbox_sid, m.mailbox_name, so.name from mail.mailbox m, security.securable_object so where m.mailbox_sid = so.sid_id and m.mailbox_name != nvl(so.name,'!3$!"L£P$!"P')) loop
		security.security_pkg.debugmsg('the mailbox ' ||r.mailbox_sid||' named '||r.mailbox_name||' has mismatched so name '||r.name);
		dbms_output.put_line('the mailbox ' ||r.mailbox_sid||' named '||r.mailbox_name||' has mismatched so name '||r.name);
		update security.securable_object
		   set name = r.mailbox_name
		 where sid_id = r.mailbox_sid;
	end loop;
	for r in (select a.account_sid, a.email_address, so.name from mail.account a, security.securable_object so where a.account_sid = so.sid_id and a.email_address != nvl(so.name,'!3$!"L£P$!"P')) loop
		security.security_pkg.debugmsg('the account ' ||r.account_sid||' named '||r.email_address||' has mismatched so name '||r.name);
		dbms_output.put_line('the account ' ||r.account_sid||' named '||r.email_address||' has mismatched so name '||r.name);
		update security.securable_object
		   set name = r.email_address
		 where sid_id = r.account_sid;
	end loop;
	-- delete accounts / mailboxes with no SOs
	for r in (select account_sid, email_address from mail.account where account_sid not in (select sid_id from security.securable_object)) loop
		security.security_pkg.debugmsg('the account ' ||r.account_sid||' named '||r.email_address||' has no backing sos, deleting');
		dbms_output.put_line('the account ' ||r.account_sid||' named '||r.email_address||' has no backing sos, deleting');
		--mail.mail_pkg.deleteAccount(r.account_sid);
	end loop;
	for r in (select mailbox_sid, mailbox_name from mail.mailbox where mailbox_sid not in (select sid_id from security.securable_object)) loop
		security.security_pkg.debugmsg('the mailbox ' ||r.mailbox_sid||' named '||r.mailbox_name||' has no backing sos, deleting');
		dbms_output.put_line('the mailbox ' ||r.mailbox_sid||' named '||r.mailbox_name||' has no backing sos, deleting');
		DELETE FROM mail.message_address_field
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
		 						 	  
		DELETE FROM mail.message_address_field
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
	
		DELETE FROM mail.message_header
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
		DELETE FROM mail.message
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
	
		DELETE FROM mail.fulltext_index
		 WHERE mailbox_sid = r.mailbox_sid;
	end loop;
	-- and now the other way around -- delete mailboxes / accounts with SOs but no matching mail objects
	for r in (
		select t.sid_id, max(t.lvl)
		  from (select sid_id,level lvl
	  	  		  from security.securable_object so start with parent_sid_id is null connect by prior sid_id = parent_sid_id) t,
	  	  	   ( (select sid_id from security.securable_object start with parent_sid_id = securableobject_pkg.getsidfrompath(null,0,'/Mail/Accounts') connect by prior sid_id = parent_sid_id
				   minus
				  select account_sid from mail.account)
				 union all 
				 (select sid_id from security.securable_object start with parent_sid_id = securableobject_pkg.getsidfrompath(null,0,'/Mail/Folders') connect by prior sid_id = parent_sid_id
				   minus
				  select mailbox_sid from mail.mailbox)) d
		 where 1 = 0 and t.sid_id = d.sid_id
		group by t.sid_id
		order by max(t.lvl) desc
	) loop
		security.security_pkg.debugmsg('the object with sid '||r.sid_id||' and path '||securableobject_pkg.getpathfromsid(null,r.sid_id)||' has no matching mailbox/account SO, deleting');
		dbms_output.put_line('the object with sid '||r.sid_id||' and path '||securableobject_pkg.getpathfromsid(null,r.sid_id)||' has no matching mailbox/account SO, deleting');
		DELETE FROM security.acl
		 WHERE acl_id = security.Acl_Pkg.GetDACLIDForSID(r.sid_id)
 		    OR sid_id = r.sid_id;
	
	    -- this securable object may be a user, or a group.  If so delete the necessary records
	    DELETE FROM security.user_table
	     WHERE sid_id = r.sid_id;
	     
	    DELETE FROM security.user_password_history
	     WHERE sid_id = r.sid_id;
	
	    DELETE FROM security.user_certificates
	     WHERE sid_id = r.sid_id;
	     	
	    DELETE FROM security.securable_object
	     WHERE sid_id = r.sid_id;
		
	end loop;
end;
/

set serveroutput on

declare
	v_root_mailbox_sid 		number;
	v_tracker_mailbox_sid	number;
	v_sent_mailbox_sid		number;
	v_users_mailbox_sid		number;
	v_user_mailbox_sid		number;
	v_outbox_mailbox_sid	number;
	v_admins_sid			number;
	v_reg_users_sid			number;
	v_acl_count				number;
	v_email					csr.customer.system_mail_address%TYPE;
	v_tracker_email			csr.customer.tracker_mail_address%TYPE;
	v_account_sid			NUMBER(10);
	v_user_so_exists		number;
begin
	dbms_output.enable(null);
	security.user_pkg.LogonAdmin;
	for r in (select system_mail_address, tracker_mail_address, host, app_sid
				from csr.customer ) loop
		security.security_pkg.SetApp(r.app_sid);

		dbms_output.put_line('fixing mailbox permissions for '||r.host);
		security.security_pkg.debugmsg('fixing mailbox permissions for '||r.host);
		v_reg_users_sid := security.securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
		
		begin
			v_admins_sid := security.securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Administrators');
		exception
			when security.security_pkg.object_not_found then
				v_admins_sid := null;
		end;
					
		-- create system mail account and add an Outbox (foo.credit360.com -> foo@credit360.com)
		-- .credit360.com = 14 chars
		IF LOWER(SUBSTR(r.host, LENGTH(r.host)-13,14)) = '.credit360.com' THEN
			-- a standard foo.credit360.com
			v_email := SUBSTR(r.host, 1, LENGTH(r.host)-14)||'@credit360.com';
			v_tracker_email := SUBSTR(r.host, 1, LENGTH(r.host)-14)||'_tracker@credit360.com';
		ELSE
			-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
			v_email := r.host||'@credit360.com';
			v_tracker_email := r.host||'_tracker@credit360.com';
		END IF;
		
		-- if the address is wrong, then just create a new one
		-- this stuff all comes from renaming sites or importing not doing the right thing (it's a mix of renames + imports to test sites)
		begin
			dbms_output.put_line('createAccount for '||r.host||': '||v_email);
			security.security_pkg.debugmsg('createAccount for '||r.host||': '||v_email);
			mail.mail_pkg.createAccount(v_email, NULL, 'System mail account for '||r.host, v_account_sid, v_root_mailbox_sid);
		exception
			when security.security_pkg.DUPLICATE_OBJECT_NAME then
				v_root_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(null, v_email);
		end;
		IF v_email != r.system_mail_address THEN
			dbms_output.put_line('created '||v_email||' (was '||r.system_mail_address||')');
			security.security_pkg.debugmsg('created '||v_email||' (was '||r.system_mail_address||')');
		end if;

		-- if they exist, give administrators full control over the mailboxes
		if v_admins_sid is not null	then
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = security.acl_pkg.GetDACLIDForSID(v_root_mailbox_sid)
			   and ace_type = security.security_pkg.ACE_TYPE_ALLOW and sid_id = v_admins_sid and permission_set = security.security_pkg.PERMISSION_STANDARD_ALL;
			if v_acl_count = 0 then
				security.acl_pkg.AddACE(
					SYS_CONTEXT('SECURITY', 'ACT'), 
					security.acl_pkg.GetDACLIDForSID(v_root_mailbox_sid), 
					security.security_pkg.ACL_INDEX_LAST, 
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);
				security.acl_pkg.PropogateAces(SYS_CONTEXT('SECURITY', 'ACT'), v_root_mailbox_sid);
			end if;
		end if;

		begin	
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Sent', v_sent_mailbox_sid);
		exception
			when security.security_pkg.DUPLICATE_OBJECT_NAME then
				v_sent_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Sent');		
		end;
		select count(*)
		  into v_acl_count
		  from security.acl 
		 where acl_id = security.acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid)
		   and ace_type = security.security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security.security_pkg.PERMISSION_ADD_CONTENTS;
		if v_acl_count = 0 then
			security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_ADD_CONTENTS);
		end if;
		
		begin
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Outbox', v_outbox_mailbox_sid);
		exception
			when security.security_pkg.DUPLICATE_OBJECT_NAME then
				v_outbox_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Outbox');
		end;
		
		select count(*)
		  into v_acl_count
		  from security.acl 
		 where acl_id = security.acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid)
		   and ace_type = security.security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security.security_pkg.PERMISSION_ADD_CONTENTS;
		if v_acl_count = 0 then
			security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_ADD_CONTENTS);
		end if;
		
		begin
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Users', v_users_mailbox_sid);
		exception
			when security.security_pkg.DUPLICATE_OBJECT_NAME then
				v_users_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Users');
		end;

		for u in (select csr_user_sid, user_name
					from csr.csr_user) loop
			--dbms_output.put_line('adding mailbox for '||u.user_name||' ('||u.csr_user_sid||')');
			--security.security_pkg.debugmsg('adding mailbox for '||u.user_name||' ('||u.csr_user_sid||')');
			begin
				mail.mail_pkg.createMailbox(v_users_mailbox_sid, u.csr_user_sid, v_user_mailbox_sid);
			exception
				when security.security_pkg.DUPLICATE_OBJECT_NAME then
					v_user_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_users_mailbox_sid, u.csr_user_sid);
			end;
			select count(*) into v_user_so_exists from security.securable_object where sid_id = u.csr_user_sid;
			if v_user_so_exists <> 0 then
				select count(*)
				  into v_acl_count
				  from security.acl 
				 where acl_id = security.acl_pkg.GetDACLIDForSID(v_user_mailbox_sid)
				   and ace_type = security.security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security.security_pkg.PERMISSION_ADD_CONTENTS;
				if v_acl_count = 0 then
					security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_ADD_CONTENTS);
				end if;
				select count(*)
				  into v_acl_count
				  from security.acl 
				 where acl_id = security.acl_pkg.GetDACLIDForSID(v_user_mailbox_sid)
				   and ace_type = security.security_pkg.ACE_TYPE_ALLOW and sid_id = u.csr_user_sid and permission_set = security.security_pkg.PERMISSION_STANDARD_ALL;
				if v_acl_count = 0 then
					security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, u.csr_user_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
				end if;
			end if;
		end loop;
		
		begin
			mail.mail_pkg.createAccount(v_tracker_email, NULL, 'Tracker mail account for '||r.host, v_account_sid, v_tracker_mailbox_sid);
			dbms_output.put_line('created '||v_tracker_email||' (was '||r.tracker_mail_address||')');
			security.security_pkg.debugmsg('created '||v_tracker_email||' (was '||r.tracker_mail_address||')');
		exception
			when security.security_pkg.DUPLICATE_OBJECT_NAME then
				v_tracker_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(null, v_tracker_email);
		end;

		-- if they exist, give administrators full control over the mailboxes
		if v_admins_sid is not null	then
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = security.acl_pkg.GetDACLIDForSID(v_tracker_mailbox_sid)
			   and ace_type = security.security_pkg.ACE_TYPE_ALLOW and sid_id = v_admins_sid and permission_set = security.security_pkg.PERMISSION_STANDARD_ALL;
			if v_acl_count = 0 then
				security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_tracker_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
				security.acl_pkg.PropogateAces(SYS_CONTEXT('SECURITY', 'ACT'), v_root_mailbox_sid);
			end if;
		end if;
		
		UPDATE csr.customer
		   SET tracker_mail_address = v_tracker_email, system_mail_address = v_email
		 WHERE app_sid = r.app_sid;
		-- COMMIT;
	end loop;
end;
/

-- UserCreatorDaemon needs to be able to add mailboxes
declare
	v_user_creator_sid		number;
	v_root_mailbox_sid 		number;
	v_users_mailbox_sid		number;
	v_reg_users_sid			number;
	v_acl_count				number;
begin
	dbms_output.enable(null);
	security.user_pkg.LogonAdmin;
	for r in (select host, app_sid, system_mail_address
				from csr.customer) loop
		security.security_pkg.SetApp(r.app_sid);

		security.security_pkg.debugmsg('adding UCD permissions to '||r.host);
		dbms_output.put_line('adding UCD permissions to '||r.host);
		begin
			v_reg_users_sid := security.securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
			v_user_creator_sid := security.securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon');
			v_root_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(null, r.system_mail_address);
			v_users_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Users');
	
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = security.acl_pkg.GetDACLIDForSID(v_users_mailbox_sid)
			   and ace_type = security.security_pkg.ACE_TYPE_ALLOW
			   and sid_id = v_user_creator_sid
			   and permission_set = security.security_pkg.PERMISSION_ADD_CONTENTS;
			if v_acl_count = 0 then
				security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), 
					security.acl_pkg.GetDACLIDForSID(v_users_mailbox_sid), 
					security.security_pkg.ACL_INDEX_LAST, 
					security.security_pkg.ACE_TYPE_ALLOW,
					0, 
					v_user_creator_sid, 
					security.security_pkg.PERMISSION_ADD_CONTENTS);
			end if;

			-- the user creator daemon needs to be a member of registered users to send mails to them
			security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_creator_sid, v_reg_users_sid);
		exception
			when security.security_pkg.object_not_found then
				dbms_output.put_line('No user creator daemon');
				security.security_pkg.debugmsg('No user creator daemon');
		end;
	end loop;
end;
/
