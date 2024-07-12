-- Please update version.sql too -- this keeps clean builds in sync
define version=1271
@update_header

create table csr.flow_item_subscription
(
	app_sid				number(10) default sys_context('security', 'app') not null,
	flow_item_id		number(10) not null,
	user_sid			number(10) not null,
	constraint pk_flow_item_subscription primary key (app_sid, flow_item_id, user_sid),
	constraint fk_flow_item_sub_flow_item foreign key (app_sid, flow_item_id)
	references csr.flow_item (app_sid, flow_item_id),
	constraint fk_flow_item_sub_csr_user foreign key (app_sid, user_sid)
	references csr.csr_user (app_sid, csr_user_sid)
);
create index csr.ix_flow_item_sub_user on csr.flow_item_subscription (app_sid, user_sid);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
	