-- Please update version.sql too -- this keeps clean builds in sync
define version=237
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

/* all constraints referencing PK59
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK59','PK_DELEGATION')
order by table_name, constraint_name;

DELEGATION_IND                 REFDELEGATION100
DELEGATION_REGION              REFDELEGATION103
DELEGATION_USER                REFDELEGATION105
SHEET                          REFDELEGATION106
SHEET_HISTORY                  REFDELEGATION158
*/

alter table delegation drop primary key cascade drop index ;
alter table delegation add constraint pk_delegation primary key (app_sid, delegation_sid)
using index tablespace indx;

alter table sheet add app_sid number(10) default sys_context('SECURITY','APP');
update sheet set app_sid = (select app_sid from delegation where delegation.delegation_sid = sheet.delegation_sid);
alter table sheet modify app_sid not null;
 

/* now do same for sheet 
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_SHEET','PK63')
order by table_name, constraint_name;

SHEET_HISTORY                  REFSHEET108
SHEET_VALUE                    REFSHEET112

select table_name,constraint_name from user_constraints where r_constraint_name in ('PK64','PK_SHEET_HISTORY')
order by table_name, constraint_name;

SHEET                          REFSHEET_HISTORY116
*/
alter table sheet drop primary key cascade drop index ;
alter table sheet add constraint pk_sheet primary key (app_sid, sheet_id)
using index tablespace indx;

alter table sheet_history drop primary key cascade drop index;
alter table sheet_history add constraint pk_sheet_history PRIMARY KEY (APP_SID, SHEET_HISTORY_ID)
using index tablespace indx;


alter table SHEET_INHERITED_VALUE add app_sid number(10) default sys_context('SECURITY','APP');
update SHEET_INHERITED_VALUE set app_sid = (
	select app_sid from sheet_value where SHEET_INHERITED_VALUE.sheet_value_id = sheet_value.sheet_value_id);
alter table SHEET_INHERITED_VALUE modify app_sid not null;
alter table SHEET_INHERITED_VALUE drop primary key drop index;
alter table SHEET_INHERITED_VALUE add
    CONSTRAINT PK_SHEET_INHERITED_VALUE PRIMARY KEY (APP_SID, SHEET_VALUE_ID, INHERITED_VALUE_ID)
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK65','PK_SHEET_VALUE')
order by table_name, constraint_name;

SHEET_INHERITED_VALUE          REFSHEET_VALUE119
SHEET_INHERITED_VALUE          REFSHEET_VALUE120
SHEET_VALUE_ACCURACY           REFSHEET_VALUE439
SHEET_VALUE_CHANGE             REFSHEET_VALUE146
SHEET_VALUE_FILE               REFSHEET_VALUE733
*/
alter table sheet_value drop primary key cascade drop index ;
alter table sheet_value add
    CONSTRAINT PK_sheet_value PRIMARY KEY (APP_SID, SHEET_VALUE_ID);
    
alter table SHEET_VALUE_ACCURACY add app_sid number(10) default sys_context('SECURITY','APP');
update SHEET_VALUE_ACCURACY set app_sid = (
	select app_sid from sheet_value where sheet_value.sheet_value_id = sheet_value_accuracy.sheet_value_id);
alter table SHEET_VALUE_ACCURACY modify app_sid not null;
alter table SHEET_VALUE_ACCURACY drop primary key drop index;
alter table SHEET_VALUE_ACCURACY add 
    CONSTRAINT PK_SHEET_VALUE_ACCURACY PRIMARY KEY (APP_SID, SHEET_VALUE_ID, ACCURACY_TYPE_OPTION_ID)
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK82','PK_SHEET_VALUE_CHANGE')
order by table_name, constraint_name;

SHEET_VALUE                    REFSHEET_VALUE_CHANGE141
SHEET_VALUE_CHANGE_FILE        REFSHEET_VALUE_CHANGE737
*/
alter table sheet_value_change drop primary key cascade drop index ;
alter table sheet_value_change add
    CONSTRAINT PK_sheet_value_change PRIMARY KEY (APP_SID, SHEET_VALUE_CHANGE_ID)
 ;
 
 
alter table SHEET_VALUE_CHANGE_FILE add app_sid number(10) default sys_context('SECURITY','APP');
update SHEET_VALUE_CHANGE_FILE set app_sid = (
	select app_sid from SHEET_VALUE_CHANGE where SHEET_VALUE_CHANGE.SHEET_VALUE_CHANGE_ID = SHEET_VALUE_CHANGE_FILE.SHEET_VALUE_CHANGE_ID);
alter table SHEET_VALUE_CHANGE_FILE modify app_sid not null;
alter table SHEET_VALUE_CHANGE_FILE drop primary key drop index;
alter table SHEET_VALUE_CHANGE_FILE add constraint 
	PK_SHEET_VALUE_CHANGE_FILE PRIMARY KEY (SHEET_VALUE_CHANGE_ID, FILE_UPLOAD_SID);


