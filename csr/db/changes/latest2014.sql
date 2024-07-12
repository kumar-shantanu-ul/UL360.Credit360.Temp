define version=2014
@update_header

ALTER TABLE CSR.INITIATIVE_PROJECT ADD(
  TAB_SID           NUMBER(10, 0)
);

@../initiative_project_body

grant select on csr.flow_state to web_user;
grant select on csr.flow_item to web_user;
grant select on csr.flow_state_role to web_user;
grant select on csr.region_role_member to web_user;
grant select on csr.initiative to web_user;

grant select on csr.flow_state to cms;
grant select on csr.flow_item to cms;
grant select on csr.flow_state_role to cms;
grant select on csr.region_role_member to cms;
grant select on csr.initiative to cms;

@update_tail
