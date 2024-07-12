-- Please update version.sql too -- this keeps clean builds in sync
define version=851
@update_header

CREATE OR REPLACE VIEW csr.delegation_delegator (app_sid, delegation_sid, delegator_sid) AS
	SELECT d.app_sid, d.delegation_sid, du.user_sid
	  FROM delegation d, v$delegation_user du
	 WHERE d.app_sid = du.app_sid AND d.parent_sid = du.delegation_sid;

@update_tail
