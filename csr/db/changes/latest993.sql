-- Please update version.sql too -- this keeps clean builds in sync
define version=993
@update_header

grant select, references on csr.role to cms;
grant select, references on csr.flow to cms;
grant select, references on csr.flow_state to cms;

alter table cms.tab add flow_sid number(10);
alter table cms.tab add constraint fk_tab_flow foreign key (app_sid, flow_sid) references csr.flow (app_sid, flow_sid);
create index cms.ix_tab_flow on cms.tab (app_sid, flow_sid);

create table cms.tab_column_role_permission (
	app_sid							number(10) default sys_context('security', 'app') not null,
	column_sid						number(10) not null,
	role_sid						number(10) not null,
	permission						number(10) not null check (permission in (0, 1, 2)),
	constraint pk_tab_column_role_permission primary key (app_sid, column_sid, role_sid),
	constraint fk_tab_column_perm_tab_col foreign key (app_sid, column_sid) references cms.tab_column (app_sid, column_sid),
	constraint fk_tab_column_perm_role foreign key (app_sid, role_sid) references csr.role (app_sid, role_sid)
);
create index cms.ix_tab_column_perm_role on cms.tab_column_role_permission (app_sid, role_sid);

create table cms.flow_tab_column_cons (
	app_sid							number(10) default sys_context('security', 'app') not null,
	column_sid						number(10) not null,
	flow_state_id					number(10) not null,
	nullable						number(1) default 1 not null check (nullable in (0,1)),
	constraint pk_flow_tab_column_cons primary key (app_sid, column_sid, flow_state_id),
	constraint fk_flow_tab_col_cons_tab_col foreign key (app_sid, column_sid) references cms.tab_column (app_sid, column_sid),
	constraint fk_flow_tab_col_flow_state foreign key (app_sid, flow_state_id) references csr.flow_state (app_sid, flow_state_id)
);
create index cms.ix_tab_col_cons_flow_state on cms.flow_tab_column_cons (app_sid, flow_state_id);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
