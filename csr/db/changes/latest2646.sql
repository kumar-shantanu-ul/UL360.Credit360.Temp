-- Please update version.sql too -- this keeps clean builds in sync
define version=2646
@update_header

UPDATE csr.flow_state_role_capability
   SET permission_set = 1
 WHERE flow_capability_id = 13 --csr.csr_data_pkg.FLOW_CAP_AUDIT_SCORE
   AND permission_set = 2;

@update_tail