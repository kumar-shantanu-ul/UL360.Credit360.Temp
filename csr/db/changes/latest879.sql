-- Please update version.sql too -- this keeps clean builds in sync
define version=879
@update_header

create table csr.ind_selection_group (
	app_sid							number(10) default sys_context('security', 'app'),
	master_ind_sid					number(10) not null,
	constraint pk_ind_selection_group primary key (app_sid, master_ind_sid),
	constraint fk_ind_sel_group_ind foreign key (app_sid, master_ind_sid)
	references csr.ind (app_sid, ind_sid)
);

create table csr.ind_selection_group_member (
	app_sid							number(10) default sys_context('security', 'app'),
	master_ind_sid					number(10) not null,
	ind_sid							number(10) not null,
	pos								number(10) not null,
	description						varchar2(500),
	constraint pk_ind_selection_group_member primary key (app_sid, master_ind_sid, ind_sid),
	constraint uk_ind_selection_group_ind unique (app_sid, ind_sid),
	constraint fk_ind_sel_grp_mem_sel_grp foreign key (app_sid, master_ind_sid)
	references csr.ind_selection_group (app_sid, master_ind_sid),
	constraint fk_ind_sel_grp_mem_ind foreign key (app_sid, ind_sid)
	references csr.ind (app_sid, ind_sid)
);

@../delegation_body

@update_tail
