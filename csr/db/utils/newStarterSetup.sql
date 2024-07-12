PROMPT please enter parameters: username(1), password(2), full name(3), friendly name(4), email address(5), team(6), host(7), link(8), super admin(9)
prompt
prompt Team:
PROMPT >>>	0 - Account Managers
PROMPT >>>	1 - Implementation
PROMPT >>>	2 - Support
PROMPT >>>	3 - Technical (Dev, Support, Infrastructure)
PROMPT >>>	4 - Management
PROMPT >>>	5 - Sales (Business Development)
PROMPT >>>	6 - Administration
PROMPT >>>	7 - Marketing
PROMPT >>>	8 - Creative
PROMPT >>>	9 - Contractors
PROMPT >>> 10 - Project Managers
PROMPT >>> 11 - Product
PROMPT >>> 12 - Partnerships
PROMPT >>> 13 - HR
PROMPT >>> 14 - Finance
PROMPT >>> 15 - Service (John Whybrow)
PROMPT >>> 16 - Infrastructure
PROMPT >>> 17 - Service Managers (Previously a type of account manager)

PROMPT
PROMPT host is host name under which owl is set up, this defaults to www.credit360.com if left blank.
Prompt
Prompt link:
Prompt >>> Y - Link new user to an existing (orphan) email address.
Prompt >>> N - Create new email address for new user.
Prompt super admin:
Prompt >>> Y - Create super user
Prompt >>> N - Create credit360 user
Prompt
SET SERVEROUTPUT ON
DECLARE
	v_user				varchar2(30) := '&&1';
	v_pass				varchar2(30) := '&&2';
	v_full_name			varchar2(500) := '&&3';
	v_friendly_name		varchar2(500) := '&&4';
	v_email_address		varchar2(500) := '&&5';
	v_team_id			number := '&&6';
	v_owl_host			varchar2(60) := '&&7';
	v_link				varchar2(1) := UPPER('&&8');
	v_super				varchar2(1) := UPPER('&&9');
	v_account_sid		number;
	v_root_mailbox_sid	number;
	v_new_mailbox_sid	number;
	v_user_sid			number;
	v_temp				number;
	reply				boolean;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Will create user '|| v_user);
	--
	--
	security.user_pkg.logonadmin;
	--
	-- Verify valid team_id parameter
	IF v_team_id < 0 OR v_team_id > 17 THEN
		DBMS_OUTPUT.PUT_LINE('Team parameter must be between 0 and 17 but is ''' || v_team_id || '''.');
		RETURN;
	END IF;

	--
	-- Verify LINK parameter
	IF v_link NOT IN ('Y', 'N') THEN
		DBMS_OUTPUT.PUT_LINE('Link parameter must be ''Y'' or ''N'' but is ''' || v_link || '''.');
		RETURN;
	END IF;

	-- Verify LINK parameter
	IF v_super NOT IN ('Y', 'N') THEN
		DBMS_OUTPUT.PUT_LINE('Super Admin must be ''Y'' or ''N'' but is ''' || v_super || '''.');
		RETURN;
	END IF;

	BEGIN
		SELECT ma.account_sid, ma.root_mailbox_sid, mu.user_sid
		INTO v_account_sid, v_root_mailbox_sid, v_user_sid
		FROM mail.ACCOUNT ma
		LEFT JOIN mail.user_account mu ON mu.account_sid = ma.account_sid
		WHERE ma.email_address = v_email_address;
		IF v_user_sid IS NOT NULL THEN
			DBMS_OUTPUT.PUT_LINE('Email address ''' || v_email_address || ''' is already in use by another user.');
			RETURN;
		END IF;
		IF v_link = 'N' THEN
			DBMS_OUTPUT.PUT_LINE('Email address ''' || v_email_address || ''' has been created but not assigned to a user.');
			DBMS_OUTPUT.PUT_LINE('If you wish to use this email address for the new user then set the link parameter to ''Y''.');
			RETURN;
		END IF;
		DBMS_OUTPUT.PUT_LINE('Will linked to email account ' || v_email_address || '.');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF v_link = 'Y' THEN
				DBMS_OUTPUT.PUT_LINE('Email address ''' || v_email_address || ''' does not exist; set link parameter to ''N''.');
				RETURN;
			END IF;
			--
			-- Create new email account
			mail.mail_pkg.createaccount(v_email_address, v_pass, v_full_name, 1, v_account_sid, v_root_mailbox_sid);
			DBMS_OUTPUT.PUT_LINE('Email account ' || v_email_address || ' created.');
	END;

	IF v_owl_host IS NULL THEN
		v_owl_host := 'www.credit360.com';
	END IF;

	security.user_pkg.logonadmin(v_owl_host);

	IF v_super = 'Y' THEN
		--
		-- Create super user
		csr.csr_user_pkg.createSuperAdmin(SYS_CONTEXT('security', 'act'), v_user, v_pass, v_full_name, v_friendly_name, v_email_address, v_user_sid);
		--
		-- Give superadmin permissions on email account
		security.acl_pkg.AddACE(security.security_pkg.getact, security.acl_pkg.GetDACLIDForSID(v_account_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL);

		-- Give superadmin permissions on the folders
		security.acl_pkg.AddACE(security.security_pkg.getact, security.acl_pkg.GetDACLIDForSID(v_root_mailbox_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL);
	ELSE
		--
		-- Create www.credit360.com user
		csr.csr_user_pkg.CreateUser(
				in_act						=> SYS_CONTEXT('SECURITY','ACT'),
				in_app_sid					=> SYS_CONTEXT('SECURITY','APP'),
				in_user_name				=> v_user,
				in_password					=> v_pass,
				in_full_name				=> v_full_name,
				in_friendly_name			=> v_friendly_name,
				in_email					=> v_email_address,
				in_job_title				=> NULL,
				in_phone_number				=> NULL,
				in_info_xml					=> NULL,
				in_send_alerts				=> 1,
				in_enable_aria				=> 0,
				in_line_manager_sid			=> NULL,
				out_user_sid				=> v_user_sid
			);
	END IF;

	--
	-- Link user to mail (either existing mail or new mail)
	INSERT INTO mail.user_account (user_sid, account_sid)
	VALUES (v_user_sid, v_account_sid);

	--
	-- Link to shared folders
	BEGIN
		SELECT 1 INTO v_temp FROM mail.mailbox
		WHERE  mailbox_sid = 12081660 AND mailbox_name = 'shared folders';

		mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Clients (Shared)', v_new_mailbox_sid);
		UPDATE mail.mailbox
		   SET link_to_mailbox_sid = 10443860
		 WHERE mailbox_sid = v_new_mailbox_sid;


		mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'New Things (Shared)', v_new_mailbox_sid);
		UPDATE mail.mailbox
		   SET link_to_mailbox_sid = 12445927
		 WHERE mailbox_sid = v_new_mailbox_sid;

		IF v_team_id = 7 THEN
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Marketing (Shared)', v_new_mailbox_sid);
			UPDATE mail.mailbox
			   SET link_to_mailbox_sid = 11859839
			 WHERE mailbox_sid = v_new_mailbox_sid;
		END IF;

		IF v_team_id IN (1, 3) THEN
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Dev (Shared)', v_new_mailbox_sid);
			UPDATE mail.mailbox
			   SET link_to_mailbox_sid = 10443903
			 WHERE mailbox_sid = v_new_mailbox_sid;
		END IF;

		IF v_team_id = 3 THEN
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Technical Support (Shared)', v_new_mailbox_sid);
			UPDATE mail.mailbox
			   SET link_to_mailbox_sid = 16726160
			 WHERE mailbox_sid = v_new_mailbox_sid;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('Shared folders don''t exist on this system.');
			DBMS_OUTPUT.PUT_LINE('Skipping creation of shared folder links for new user.');
	END;

	-- Create an OWL account for timesheets etc
	owl.user_pkg.CreateEmployee(v_user_sid, v_team_id, v_email_address, v_full_name);

	DBMS_OUTPUT.PUT_LINE('User ' || v_user || ' created successfully.');
END;
/

-- Allow multiple runs for different new users without having to log out and back in
UNDEFINE 1 2 3 4 5 6 7 8 9

