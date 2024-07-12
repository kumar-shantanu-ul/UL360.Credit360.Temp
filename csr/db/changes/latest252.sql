-- Please update version.sql too -- this keeps clean builds in sync
define version=252
@update_header

CREATE INDEX IDX_ALERT_SENT_TYPE ON ALERT(SENT_DTM, ALERT_TYPE_ID)
TABLESPACE INDX
;

@..\alert_body
    
@update_tail
