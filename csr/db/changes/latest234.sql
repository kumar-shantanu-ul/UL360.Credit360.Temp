-- Please update version.sql too -- this keeps clean builds in sync
define version=234
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
all constraints referencing PK_REGION
select table_name,constraint_name from user_constraints where r_constraint_name='PK_REGION'
order by table_name, constraint_name;

x ALL_METER                      REFREGION852
x CUSTOMER                       FK_CUST_REG_ROOT_REGION
x DASHBOARD_ITEM                 REFREGION58
x DATAVIEW_ZONE                  REFREGION364
x DATAVIEW_ZONE                  REFREGION366
x DELEGATION_REGION              REFREGION102
x IMP_REGION                     REFREGION14
x PCT_OWNERSHIP                  REFREGION564
x PCT_OWNERSHIP_CHANGE           REFREGION570
x PENDING_REGION                 REFREGION480
x RANGE_REGION_MEMBER            REFREGION25
x REGION                         REFREGION219
x REGION_OWNER                   REFREGION74
x REGION_ROLE_MEMBER             REFREGION763
x REGION_TAG                     REFREGION229
x SHEET_VALUE                    REFREGION111
x SHEET_VALUE_CHANGE             REFREGION143
x SURVEY_RESPONSE                REFREGION562
x TARGET                         REFREGION37
x TARGET_DASHBOARD_VALUE         REFREGION131
x UNAPPROVED_VAL                 REFREGION639
x VAL                            REFREGION6
x VAL_NOTE                       REFREGION38
*/

