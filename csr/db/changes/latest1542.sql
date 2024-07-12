-- Please update version.sql too -- this keeps clean builds in sync
define version=1542
@update_header

/* text */
CREATE OR REPLACE VIEW csr.v$my_section AS
    SELECT s.section_sid, firm.current_state_id, MAX(firm.is_editable) is_editable, 'F' source
      FROM csr.v$flow_item_role_member firm
        JOIN csr.section s ON firm.flow_item_id = s.flow_item_id AND firm.app_sid = s.app_sid
        JOIN csr.section_module sm
            ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
            AND firm.region_sid = sm.region_sid AND firm.app_sid = sm.app_sid
     WHERE NOT EXISTS (
        -- exclude if sections are currently in a workflow state that is routed
        SELECT null FROM csr.section_routed_flow_state WHERE flow_state_id = firm.current_state_id
     )
     GROUP BY s.section_sid, firm.current_state_id
    UNION ALL
    -- everything where the section is currently in a workflow state that is routed, and the user is in the currently route_step
    SELECT s.section_sid, fi.current_state_id, 1 is_editable, 'R' source
      FROM csr.section s
        JOIN csr.flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
        JOIN csr.route r ON fi.current_state_id = r.flow_state_id AND fi.app_sid = r.app_sid
        JOIN csr.route_step rs
            ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
            AND s.current_route_step_id = rs.route_step_id AND s.app_sid = rs.app_sid
        JOIN csr.route_step_user rsu
            ON rs.route_step_id = rsu.route_step_id
            AND rs.app_sid = rsu.app_sid
            AND rsu.csr_user_sid = SYS_CONTEXT('SECURITY','SID');


@update_tail