-- Please update version.sql too -- this keeps clean builds in sync
define version=1132
@update_header

alter table csr.measure add (
	factor number(10),
	m number(10),
	kg number(10),
	s number(10),
	a number(10),
	k number(10),
	mol number(10),
	cd number(10)
);
alter table csr.measure add constraint ck_measure_si_detail check (
	( factor is not null and m is not null and kg is not null and s is not null and a is not null and k is not null and mol is not null and cd is not null ) or
	( factor is null and m is null and kg is null and s is null and a is null and k is null and mol is null and cd is null ) 
);

@../measure_pkg
@../measure_body

@update_tail