CREATE OR REPLACE PACKAGE BODY CSR.mailbox_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN

	mail.mailbox_pkg.CreateObject(
		in_act_id				=> in_act_id,
		in_sid_id				=> in_sid_id,
		in_class_id				=> in_class_id,
		in_name					=> in_name,
		in_parent_sid_id		=> in_parent_sid_id
	);

END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	mail.mailbox_pkg.RenameObject(
		in_act_id		=> in_act_id, 
		in_sid_id		=> in_sid_id,
		in_new_name		=> in_new_name
	);
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
BEGIN
	DELETE FROM csr.auto_imp_mail
	 WHERE mailbox_sid = in_sid_id;
	
	DELETE FROM csr.auto_imp_mail_attach_filter
	 WHERE mailbox_sid = in_sid_id;
	
	DELETE FROM csr.auto_imp_mail_subject_filter
	 WHERE mailbox_sid = in_sid_id;
	
	DELETE FROM csr.auto_imp_mail_sender_filter
	 WHERE mailbox_sid = in_sid_id;
	
	DELETE FROM csr.auto_imp_mailbox
	 WHERE mailbox_sid = in_sid_id;
	
	mail.mailbox_pkg.DeleteObject(
		in_act_id	=> in_act_id, 
		in_sid_id	=> in_sid_id
	);
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN

	mail.mailbox_pkg.MoveObject(
		in_act_id				=> in_act_id,
		in_sid_id				=> in_sid_id,
		in_new_parent_sid_id	=> in_new_parent_sid_id,
		in_old_parent_sid_id	=> in_old_parent_sid_id
	);

END;

PROCEDURE CreateCsrMailbox(
	in_email_address		IN	mail.account.email_address%TYPE,
	out_new_sid				OUT	mail.mailbox.mailbox_sid%TYPE
)
AS
	v_account_sid				mail.account.account_sid%TYPE;
	v_admins_sid				security_pkg.T_SID_ID;
BEGIN

		-- Create the mail account
	mail.mail_pkg.createAccount(
		in_email_address				=> in_email_address,
		in_password						=> NULL,
		in_description					=> '',
		in_for_outlook					=> 0,
		in_class_id						=> security.class_pkg.getClassId('CSRMailbox'),
		out_account_sid					=> v_account_sid,
		out_root_mailbox_sid			=> out_new_sid
	);
	
	-- Get hold of the host's adminstrators group sid
	v_admins_sid := securableobject_pkg.GetSidFromPath(
		security_pkg.getACT, 
		securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, 
			security_pkg.getAPP, 
			'Groups'
		), 
		'Administrators'
	);
	
	-- Set permissions on the root folder and propagate
	acl_pkg.AddACE(
		security_pkg.GetACT, 
		acl_pkg.GetDACLIDForSID(out_new_sid), 
		-1, 
		security_pkg.ACE_TYPE_ALLOW, 
		security_pkg.ACE_FLAG_DEFAULT, 
		v_admins_sid,
		security_pkg.PERMISSION_STANDARD_READ
	);
	
	acl_pkg.PropogateACEs(
		security_pkg.GetACT, 
		out_new_sid
	);

END;

END mailbox_pkg;
/
