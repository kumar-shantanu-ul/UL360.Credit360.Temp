CREATE OR REPLACE PACKAGE BODY MAIL.mail_pkg
AS

FUNCTION generateSalt 
RETURN NUMBER
AS
    v_salt CHAR(32);
    -- This is fixed, but we seem to get different ACTs each time anyway
    -- Presumably sufficient entropy is added that we don't need to fetch it ourselves?
    -- Since Oracle couldn't be fucked to document the function, I'm not really
    -- sure what the answer is.
    seedval RAW(80) := HEXTORAW('3D074594FB092A1A11228BE1A8FD488A'
							 || '83455D95C79318D15787A796A68F932D'
							 || 'A2821E85667A2F28DA5B8AC594A9147C'
							 || '85F8BCDC25EDD95DB7B48E29FFBB1B30'
							 || '49DDD6A4AABDCE5861BE68FD1C603160');
BEGIN
	v_salt := RAWTOHEX(DBMS_OBFUSCATION_TOOLKIT.DES3GETKEY(seed => seedval));
	RETURN TO_NUMBER(SUBSTR(v_salt,1,8),'XXXXXXXX'); 
END;

FUNCTION hashPassword(
   in_salt				IN NUMBER, 
   in_pass 				IN VARCHAR2
)
RETURN VARCHAR2
AS
	v_hex_digest 	VARCHAR2(32);
	v_digest 		VARCHAR2(16);
BEGIN
	v_digest := DBMS_OBFUSCATION_TOOLKIT.MD5(
		INPUT_STRING => NVL(TO_CHAR(in_salt),'X')||NVL(in_pass,'Y'));
	SELECT RAWTOHEX(v_digest) 
	  INTO v_hex_digest 
	  FROM dual;
	RETURN v_hex_digest;
END;

FUNCTION getAccountFromMailbox(
	in_mailbox_sid		IN	mailbox_message.mailbox_sid%TYPE
) RETURN account.account_sid%TYPE
AS
	v_root_mailbox_sid	mailbox.mailbox_sid%TYPE;
	v_account_sid		account.account_sid%TYPE;
BEGIN
	BEGIN
		-- Walk up tree to get the root mailbox
		SELECT mailbox_sid
		  INTO v_root_mailbox_sid
		  FROM (
			SELECT mailbox_sid, parent_sid
  			  FROM mailbox
		   CONNECT BY PRIOR parent_sid = mailbox_sid
		     START WITH mailbox_sid = in_mailbox_sid
			   )
		WHERE NVL(parent_sid,0) = 0;
		
		-- Use this to look up the account
		SELECT MIN(account_sid)
		  INTO v_account_sid
		  FROM account
		 WHERE root_mailbox_sid = v_root_mailbox_sid;
		 RETURN v_account_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE MAILBOX_NOT_FOUND;
	END;
END;

PROCEDURE deleteMessage(
	in_mailbox_sid					IN 	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN 	mailbox_message.message_uid%TYPE
)
IS
	v_modseq						mailbox.modseq%TYPE;
BEGIN
	-- Add a delete job for the message, if required
	UPDATE mailbox
	   SET modseq = modseq + 1
	 WHERE mailbox_sid = in_mailbox_sid
	 	   RETURNING modseq INTO v_modseq;
	
	INSERT INTO expunged_message (mailbox_sid, modseq, min_uid, max_uid)
	VALUES (in_mailbox_sid, v_modseq, in_message_uid, in_message_uid);

	-- Clean all child objects
	DELETE FROM account_message
	 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid;
	-- Clean the message itself
	DELETE FROM mailbox_message
	 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid;
END;

PROCEDURE copyMessage(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mailbox_message.message_uid%TYPE,
	in_dest_mailbox_sid				IN	mailbox_message.mailbox_sid%TYPE,
	out_dest_message_uid			OUT	mailbox_message.message_uid%TYPE
)
IS
	v_new_uid						mailbox.last_message_uid%TYPE;
	v_modseq						mailbox.modseq%TYPE;
BEGIN
	-- lock the destination mailbox	
	UPDATE mailbox
	   SET last_message_uid = last_message_uid + 1, modseq = modseq + 1
	 WHERE mailbox_sid = in_dest_mailbox_sid
	 	   RETURNING last_message_uid, modseq INTO v_new_uid, v_modseq;
	out_dest_message_uid := v_new_uid;

	-- copy the various bits of the mail
	INSERT INTO mailbox_message (mailbox_sid, message_uid, message_id, flags,
		received_dtm, modseq)
		SELECT in_dest_mailbox_sid, v_new_uid, m.message_id, m.flags,
			   m.received_dtm, v_modseq
		  FROM mailbox_message m
		 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid;

	IF SQL%ROWCOUNT = 0 THEN
		RAISE MESSAGE_NOT_FOUND;
	END IF;
END;

PROCEDURE moveMessage(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mailbox_message.message_uid%TYPE,
	in_dest_mailbox_sid				IN	mailbox_message.mailbox_sid%TYPE,
	out_dest_message_uid			OUT	mailbox_message.message_uid%TYPE
)
IS
BEGIN
	-- XXX: we could use ON UPDATE CASCADE for the constraints to do this
	copyMessage(in_mailbox_sid, in_message_uid, in_dest_mailbox_sid, out_dest_message_uid);
	deleteMessage(in_mailbox_sid, in_message_uid);
END;

PROCEDURE resetPassword(
	in_account_sid					IN	mailbox.mailbox_sid%TYPE,
	in_password						IN	VARCHAR2
)
AS
	v_salt			account.password_salt%TYPE;
BEGIN
	v_salt := generateSalt();
	UPDATE account 
	   SET password = hashPassword(v_salt, in_password),
	       password_salt = v_salt,
	       apop_secret = in_password
	 WHERE account_sid = in_account_sid;
END;

PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	createAccount(in_email_address, in_password, in_description, 0, out_account_sid, out_root_mailbox_sid);
END;

