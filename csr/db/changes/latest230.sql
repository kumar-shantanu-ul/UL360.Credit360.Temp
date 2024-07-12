-- Please update version.sql too -- this keeps clean builds in sync
define version=230
@update_header

/*
drop table factor_set cascade constraints;
drop table gas_type cascade constraints;
drop table factor_set_gas_type cascade constraints;
drop table factor cascade constraints;
drop table factor_history cascade constraints;
drop table std_factor_set cascade constraints;
drop table std_factor_set_customer cascade constraints;
drop sequence factor_id_seq;
drop sequence factor_set_id_seq;
drop sequence gas_type_id_seq;
alter table ind drop column factor_set_id;
*/

create table factor_set
(
	app_sid				number(10) not null,
	factor_set_id		number(10) not null,
	name				varchar2(200) not null,
	varies_by_geography	number(1) not null check (varies_by_geography in (0,1)),
	measure_sid			number(10) not null,
	constraint pk_factor_set primary key (app_sid, factor_set_id)
	using index tablespace indx,
	constraint uk_factor_set_id unique (factor_set_id)
	using index tablespace indx,
	constraint fk_factor_set_customer foreign key (app_sid)
	references customer(app_sid),
	constraint fk_factor_set_measure foreign key (measure_sid)
	references measure(measure_sid)
);

create table gas_type
(
	gas_type_id			number(10) not null,
	name				varchar2(200) not null,
	constraint pk_gas_type primary key (gas_type_id)
	using index tablespace indx
);

create table factor_set_gas_type
(
	app_sid				number(10) not null,
	factor_set_id		number(10) not null,
	gas_type_id			number(10) not null,
	constraint uk_factor_set_gas_type unique (factor_set_id, gas_type_id)
	using index tablespace indx,
	constraint fk_fact_set_gas_type_fact_set foreign key (app_sid, factor_set_id)
	references factor_set(app_sid, factor_set_id),
	constraint fk_fact_set_gas_type_gas_type foreign key (gas_type_id)
	references gas_type(gas_type_id)
);

create table factor
(
	app_sid				number(10) not null,
	factor_id			number(10) not null,
	factor_set_id		number(10) not null,
	gas_type_id			number(10) not null,
	start_dtm			date not null,
	end_dtm				date not null,
	geo_region_code		varchar2(10) not null,
	value				number(24, 10) not null,
	note				clob not null,
	constraint pk_factor primary key (app_sid, factor_id)
	using index tablespace indx,
	constraint uk_factor unique (factor_set_id, gas_type_id, start_dtm)
	using index  tablespace indx,
	constraint fk_factor_gas_type foreign key (gas_type_id)
	references gas_type(gas_type_id),
	constraint fk_factor_set_id foreign key (app_sid, factor_set_id)
	references factor_set(app_sid, factor_set_id)
);

create table factor_history
(
	app_sid				number(10) not null,
	factor_id			number(10) not null,
	changed_dtm			number(10) not null,
	user_sid			number(10) not null,
	old_value			number(24, 10) not null,
	note				clob not null,
	constraint fk_factor_history_factor foreign key (app_sid, factor_id)
	references factor(app_sid, factor_id)
);

create table std_factor_set
(
	factor_set_id		number(10) not null,
	constraint pk_std_factor_set primary key (factor_set_id)
	using index tablespace indx,
	constraint fk_std_factor_set_factor_set foreign key (factor_set_id)
	references factor_set(factor_set_id)
);

create table std_factor_set_customer
(
	factor_set_id		number(10) not null,
	app_sid				number(10) not null,
	constraint pk_std_factor_set_customer primary key (factor_set_id)
	using index tablespace indx,
	constraint fk_std_fct_set_cust_std_fct foreign key (factor_set_id)
	references std_factor_set(factor_set_id),
	constraint fk_std_factor_set_cust_cust foreign key (app_sid)
	references customer(app_sid)
);

create sequence factor_id_seq;
create sequence factor_set_id_seq;
create sequence gas_type_id_seq;

alter table ind add factor_set_id number(10);
alter table ind add constraint fk_ind_factor_set foreign key
(factor_set_id) references factor_set(factor_set_id);

@..\csr_data_pkg
@..\indicator_pkg
@..\indicator_body
@..\measure_pkg
@..\measure_body
@..\vb_legacy_body
@..\factor_pkg
@..\factor_body

alter session set current_schema="ACTIONS";
@..\actions\project_body
@..\actions\task_body
@..\actions\ind_template_body

alter session set current_schema="CSR";
@..\..\..\aspen2\tools\recompile_packages

grant execute on factor_pkg to web_user;

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'FACTOR',
        policy_name     => 'FACTOR_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'FACTOR_HISTORY',
        policy_name     => 'FACTOR_HISTORY_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'FACTOR_SET',
        policy_name     => 'FACTOR_SET_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'FACTOR_SET_GAS_TYPE',
        policy_name     => 'FACTOR_SET_GAS_TYPE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'STD_FACTOR_SET_CUSTOMER',
        policy_name     => 'STD_FACTOR_SET_CUSTOMER_POL',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
end;
/

@update_tail
