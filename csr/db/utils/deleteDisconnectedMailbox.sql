
begin
	for r in (
		select mailbox_sid, mailbox_name 
          from mailbox
		 start with mailbox_sid in (
			-- figure out which one ISN'T being used
			select mailbox_sid from mailbox where mailbox_name = 'rbsenv@credit360.com'
			minus
			select root_mailbox_sid from account where email_address = 'rbsenv@credit360.com'
		)
	   connect by prior mailbox_sid = parent_sid
		 order by level desc -- sort so we delete from bottom up
	)
	loop
		-- we can't use the stored proc because this isn't linked to an account
		-- and we'd get an error message when it tries to find the right full text
		-- index.
		-- Clean all message child objects
		DELETE FROM message_address_field
		 WHERE mailbox_sid = r.mailbox_sid;

		DELETE FROM message_header
		 WHERE mailbox_sid = r.mailbox_sid;

		-- Clean the messages themselves
		DELETE FROM message
		 WHERE mailbox_sid = r.mailbox_sid;	

		-- Delete the mailbox itself
		DELETE FROM mailbox
		 WHERE mailbox_sid = r.mailbox_sid;
	end loop;
end;
/

