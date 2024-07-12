-- Please update version.sql too -- this keeps clean builds in sync
define version=1642
@update_header

CREATE UNIQUE INDEX CHAIN.IX_UNIQUE_ACTIVE_GUID ON CHAIN.INVITATION(APP_SID, GUID, NVL2(REINVITATION_OF_INVITATION_ID, INVITATION_ID, 0))
;

@..\supplier_body

@update_tail
