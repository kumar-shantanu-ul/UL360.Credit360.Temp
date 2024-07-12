-- Please update version.sql too -- this keeps clean builds in sync
define version=1525
@update_header

insert into csr.batch_job_type (batch_job_type_id, description, plugin_name)  -- basedata
values (4, 'AS2 message delivery notification', 'as2-mdn');

insert into csr.batch_job_type (batch_job_type_id, description, plugin_name)  -- basedata
values (5, 'AS2 message', 'as2-message');

create table csr.batch_job_as2_outbound_receipt
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	batch_job_id number(10, 0) not null,
	original_message_id varchar2(998) not null,
	constraint pk_bj_as2_or primary key (app_sid, batch_job_id),
	constraint uk_bj_as2_or_omi unique (original_message_id)
);

create table csr.as2_outbound_receipt
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	original_message_id varchar2(998) not null,
	message_id varchar2(998) null,
	sent_dtm date null,
	local_end_point varchar2(256) not null,
	remote_end_point varchar2(256) not null,
	as2_from varchar2(128) not null,
	as2_to varchar2(128) not null,
	subject varchar2(2048) null,
	message varchar2(2048) null,
	message_integrity_check raw(20) not null,
	constraint pk_as2_or primary key (app_sid, original_message_id),
	constraint uk_as2_or_omi unique (original_message_id),
	constraint uk_as2_or_mi unique (message_id)
);

create table csr.batch_job_as2_outbound_message
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	batch_job_id number(10, 0) not null,
	message_id varchar2(998) not null,
	constraint pk_bj_as2_om primary key (app_sid, batch_job_id),
	constraint uk_bj_as2_om_mi unique (message_id)
);

create table csr.as2_outbound_message
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	message_id varchar2(998) not null,
	sent_dtm date null,
	local_end_point varchar2(256) not null,
	remote_end_point varchar2(256) not null,
	as2_from varchar2(128) not null,
	as2_to varchar2(128) not null,
	subject varchar2(2048) null,
	receipt_delivery char(1) default 'N' not null,
	receipt_url varchar2(256) null,
	file_name varchar2(255) not null,
	mime_type varchar2(255) not null,
	message blob not null,
	constraint pk_as2_om primary key (app_sid, message_id),
	constraint uk_as2_om_mi unique (message_id),
	constraint ck_as2_om_rd check (receipt_delivery in ('N', 'A', 'S'))
);

create table csr.as2_inbound_receipt
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	message_id varchar2(998) not null,
	original_message_id varchar2(998) not null,
	received_dtm date default sysdate not null,
	message_integrity_check raw(20) not null,
	subject varchar2(2048) null,
	message varchar2(2048) null,
	constraint pk_as2_ir primary key (app_sid, message_id),
	constraint uk_as2_ir_mi unique (message_id),
	constraint uk_as2_ir_omi unique (original_message_id)
);

alter table csr.batch_job_as2_outbound_receipt add constraint fk_bjaor_bj
foreign key (app_sid, batch_job_id)
references csr.batch_job(app_sid, batch_job_id) on delete cascade
;

alter table csr.batch_job_as2_outbound_message add constraint fk_bjaom_bj
foreign key (app_sid, batch_job_id)
references csr.batch_job(app_sid, batch_job_id) on delete cascade
;

alter table csr.batch_job_as2_outbound_receipt add constraint fk_bjaor_aor
foreign key (app_sid, original_message_id)
references csr.as2_outbound_receipt(app_sid, original_message_id)
;

alter table csr.batch_job_as2_outbound_message add constraint fk_bjaom_aom
foreign key (app_sid, message_id)
references csr.as2_outbound_message(app_sid, message_id)
;

alter table csr.as2_inbound_receipt add constraint fk_air_om
foreign key (app_sid, original_message_id)
references csr.as2_outbound_message(app_sid, message_id)
;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'BATCH_JOB_AS2_OUTBOUND_RECEIPT',
		'BATCH_JOB_AS2_OUTBOUND_MESSAGE',
		'AS2_OUTBOUND_RECEIPT',
		'AS2_OUTBOUND_MESSAGE',
		'AS2_INBOUND_RECEIPT'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

CREATE OR REPLACE PACKAGE CSR.AS2_PKG
AS
END;
/

grant execute on csr.as2_pkg to web_user;

@..\batch_job_pkg
@..\as2_pkg
@..\as2_body

@update_tail