PROCEDURE createSpecialFolder(
	in_account_sid					IN	account.account_sid%TYPE,
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_mailbox_name					IN	mailbox.mailbox_name%TYPE,
	in_special_use					IN	mailbox.special_use%TYPE,
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	mailbox_pkg.createMailbox(in_parent_sid, in_mailbox_name, in_account_sid, out_mailbox_sid);
	UPDATE mail.mailbox
	   SET special_use = in_special_use
	 WHERE mailbox_sid = out_mailbox_sid;
END;

PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	in_for_outlook					IN	NUMBER,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	createAccount(
		in_email_address				=> in_email_address,
		in_password						=> in_password,
		in_description					=> in_description,
		in_for_outlook					=> in_for_outlook,
		in_class_id						=> NULL,
		out_account_sid					=> out_account_sid,
		out_root_mailbox_sid			=> out_root_mailbox_sid
	);
END;

PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	in_for_outlook					IN	NUMBER,
	in_class_id						IN	NUMBER DEFAULT NULL,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
IS
	v_salt			account.password_salt%TYPE;
	v_inbox_sid		mailbox.mailbox_sid%TYPE;
	v_accounts_sid	security.security_pkg.T_SID_ID;
	v_folders_sid	security.security_pkg.T_SID_ID;
	v_folder_sid	security.security_pkg.T_SID_ID;
BEGIN
	-- Folders where the mail SOs live
	v_folders_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '/Mail/Folders');
	v_accounts_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '/Mail/Accounts');

	-- Create the account
	-- XXX: this probably ought to change to just log the user on with security.security.user_pkg,
	-- leaving it for now as too many other changes to make
	security.user_pkg.createuser(
		in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_parent_sid			=> v_accounts_sid,
		in_login_name			=> in_email_address,
		in_plaintext_password	=> in_password,
		in_class_id				=> security.security_pkg.SO_USER,
		out_user_sid			=> out_account_sid
	);
	
	-- Grant the creating user permissions on the account (except for builtin/administrator, which by default has permissions)
	IF SYS_CONTEXT('SECURITY', 'SID') != security.security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(out_account_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, SYS_CONTEXT('SECURITY', 'SID'), security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
	
	BEGIN
		INSERT INTO account_alias
			(account_sid, email_address)
		VALUES
			(out_account_sid, in_email_address);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'The email address '||in_email_address||' is already in use');
	END;
		
	v_salt := generateSalt();
	INSERT INTO account
		(account_sid, email_address, password, password_salt, apop_secret)
	VALUES
		(out_account_sid, in_email_address, hashPassword(v_salt, in_password), v_salt, in_password);
		
	-- Create the root mailbox/inbox for the account
	mailbox_pkg.createMailboxWithClass(v_folders_sid, in_email_address, out_account_sid, in_class_id, out_root_mailbox_sid);

	-- Grant the creating user permissions on the mailbox (except for builtin/administrator, which by default has permissions)
	IF SYS_CONTEXT('SECURITY', 'SID') != security.security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(out_root_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, SYS_CONTEXT('SECURITY', 'SID'), security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
	-- Grant the account permissions on the mailbox
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(out_root_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, out_account_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Create an inbox for the account
	mailbox_pkg.createMailboxWithClass(out_root_mailbox_sid, 'Inbox', out_account_sid, in_class_id, v_inbox_sid);
	
	-- If the account is for outlook, then pre-create the special folders because it's too retarded to allow the
	-- user to set them manually, and too retarded to use them if you create them after adding the account
	IF in_for_outlook = 1 THEN
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Drafts', SU_Drafts, v_folder_sid);
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Junk E-mail', SU_Junk, v_folder_sid);
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Deleted Items', SU_Trash, v_folder_sid);
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Sent Items', SU_Sent, v_folder_sid);
	END IF;
	
	UPDATE account
	   SET root_mailbox_sid = out_root_mailbox_sid,
		   inbox_sid = v_inbox_sid
	 WHERE account_sid = out_account_sid;
END;

PROCEDURE renameAccount(
	in_account_sid					IN	account.account_sid%TYPE,
	in_new_email_address			IN	account.email_address%TYPE
)
IS
	v_folders_sid					security.security_pkg.T_SID_ID;
	v_root_mailbox_sid				account.root_mailbox_sid%TYPE;
	v_old_email_address				account.email_address%TYPE;
BEGIN
	-- renaming the securable objects will effectively take care of security checks	
	
	-- the bit under /Mail/Accounts
	security.securableObject_pkg.renameSO(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, in_new_email_address);
	
	-- get the old mail address for cleaning up account alias
	SELECT email_address
	  INTO v_old_email_address
	  FROM account
	 WHERE account_sid = in_account_sid;
	 
	-- account.email_address references the alias table, so add the new address as an alias
	BEGIN
		INSERT INTO account_alias
			(account_sid, email_address)
		VALUES
			(in_account_sid, in_new_email_address);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'The email address '||in_new_email_address||' is already in use');
	END;

	-- set the new address
	UPDATE account
	   SET email_address = in_new_email_address
	 WHERE account_sid = in_account_sid;

	-- clean up the old one
	DELETE FROM account_alias
     WHERE account_sid = in_account_sid
       AND email_address = v_old_email_address;
	
	-- now fix up the stuff under /Mail/Folders 
	SELECT root_mailbox_sid
	  INTO v_root_mailbox_sid
	  FROM account
	 WHERE account_sid = in_account_sid;
	 
	security.securableObject_pkg.renameSO(SYS_CONTEXT('SECURITY', 'ACT'), v_root_mailbox_sid, in_new_email_address);
END;

-- legacy wrapper
PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
IS
	v_account_sid					account.account_sid%TYPE;
BEGIN
	createAccount(in_email_address, in_password, null, v_account_sid, out_root_mailbox_sid);
END;

PROCEDURE addAccountAlias(
	in_account_sid					IN	account_alias.account_sid%TYPE,
	in_email_address				IN	account_alias.email_address%TYPE
)
AS
	v_accounts_sid					security.security_pkg.T_SID_ID;
BEGIN
	-- Write permission is required on the account to modify it
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Add contents permission denied on the account with sid '||in_account_sid);
	END IF;
	
	-- Add contents permission on the accounts folder is required to add an e-mail address
	v_accounts_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '/Mail/Accounts');
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_accounts_sid, security.security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Add contents permission denied on /Mail/Accounts');
	END IF;

	-- account.email_address references the alias table, so add the new address as an alias
	BEGIN
		INSERT INTO account_alias
			(account_sid, email_address)
		VALUES
			(in_account_sid, in_email_address);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'The email address '||in_email_address||' is already in use');
	END;
