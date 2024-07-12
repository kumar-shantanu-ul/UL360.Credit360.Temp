-- Please update version.sql too -- this keeps clean builds in sync
define version=2454
@update_header

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, f.label flow_label,
		fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
		fs.state_colour current_state_colour, 
        fi.survey_response_id, fi.dashboard_instance_id  -- deprecated
      FROM flow_item fi
	    JOIN flow f ON fi.flow_sid = f.flow_sid
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid 
    ;   

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid, fsr.is_editable
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;


@update_tail
