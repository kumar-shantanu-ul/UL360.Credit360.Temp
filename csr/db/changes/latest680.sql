-- Please update version.sql too -- this keeps clean builds in sync
define version=680
@update_header

alter table csr.delegation_grid add aggregation_xml xmltype;

create table csr.delegation_grid_aggregate_ind (
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	ind_sid							number(10) not null,
	aggregate_to_ind_sid			number(10) not null,
	constraint pk_delegation_grid_aggr_ind primary key (app_sid, ind_sid)
	using index,
	constraint fk_deleg_grid_aggr_ind_ind foreign key (app_sid, ind_sid)
	references csr.ind (app_sid, ind_sid),
	constraint fk_deleg_grid_aggr_to_ind foreign key (app_sid, aggregate_to_ind_sid)
	references csr.ind (app_sid, ind_sid)
);
create index csr.ix_deleg_grid_aggr_ind_agg_to on csr.delegation_grid_aggregate_ind (app_sid, aggregate_to_ind_sid) ;

alter table csr.delegation_ind drop column delegation_grid_id cascade constraints;
alter table csr.delegation_grid drop column delegation_grid_id cascade constraints;

-- argh
create table fb8715_backup_delegation_grid as 
	select * from csr.delegation_grid where ind_sid is null;
delete from csr.delegation_grid where ind_sid is null;

-- Casey needed to: drop index ix_deleg_grid_ind;
alter table csr.delegation_grid add constraint pk_delegation_grid primary key (app_sid, ind_sid) using index ;
drop sequence csr.delegation_grid_id_seq;

@../delegation_body
@../sheet_body

@update_tail


