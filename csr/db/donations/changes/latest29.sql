-- Please update version.sql too -- this keeps clean builds in sync
define version=29
@update_header

-- clean up duff data
delete from customer_filter_flag where csr_root_sid not in (select csr_root_sid from csr.customer);
delete from customer_default_exrate where csr_root_sid not in (select csr_root_sid from csr.customer);

-- TODO: no RI on these tables
alter table customer_filter_flag add app_sid number(10);
update customer_filter_flag set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = customer_filter_flag.csr_root_sid);
alter table customer_filter_flag modify app_sid not null;
alter table customer_filter_flag drop constraint pk72;
begin
	for r in (select index_name from user_indexes where index_name='PK72') loop
		execute immediate 'drop index pk72';
	end loop;
end;
/
alter table customer_filter_flag add constraint pk72 primary key (app_sid) using index tablespace indx;
alter table customer_filter_flag drop column csr_root_sid;

alter table customer_default_exrate add app_sid number(10);
update customer_default_exrate set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = customer_default_exrate.csr_root_sid);
alter table customer_default_exrate modify app_sid not null;
alter table customer_default_exrate drop constraint pk74;
begin
	for r in (select index_name from user_indexes where index_name='PK74') loop
		execute immediate 'drop index pk74';
	end loop;
end;
/
alter table customer_default_exrate add constraint pk74 primary key (app_sid, currency_code) using index tablespace indx;
alter table customer_default_exrate drop column csr_root_sid;

@..\build

PROMPT Recompiling invalid packages
@c:\cvs\aspen2\tools\recompile_packages.sql

@update_tail
