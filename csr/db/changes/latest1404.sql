-- Please update version.sql too -- this keeps clean builds in sync
define version=1404
@update_header

UPDATE csr.std_alert_type_param
   SET display_pos = 8
 WHERE std_alert_type_id = 41 and field_name='SUBJECT_RCVD';
 
UPDATE csr.std_alert_type_param
   SET description = 'Errors',
	   help_text = 'The problems encountered'
 WHERE std_alert_type_id = 41 and display_pos = 7;

alter table csr.property_division add (region_sid number(10));

update csr.property_division set region_sid = (select region_sid from csr.property p where property_division.property_id = p.property_id);

alter table csr.property_division modify region_sid not null;

BEGIN
	FOR r IN (
		SELECT owner, constraint_name, table_name
		   FROM all_constraints
		  WHERE R_constraint_name in (
		   select constraint_name from all_constraints where owner ='CSR' and table_name ='PROPERTY' and constraint_type='P'
		 )
	)
	LOOP
		dbms_output.put_line('dropping constraint '||r.owner||'.'||r.table_name||r.constraint_name||'...');
		execute immediate 'alter table '||r.owner||'.'||r.table_name||' drop constraint '||r.constraint_name;
	END LOOP;
END;
/
begin
	for r in (select 1 from all_constraints where constraint_name='PROPERTY_CSR_USER' and table_name='PROPERTY' and owner='CSR') loop
		execute immediate 'ALTER TABLE CSR.PROPERTY DROP CONSTRAINT PROPERTY_CSR_USER';
	end loop;
end;
/

alter table csr.property drop primary key drop index;
alter table csr.property_division drop primary key drop index;

declare 
	v_exists number;
begin
	for r in (select column_name
	  			from all_tab_columns
	  		   where table_name='PROPERTY' and owner='CSR' 
	  		     and column_name IN ('TELEPHONE', 'GROUP_ID', 'MANAGER_CSR_USER_SID', 'NEIGH_ASSMT_DIRTY', 'PROPERTY_ID')) loop
		execute immediate 'alter table csr.property drop column '||r.column_name;
	end loop;
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='STREET_ADDRESS';
	if v_exists = 1 then
		execute immediate 'alter table csr.property rename column street_address to street_addr_1';
	end if;	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='STREET_ADDR_1';
	if v_exists = 0 then
		execute immediate 'alter table csr.property add street_addr_1 varchar2(200)';
	end if;
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='STREET_ADDR_2';
	if v_exists = 0 then
		execute immediate 'alter table csr.property add STREET_ADDR_2 varchar2(200)';
	end if;
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='CITY';
	if v_exists = 0 then
		execute immediate 'alter table csr.property add CITY varchar2(200)';
	end if;
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='STATE';
	if v_exists = 0 then
		execute immediate 'alter table csr.property add STATE varchar2(200)';
	end if;
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='POSTCODE';
	if v_exists = 0 then
		execute immediate 'alter table csr.property add POSTCODE varchar2(200)';
	end if;
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where table_name='PROPERTY' and owner='CSR' and column_name='POSTCODE';
	if v_exists = 0 then
		execute immediate 'alter table csr.property add POSTCODE varchar2(200)';
	end if;
end;
/
alter table csr.property_division drop column property_id;

alter table csr.property add CONSTRAINT PK_PROPERTY PRIMARY KEY (APP_SID, REGION_SID);
alter table csr.property_division add constraint PK_PROPERTY_DIVISION PRIMARY KEY (APP_SID, DIVISION_ID, REGION_SID, START_DTM);

ALTER TABLE CSR.PROPERTY_DIVISION ADD CONSTRAINT FK_PROP_PROP_DIV 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.PROPERTY(APP_SID, REGION_SID);
    
drop sequence csr.PROPERTY_ID_SEQ;

@..\calc_pkg
@..\division_pkg

@..\region_body
@..\division_body

@update_tail
