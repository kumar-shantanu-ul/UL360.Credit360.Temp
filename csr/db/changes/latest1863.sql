-- Please update version.sql too -- this keeps clean builds in sync
define version=1863
@update_header

ALTER TABLE csrimp.flow_transition_alert_role
 DROP PRIMARY KEY CASCADE DROP INDEX;

  ALTER TABLE csrimp.flow_transition_alert_role
    ADD CONSTRAINT pk_flow_transition_alert_role
       PRIMARY KEY (csrimp_session_id, flow_transition_alert_id, role_sid);

@../csrimp/imp_body

@update_tail
