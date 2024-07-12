-- Please update version.sql too -- this keeps clean builds in sync
define version=2094
@update_header

ALTER TABLE csr.calendar_event_invite 
		ADD (declined_dtm DATE);

ALTER TABLE csr.calendar_event_invite 
	 MODIFY (accepted_dtm DATE);

@update_tail
