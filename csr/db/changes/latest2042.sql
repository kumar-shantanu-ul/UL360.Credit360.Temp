-- Please update version.sql too -- this keeps clean builds in sync
define version=2042
@update_header

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_SCHED_ALERT_RECIP_LOOKUP
(
	ID							NUMBER(10) NOT NULL,
	SID							NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;

@../chain/scheduled_alert_pkg
@../chain/scheduled_alert_body
 
@update_tail