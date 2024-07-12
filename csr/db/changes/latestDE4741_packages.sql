CREATE OR REPLACE PACKAGE CSR.TEMP_DE4741_PACKAGE IS

ERR_MAILBOX_NOT_FOUND				CONSTANT NUMBER := -20506;
MAILBOX_NOT_FOUND					EXCEPTION;
PRAGMA EXCEPTION_INIT(MAILBOX_NOT_FOUND, -20506);

FUNCTION getInboxSIDFromEmail(
	in_email_address				IN	VARCHAR2
) RETURN mail.account.inbox_sid%TYPE;

PROCEDURE MarkMessageAsUnread(
	in_mailbox_sid					IN	mail.mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mail.mailbox_message.message_uid%TYPE
);

END;
/


CREATE OR REPLACE PACKAGE BODY CSR.TEMP_DE4741_PACKAGE IS

FUNCTION getInboxSIDFromEmail(
	in_email_address				IN	VARCHAR2
) RETURN mail.account.inbox_sid%TYPE
AS
	v_inbox_sid mail.account.inbox_sid%TYPE;
BEGIN
	BEGIN
		SELECT a.inbox_sid
		  INTO v_inbox_sid
		  FROM mail.account_alias aa, mail.account a
		 WHERE LOWER(aa.email_address) = LOWER(in_email_address)
		   AND a.account_sid = aa.account_sid;
		 
		RETURN v_inbox_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE MAILBOX_NOT_FOUND;
	END;
END;

PROCEDURE MarkMessageAsUnread(
	in_mailbox_sid					IN	mail.mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mail.mailbox_message.message_uid%TYPE
)
AS
	v_modseq						mail.mailbox.modseq%TYPE;
BEGIN
	UPDATE mail.mailbox
	   SET modseq = modseq + 1
	 WHERE mailbox_sid = in_mailbox_sid
	 	   RETURNING modseq INTO v_modseq;
	 	   
	UPDATE mail.mailbox_message
	   SET modseq = v_modseq, flags = security.bitwise_pkg.bitand(flags, security.bitwise_pkg.bitnot(4 /*mail_pkg.Flag_Seen*/))
	 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid
	   AND bitand(flags, 4 /*mail_pkg.Flag_Seen*/) != 0;
END;

END;
/
