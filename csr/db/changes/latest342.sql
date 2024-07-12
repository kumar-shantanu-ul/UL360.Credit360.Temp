-- Please update version.sql too -- this keeps clean builds in sync
define version=342
@update_header

INSERT INTO customer_alert_type (app_sid, alert_type_id) 
    SELECT DISTINCT app_sid, 20 FROM csr.customer_alert_type  WHERE app_sid NOT IN (
        SELECT app_sid FROM csr.customer_alert_type  WHERE alert_type_id = 20
    );

@update_tail
