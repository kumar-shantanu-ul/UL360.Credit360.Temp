-- this doesn't do everything but just does the stuff I needed for Iain's deletion
exec user_pkg.logonadmin('cbre.credit360.com');

create table xx_cb_role as
    select * From role as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
     where role_sid in (14171242,14171243);

create table xx_cb_delegation_role as
    select * From delegation_role as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
     where role_sid in (select role_sid from xx_cb_role);

create table xx_cb_region_role_member as
    select * From region_role_member as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
     where role_sid in (select role_sid from xx_cb_role);

insert into role
	select * from xx_cb_role;
	
insert into delegation_role
	select * from xx_cb_delegation_role;
	
insert into region_role_member
	select * from xx_cb_region_role_member;

-- securable objects
create  table xx_cb_so as 
	select * from security.securable_object as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
	 where sid_id in (select role_sid from xx_cb_role);

create  table xx_cb_acl as
	select * 
	  from security.acl as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
	 where acl_id in (select dacl_id from xx_cb_so)
	 union
	select * 
	  from security.acl as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
	 where sid_id in (select sid_id from xx_cb_so)
	 ;
	    

create table xx_cb_group_table as 
	select * 
	  from security.group_table as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
	 where sid_id in (select sid_id from xx_cb_so);

create  table xx_cb_group_members as 
	select * 
	  from security.group_members as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
	 where group_sid_id in (select sid_id from xx_cb_so)
	 union
	select * 
	  from security.group_members as of timestamp to_timestamp('2012-11-18 20:00:00','yyyy-mm-dd hh24:mi:ss')
	 where member_sid_id in (select sid_id from xx_cb_so);


insert into security.securable_object
	select * from xx_cb_so;
	
insert into security.acl
	select * from xx_cb_acl;

insert into security.group_table
	select * from xx_cb_group_table;

insert into security.group_members
	select * from xx_cb_group_members;



begin
    for r in (select table_name from user_tables where table_name like UPPER('XX_cb_%') and table_name not like '%_NEW_%') loop
        execute immediate 'drop table '||r.table_name||' purge';
    end loop;
end;
/


commit;
