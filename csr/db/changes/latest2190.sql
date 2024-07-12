-- Please update version.sql too -- this keeps clean builds in sync
define version=2190
@update_header

INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (13, 'audit', 'View audit scores', 1, 0);

INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
SELECT fs.app_sid, csr.FLOW_STATE_RL_CAP_ID_SEQ.nextval, fs.flow_state_id, 13, fx.role_sid, fx.flow_involvement_type_id, 2
  FROM csr.flow_state fs
  JOIN (
    SELECT flow_state_id, role_sid, null flow_involvement_type_id, app_sid
      FROM csr.flow_state_role fsr
     UNION
    SELECT flow_state_id, null, flow_involvement_type_id, app_sid
      FROM csr.flow_state_involvement fsi
  ) fx ON fx.flow_state_id = fs.flow_state_id AND fx.app_sid = fs.app_sid
 WHERE EXISTS (
    SELECT *
      FROM csr.flow_state_role_capability fsrc
     WHERE fsrc.flow_state_id = fs.flow_state_id
       AND fsrc.app_sid = fs.app_sid
       AND fsrc.flow_capability_id != 13
 ) AND NOT EXISTS (
    SELECT *
      FROM csr.flow_state_role_capability fsrc
     WHERE fsrc.flow_state_id = fs.flow_state_id
       AND fsrc.app_sid = fs.app_sid
       AND fsrc.flow_capability_id = 13
 );
 
 @update_tail