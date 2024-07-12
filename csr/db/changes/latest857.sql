-- Please update version.sql too -- this keeps clean builds in sync
define version=857
@update_header

create table csr.scrag_progress_phase
(
	phase							number(10) not null,
	description						varchar2(500) not null,
	constraint pk_scrag_progress_phase primary key (phase)
);

begin
	insert into csr.scrag_progress_phase (phase, description) values (0, 'Idle');
	insert into csr.scrag_progress_phase (phase, description) values (1, 'Fetching data');
	insert into csr.scrag_progress_phase (phase, description) values (2, 'Aggregating up');
	insert into csr.scrag_progress_phase (phase, description) values (3, 'Aggregating down');
	insert into csr.scrag_progress_phase (phase, description) values (4, 'Running calculations');
	insert into csr.scrag_progress_phase (phase, description) values (5, 'Writing data');
	insert into csr.scrag_progress_phase (phase, description) values (6, 'Merging data');
end;
/

create table csr.scrag_progress
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	pass							number(10) default 0 not null,
	total_passes					number(10) default 0 not null,
	phase							number(10) default 0 not null,
	work_done						number(10) default 0 not null,
	total_work						number(10) default 0 not null,
	updated_dtm						date default sysdate not null,
	constraint pk_scrag_progress primary key (app_sid),
	constraint fk_scrag_progress_customer foreign key (app_sid) references csr.customer(app_sid),
	constraint fk_scrag_progress_phase foreign key (phase) references csr.scrag_progress_phase(phase)
);

create index csr.ix_scrag_progress_phase on csr.scrag_progress(phase);

create or replace view csr.v$scrag_progress as
	select sp.app_sid, c.host, sp.pass, sp.total_passes, sp.phase, spp.description phase_description, sp.work_done, sp.total_work, sp.updated_dtm
	  from csr.scrag_progress sp, csr.scrag_progress_phase spp, customer c
	 where sp.phase = spp.phase
	   AND sp.app_sid = c.app_sid;

insert into csr.scrag_progress (app_sid)
	select app_sid
	  from csr.customer;
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'SCRAG_PROGRESS',
		policy_name     => 'SCRAG_PROGRESS_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
