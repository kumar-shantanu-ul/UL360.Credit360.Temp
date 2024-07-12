CREATE OR REPLACE PACKAGE BODY CSR.site_name_management_pkg IS

-- Based on the old util/renameSite.sql. Changed to work on the logged in site and tidied.
PROCEDURE RenameSite(
	in_to_host			IN	csr.customer.host%TYPE
)
AS
	v_to_host				csr.customer.host%TYPE := in_to_host;
	v_from_host				csr.customer.host%TYPE;
	v_swap_host				csr.customer.host%TYPE;
	v_from_email 			csr.customer.system_mail_address%TYPE;
	v_to_email				csr.customer.system_mail_address%TYPE;
	v_from_tracker_email 	csr.customer.tracker_mail_address%TYPE;
	v_to_tracker_email		csr.customer.tracker_mail_address%TYPE;
	v_from_app_sid			security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_to_app_sid			security.security_pkg.T_SID_ID;
	v_is_in_customer		INTEGER;
	v_mail_sid				security.security_pkg.T_SID_ID;
BEGIN

	SELECT host
	  INTO v_from_host
	  FROM csr.customer
	 WHERE app_sid = v_from_app_sid;
	
	BEGIN
		SELECT application_sid_id 
		  INTO v_to_app_sid
		  FROM security.website
		 WHERE UPPER(website_name) = UPPER(v_to_host);
	EXCEPTION
		WHEN no_data_found THEN
			v_to_app_sid := NULL;
	END;

	IF v_to_app_sid = v_from_app_sid THEN
		BEGIN
			SELECT sid_id 
			  INTO v_to_app_sid
			  FROM security.securable_object
			 WHERE link_sid_id = v_from_app_sid
			   AND LOWER(name) = LOWER(v_to_host);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_swap_host := v_from_host;
				v_from_host := v_to_host;
				v_to_host := v_swap_host;
				
				SELECT sid_id 
				  INTO v_to_app_sid
				  FROM security.securable_object
				 WHERE link_sid_id = v_from_app_sid
				   AND LOWER(name) = LOWER(v_to_host);
		END;
		   
		UPDATE security.securable_object
		   SET name = NULL
		 WHERE sid_id = v_to_app_sid;
		 
		UPDATE security.website
		   SET website_name = TO_CHAR(v_to_app_sid)
		 WHERE website_name = v_to_host;
	ELSIF v_to_app_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Website ' || v_to_host || ' already exists and is not a soft link');
	END IF;

	-- rename the app object iteself
	security.securableobject_pkg.renameSO(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'), 
		in_sid_id		=> SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_name	=> v_to_host
	);
	
	-- slightly horrid code to fix up attributes
	UPDATE aspen2.application
	   SET metadata_connection_string = REPLACE(metadata_connection_string, v_from_host, v_to_host),
	   	   menu_path = REPLACE(menu_path, v_from_host, v_to_host),
	   	   commerce_store_path = REPLACE(commerce_store_path, v_from_host, v_to_host),
		   logon_url = REPLACE(logon_url, v_from_host, v_to_host)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- fix up the website table
	UPDATE security.website 
	   SET website_name = v_to_host 
	 WHERE website_name = v_from_host;
	 
	UPDATE security.home_page 
	   SET created_by_host = v_to_host 
	 WHERE created_by_host = v_from_host;

	-- skip some stuff if it's an old site with an entry in security.website but not in csr.customer
	SELECT COUNT(*)
	  INTO v_is_in_customer
	  FROM csr.customer
	 WHERE host = v_from_host;

	IF v_is_in_customer > 0 THEN
		-- feeble attempt to update the name (just in case it's the host)
		UPDATE csr.customer 
		   SET name = v_to_host
		 WHERE name = v_from_host
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		-- figure out name of new system and tracker mail accounts
		-- .credit360.com = 14 chars
		IF LOWER(SUBSTR(v_to_host, LENGTH(v_to_host)-13,14)) = '.credit360.com' THEN
			-- a standard foo.credit360.com
			v_to_email := SUBSTR(v_to_host, 1, LENGTH(v_to_host)-14)||'@credit360.com';
			v_to_tracker_email := SUBSTR(v_to_host, 1, LENGTH(v_to_host)-14)||'_tracker@credit360.com';
		ELSE
			-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
			v_to_email := v_to_host||'@credit360.com';
			v_to_tracker_email := v_to_host||'_tracker@credit360.com';
		END IF;

		-- rename mail accounts
		SELECT system_mail_address, tracker_mail_address 
		  INTO v_from_email, v_from_tracker_email 
		  FROM csr.customer 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		v_mail_sid := mail.mail_pkg.getMailboxSIDFromPath(
			in_parent_sid	=> NULL, 
			in_path			=> v_from_email
		);
		mail.mail_pkg.renameAccount(
			in_account_sid			=> mail.mail_pkg.getAccountFromMailbox(in_mailbox_sid => v_mail_sid), 
			in_new_email_address	=> v_to_email
		);
		
		v_mail_sid := mail.mail_pkg.getMailboxSIDFromPath(
			in_parent_sid	=> NULL, 
			in_path			=> v_from_tracker_email
		);
		mail.mail_pkg.renameAccount(
			in_account_sid			=> mail.mail_pkg.getAccountFromMailbox(in_mailbox_sid => v_mail_sid), 
			in_new_email_address	=> v_to_tracker_email);

		-- fix up the csr.customer table
		UPDATE csr.customer 
		   SET host = v_to_host,
			   system_mail_address = v_to_email,
			   tracker_mail_address = v_to_tracker_email
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;

	IF v_to_app_sid IS NOT NULL THEN
		UPDATE security.website
		   SET website_name = v_from_host
		 WHERE website_name = TO_CHAR(v_to_app_sid);
		 
		UPDATE security.securable_object
		   SET name = v_from_host
		 WHERE sid_id = v_to_app_sid;
	 END IF;
END;

PROCEDURE GetSoftlinks(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_base_site_name	csr.customer.host%type;
BEGIN

	SELECT host
	  INTO v_base_site_name
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur FOR
		SELECT website_name
		  FROM security.website
		 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(website_name) != LOWER(v_base_site_name)
		 ORDER BY LOWER(website_name) ASC;

END;

PROCEDURE CreateSoftLink(
	in_softlink_name	IN	csr.customer.host%TYPE
)
AS
	v_act				security.security_pkg.t_act_id;
	v_app_sid			security.security_pkg.t_sid_id;
	v_app_name			varchar2(100);
begin

	SELECT host
	  INTO v_app_name
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 333333, v_act);
	v_app_sid := security.SecurableObject_pkg.GetSIDFromPath(
		in_act				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_parent_sid_id	=> 0,
		in_path				=> '//Aspen/Applications/' || v_app_name
	);

	security.softlink_pkg.CreateWebsiteSoftlink(
		in_act				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_name			=> v_app_name,
		in_softlink_name	=> in_softlink_name
	);

END;

PROCEDURE DeleteSoftLink(
	in_softlink_name	IN	csr.customer.host%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	
	BEGIN
		security.softlink_pkg.DeleteWebsiteSoftlink(
			in_app_sid			=> v_app_sid,
			in_softlink_name	=> in_softlink_name
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Softlink "' || in_softlink_name || '" could not be found');
	END;
	
END;

END site_name_management_pkg;
/