alter TABLE SHEET_VALUE_FILE add app_sid number(10) default sys_context('SECURITY','APP');
update SHEET_VALUE_FILE set app_sid = (select app_sid from sheet_value where sheet_value.sheet_value_id = sheet_value_file.sheet_value_id);
alter table SHEET_VALUE_FILE modify app_sid not null;
alter table SHEET_VALUE_FILE drop primary key drop index;
alter table SHEET_VALUE_FILE add constraint
PK_SHEET_VALUE_FILE PRIMARY KEY (APP_SID, SHEET_VALUE_ID, FILE_UPLOAD_SID)
 ;


-- rbs.credit360.com has some weird delegation_inds crossed with test.rbs.credit360.com
/*
select app_sid,delegation_sid from delegation_ind minus select app_sid,delegation_sid from delegation;

   APP_SID DELEGATION_SID
---------- --------------
   1220584        4093897
   1220584        4093902
   1220584        7721381
   1220584        7721382
select app_sid from delegation where delegation_sid in (select delegation_sid from (
select app_sid,delegation_sid from delegation_ind minus select app_sid,delegation_sid from delegation));
select host from customer where app_sid=3632553;

select di.app_sid di_app_sid,d.app_sid del_app_sid,di.delegation_sid,di.ind_sid,i.app_sid ind_app_sid
 from delegation_ind di, delegation d, ind i
where di.delegation_sid = d.delegation_sid and di.ind_sid = i.ind_sid and d.app_sid <> di.app_sid ;

-- all tests that belong to test.rbs.credit360.com with x-wired inds, nuke them
*/

delete from delegation_ind where rowid in (
select di.rowid 
 from delegation_ind di, delegation d, ind i
where di.delegation_sid = d.delegation_sid and di.ind_sid = i.ind_sid and
d.app_sid <> di.app_sid 
);
 ALTER TABLE DELEGATION_IND ADD CONSTRAINT RefDELEGATION100 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
 ;

-- same here
/*
select dr.app_sid dr_app_sid,d.app_sid del_app_sid,dr.delegation_sid,dr.region_sid,r.app_sid region_app_sid
 from delegation_region dr, delegation d, region r
where dr.delegation_sid = d.delegation_sid and dr.region_sid = r.region_sid and d.app_sid <> dr.app_sid ;
*/ 
delete from delegation_region where rowid in (
select dr.rowid
 from delegation_region dr, delegation d, region r
where dr.delegation_sid = d.delegation_sid and dr.region_sid = r.region_sid and d.app_sid <> dr.app_sid );
 ALTER TABLE DELEGATION_REGION ADD CONSTRAINT RefDELEGATION103 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
 ;
 
 ALTER TABLE DELEGATION_USER ADD CONSTRAINT RefDELEGATION105 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
 ;
 
 ALTER TABLE SHEET ADD CONSTRAINT RefDELEGATION106 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
 ;
 
 ALTER TABLE SHEET ADD CONSTRAINT RefSHEET_HISTORY116 
    FOREIGN KEY (APP_SID, LAST_SHEET_HISTORY_ID)
    REFERENCES SHEET_HISTORY(APP_SID, SHEET_HISTORY_ID)
 ;
 
 
 
 ALTER TABLE SHEET_HISTORY ADD CONSTRAINT RefDELEGATION158 
    FOREIGN KEY (APP_SID, TO_DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
 ;
 
 ALTER TABLE SHEET_HISTORY ADD CONSTRAINT RefSHEET108 
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES SHEET(APP_SID, SHEET_ID)
 ;
 
 
 ALTER TABLE SHEET_INHERITED_VALUE ADD CONSTRAINT RefSHEET_VALUE119 
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
 ALTER TABLE SHEET_INHERITED_VALUE ADD CONSTRAINT RefSHEET_VALUE120 
    FOREIGN KEY (APP_SID, INHERITED_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
 
 ALTER TABLE SHEET_VALUE ADD CONSTRAINT RefSHEET_VALUE_CHANGE141 
    FOREIGN KEY (APP_SID, LAST_SHEET_VALUE_CHANGE_ID)
    REFERENCES SHEET_VALUE_CHANGE(APP_SID, SHEET_VALUE_CHANGE_ID)
 ;
 
 ALTER TABLE SHEET_VALUE ADD CONSTRAINT RefSHEET112 
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES SHEET(APP_SID, SHEET_ID)
 ;

--
 ALTER TABLE SHEET_VALUE_ACCURACY ADD CONSTRAINT RefSHEET_VALUE439 
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
 
 ALTER TABLE SHEET_VALUE_CHANGE ADD CONSTRAINT RefSHEET_VALUE146 
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
 
 ALTER TABLE SHEET_VALUE_CHANGE_FILE ADD CONSTRAINT RefSHEET_VALUE_CHANGE737 
    FOREIGN KEY (APP_SID, SHEET_VALUE_CHANGE_ID)
    REFERENCES SHEET_VALUE_CHANGE(APP_SID, SHEET_VALUE_CHANGE_ID)
 ;
 
 ALTER TABLE SHEET_VALUE_FILE ADD CONSTRAINT RefSHEET_VALUE739 
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
@update_tail
