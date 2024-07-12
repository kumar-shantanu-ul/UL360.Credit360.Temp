-- Please update version.sql too -- this keeps clean builds in sync
define version=1964
@update_header

CREATE OR REPLACE VIEW CSR.V$USER_MSG AS
	SELECT um.user_msg_id, um.user_sid, cu.full_name, cu.email, um.msg_dtm, um.msg_text, um.reply_to_msg_id
	  FROM user_msg um 
	  JOIN csr_user cu ON um.user_sid = cu.csr_user_sid AND um.app_sid = cu.app_sid;

@update_tail