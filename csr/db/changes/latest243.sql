-- Please update version.sql too -- this keeps clean builds in sync
define version=243
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
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK127','PK_DIARY_EVENT')
order by table_name, constraint_name;

x DIARY_EVENT_GROUP              REFDIARY_EVENT202
*/
alter table diary_event modify app_sid  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table diary_event drop primary key cascade drop index;
alter table diary_event add 
    CONSTRAINT PK_DIARY_EVENT PRIMARY KEY (APP_SID, DIARY_EVENT_SID)
    USING INDEX
TABLESPACE INDX
 ;

 
alter table DIARY_EVENT_GROUP add APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update diary_event_Group set app_sid = (select app_sid from diary_event where diary_event.diary_Event_sid=diary_event_group.diary_event_sid);
alter table diary_event_group modify app_sid not null;
alter table diary_Event_group drop primary key drop index;
alter table diary_event_group add 
    CONSTRAINT PK_DIARY_EVENT_GROUP PRIMARY KEY (APP_SID, DIARY_EVENT_SID, GROUP_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_OBJECTIVE')
order by table_name, constraint_name;

x OBJECTIVE_STATUS               REFOBJECTIVE54
*/
alter table objective modify app_sid  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update objective set app_sid = (select application_sid_id from security.securable_object so where so.sid_id=objective.objective_sid)
where app_sid is null;
alter table objective modify app_sid not null;
alter table objective drop primary key cascade drop index;
alter table objective add
    CONSTRAINT PK_OBJECTIVE PRIMARY KEY (APP_SID, OBJECTIVE_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 

alter table OBJECTIVE_STATUS drop primary key drop index;
alter table OBJECTIVE_STATUS add
CONSTRAINT PK_OBJECTIVE_STATUS PRIMARY KEY (APP_SID, OBJECTIVE_SID, START_DTM, END_DTM)
     USING INDEX
 TABLESPACE INDX
 ;


alter table PCT_OWNERSHIP_CHANGE modify app_Sid not null;
alter table PCT_OWNERSHIP_CHANGE drop primary key drop index;
alter table PCT_OWNERSHIP_CHANGE add
    CONSTRAINT PK_PCT_OWNERSHIP_CHANGE PRIMARY KEY (APP_SID, PCT_OWNERSHIP_CHANGE_ID)
    USING INDEX
TABLESPACE INDX
 ;


/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_QUICK_SURVEY','PK116')
order by table_name, constraint_name;
x QUICK_SURVEY_RESPONSE          REFOLDSURVEY192
*/
alter table QUICK_SURVEY add  APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update quick_survey set app_sid = (select application_sid_id from security.securable_object so where so.sid_id=quick_survey.survey_sid);
delete from quick_survey where survey_sid not in (select sid_id from security.securable_object) and app_sid is null;
alter table quick_survey modify app_sid not null;
alter table quick_survey drop primary key cascade drop index;
alter table quick_survey add
    CONSTRAINT PK_QUICK_SURVEY PRIMARY KEY (APP_SID, SURVEY_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_QUICK_SURVEY_RESPONSE','PK117')
order by table_name, constraint_name;
x QUICK_SURVEY_RESPONSE_ANSWER   REFSURVEY_RESPONSE193
*/
alter TABLE QUICK_SURVEY_RESPONSE add APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update QUICK_SURVEY_RESPONSE set app_sid = (select app_sid from quick_survey where quick_survey.survey_sid=quick_survey_response.survey_sid);
alter table QUICK_SURVEY_RESPONSE modify app_sid not null;
alter table QUICK_SURVEY_RESPONSE drop primary key cascade drop index;
alter table QUICK_SURVEY_RESPONSE add
    CONSTRAINT PK_QUICK_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter TABLE QUICK_SURVEY_RESPONSE_ANSWER add APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update QUICK_SURVEY_RESPONSE_ANSWER set app_sid = (select app_sid from QUICK_SURVEY_RESPONSE where QUICK_SURVEY_RESPONSE_ANSWER.SURVEY_RESPONSE_ID = QUICK_SURVEY_RESPONSE.SURVEY_RESPONSE_ID);
alter TABLE QUICK_SURVEY_RESPONSE_ANSWER modify app_sid not null;
alter TABLE QUICK_SURVEY_RESPONSE_ANSWER drop primary key drop index;
alter TABLE QUICK_SURVEY_RESPONSE_ANSWER add 
    CONSTRAINT PK_QUICK_SURVEY_RESP_ANSWR PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID, QUESTION_CODE)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter table  SESSION_EXTRA  add    APP_SID    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update session_extra set app_sid  = (
	select so.application_sid_id 
	  from security.securable_object so, security.act
	 where act.act_id = session_extra.act_id and act.act_index=1 and
	 	   act.sid_id=so.sid_id );
delete from session_extra where act_id not in (select act_id from security.act_timeout);
alter table SESSION_EXTRA modify app_sid not null;
alter table SESSION_EXTRA drop primary key drop index;
alter table SESSION_EXTRA add
    CONSTRAINT PK_SESSION_EXTRA PRIMARY KEY (APP_SID, ACT_ID, KEY)
     USING INDEX
 TABLESPACE INDX
 ;
 
 
alter table trash modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update TRASH tx set app_sid = (
	select application_sid_id 
	  from security.securable_object so, trash t
	 where tx.trash_sid = t.trash_sid and so.sid_id = t.trash_sid) where app_sid is null;
delete from trash where trash_sid not in (select sid_id from security.securable_object) and app_sid is null;
-- hmm, need to fix up security again, some things have popped up without app sids -- scripts, etc i guess
-- will be harder in future

begin
	for r in (select trash_sid from trash where app_sid is null) loop
		for s in (select application_sid_id
					from security.securable_object
					start with sid_id = r.trash_sid
					connect by prior parent_sid_id = sid_id) loop
			if s.application_sid_id is not null then
				update trash 
				   set app_sid = s.application_sid_id
				 where trash_sid = r.trash_sid;
				 exit;
			end if;
		end loop;
	end loop;
end;
/

alter table trash modify app_sid not null;
alter table trash drop primary key drop index;
alter table trash add 
    CONSTRAINT PK_TRASH PRIMARY KEY (APP_SID, TRASH_SID)
    USING INDEX
TABLESPACE INDX
 ;

begin
	for r in (select index_name from user_indexes where index_name in(
		'REF561', 'REF562', 'REF3254', 'REF563'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/

CREATE INDEX IDX_OBJECTIVE_DELIVERY_USER ON OBJECTIVE(APP_SID, DELIVERY_USER_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_OBJECTIVE_RESPON_USER ON OBJECTIVE(APP_SID, RESPONSIBLE_USER_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_OBJCTV_STAT_UPDATD_BY ON OBJECTIVE_STATUS(APP_SID, UPDATED_BY_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_OBJCTV_STAT_OBJCTV ON OBJECTIVE_STATUS(APP_SID, OBJECTIVE_SID)
 TABLESPACE INDX
 ;

 
ALTER TABLE OBJECTIVE ADD CONSTRAINT RefCUSTOMER1021 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
 
ALTER TABLE PCT_OWNERSHIP_CHANGE ADD CONSTRAINT RefCSR_USER1022 
    FOREIGN KEY (APP_SID, ADDED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE PCT_OWNERSHIP_CHANGE ADD CONSTRAINT RefCUSTOMER1023 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


ALTER TABLE QUICK_SURVEY ADD CONSTRAINT RefCUSTOMER1024 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


 
 ALTER TABLE QUICK_SURVEY_RESPONSE ADD CONSTRAINT RefQUICK_SURVEY896 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES QUICK_SURVEY(APP_SID, SURVEY_SID)
 ;
 
 

ALTER TABLE SESSION_EXTRA ADD CONSTRAINT RefCUSTOMER1025 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
ALTER TABLE TRASH ADD CONSTRAINT RefCUSTOMER1026 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


ALTER TABLE DIARY_EVENT_GROUP ADD CONSTRAINT RefDIARY_EVENT202 
    FOREIGN KEY (APP_SID, DIARY_EVENT_SID)
    REFERENCES DIARY_EVENT(APP_SID, DIARY_EVENT_SID)
;

-- mixed up objective things
-- 1019474 -> jlp
-- but updated by boots...
update objective_status set app_sid=203969,updated_by_sid=3 where objective_sid=1019474;
update objective set app_sid=203969 where objective_sid=1019474;

ALTER TABLE OBJECTIVE_STATUS ADD CONSTRAINT RefOBJECTIVE54 
    FOREIGN KEY (APP_SID, OBJECTIVE_SID)
    REFERENCES OBJECTIVE(APP_SID, OBJECTIVE_SID)
;

ALTER TABLE QUICK_SURVEY_RESPONSE_ANSWER ADD CONSTRAINT RefQUICK_SURVEY_RESPONSE897 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID)
    REFERENCES QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID)
;

begin
	for r in (select * from user_objects where object_name='APPSIDCHECKNULLABLE') loop
		execute immediate 'drop function appsidchecknullable';
	end loop;
end;
/

@update_tail