alter table region drop primary key cascade drop index ;
alter table region add constraint pk_region primary key (app_sid, region_sid);
alter table region add constraint uk_region_region_sid unique (region_sid) 
using index tablespace indx;
ALTER TABLE REGION ADD CONSTRAINT RefREGION219 
   FOREIGN KEY (APP_SID, LINK_TO_REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
;
  

alter table all_meter drop primary key cascade drop index;
alter table all_meter add 
    CONSTRAINT PK406 PRIMARY KEY (APP_SID, REGION_SID);

alter table meter_reading add app_sid number(10) default sys_context('SECURITY','APP');
update meter_reading set app_sid = (select app_sid from region where region.region_sid = meter_reading.region_sid);
alter table meter_reading modify app_sid not null;

alter table delegation_region add app_sid number(10) default sys_context('SECURITY','APP');
update delegation_region set app_sid = (select app_sid from region where region.region_sid = delegation_region.region_sid);
alter table delegation_region modify app_sid not null;
alter table delegation_region drop primary key drop index;
alter table delegation_region add
   CONSTRAINT PK61 PRIMARY KEY (DELEGATION_SID, REGION_SID, APP_SID)
 ;

-- because it's now part of an optional key 
alter table imp_region modify app_sid null;
  
alter table pct_ownership add app_sid number(10) default sys_context('SECURITY','APP');
update pct_ownership set app_sid = (select app_sid from region where region.region_sid = pct_ownership.region_sid);
alter table pct_ownership modify app_sid not null;
alter table pct_ownership drop primary key drop index;
alter table pct_ownership add
  CONSTRAINT PK315 PRIMARY KEY (APP_SID, REGION_SID, START_DTM)
 ;
 
 
alter table pct_ownership_change add app_sid number(10) default sys_context('SECURITY','APP');
update pct_ownership_change set app_sid = (select app_sid from region where region.region_sid = pct_ownership_change.region_sid);

alter table pending_region add app_sid number(10) default sys_context('SECURITY','APP');
update pending_region set app_sid = (select app_sid from region where region.region_sid = pending_region.maps_to_region_sid);
  

alter table range_region_member add app_sid number(10) default sys_context('SECURITY','APP');
update range_region_member set app_sid = (select app_sid from region where region.region_sid = range_region_member.region_sid);
alter table range_region_member modify app_sid not null;
alter table range_region_member drop primary key drop index;
alter table range_region_member add
   CONSTRAINT PK_RANGE_REGION_MEMBER PRIMARY KEY (APP_SID, RANGE_SID, REGION_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 
 
alter table region_owner add app_sid number(10) default sys_context('SECURITY','APP');
update region_owner set app_sid = (select app_sid from region where region.region_sid = region_owner.region_sid);
alter table region_owner modify app_sid not null;
alter table region_owner drop primary key drop index;
alter table region_owner add
   CONSTRAINT PK51 PRIMARY KEY (APP_SID, REGION_SID, USER_SID)
 ;
 
alter table region_role_member add app_sid number(10) default sys_context('SECURITY','APP');
update region_role_member set app_sid = (select app_sid from region where region.region_sid = region_role_member.region_sid);
alter table region_role_member modify app_sid not null;
alter table region_role_member drop primary key drop index;
alter table region_role_member add
    CONSTRAINT PK_REGION_ROLE_MEMBER PRIMARY KEY (APP_SID, USER_SID, REGION_SID, ROLE_SID)
 ;

alter table region_tag add app_sid number(10) default sys_context('SECURITY','APP');
update region_tag set app_sid = (select app_sid from region where region.region_sid = region_tag.region_sid);
alter table region_tag modify app_sid not null;
alter table region_tag drop primary key drop index;
alter table region_tag add
   CONSTRAINT PK137 PRIMARY KEY (APP_SID, TAG_ID, REGION_SID)
 ;
 
 
alter table survey_response add app_sid number(10) default sys_context('SECURITY','APP');
update survey_response set app_sid = (select app_sid from region where region.region_sid = survey_response.region_sid);
alter table survey_response modify app_sid not null;
 
 
ALTER TABLE ALL_METER ADD CONSTRAINT RefREGION852 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE CUSTOMER ADD CONSTRAINT FK_CUST_REG_ROOT_REGION 
    FOREIGN KEY (APP_SID, REGION_ROOT_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE DASHBOARD_ITEM ADD CONSTRAINT RefREGION58 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE DATAVIEW_ZONE ADD CONSTRAINT RefREGION364 
    FOREIGN KEY (APP_SID, START_VAL_REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;
  
 ALTER TABLE DATAVIEW_ZONE ADD CONSTRAINT RefREGION366 
    FOREIGN KEY (APP_SID, END_VAL_REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE DELEGATION_REGION ADD CONSTRAINT RefREGION102 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
  
delete 
  from imp_region 
 where maps_to_region_sid in (
 	select maps_to_region_sid from (
 		select app_sid, maps_to_region_sid
 		  from imp_region
 		 minus
 		select app_sid, region_sid
 		  from region));

 ALTER TABLE IMP_REGION ADD CONSTRAINT RefREGION14 
    FOREIGN KEY (APP_SID, MAPS_TO_REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE METER_READING ADD CONSTRAINT RefALL_METER853 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES ALL_METER(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE PCT_OWNERSHIP ADD CONSTRAINT RefREGION564 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE PCT_OWNERSHIP_CHANGE ADD CONSTRAINT RefREGION570 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;
 

 ALTER TABLE PENDING_REGION ADD CONSTRAINT RefREGION480 
    FOREIGN KEY (APP_SID, MAPS_TO_REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
 ;

 ALTER TABLE RANGE_REGION_MEMBER ADD CONSTRAINT RefREGION25 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE REGION_OWNER ADD CONSTRAINT RefREGION74 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;

 ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefREGION763 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;

 ALTER TABLE REGION_TAG ADD CONSTRAINT RefREGION229 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE SHEET_VALUE ADD CONSTRAINT RefREGION111 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE SHEET_VALUE_CHANGE ADD CONSTRAINT RefREGION143 
   FOREIGN KEY (APP_SID, REGION_SID)
  REFERENCES REGION(APP_SID, REGION_SID)
 ;
  
 ALTER TABLE SURVEY_RESPONSE ADD CONSTRAINT RefREGION562 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE TARGET ADD CONSTRAINT RefREGION37 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE TARGET_DASHBOARD_VALUE ADD CONSTRAINT RefREGION131 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE UNAPPROVED_VAL ADD CONSTRAINT RefREGION639 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 
 ALTER TABLE VAL ADD CONSTRAINT RefREGION6 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE VAL_NOTE ADD CONSTRAINT RefREGION38 
   FOREIGN KEY (APP_SID, REGION_SID)
   REFERENCES REGION(APP_SID, REGION_SID)
 ;

@update_tail