END;

PROCEDURE deleteAccountAlias(
	in_account_sid					IN	account_alias.account_sid%TYPE,
	in_email_address				IN	account_alias.email_address%TYPE
)
AS
BEGIN
	-- Write permission is required on the account to modify it
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Add contents permission denied on /Mail/Accounts');
	END IF;

	DELETE FROM account_alias
	 WHERE account_sid = in_account_sid 
	   AND LOWER(email_address) = LOWER(in_email_address);
END;

PROCEDURE getAccountAliases(
	in_account_sid					IN	account.account_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Read permission is required on the account to list aliases
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the account with sid '||in_account_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT email_address
		  FROM account_alias
		 WHERE account_sid = in_account_sid
		 MINUS
		SELECT email_address
		  FROM account
		 WHERE account_sid = in_account_sid;
END;

PROCEDURE createAccountForCurrentUser(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
IS
BEGIN
	createAccount(in_email_address, in_password, in_description, out_account_sid, out_root_mailbox_sid);
	INSERT INTO user_account 
		(user_sid, account_sid)
	VALUES
		(SYS_CONTEXT('SECURITY', 'SID'), out_account_sid);
END;

PROCEDURE deleteAccount(
	in_email_address	IN	account.email_address%TYPE
)
IS
	v_account_sid		account.account_sid%TYPE;
BEGIN
	SELECT account_sid
	  INTO v_account_sid
	  FROM account
	 WHERE LOWER(email_address) = LOWER(in_email_address);

	deleteAccount(v_account_sid);
END;

PROCEDURE deleteAccount(
	in_account_sid		IN	account.account_sid%TYPE
)
IS
	v_root_mailbox_sid	account.root_mailbox_sid%TYPE;
BEGIN
	SELECT root_mailbox_sid
	  INTO v_root_mailbox_sid
	  FROM account
	 WHERE account_sid = in_account_sid;

	DELETE FROM temp_mailbox;
	INSERT INTO temp_mailbox (mailbox_sid)
		SELECT mailbox_sid
	 	  FROM mailbox
	 		   START WITH mailbox_sid = v_root_mailbox_sid
	 		   CONNECT BY PRIOR mailbox_sid = parent_sid;
	 		   
	DELETE FROM account_message
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	DELETE FROM mailbox_message
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);

	DELETE FROM mbox_subscription
	 WHERE account_sid = in_account_sid;

	DELETE FROM message_filter_entry
	 WHERE message_filter_id IN (SELECT message_filter_id
	 							   FROM message_filter
	 							  WHERE account_sid = in_account_sid);

	DELETE FROM message_filter
	 WHERE account_sid = in_account_sid;

	DELETE FROM user_account
	 WHERE account_sid = in_account_sid;

	DELETE FROM vacation_notified
	 WHERE account_sid = in_account_sid;

	DELETE FROM vacation
	 WHERE account_sid = in_account_sid;
	 
	DELETE FROM account
	 WHERE account_sid = in_account_sid;

	DELETE FROM account_alias
	 WHERE account_sid = in_account_sid;
	 
	-- Mark mailboxes as containers to speed up deletion a bit, then clean up all the
	-- SOs using DeleteSO
	UPDATE security.securable_object
	   SET class_id = security.security_pkg.SO_CONTAINER
	 WHERE sid_id IN (SELECT mailbox_sid
 						FROM temp_mailbox);

	FOR r IN (SELECT mailbox_sid
				FROM temp_mailbox) LOOP
		security.securableObject_pkg.deleteSO(SYS_CONTEXT('SECURITY', 'ACT'), r.mailbox_sid);
	END LOOP;

	DELETE FROM mail.expunged_message
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);

	DELETE FROM account_mailbox
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);

	DELETE FROM mailbox
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	 						 	  
	-- Clean up the account object
	security.securableObject_pkg.deleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid);
END;

PROCEDURE setAccountDetails(
	in_account_sid					IN	account.account_sid%TYPE,
	in_description					IN	account.description%TYPE,
	in_inbox_sid					IN	account.inbox_sid%TYPE
)
IS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the account with sid '||in_account_sid);
	END IF;

	UPDATE account
	   SET description = in_description, inbox_sid = in_inbox_sid
	 WHERE account_sid = in_account_sid;
END;

PROCEDURE createMailbox(
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_name							IN	mailbox.mailbox_name%TYPE,
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE
)
IS
BEGIN
	mailbox_pkg.createMailbox(in_parent_sid, in_name, NULL, out_mailbox_sid);
END;

PROCEDURE deleteMailbox(
	in_mailbox_sid					IN	mailbox.mailbox_sid%TYPE
)
IS
BEGIN
	security.securableObject_pkg.deleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_mailbox_sid);
END;

FUNCTION getMailboxSIDFromPath(
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_path							IN	VARCHAR2
) RETURN mailbox.mailbox_sid%TYPE
AS
	v_sid			mailbox.mailbox_sid%TYPE;
	v_parent_sid	mailbox.mailbox_sid%TYPE;
BEGIN
	getMailboxFromPath(in_parent_sid, in_path, v_sid, v_parent_sid);
	RETURN v_sid;
END;

PROCEDURE getMailboxFromPath(
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_path							IN	VARCHAR2,
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE,
	out_parent_sid					OUT mailbox.parent_sid%TYPE
)
AS
	v_pos			BINARY_INTEGER;
	v_last_pos		BINARY_INTEGER DEFAULT 1;
	v_length		BINARY_INTEGER DEFAULT LENGTH(in_path);
	v_mailbox_name	VARCHAR2(4000);
