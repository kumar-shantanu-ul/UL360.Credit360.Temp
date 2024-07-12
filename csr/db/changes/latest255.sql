-- Please update version.sql too -- this keeps clean builds in sync
define version=255
@update_header

CREATE OR REPLACE VIEW DELEGATION_DELEGATOR
(APP_SID, DELEGATION_SID, DELEGATOR_SID) AS
SELECT d.APP_SID, d.DELEGATION_SID, du.USER_SID
FROM DELEGATION d, DELEGATION_USER du
WHERE d.app_sid = du.app_sid AND d.parent_sid = du.delegation_sid;

@..\delegation_body
    
@update_tail
