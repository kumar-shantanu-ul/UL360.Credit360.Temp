define version=770
@update_header

create index csr.ix_flow_state_tr_from_st_rle on csr.flow_state_transition_role (app_sid, from_state_id, role_sid);
	
@update_tail
