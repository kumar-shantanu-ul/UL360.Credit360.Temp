
/*
doesn't currently restore from:

	DELEGATION_COMMENT 
	SUPPLIER_DELEGATION
	CHAIN_TPL_DELEGATION 
	DELEG_PLAN_DELEG_REGION 
	DELEG_PLAN_DELEG 

	DELEGATION_IND_COND_ACTION  (deprecated)
	DELEGATION_IND_COND 		(deprecated)
	DELEGATION_IND_TAG 			(mostly deprecated)
	DELEGATION_IND_TAG_LIST 	(mostly deprecated)
	DELEGATION_TAG 				(mostly deprecated)
	
*/

exec user_pkg.logonadmin('heineken.credit360.com');

-- delegation (excl. roles table, condition tables)


create table xx_heineken_delegation as
	select * from csr.delegation as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
            where delegation_sid in (
            	select delegation_sid 
              	  from csr.deleted_delegation
            	 where deleted_dtm > sysdate-1 
              	   and deleted_by_user_sid in (
              	   		select csr_user_sid 
                          from csr.superadmin 
                         where email like '&&email%'));

create table xx_heineken_deleg_date_sched as
	select * from csr.delegation_date_schedule as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	where delegation_date_schedule_id in (select delegation_date_schedule_id from xx_heineken_delegation)
	  and delegation_date_schedule_id not in (select delegation_date_schedule_id from csr.delegation_date_schedule);

create table xx_heineken_delegation_ind as
    select * From delegation_ind as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);

create table xx_heineken_delegation_region as
    select * From delegation_region as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);

create table xx_heineken_delegation_user as
    select * From delegation_user as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);

create table xx_heineken_delegation_role as
    select * From delegation_role as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);

create table xx_heineken_form_expr as
    select * From form_expr as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);


create table xx_heineken_deleg_ind_form_exp as
    select * From deleg_ind_form_expr as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);


create table xx_heineken_deleg_ind_group as
    select * From deleg_ind_group as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
     where delegation_sid in (select delegation_sid from xx_heineken_delegation);





-- sheets
create table xx_heineken_sheet as 
	select * 
	  from sheet as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where sheet_Id in  (
		select sheet_id from sheet as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
		 where delegation_sid in (select delegation_sid from xx_heineken_delegation)
	);

create table xx_heineken_sheet_value as 
	select * 
	  from sheet_value as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where sheet_Id in  (select sheet_id from xx_heineken_sheet);


create table xx_heineken_sheet_value_change as 
	select * 
	  from sheet_value_change as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where sheet_value_Id in  (select sheet_value_id from xx_heineken_sheet_value);


create table xx_heineken_sheet_history as 
	select * 
	  from sheet_history as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where sheet_Id in  (select sheet_id from xx_heineken_sheet);


create table xx_heineken_sheet_value_file as 
	select * 
	  from sheet_value_file as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where sheet_value_Id in  (select sheet_value_id from xx_heineken_sheet_value);

create table xx_heineken_sheet_value_acc as 
	select * 
	  from sheet_value_accuracy as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where sheet_value_Id in  (select sheet_value_id from xx_heineken_sheet_value);

create table xx_heineken_file_upload as 
	select * 
	  from file_upload as of timestamp to_date('2015-09-25 11:00:00', 'yyyy-mm-dd HH24:MI:SS') 
	 where file_upload_sid in  (select file_upload_sid from xx_heineken_sheet_value_file);

insert into delegation_date_schedule select * from xx_heineken_deleg_date_sched;

insert into delegation select * from xx_heineken_delegation;

insert into delegation_ind select * from xx_heineken_delegation_ind;

insert into delegation_Region select * from xx_heineken_delegation_region;

insert into delegation_user select * from xx_heineken_delegation_user;

insert into delegation_role select * from xx_heineken_delegation_role;

insert into file_upload select * from xx_heineken_file_upload;

insert into form_expr select * from xx_heineken_form_expr;

insert into deleg_ind_form_expr select * from xx_heineken_deleg_ind_form_exp;

insert into deleg_ind_group select * from xx_heineken_deleg_ind_group;





insert into sheet (app_sid, sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, last_sheet_history_id, is_visible)
    select app_sid, sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, null, is_visible from xx_heineken_sheet;
    
insert into sheet_history select * from xx_heineken_sheet_history;

begin
    for r in (select sheet_id, last_sheet_history_id from xx_heineken_sheet) loop
        update sheet set last_sheet_history_id = r.last_sheet_history_id where sheet_id = r.sheet_id;
    end loop;
end;
/


insert into sheet_value ( APP_SID, SHEET_VALUE_ID, SHEET_ID, IND_SID, REGION_SID, VAL_NUMBER, SET_BY_USER_SID, SET_DTM, NOTE, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, IS_INHERITED, STATUS, ALERT, FLAG, VAR_EXPL_NOTE)
	select  APP_SID, SHEET_VALUE_ID, SHEET_ID, IND_SID, REGION_SID, VAL_NUMBER, SET_BY_USER_SID, SET_DTM, NOTE, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, IS_INHERITED, STATUS, ALERT, FLAG, VAR_EXPL_NOTE
	 from xx_heineken_sheet_value;

insert into sheet_value_change select * from xx_heineken_sheet_value_change;

begin
    for r in (select sheet_value_id, last_sheet_value_change_id from xx_heineken_sheet_value) loop
        update sheet_value set last_sheet_value_change_id = r.last_sheet_value_change_id where sheet_value_id = r.sheet_value_id;
    end loop;
end;
/

insert into sheet_value_accuracy select * from xx_heineken_sheet_value_acc;

insert into sheet_value_file select * from xx_heineken_sheet_value_file;



-- securable objects
create  table xx_heineken_so as 
	select * from security.securable_object as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	 where sid_id in (select delegation_sid from xx_heineken_delegation union select file_upload_sid from xx_heineken_sheet_value_file);

create  table xx_heineken_acl as
	select * 
	  from security.acl as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	 where acl_id in (select dacl_id from xx_heineken_so)
	 union
	select * 
	  from security.acl as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	 where sid_id in (select sid_id from xx_heineken_so)
	 ;
	    

create table xx_heineken_group_table as 
	select * 
	  from security.group_table as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	 where sid_id in (select sid_id from xx_heineken_so);

create  table xx_heineken_group_members as 
	select * 
	  from security.group_members as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	 where group_sid_id in (select sid_id from xx_heineken_so)
	 union
	select * 
	  from security.group_members as of timestamp to_timestamp('2015-09-25 11:00:00','yyyy-mm-dd hh24:mi:ss')
	 where group_sid_id in (select sid_id from xx_heineken_so);


insert into security.securable_object
	select * from xx_heineken_so;
	
insert into security.acl
	select * from xx_heineken_acl;

insert into security.group_table
	select * from xx_heineken_group_table;

insert into security.group_members
	select * from xx_heineken_group_members;

-- remove from list of deleted delegations
delete from deleted_delegation where delegation_sid in (select delegation_sid from delegation);

begin
    for r in (select table_name from user_tables where table_name like UPPER('xx_heineken_%') and table_name not like '%_NEW_%') loop
        execute immediate 'drop table '||r.table_name||' purge';
    end loop;
end;
/


commit;
