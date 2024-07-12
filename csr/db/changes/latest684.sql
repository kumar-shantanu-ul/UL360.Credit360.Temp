-- Please update version.sql too -- this keeps clean builds in sync
define version=684
@update_header

alter table csr.delegation_grid_aggregate_ind drop constraint pk_delegation_grid_aggr_ind;
alter table csr.delegation_grid_aggregate_ind add constraint pk_delegation_grid_aggr_ind 
primary key (app_sid, ind_sid, aggregate_to_ind_sid);

alter table csr.delegation_grid_aggregate_ind drop constraint fk_deleg_grid_aggr_ind_ind;
alter table csr.delegation_grid_aggregate_ind add constraint fk_deleg_grid_agr_deleg_grid foreign key (app_sid, ind_sid)
references csr.delegation_grid (app_sid, ind_sid);

insert into csr.delegation_grid_aggregate_ind (app_sid, ind_sid, aggregate_to_ind_sid)
	select distinct dg.app_sid, dg.ind_sid, di2.ind_sid aggregate_to_ind_sid
	  from csr.delegation_grid dg, csr.delegation_ind di1, csr.delegation_ind di2
	 where di1.app_sid = di2.app_sid and di1.delegation_sid = di2.delegation_sid
	   and di1.app_sid = dg.app_sid and di1.ind_sid = dg.ind_sid
	   and di2.visibility = 'HIDE'
	   and (di2.app_sid, di2.ind_sid) not in (select app_sid, ind_sid from csr.delegation_grid)
	 minus
	select app_sid, ind_sid, aggregate_to_ind_sid
	  from csr.delegation_grid_aggregate_ind;

@../delegation_pkg
@../delegation_body

@update_tail


