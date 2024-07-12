-- Please update version.sql too -- this keeps clean builds in sync
define version=233
@update_header

begin
	for r in (select object_name, policy_name from user_policies) loop
		dbms_rls.drop_policy(
            object_schema   => 'CSR',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

/*
all constraints referencing PK_IND
select table_name,constraint_name from user_constraints where r_constraint_name='PK_IND'
order by table_name, constraint_name;

x ALL_METER                      REFIND779
x ATTACHMENT                     REFIND825
x CALC_DEPENDENCY                REFIND17
x CALC_DEPENDENCY                REFIND32
x CUSTOMER                       FK_CUST_IND_ROOT_IND
x DASHBOARD_ITEM                 REFIND59
x DATAVIEW_ZONE                  REFIND363
x DATAVIEW_ZONE                  REFIND365
x DELEGATION_IND                 REFIND101
x IMP_IND                        REFIND13
x IND                            REFIND855
x IND_FLAG                       REFIND176
x IND_OWNER                      REFIND29
x IND_TAG                        REFIND227
x IND_WINDOW                     REFIND30
??? MCD_MAP                        FK_MCD_MAP_1
??? MCD_MAP                        FK_MCD_MAP_2
x PENDING_IND                    REFIND474
x RANGE_IND_MEMBER               REFIND235
x RANGE_IND_MEMBER               REFIND24
x REGION_RECALC_JOB              REFIND23
x SHEET_VALUE                    REFIND110
x SHEET_VALUE_CHANGE             REFIND142
x SNAPSHOT_IND                   REFIND866
x STORED_CALC_JOB                REFIND33
x TARGET                         REFIND36
x TARGET_DASHBOARD_IND_MEMBER    REFIND127
x TARGET_DASHBOARD_IND_MEMBER    REFIND128
x TARGET_DASHBOARD_VALUE         REFIND130
x TPL_REPORT_TAG_IND             REFIND909
x UNAPPROVED_VAL                 REFIND640
x VAL                            FK_VAL_IND
x VAL_NOTE                       REFIND39
*/

alter table ind drop primary key cascade drop index ;
alter table ind add constraint pk_ind primary key (app_sid, ind_sid);
alter table ind add constraint uk_ind_ind_sid unique (ind_sid) 
using index tablespace indx;
ALTER TABLE IND ADD CONSTRAINT RefIND855 
    FOREIGN KEY (APP_SID, AGGR_ESTIMATE_WITH_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
;


alter table all_meter add app_sid number(10) default sys_context('SECURITY','APP');
ALTER TABLE ALL_METER ADD CONSTRAINT RefIND848 
    FOREIGN KEY (APP_SID, PRIMARY_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
update all_meter set app_sid = (select app_sid from ind where primary_ind_sid = ind_sid);

/* orphans?
delete from meter_reading where rowid in (
	select mr.rowid
	  from all_meter am, meter_reading mr
	 where am.primary_ind_sid not in (select ind_sid from ind) and
	 	   mr.region_sid = am.region_sid);
delete from all_meter where primary_ind_sid not in (select ind_sid from ind);
*/
alter table all_meter modify app_sid not null;

alter table attachment add app_sid number(10) default sys_context('SECURITY','APP');
update attachment set app_sid = (select app_sid from ind where indicator_sid = ind_sid);
ALTER TABLE ATTACHMENT ADD CONSTRAINT RefIND825 
    FOREIGN KEY (APP_SID, INDICATOR_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;

-- TODO: attachment pk should include / push app_sid too (looks messy!)

alter table calc_dependency add app_sid number(10) default sys_context('SECURITY','APP');
update calc_dependency set app_sid = (select app_sid from ind where calc_ind_sid = ind_sid);
alter table calc_dependency modify app_sid not null;
ALTER TABLE CALC_DEPENDENCY ADD CONSTRAINT RefIND17 
    FOREIGN KEY (APP_SID, CALC_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
ALTER TABLE CALC_DEPENDENCY ADD CONSTRAINT RefIND32 
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES IND(APP_SID, IND_SID)
;

alter table calc_dependency drop primary key drop index;
alter table calc_dependency add 
CONSTRAINT PK_CALC_DEPENDENCY PRIMARY KEY (APP_SID, CALC_IND_SID, IND_SID, DEP_TYPE)
     USING INDEX
 TABLESPACE INDX;
 
-- TODO: push into pk
alter TABLE DASHBOARD_ITEM add app_sid number(10) default sys_context('SECURITY','APP');
update dashboard_item set app_sid = (select app_sid from ind where ind.ind_sid = dashboard_item.ind_sid);
alter table dashboard_item modify app_sid not null;
 
ALTER TABLE DASHBOARD_ITEM ADD CONSTRAINT RefIND59 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ; 
 
-- TODO: push into pk
alter table  DATAVIEW_ZONE add app_sid number(10)  default sys_context('SECURITY','APP');
update DATAVIEW_ZONE set app_sid = (select app_sid from ind where start_val_ind_sid = ind.ind_sid);
alter table  dataview_zone modify app_sid not null;

ALTER TABLE DATAVIEW_ZONE ADD CONSTRAINT RefIND363 
    FOREIGN KEY (APP_SID, START_VAL_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
 
ALTER TABLE DATAVIEW_ZONE ADD CONSTRAINT RefIND365 
    FOREIGN KEY (APP_SID, END_VAL_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
  
alter table DELEGATION_IND add app_sid number(10) default sys_context('SECURITY','APP');
update delegation_ind set app_sid = (select app_sid from ind where delegation_ind.ind_sid = ind.ind_sid);
alter table  delegation_ind modify app_sid not null;
ALTER TABLE DELEGATION_IND ADD CONSTRAINT RefIND101 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
alter table delegation_ind drop primary key drop index;
alter table delegation_ind add 
CONSTRAINT PK60 PRIMARY KEY (APP_SID, DELEGATION_SID, IND_SID);

-- crap on live
delete 
  from imp_val
 where imp_ind_id in (
 	select imp_ind_id
 	  from imp_ind
 	 where maps_to_ind_sid in (
	 	select maps_to_ind_sid from (
	 		select app_sid, maps_to_ind_sid
	 		  from imp_ind
	 		 minus
	 		select app_sid, ind_sid
	 		  from ind)));
delete 
  from imp_ind 
 where maps_to_ind_sid in (
 	select maps_to_ind_sid from (
 		select app_sid, maps_to_ind_sid
 		  from imp_ind
 		 minus
 		select app_sid, ind_sid
 		  from ind));
 		   
ALTER TABLE IMP_IND ADD constraint RefIND13
   FOREIGN KEY (APP_SID, MAPS_TO_IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
;

 
alter table  IND_ACCURACY_TYPE add app_sid number(10) default sys_context('SECURITY','APP');
update ind_accuracy_type set app_sid = (select app_sid from ind where ind.ind_sid = ind_accuracy_type.ind_sid);
alter table ind_accuracy_type modify app_sid not null;
 ALTER TABLE IND_ACCURACY_TYPE ADD CONSTRAINT RefIND437 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
alter table ind_accuracy_type drop primary key drop index;
alter table ind_accuracy_type add constraint PK165 PRIMARY KEY (APP_SID, IND_SID, ACCURACY_TYPE_ID)
using index tablespace indx;

alter table ind_flag  add app_sid number(10) default sys_context('SECURITY','APP');
update ind_flag set app_sid = (select app_sid from ind where ind.ind_sid = ind_flag.ind_sid);
alter table ind_flag  modify app_sid not null;
ALTER TABLE IND_FLAG ADD CONSTRAINT RefIND176 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
;
alter table ind_flag drop primary key cascade drop index;
alter table ind_flag add
CONSTRAINT PK105 PRIMARY KEY (APP_SID, IND_SID, FLAG);

alter table sheet_value add app_sid number(10) default sys_context('SECURITY','APP');
update sheet_value set app_sid = (select app_sid from ind where ind.ind_sid = sheet_value.ind_sid);
alter table sheet_value modify app_sid not null;
ALTER TABLE SHEET_VALUE ADD CONSTRAINT RefIND110 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
 ALTER TABLE SHEET_VALUE ADD CONSTRAINT RefIND_FLAG177 
    FOREIGN KEY (APP_SID, IND_SID, FLAG)
    REFERENCES IND_FLAG(APP_SID, IND_SID, FLAG)
 ;
 
alter table sheet_value_change add app_sid number(10) default sys_context('SECURITY','APP');
update sheet_value_change set app_sid = (select app_sid from ind where ind.ind_sid = sheet_value_change.ind_sid);
alter table sheet_value_change modify app_sid not null;
 ALTER TABLE SHEET_VALUE_CHANGE ADD CONSTRAINT RefIND142 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
  ALTER TABLE SHEET_VALUE_CHANGE ADD CONSTRAINT RefIND_FLAG179 
   FOREIGN KEY (APP_SID, IND_SID, FLAG)
   REFERENCES IND_FLAG(APP_SID, IND_SID, FLAG)
 ;

alter table ind_owner  add app_sid number(10) default sys_context('SECURITY','APP');
update ind_owner set app_sid = (select app_sid from ind where ind.ind_sid = ind_owner.ind_sid);
alter table ind_owner modify app_sid not null;
ALTER TABLE IND_OWNER ADD CONSTRAINT RefIND29 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
alter table ind_owner drop primary key drop index;
alter table ind_owner add
CONSTRAINT PK_IND_OWNER PRIMARY KEY (APP_SID, IND_SID, USER_SID)
;

alter table ind_tag  add app_sid number(10) default sys_context('SECURITY','APP');
update ind_tag set app_sid = (select app_sid from ind where ind.ind_sid = ind_tag.ind_sid);
alter table ind_tag modify app_sid not null;
ALTER TABLE IND_TAG ADD CONSTRAINT RefIND227 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
alter table ind_tag drop primary key drop index;
alter table ind_tag add
    CONSTRAINT PK138 PRIMARY KEY (APP_SID, TAG_ID, IND_SID);

 
 
alter table ind_window add app_sid number(10) default sys_context('SECURITY','APP');
update ind_window set app_sid = (select app_sid from ind where ind.ind_sid = ind_window.ind_sid);
alter table ind_window modify app_sid not null;
ALTER TABLE IND_WINDOW ADD CONSTRAINT RefIND30 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
;
alter table ind_window drop primary key drop index;
alter table ind_window add
   CONSTRAINT PK_IND_WINDOW PRIMARY KEY (IND_SID, PERIOD, APP_SID);


alter table pending_ind add app_sid number(10) default sys_context('SECURITY','APP');
update pending_ind set app_sid = (select app_sid from ind where ind.ind_sid = pending_ind.maps_to_ind_sid);
ALTER TABLE PENDING_IND ADD CONSTRAINT RefIND474 
   FOREIGN KEY (APP_SID, MAPS_TO_IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
 

alter table range_ind_member add app_sid number(10) default sys_context('SECURITY','APP');
update range_ind_member set app_sid = (select app_sid from ind where ind.ind_sid = range_ind_member.ind_sid);
alter table range_ind_member modify app_sid not null;
alter table range_ind_member drop primary key drop index;
alter table range_ind_member add 
	CONSTRAINT PK_RANGE_IND_MEMBER PRIMARY KEY (APP_SID, RANGE_SID, IND_SID)
     USING INDEX TABLESPACE INDX;
ALTER TABLE RANGE_IND_MEMBER ADD CONSTRAINT RefIND24 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
;
ALTER TABLE RANGE_IND_MEMBER ADD CONSTRAINT RefIND235 
    FOREIGN KEY (APP_SID, MULTIPLIER_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;

alter table snapshot_ind add app_sid number(10) default sys_context('SECURITY','APP');
update snapshot_ind set app_sid = (select app_sid from ind where ind.ind_sid = snapshot_ind.ind_sid);
alter table snapshot_ind modify app_sid not null;
alter table snapshot_ind drop primary key drop index;
alter table snapshot_ind add 
	CONSTRAINT PK440 PRIMARY KEY (APP_SID, NAME, IND_SID)
 ;
ALTER TABLE SNAPSHOT_IND ADD CONSTRAINT RefIND870 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
 

alter table target add app_sid number(10) default sys_context('SECURITY','APP');
update target set app_sid = (select app_sid from ind where ind.ind_sid = target.ind_sid);
alter table target modify app_sid not null;
ALTER TABLE TARGET ADD CONSTRAINT RefIND36 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
 

alter table target_dashboard_ind_member add app_sid number(10) default sys_context('SECURITY','APP');
update target_dashboard_ind_member set app_sid = (select app_sid from ind where ind.ind_sid = target_dashboard_ind_member.ind_sid);
alter table target_dashboard_ind_member modify app_sid not null;
ALTER TABLE TARGET_DASHBOARD_IND_MEMBER ADD CONSTRAINT RefIND127 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
 ALTER TABLE TARGET_DASHBOARD_IND_MEMBER ADD CONSTRAINT RefIND128 
   FOREIGN KEY (APP_SID, TARGET_IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
alter table target_dashboard_ind_member drop primary key drop index;
alter table target_dashboard_ind_member add 
	CONSTRAINT PK_TARGET_DASHBOARD_IND_MEMBER PRIMARY KEY (APP_SID, TARGET_DASHBOARD_SID, IND_SID);
 
alter table target_dashboard_value add app_sid number(10) default sys_context('SECURITY','APP');
update target_dashboard_value set app_sid = (select app_sid from ind where ind.ind_sid = target_dashboard_value.ind_sid);
alter table target_dashboard_value modify app_sid not null;
ALTER TABLE TARGET_DASHBOARD_VALUE ADD CONSTRAINT RefIND130 
    FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
;
alter table target_dashboard_value drop primary key drop index;
alter table target_dashboard_value add 
    CONSTRAINT PK_TARGET_DASHBOARD_VALUE PRIMARY KEY (app_sid, TARGET_DASHBOARD_SID, IND_SID, REGION_SID)
    using index tablespace indx;
    

alter table tpl_report_tag_ind add app_sid number(10) default sys_context('SECURITY','APP');
update tpl_report_tag_ind set app_sid = (select app_sid from ind where ind.ind_sid = tpl_report_tag_ind.ind_sid);
alter table tpl_report_tag_ind modify app_sid not null;
ALTER TABLE TPL_REPORT_TAG_IND ADD CONSTRAINT RefIND909 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
;
alter table tpl_report_tag_ind drop primary key drop index;
alter table tpl_report_tag_ind add 
    CONSTRAINT PK1003 PRIMARY KEY (APP_SID, TPL_REPORT_SID, TAG, IND_SID);
 
alter table unapproved_val add app_sid number(10) default sys_context('SECURITY','APP');
update unapproved_val set app_sid = (select app_sid from ind where ind.ind_sid = unapproved_val.ind_sid);
alter table unapproved_val modify app_sid not null;
  
ALTER TABLE UNAPPROVED_VAL ADD CONSTRAINT RefIND640 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID);
alter table unapproved_val drop primary key drop index;
alter table unapproved_val add 
    CONSTRAINT PK353 PRIMARY KEY (app_sid, IND_SID, REGION_SID, START_DTM, END_DTM)
; 
 

alter table val add app_sid number(10) default sys_context('SECURITY','APP');
update val set app_sid = (select app_sid from ind where ind.ind_sid = val.ind_sid);
alter table val modify app_sid not null;
ALTER TABLE VAL ADD CONSTRAINT FK_VAL_IND 
   FOREIGN KEY (APP_SID, IND_SID)
   REFERENCES IND(APP_SID, IND_SID)
 ;
 
alter table val_note add app_sid number(10) default sys_context('SECURITY','APP');
update val_note set app_sid = (select app_sid from ind where ind.ind_sid = val_note.ind_sid);
alter table val_note modify app_sid not null;
 ALTER TABLE VAL_NOTE ADD CONSTRAINT RefIND39 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
 

ALTER TABLE CUSTOMER ADD CONSTRAINT FK_CUST_IND_ROOT_IND 
   FOREIGN KEY (APP_SID, IND_ROOT_SID)
   REFERENCES IND(APP_SID, IND_SID)
;
 
 
ALTER TABLE REGION_RECALC_JOB ADD CONSTRAINT RefIND23 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;
 
 
ALTER TABLE STORED_CALC_JOB ADD CONSTRAINT RefIND729 
    FOREIGN KEY (APP_SID, CALC_IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
 ;

@update_tail
