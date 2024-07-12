-- Please update version.sql too -- this keeps clean builds in sync
define version=764
@update_header

declare
	v_version number;
begin
	begin
		select db_version
		  into v_version
		  from chain.version
		 where part = 'trunk';
	exception
		when others then
			raise_application_error(-20001, 'failed to get the chain version -- possibly a very old schema: '||sqlerrm);
	end;
	if v_version != 138 then
		raise_application_error(-20001, 'chain must be version 138 first');
	end if;
	select db_version
	  into v_version
	  from donations.version;
	if v_version != 64 then
		raise_application_error(-20001, 'donations must be version 64 first');
	end if;
	select db_version
	  into v_version
	  from actions.version;
	if v_version != 90 then
		raise_application_error(-20001, 'actions must be version 90 first');
	end if;
	-- hmm, strange mismatch between live and the schema here
	begin
		select db_version
		  into v_version
		  from supplier.version;
	exception
		when others then
			select db_version
			  into v_version
			  from supplier.version
			 where part = 'generic';
	end;
	if v_version != 88 then
		raise_application_error(-20001, 'supplier must be version 88 first');
	end if;
	select db_version
	  into v_version
	  from csrimp.version;
	if v_version != 8 then
		raise_application_error(-20001, 'csrimp must be version 8 first');
	end if;
end;
/

drop table chain.version;
drop table donations.version;
drop table actions.version;
drop table supplier.version;
drop table csrimp.version;

alter table csr.version add only_one_row number(1) default 0 not null;
alter table csr.version add constraint ck_version_one_row check (only_one_row = 0);
alter table csr.version add constraint pk_version primary key (only_one_row);

@update_tail
