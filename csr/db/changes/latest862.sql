-- Please update version.sql too -- this keeps clean builds in sync
define version=862
@update_header

CREATE OR REPLACE VIEW csr.v$user_flow_item AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, fi.current_state_id, fi.current_state_label,
           fi.survey_response_id, fi.dashboard_instance_id
      FROM v$flow_item fi
     WHERE (fi.app_sid, fi.current_state_id) IN (
     		SELECT fsr.app_sid, fsr.flow_state_id
     		  FROM flow_state_role fsr 
      		  JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
      		  JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid 
     		 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID'));
 
@../flow_pkg
@../flow_body

@update_tail