BEGIN
	-- Initial output
	out_mailbox_sid := in_parent_sid;
	out_parent_sid := in_parent_sid;
	
	-- Repeat for each component in the path
	WHILE v_last_pos <= v_length LOOP
		v_pos := INSTR(in_path, '/', v_last_pos);
		IF v_pos = 0 THEN
			v_pos := v_length + 1;
		END IF;
		--security.security_pkg.debugmsg('look for '||LOWER(SUBSTR(in_path, v_last_pos, v_pos - v_last_pos)) || ' with parent sid ' || out_mailbox_sid);
		IF v_pos - v_last_pos >= 1 THEN
			BEGIN
				out_parent_sid := out_mailbox_sid;
				v_mailbox_name := LOWER(SUBSTR(in_path, v_last_pos, v_pos - v_last_pos));
				IF out_mailbox_sid IS NULL THEN
					SELECT NVL(link_to_mailbox_sid, mailbox_sid)
					  INTO out_mailbox_sid
					  FROM mailbox
					 WHERE parent_sid IS NULL
					   AND LOWER(mailbox_name) = v_mailbox_name;
				ELSE
					SELECT NVL(link_to_mailbox_sid, mailbox_sid)
					  INTO out_mailbox_sid
					  FROM mailbox
					 WHERE parent_sid = out_mailbox_sid
					   AND LOWER(mailbox_name) = v_mailbox_name;
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					--oh bugger i've used the wrong numbers
					--security.security_pkg.debugmsg('The mailbox with parent sid '||in_parent_sid||' and path '||in_path||' could not be found');
					RAISE mail_pkg.PATH_NOT_FOUND;					
					--RAISE_APPLICATION_ERROR(mail_pkg.ERR_PATH_NOT_FOUND, 'The mailbox with parent sid '||in_parent_sid||' and path '||in_path||' could not be found');
			END;
		END IF;
		v_last_pos := v_pos + 1;
	END LOOP;
END;

FUNCTION getPathFromMailbox(
	in_mailbox_sid					IN	mailbox.mailbox_sid%TYPE
) RETURN VARCHAR2
AS
	v_path 	VARCHAR2(4000);
	v_found BOOLEAN;
BEGIN
	v_found := FALSE;
	FOR r IN (
			SELECT mailbox_name, parent_sid
  			  FROM mailbox
		   CONNECT BY PRIOR parent_sid = mailbox_sid
		     START WITH mailbox_sid = in_mailbox_sid 
		     ) LOOP
		v_found := TRUE;
		v_path := '/' || r.mailbox_name || v_path;
	END LOOP;
	IF NOT v_found THEN
		RAISE MAILBOX_NOT_FOUND;
	END IF;
	IF v_path IS NULL THEN
		RETURN '/';
	END IF;
	RETURN v_path;
END;

FUNCTION parseLink(
	in_sid							IN	mailbox.mailbox_sid%TYPE
) RETURN mailbox.mailbox_sid%TYPE
AS 
	v_sid	mailbox.mailbox_sid%TYPE;
BEGIN
	BEGIN
		SELECT NVL(link_to_mailbox_sid, mailbox_sid)
		  INTO v_sid
		  FROM mailbox
		 WHERE mailbox_sid = in_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_sid := in_sid;
	END;
	RETURN v_sid;
END;

FUNCTION processStartPoints(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER
)
RETURN security.T_SID_TABLE
AS
	v_parsed_sids	security.security_pkg.T_SID_IDS;
BEGIN
	-- Process link and check permissions
	FOR i IN in_parent_sids.FIRST .. in_parent_sids.LAST
	LOOP
		IF in_include_root = 0 THEN			
			v_parsed_sids(i) := ParseLink(in_parent_sids(i));
		ELSE 
			v_parsed_sids(i) := in_parent_sids(i);
		END IF;
	END LOOP;
	RETURN security.security_pkg.SidArrayToTable(v_parsed_sids);
END;

PROCEDURE getUserAccounts(
	out_cur							OUT	SYS_REFCURSOR
)
IS
BEGIN
	OPEN out_cur FOR
		SELECT a.account_sid, a.email_address, a.root_mailbox_sid, a.inbox_sid, a.description
		  FROM user_account ua, account a
		 WHERE ua.user_sid = SYS_CONTEXT('SECURITY', 'SID') AND a.account_sid = ua.account_sid;
END;

FUNCTION isUserAccount(
	in_account_sid					IN	account.account_sid%TYPE
) RETURN NUMBER
IS
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM user_account
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID') AND account_sid = in_account_sid;
	RETURN v_cnt;
END;

PROCEDURE getAccount(
	in_account_sid					IN	account.account_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR	
)
IS
BEGIN
	OPEN out_cur FOR
		SELECT a.account_sid, a.email_address, a.root_mailbox_sid, a.inbox_sid, m.mailbox_name inbox_name, a.description
		  FROM account a, mailbox m
		 WHERE a.account_sid = in_account_sid AND a.inbox_sid = m.mailbox_sid;
END;

