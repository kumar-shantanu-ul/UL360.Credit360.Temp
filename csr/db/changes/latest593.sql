-- Please update version.sql too -- this keeps clean builds in sync
define version=593
@update_header

create table csr.approval_step_model
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	approval_step_id number(10, 0) not null,
	model_sid number(10, 0) not null,
	subdelegations char(1) default 'Y' not null,
	link_description varchar2(50) not null,
	icon_cls varchar2(50) null,
	constraint pk_approval_step_model primary key (app_sid, approval_step_id, model_sid),
	constraint ck_asm_subdelegations check (subdelegations in ('Y', 'N'))
);

alter table csr.approval_step_model add constraint fk_asm_m foreign key (app_sid, model_sid) references csr.model(app_sid, model_sid);
alter table csr.approval_step_model add constraint fk_asm_as foreign key (app_sid, approval_step_id) references csr.approval_step(app_sid, approval_step_id);

@..\pending_pkg
@..\pending_body

@update_tail
