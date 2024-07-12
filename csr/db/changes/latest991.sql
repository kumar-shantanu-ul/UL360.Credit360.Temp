-- Please update version.sql too -- this keeps clean builds in sync
define version=991
@update_header

GRANT SELECT ON security.group_members TO csr WITH GRANT OPTION;

CREATE OR REPLACE VIEW csr.v$user_flow_item AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, fi.current_state_id, fi.current_state_label,
           fi.survey_response_id, fi.dashboard_instance_id
      FROM v$flow_item fi
     WHERE (fi.app_sid, fi.current_state_id) IN (
     		SELECT fsr.app_sid, fsr.flow_state_id
     		  FROM flow_state_role fsr 
      		  JOIN (SELECT group_sid_id
					  FROM security.group_members 
						   START WITH member_sid_id = SYS_CONTEXT('SECURITY','SID')
						   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id) g
				ON g.group_sid_id = fsr.role_sid);     		 

@update_tail
