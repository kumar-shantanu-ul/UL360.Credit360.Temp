grant select, references on csr.customer to chem;
grant references on csr.file_upload to chem;

grant select on aspen2.filecache to chem;
grant select on csr.ind to chem;
grant select on csr.sheet to chem;
grant select on csr.csr_user to chem;
grant select on csr.sheet_history to chem;
grant select, references on security.application to chem;
grant select on csr.delegation to chem;
grant select on csr.sheet_action to chem;

grant select on csr.delegation_ind to chem;
grant select on csr.delegation_plugin to chem;
grant select on csr.delegation_region to chem;

grant insert,select on csr.flow_item to chem;
grant references on csr.flow_item to chem;
grant references on csr.region to chem;
grant select on csr.flow to chem;
grant select on csr.flow_state_log to chem;
grant select on csr.flow_item_id_seq to chem;
grant select on csr.role to chem with grant option;
grant select on csr.region_role_member to chem with grant option;
grant select on csr.flow_state_role to chem   with grant option;
grant select on csr.flow_state to chem  with grant option;
grant select on csr.region to chem with grant option;
grant select on csr.flow_item to chem with grant option;
