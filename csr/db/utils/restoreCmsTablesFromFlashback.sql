
create table mark.restore_tab (tab_sid number(10) not null);

begin  
	for r in (
		select owner,object_name, original_name, type, can_undrop as "UND", can_purge as "PUR", droptime
		  from dba_recyclebin 
		where type='TABLE' and owner='SHEPMPPTWO' 
		and droptime >= date '2013-10-04'
	) loop
	dbms_output.put_line('flashback table '||r.owner||'.'||r.original_name||' to before drop;');
		--execute immediate 'flashback table '||r.owner||'.'||r.object_name||' to before drop';
	end loop;
end;
/

begin
exec user_pkg.logonadmin('shepm-pp.credit360.com');
insert into mark.restore_Tab
	select tab_sid from cms.tab as of timestamp timestamp '2013-10-04 13:00:00'
where app_sid = sys_context('security','app')
 and tab_sid not in (select tab_sid from cms.tab); 

insert into cms.tab (FLOW_SID,REGION_COL_SID,MANAGED,AUTO_REGISTERED,CMS_EDITOR,ISSUES,TAB_SID,APP_SID,ORACLE_SCHEMA,ORACLE_TABLE,DESCRIPTION,FORMAT_SQL)
select FLOW_SID,REGION_COL_SID,MANAGED,AUTO_REGISTERED,CMS_EDITOR,ISSUES,TAB_SID,APP_SID,ORACLE_SCHEMA,ORACLE_TABLE,DESCRIPTION,FORMAT_SQL
from cms.tab as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.tab_column
select * from cms.tab_column as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.uk_cons
select * from cms.uk_cons as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.fk_cons
select * from cms.fk_cons as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.fk_cons_col
select * from cms.fk_cons_col as of timestamp timestamp '2013-10-04 13:00:00'
where fk_cons_id in (
select fk_cons_id from cms.fk_cons as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab));

update cms.tab t set pk_cons_id = (
select pk_cons_id from cms.tab 
as of timestamp timestamp '2013-10-04 13:00:00' ot
where ot.tab_sid = t.tab_sid) where t.tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.uk_cons_col
select * from cms.uk_cons_col as of timestamp timestamp '2013-10-04 13:00:00'
where uk_cons_id in (
select uk_cons_id from cms.uk_cons as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab));
	 		 	   								  
insert into cms.ck_cons
select * from cms.ck_cons as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.ck_cons_col
select * from cms.ck_cons_col as of timestamp timestamp '2013-10-04 13:00:00'
where ck_cons_id in (
select ck_cons_id from cms.ck_cons as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab));
	    
insert into cms.filter
select * from cms.filter as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.active_session_filter
select * from cms.active_session_filter as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab);


insert into cms.form
select * from cms.form as of timestamp timestamp '2013-10-04 13:00:00'
where parent_tab_sid in (select tab_sid from mark.restore_tab);

insert into cms.flow_tab_column_cons
select * from cms.flow_tab_column_cons as of timestamp timestamp '2013-10-04 13:00:00'
where column_sid in (
select column_sid from cms.tab_column as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab));

insert into csr.flow_transition_alert_cms_col
select * from csr.flow_transition_alert_cms_col as of timestamp timestamp '2013-10-04 13:00:00'
where column_sid in (
select column_sid from cms.tab_column as of timestamp timestamp '2013-10-04 13:00:00'
where tab_sid in (select tab_sid from mark.restore_tab));


	insert into security.securable_object
	select * from security.securable_object as of timestamp timestamp '2013-10-04 13:00:00'
	where sid_id in (select tab_sid from mark.restore_tab);
	
	insert into security.securable_object_attributes
	select * from security.securable_object_attributes as of timestamp timestamp '2013-10-04 13:00:00'
	where sid_id in (select tab_sid from mark.restore_tab);
	
	insert into security.acl
	select * from security.acl as of timestamp timestamp '2013-10-04 13:00:00'
	where sid_id in (select tab_sid from mark.restore_tab);

	insert into security.acl
	select * from security.acl as of timestamp timestamp '2013-10-04 13:00:00'
	where acl_id in (select dacl_id from security.securable_object where sid_id in (select tab_sid from mark.restore_tab));
end;
/

commit;

exec cms.tab_pkg.recreateviews;
