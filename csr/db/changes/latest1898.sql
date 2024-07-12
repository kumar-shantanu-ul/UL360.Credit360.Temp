-- Please update version.sql too -- this keeps clean builds in sync
define version=1898
@update_header

CREATE INDEX CSR.IX_RRM_USER ON CSR.REGION_ROLE_MEMBER(APP_SID, USER_SID);

@../region_body

@update_tail