PROCEDURE getTreeWithDepth(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ mailbox_sid, mailbox_name, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf
		  FROM mailbox
		 WHERE level <= in_fetch_depth
		       START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 		      (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
			   CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
		  	   ORDER SIBLINGS BY LOWER(mailbox_name);
END;

PROCEDURE getTreeWithSelect(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ mailbox_sid, mailbox_name, lvl, is_leaf
		  FROM (SELECT mailbox_sid, mailbox_name, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn,
             	       sys_connect_by_path(to_char(mailbox_sid),'/')||'/' path,
             	       sys_connect_by_path(to_char(parent_sid),'/')||'/' ppath             	       
		 	      FROM mailbox m
			      START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			     (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
		 		CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
		 		  ORDER SIBLINGS BY LOWER(m.mailbox_name))
		  WHERE lvl <= in_fetch_depth OR path IN (
         			SELECT (SELECT '/'||reverse(sys_connect_by_path(reverse(to_char(mailbox_sid)),'/'))
                  	  	      FROM mailbox mp
                	         WHERE (in_include_root = 1 and mp.mailbox_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
                	 	           (in_include_root = 0 and mp.parent_sid IN (SELECT column_value FROM TABLE(v_roots)))
                                   START WITH mp.mailbox_sid = m.mailbox_sid
                                   CONNECT BY PRIOR mp.parent_sid = mp.mailbox_sid) path
		 		      FROM mailbox m
		 		           START WITH mailbox_sid = in_select_sid
		 	               CONNECT BY PRIOR parent_sid = mailbox_sid AND (
		 	                   (in_include_root = 1 AND PRIOR mailbox_sid NOT IN (SELECT column_value FROM TABLE(v_roots))) OR
           					   (in_include_root = 0 AND PRIOR parent_sid NOT IN (SELECT column_value FROM TABLE(v_roots))))
                  ) OR ppath IN (
         			SELECT (SELECT '/'||reverse(sys_connect_by_path(reverse(to_char(parent_sid)),'/'))
                  	  	      FROM mailbox mp
                	         WHERE (in_include_root = 1 and mp.mailbox_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
                	 	           (in_include_root = 0 and mp.parent_sid IN (SELECT column_value FROM TABLE(v_roots)))
                                   START WITH mp.mailbox_sid = m.mailbox_sid
                                   CONNECT BY PRIOR mp.parent_sid = mp.mailbox_sid) path
		 		      FROM mailbox m
		 		           START WITH mailbox_sid = in_select_sid
		 	               CONNECT BY PRIOR parent_sid = mailbox_sid AND (
		 	                   (in_include_root = 1 AND PRIOR mailbox_sid NOT IN (SELECT column_value FROM TABLE(v_roots))) OR
           					   (in_include_root = 0 AND PRIOR parent_sid NOT IN (SELECT column_value FROM TABLE(v_roots))))
           	      )
        ORDER BY rn;
END;

PROCEDURE getTreeTextFiltered(
	in_account_sid					IN  account.account_sid%TYPE,
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_root_mailbox_sid				mailbox.mailbox_sid%TYPE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);
	
	SELECT root_mailbox_sid
	  INTO v_root_mailbox_sid
	  FROM account
	 WHERE account_sid = in_account_sid;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ mailbox_sid, mailbox_name, lvl, is_leaf
		  FROM ( 
		  	SELECT mailbox_sid, mailbox_name, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn
		  	  FROM mailbox
		  	 	   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			      (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
				   CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
		  	 ORDER SIBLINGS BY LOWER(mailbox_name))
		 WHERE mailbox_sid IN (
		  	SELECT m.mailbox_sid 
		  	  FROM mailbox m, (
					SELECT m2.mailbox_sid, m1.mailbox_sid parent_sid
					  FROM mailbox m1, mailbox m2
					 WHERE m1.link_to_mailbox_sid = m2.parent_sid
					 UNION ALL
					SELECT mailbox_sid, parent_sid
					  FROM mailbox
					  	   START WITH mailbox_sid = v_root_mailbox_sid
					  	   CONNECT BY PRIOR mailbox_sid = parent_sid) mp
			  WHERE m.mailbox_sid = mp.mailbox_sid
					START WITH m.mailbox_sid IN (SELECT mailbox_sid 
					       					       FROM mailbox 
					       				          WHERE LOWER(mailbox_name) LIKE '%'||LOWER(in_search_phrase)||'%')
			        CONNECT BY PRIOR mp.parent_sid = m.mailbox_sid)
		ORDER BY rn;
END;

PROCEDURE getListTextFiltered(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT mailbox_sid, mailbox_name, link_to_mailbox_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
					   SYS_CONNECT_BY_PATH(mailbox_name, '/') path
				  FROM mailbox
				 WHERE LOWER(mailbox_name) LIKE '%'||LOWER(in_search_phrase)||'%'
			       	   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			          (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
					   CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
				 ORDER SIBLINGS BY LOWER(mailbox_name))
		   WHERE rownum <= in_fetch_limit;
END;

FUNCTION getInboxSIDFromEmail(
	in_email_address				IN	VARCHAR2
) RETURN account.inbox_sid%TYPE
AS
	v_inbox_sid account.inbox_sid%TYPE;
BEGIN
	BEGIN
		SELECT a.inbox_sid
		  INTO v_inbox_sid
		  FROM account_alias aa, account a
		 WHERE LOWER(aa.email_address) = LOWER(in_email_address)
		   AND a.account_sid = aa.account_sid;
		 
		RETURN v_inbox_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE MAILBOX_NOT_FOUND;
	END;
END;

PROCEDURE getAllMailboxMessage(
	in_mailbox_sid					IN	mailbox.mailbox_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mm.mailbox_sid, mm.message_uid, mm.flags, m.subject, m.message_dtm,
			   m.message_id_hdr, m.in_reply_to, m.priority, m.has_attachments,
			   mm.received_dtm, m.body
		  FROM mailbox_message mm, message m
		 WHERE mm.mailbox_sid = in_mailbox_sid
		   AND mm.message_id = m.message_id;
END;

PROCEDURE cleanOrphanedMessages
AS
	TYPE t_ids IS TABLE OF NUMBER;
	v_ids t_ids;
	v_id NUMBER;
BEGIN
	-- The bulk delete approach seems to be very slow, so do this one at a time using
	-- a pl/sql collection to avoid a long running cursor (which would be subject
	-- to undo aging out -- i.e. would get a 'snapshot too old' error)
	SELECT message_id
		   BULK COLLECT INTO v_ids
	  FROM mail.message
	 WHERE message_id NOT IN (SELECT message_id
								FROM mail.mailbox_message);
								
	FOR v_i IN 1 .. v_ids.COUNT LOOP
		v_id := v_ids(v_i);
		DELETE FROM mail.message_address_field
		 WHERE message_id = v_id;
		DELETE FROM mail.message_header
		 WHERE message_id = v_id;
		DELETE FROM mail.message
		 WHERE message_id = v_id;
		COMMIT;
		--security.security_pkg.debugmsg('cleaned '||v_id||' - ' ||v_i||' of '||v_ids.COUNT);
	END LOOP;
END;

END mail_pkg;
/

CREATE OR REPLACE PACKAGE BODY MAIL.mailbox_pkg
AS

-- Securable object callbacks
PROCEDURE createObject(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_sid_id						IN	security.security_pkg.T_SID_ID,
	in_class_id						IN	security.security_pkg.T_CLASS_ID,
	in_name							IN	security.security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	null;
END;

PROCEDURE renameObject(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_sid_id						IN	security.security_pkg.T_SID_ID,
	in_new_name						IN	security.security_pkg.T_SO_NAME
)
AS
BEGIN
	UPDATE mailbox
	   SET mailbox_name = in_new_name
	 WHERE mailbox_sid = in_sid_id;
END;

PROCEDURE deleteObject(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_sid_id						IN	security.security_pkg.T_SID_ID
)
AS
BEGIN	
	-- Clean the messages themselves
	DELETE FROM account_message
	 WHERE mailbox_sid = in_sid_id;	

	DELETE FROM mailbox_message
	 WHERE mailbox_sid = in_sid_id;	

	DELETE FROM expunged_message
	 WHERE mailbox_sid = in_sid_id;

	-- Delete the mailbox itself
	DELETE FROM account_mailbox
	 WHERE mailbox_sid = in_sid_id;

	DELETE FROM mailbox
	 WHERE mailbox_sid = in_sid_id;
END;

PROCEDURE moveObject(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_sid_id						IN	security.security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security.security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE mailbox
	   SET parent_sid = in_new_parent_sid_id
	 WHERE mailbox_sid = in_sid_id;
END;

PROCEDURE createMailbox(
	in_parent_sid_id				IN	mailbox.mailbox_sid%TYPE, -- the securable object id
	in_name							IN	mailbox.mailbox_name%TYPE,
	in_account_sid 					IN  account.account_sid%TYPE DEFAULT NULL, -- if null works it out
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	createMailboxWithClass(
		in_parent_sid_id				=>	in_parent_sid_id,
		in_name							=>	in_name,
		in_account_sid 					=>	in_account_sid,
		in_class_id						=>	security.class_pkg.getClassId('Mailbox'),
		out_mailbox_sid					=>	out_mailbox_sid
	);
END;

PROCEDURE createMailboxWithClass(
	in_parent_sid_id				IN	mailbox.mailbox_sid%TYPE, -- the securable object id
	in_name							IN	mailbox.mailbox_name%TYPE,
	in_account_sid 					IN  account.account_sid%TYPE DEFAULT NULL, -- if null works it out
	in_class_id						IN	NUMBER DEFAULT NULL, -- If null, uses 'Mailbox'
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE
)
AS
	v_folders_sid					security.security_pkg.T_SID_ID;
	v_account_sid					security.security_pkg.T_SID_ID;
	v_parent_sid					security.security_pkg.T_SID_ID;
	v_class_id						NUMBER;
BEGIN
	-- as a special case, if we are creating under /Mail/Folders then stuff "null" in for parent sid
	-- this stops the mailbox code from walking up the mailbox tree into security
	v_folders_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), security.security_pkg.SID_ROOT, '/Mail/Folders');
	IF in_parent_sid_id = v_folders_sid THEN
		v_parent_sid := NULL;
	ELSE
		v_parent_sid := in_parent_sid_id;
	END IF;
	
	IF in_class_id IS NULL THEN
		v_class_id := security.class_pkg.getClassId('Mailbox');
	ELSE
		v_class_id := in_class_id;
	END IF;
	security.securableObject_pkg.createSO(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid_id, v_class_id, in_name, out_mailbox_sid);

	-- Create the mailbox
	INSERT INTO mailbox
		(mailbox_sid, parent_sid, mailbox_name, last_message_uid)
	VALUES
		(out_mailbox_sid, v_parent_sid, in_name, 0);

	-- Create an index on it
	IF in_account_sid IS NULL THEN
		v_account_sid := mail_pkg.getAccountFromMailbox(in_parent_sid_id);
	ELSE
		v_account_sid := in_account_sid;
	END IF;
END;

PROCEDURE purgeMailboxMessages(
	in_mailbox_sid					IN 	mailbox.mailbox_sid%TYPE,
	in_expire_after_days			IN	NUMBER
)
IS
	v_dtm			DATE;	
	v_modseq		mailbox.modseq%TYPE;
	v_min_uid		mailbox_message.message_uid%TYPE;
	v_max_uid		mailbox_message.message_uid%TYPE;
BEGIN
	-- Add a delete job for the message, if required
	UPDATE mailbox
	   SET modseq = modseq + 1
	 WHERE mailbox_sid = in_mailbox_sid
	 	   RETURNING modseq INTO v_modseq;

	INSERT INTO expunged_message (mailbox_sid, modseq, min_uid, max_uid)
		SELECT in_mailbox_sid, v_modseq, MIN(message_uid) min_uid, MAX(message_uid) max_uid 
		  FROM (SELECT message_uid, MAX(grp) OVER (ORDER BY message_uid ROWS UNBOUNDED PRECEDING) grp
				  FROM (SELECT mm.message_uid, 
				  			   CASE
								   WHEN mm.message_uid - LAG(mm.message_uid) OVER (ORDER BY mm.message_uid) <= 1 THEN NULL 
								   ELSE ROW_NUMBER() OVER (ORDER BY mm.message_uid)
								END grp 
				  		  FROM mailbox_message mm, message m
						 WHERE mm.mailbox_sid = in_mailbox_sid
						   AND mm.message_id = m.message_id
						   AND m.message_dtm < v_dtm))
		 GROUP BY grp;

	DELETE FROM account_message
	 WHERE mailbox_sid = in_mailbox_sid
	   AND message_uid IN (SELECT mm.message_uid
	   						 FROM mailbox_message mm, message m
	   						WHERE mm.mailbox_sid = in_mailbox_sid
							  AND mm.message_id = m.message_id
						      AND m.message_dtm < v_dtm);
	
	DELETE FROM mailbox_message
	 WHERE mailbox_sid = in_mailbox_sid
	   AND message_uid IN (SELECT mm.message_uid
	   						 FROM mailbox_message mm, message m
	   						WHERE mm.mailbox_sid = in_mailbox_sid
							  AND mm.message_id = m.message_id
						      AND m.message_dtm < v_dtm);

	COMMIT;
END;

PROCEDURE getMessage(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mailbox_message.message_uid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security.security_pkg.isAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_mailbox_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the mailbox with sid '||in_mailbox_sid);
	END IF;
	OPEN out_cur FOR
		SELECT mm.flags, m.subject, m.message_dtm, m.message_id_hdr, m.in_reply_to,
			   m.priority, m.has_attachments, mm.received_dtm, m.body
		  FROM mailbox_message mm, message m
		 WHERE mm.mailbox_sid = in_mailbox_sid
		   AND mm.message_uid = in_message_uid
		   AND mm.message_id = m.message_id;
END;

END mailbox_pkg;
/

CREATE OR REPLACE PACKAGE BODY MAIL.smtp_pkg
AS

PROCEDURE authPlain(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	out_inbox_sid					OUT	account.inbox_sid%TYPE
)
AS
	v_salt			account.password_salt%TYPE;
	v_password		account.password%TYPE;
	v_inbox_sid		account.inbox_sid%TYPE;
BEGIN
	-- Set the default output
	out_inbox_sid := -1;
	BEGIN
		-- Get account details
		SELECT password_salt, password, inbox_sid
	  	  INTO v_salt, v_password, v_inbox_sid
		  FROM account
		 WHERE LOWER(email_address) = LOWER(in_email_address);
		-- Check password
		IF mail_pkg.hashPassword(v_salt, in_password) = NVL(v_password,'NOCHANCE') THEN
			out_inbox_sid := v_inbox_sid;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE vrfy(
	in_email_address				IN 	mailbox.mailbox_name%TYPE,
	out_inbox_sid					OUT mailbox.mailbox_sid%TYPE
)
IS
	BEGIN
		SELECT a.inbox_sid 
		  INTO out_inbox_sid
		  FROM account_alias aa, account a
		 WHERE LOWER(in_email_address) = LOWER(aa.email_address)
		   AND aa.account_sid = a.account_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_inbox_sid := -1;
END;

PROCEDURE deliver_CreateMessage(
	in_flags						IN	mailbox_message.flags%TYPE,
	out_body						OUT	message.body%TYPE
)
IS
BEGIN
	-- possible 2nd delivery attempt in the same transaction
	DELETE FROM temp_message;
	DELETE FROM temp_message_address_field;
	DELETE FROM temp_message_header;

	-- insert the message
	INSERT INTO temp_message (
		flags,
		body
	) VALUES (
		in_flags,
		EMPTY_BLOB()
	) RETURNING body
	  INTO out_body;
END;

PROCEDURE deliver_CreateMessage(
	out_body						OUT	message.body%TYPE
)
AS
BEGIN
	deliver_CreateMessage(0, out_body);
END;

PROCEDURE deliver_SetMessageDetails(
	in_subject						IN	message.subject%TYPE,
	in_message_dtm					IN	message.message_dtm%TYPE,
	in_message_id_hdr				IN	message.message_id_hdr%TYPE,
	in_in_reply_to					IN	message.in_reply_to%TYPE,
	in_priority						IN	message.priority%TYPE,
	in_has_attachments				IN	message.has_attachments%TYPE
)
IS
BEGIN
	UPDATE temp_message
	   SET subject = in_subject,
	       message_dtm = in_message_dtm,
	       message_id_hdr = in_message_id_hdr,
	       in_reply_to = in_in_reply_to,
	       priority = in_priority,
	       has_attachments = in_has_attachments;
END;

PROCEDURE deliver_AddMessageAddress(
	in_field_id 					IN	message_address_field.field_id%TYPE,
	in_position						IN	message_address_field.position%TYPE,
	in_address						IN	message_address_field.address%TYPE,
	in_name							IN	message_address_field.name%TYPE
)
IS
BEGIN
	INSERT INTO temp_message_address_field (field_id, position, address, name)
	VALUES (in_field_id, in_position, in_address, in_name);
END;

PROCEDURE deliver_AddMessageHeader(
	in_position						IN	message_header.position%TYPE,
	in_name							IN	message_header.name%TYPE,
	in_value						IN	message_header.value%TYPE
)
IS
BEGIN
	INSERT INTO temp_message_header (position, name, value)
	VALUES (in_position, in_name, in_value);
END;
	
PROCEDURE filterMessage(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	out_dest_mailbox_sid			OUT	mailbox_message.mailbox_sid%TYPE,
	out_action						OUT	VARCHAR2
)
AS
	v_account_sid					account.account_sid%TYPE;
	v_matched						BOOLEAN;
	v_like_expr						VARCHAR2(4000);
	v_match_count					NUMBER;
	v_new_message_uid				mailbox_message.message_uid%TYPE;
BEGIN
	-- by default, the message stays where it is
	out_action := 'none';

	-- find the id from the mailbox
	BEGIN
		v_account_sid := mail_pkg.getAccountFromMailbox(in_mailbox_sid);
	EXCEPTION
		-- this shouldn't happen, but let's not fail if it does...
		WHEN mail_pkg.MAILBOX_NOT_FOUND THEN
			RETURN;
	END;
	--security_pkg.debugmsg('account id '||v_account_sid||' checking '||in_mailbox_sid||'.'||in_message_uid);
	
	-- check each filter in priority order
	FOR r IN (SELECT message_filter_id, description, match_type, to_mailbox_sid, matched_action
			    FROM message_filter
			   WHERE account_sid = v_account_sid
			     AND ((matched_action IN ('move', 'copy') AND to_mailbox_sid IS NOT NULL) OR 
			     	  matched_action = 'delete')
			   ORDER BY pos) LOOP

		-- check each filter entry (in any order)
		-- for "any" we assume false then set matched=true and stop if we encounter a match
		-- for "all" we assume true then set matched=false and stop if we encounter a non-match
		v_matched := CASE r.match_type WHEN 'any' THEN FALSE ELSE TRUE END;
		FOR s IN (SELECT header, match_value, match_type
					FROM message_filter_entry
				   WHERE message_filter_id = r.message_filter_id) LOOP

			v_like_expr := 
				CASE 
					WHEN s.match_type IN ('is', 'is not') THEN REPLACE(s.match_value, '\', '\\')
					WHEN s.match_type = 'starts' THEN REPLACE(s.match_value, '\', '\\')||'%'
					WHEN s.match_type = 'ends' THEN '%'||REPLACE(s.match_value, '\', '\\')
					WHEN s.match_type IN ('in', 'not in') THEN '%'||REPLACE(s.match_value, '\', '\\')||'%' 
					ELSE s.match_value
				END;

			IF s.match_type IN ('regexp', 'not regexp') THEN
				SELECT COUNT(*)
				  INTO v_match_count
				  FROM temp_message_header
				 WHERE LOWER(name) = LOWER(s.header) AND REGEXP_LIKE(value, v_like_expr, 'i');
			ELSE
				SELECT COUNT(*)
				  INTO v_match_count
				  FROM temp_message_header
				 WHERE LOWER(name) = LOWER(s.header) AND LOWER(value) LIKE LOWER(v_like_expr) ESCAPE '\';
			END IF;
						   
			--security_pkg.debugmsg('account id '||v_account_sid||' filter '||r.description||'('||r.message_filter_id||', matching '||
			--	r.match_type||' rules): '||s.header||' '||s.match_type||' LIKE '''||v_like_expr||''' count='||v_match_count);

			-- positive matches => count != 0 for a match, negative matches => count = 0 for a match
			IF (s.match_type IN ('is', 'starts', 'ends', 'in', 'regexp') AND v_match_count != 0) OR 
			   (s.match_type IN ('is not', 'not in', 'not regexp') AND v_match_count = 0) THEN
				-- if matching any, we have matched so we are done
				IF r.match_type = 'any' THEN
					v_matched := TRUE;
					EXIT;
				END IF;
			ELSE
				-- if matching all, we have not matched so we are done
				IF r.match_type = 'all' THEN
					v_matched := FALSE;
					EXIT;
				END IF;
			END IF;
		END LOOP;
		
		-- if we matched, set the destination mailbox (if any) and stop filtering
		IF v_matched THEN
			out_action := r.matched_action;
			IF r.matched_action IN ('copy', 'move') THEN
				out_dest_mailbox_sid := r.to_mailbox_sid;
			END IF;
			EXIT;
		END IF;
	END LOOP;
END;

PROCEDURE doInsert(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	out_message_uid					OUT	mailbox_message.message_uid%TYPE
)
AS
	v_modseq						mailbox_message.modseq%TYPE;
	v_sha512						message.sha512%TYPE;
	v_message_id					message.message_id%TYPE;
	v_is_new						BOOLEAN;
BEGIN
	SELECT mail.sha512(body)
	  INTO v_sha512
	  FROM temp_message;

	SELECT MIN(message_id)
	  INTO v_message_id
	  FROM message
	 WHERE sha512 = v_sha512;

	IF v_message_id IS NULL THEN
		SELECT message_id_seq.nextval
		  INTO v_message_id
		  FROM DUAL;

		BEGIN
			INSERT INTO message (message_id, subject, message_dtm, message_id_hdr, in_reply_to,
				priority, has_attachments, body, sha512)
				SELECT v_message_id, subject, message_dtm, message_id_hdr, in_reply_to,
					   priority, has_attachments, body, v_sha512
				  FROM temp_message;
			v_is_new := TRUE;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				SELECT message_id
				  INTO v_message_id
				  FROM message
				 WHERE sha512 = v_sha512;
		END;

		IF v_is_new THEN
			INSERT INTO message_header (message_id, position, name, value)
				SELECT v_message_id, position, name, value
				  FROM temp_message_header;
	
			INSERT INTO message_address_field (message_id, field_id, position, address, name)
				SELECT v_message_id, field_id, position, address, name
				  FROM temp_message_address_field;
		END IF;
	END IF;

	UPDATE mailbox
	   SET last_message_uid = last_message_uid + 1, modseq = modseq + 1
	 WHERE mailbox_sid = in_mailbox_sid
	   	   RETURNING last_message_uid, modseq INTO out_message_uid, v_modseq;

	/*FOR r in (SELECT * from temp_message) LOOP
		security.security_pkg.debugmsg('appedning '||out_message_uid||' with date '||r.received_dtm);
	end loop;*/

	INSERT INTO mailbox_message (mailbox_sid, message_uid, message_id, flags, received_dtm, modseq)
		SELECT in_mailbox_sid, out_message_uid, v_message_id, flags, received_dtm, v_modseq
		  FROM temp_message;		  
END;

FUNCTION duplicateCount(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	in_message_id_hdr				IN	message.message_id_hdr%TYPE
)
RETURN NUMBER
AS
	v_dup_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_dup_count
	  FROM mailbox mb, mailbox_message mm, message m
	 WHERE mb.mailbox_sid = in_mailbox_sid
	   AND mb.filter_duplicate_message_id = 1
	   AND mb.mailbox_sid = mm.mailbox_sid
	   AND mm.message_id = m.message_id
	   AND m.message_id_hdr = in_message_id_hdr;
	RETURN v_dup_count;
END;

PROCEDURE deliver_Complete(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE
)
AS
	v_new_message_uid				mailbox_message.message_uid%TYPE;
BEGIN
	deliver_Complete(in_mailbox_sid, v_new_message_uid);
	COMMIT;
END;

PROCEDURE deliver_Complete(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	out_message_uid					OUT	mailbox_message.message_uid%TYPE
)
AS
	v_new_mailbox_sid				mailbox_message.mailbox_sid%TYPE;
	v_action						VARCHAR2(10);
	v_message_id_hdr				message.message_id_hdr%TYPE;
BEGIN
	-- apply any server side filtering rules
	filterMessage(in_mailbox_sid, v_new_mailbox_sid, v_action);
	--security_pkg.debugmsg('in='||in_mailbox_sid||'.'||in_message_uid||', result='||v_action);

	-- grab the message id header for de-duplication
	SELECT message_id_hdr
	  INTO v_message_id_hdr
	  FROM temp_message;
 
	-- de-duplicate if needed, rules for this:
	-- a) normal delivery, de-duplicate inbox
	-- b) copy, de-duplicate inbox + copy to mailbox
	-- c) move, de-duplicate move to mailbox
	-- d) delete, do nothing
	IF v_action = 'none' THEN
		IF NOT duplicateCount(in_mailbox_sid, v_message_id_hdr) > 1 THEN
			-- mail can be added normally, so deliver
			doInsert(in_mailbox_sid, out_message_uid);
		END IF;
	ELSIF v_action = 'copy' THEN
		-- copy if not a duplicate
		IF NOT duplicateCount(v_new_mailbox_sid, v_message_id_hdr) > 0 THEN
			doInsert(v_new_mailbox_sid, out_message_uid);
		END IF;

		-- insert if not a duplicate		
		IF NOT duplicateCount(in_mailbox_sid, v_message_id_hdr) > 1 THEN
			doInsert(v_new_mailbox_sid, out_message_uid);
		END IF;
	ELSIF v_action = 'move' THEN
		-- if it's a duplicate in the destination then just discard it
		IF NOT duplicateCount(v_new_mailbox_sid, v_message_id_hdr) > 0 THEN
			doInsert(v_new_mailbox_sid, out_message_uid);
		END IF;
	ELSIF v_action = 'delete' THEN
		-- nothing to do
		NULL;
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter action: '||v_action);
	END IF;
END;

END smtp_pkg;
/
