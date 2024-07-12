
declare
	v_new_mailbox_sid	number;
begin
	user_pkg.logonadmin;
	
	for r in (
		select distinct root_mailbox_sid, lower(email_address) email_address
		  from mail.account
		 where lower(email_address) in (
			 select email_address 
			  from mail.account 
			 where email_address in (
				select cu.email 
				  from csr.csr_user cu 
					join csr.superadmin sa on cu.csr_user_sid= sa.csr_user_sid 
					join security.user_table ut on cu.csr_user_sid = ut.sid_id 
				 where account_enabled = 1
			)
		)
	 )
	 loop
		begin
			mail.mail_pkg.createMailbox(r.root_mailbox_sid, 'New things', v_new_mailbox_sid);
			update mail.mailbox 
			   set link_to_mailbox_sid = 12445927 -- ick - hardcoded SID for newthings@credit360.com/Inbox
			 where mailbox_sid = v_new_mailbox_sid;
			dbms_output.put_line('created for '||r.email_address);
		exception
			when others then null;
		end;
	 end loop;

end;
/

quit;
