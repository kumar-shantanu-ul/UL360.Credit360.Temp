PROMPT Parameters:
PROMPT 1) Enter IMAP folder name to create (lower-case by convention, e.g. credit360)
PROMPT 2) Enter (optionally comma-separated list) of email suffixes, e.g. credit360.com,credit360.co.uk
declare
	TYPE T_DOMAINS IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_client_name			VARCHAR2(255);
	v_domains				T_DOMAINS;
	v_bb_account_sid		security_pkg.T_SID_ID;
	v_bb_inbox_sid			security_pkg.T_SID_ID;
	v_client_mailbox_sid 	security_pkg.T_SID_ID;
	v_msg_filter_id			mail.message_filter.message_filter_id%TYPE;
	v_moved					NUMBER(10);
	v_run_mailbox_sids		security.security_pkg.T_SID_IDS;
	v_run_msg_filter_ids	security.security_pkg.T_SID_IDS;
	v_cnt					NUMBER(10) := 1;
begin
	user_pkg.logonadmin;
	
	v_client_name := REPLACE(LOWER('&&1'), ' ');
	FOR r IN (
		SELECT LOWER(TRIM(item)) item FROM TABLE(aspen2.utils_pkg.SplitString('&&2'))
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('filtering for @'||r.item);
		v_domains(v_cnt) := '@'||r.item;
		v_cnt := v_cnt + 1;
	END LOOP;
	--v_domains(1) := '@kuoni.ch';
	--v_domains(2) := '@kuoni.com';

	SELECT account_sid, inbox_sid
	  INTO v_bb_account_sid, v_bb_inbox_sid
	  FROM mail.account
	 WHERE email_address = 'bb@credit360.com';

	-- create mailbox
	mail.mailbox_pkg.createMailbox(
		in_parent_sid_id	=> securableobject_pkg.getsidfrompath(security_pkg.getact, 0, 'Mail/Folders/bb@credit360.com/shared folders/Clients'),
		in_name				=> v_client_name,
		in_account_sid 		=> v_bb_account_sid,
		out_mailbox_sid		=> v_client_mailbox_sid
	);

	-- add filter
	mail.message_filter_pkg.saveFilter(
		in_account_sid			=> v_bb_account_sid,
		in_message_filter_id	=> null,
		in_description			=> v_client_name,
		in_match_type			=> 'any',
		in_to_mailbox_sid		=> v_client_mailbox_sid,
		in_matched_action		=> 'move',
		out_message_filter_id	=> v_msg_filter_id
	);
	
	mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'Subject', '['||v_client_name||']', 'in');
	FOR i IN v_domains.FIRST..v_domains.LAST
	LOOP	
		DBMS_OUTPUT.PUT_LINE('adding filter for "'||v_domains(i)||'"...');
		mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'To', v_domains(i), 'in');
		mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'From', v_domains(i), 'in');
		mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'Cc', v_domains(i), 'in');
	END LOOP;

	commit;
	
	-- run filter
	v_run_mailbox_sids(1) := v_bb_inbox_sid;
	v_run_msg_filter_ids(1) := v_msg_filter_id;
	mail.message_filter_pkg.runFilters(
		in_account_sid			=> v_bb_account_sid,
		in_mailbox_sids			=> v_run_mailbox_sids,
		in_message_filter_ids	=> v_run_msg_filter_ids,
		out_count_affected		=> v_moved
	);
	DBMS_OUTPUT.PUT_LINE(v_moved||' messages matched.');	
	
	commit;
end;
/

