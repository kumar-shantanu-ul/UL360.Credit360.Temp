-- Please update version.sql too -- this keeps clean builds in sync
define version=2028
@update_header

	CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANSITION AS
    SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb, 
		fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
        tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
        fst.ask_for_comment, fst.pos transition_pos, fst.button_icon_path,
        fi.survey_response_id, fi.dashboard_instance_id -- these are deprecated
      FROM flow_item fi           
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
        JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
        JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid AND tfs.is_deleted = 0;

	CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANS_ROLE_MEMBER AS
    SELECT fit.*, r.role_sid, r.name role_name, rrm.region_sid
      FROM V$FLOW_ITEM_TRANSITION fit
        JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
        JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid 
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');
	 
@update_tail
