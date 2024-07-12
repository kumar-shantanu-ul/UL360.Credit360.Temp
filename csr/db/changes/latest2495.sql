-- Please update version.sql too -- this keeps clean builds in sync
define version=2495
@update_header

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, f.label flow_label,
		fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
		fs.state_colour current_state_colour, 
		fi.last_flow_state_log_id, fi.last_flow_state_transition_id,
        fi.survey_response_id, fi.dashboard_instance_id  -- deprecated
      FROM flow_item fi
	    JOIN flow f ON fi.flow_sid = f.flow_sid
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid 
    ;   


-- View showing all items in workflow, all roles where the current user is a member, and all regions for those roles.
-- You never want to just select from this, i.e. you would want to join this view to a workflow item detail table
-- which would also have information about which region the workflow item was applicable to (which reduces the returned
-- rows significantly ;)). 
--
-- A typical usage would be:
--
--    SELECT firm.flow_sid, firm.flow_item_id, firm.current_state_id, 
--        firm.current_state_label, firm.role_sid, firm.role_name, fsr.is_editable,
--        r.region_sid, r.description region_description,
--        adi.dashboard_instance_id, adi.start_dtm, adi.end_dtm
--      FROM V$FLOW_ITEM_ROLE_MEMBER firm
--        JOIN approval_dashboard_instance adi ON firm.dashboard_instance_id = adi.dashboard_instance_id 
--        JOIN region r ON adi.region_sid = r.region_sid AND firm.region_sid = r.region_sid      
--     WHERE adi.approval_dashboard_sid = in_dashboard_sid
--	     AND start_dtm = in_start_dtm
--	     AND end_dtm = in_end_dtm
--	   ORDER BY transition_pos;
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid, fsr.is_editable
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;

@update_tail
