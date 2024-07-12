define version=64
@update_header

ALTER TABLE CHAIN.ACTION_TYPE
 ADD (CSS_CLASS  VARCHAR2(32 BYTE));

ALTER TABLE CHAIN.EVENT_TYPE
 ADD (CSS_CLASS  VARCHAR2(32 BYTE));

@latest64_views
@..\action_pkg
@..\event_pkg
@..\action_body
@..\event_body
 
@update_tail