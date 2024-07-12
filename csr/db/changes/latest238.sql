-- Please update version.sql too -- this keeps clean builds in sync
define version=238
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

/* all constraints referencing PK_VAL
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_VAL')
order by table_name, constraint_name;

IMP_VAL                        REFVAL15
VAL_ACCURACY                   REFVAL441
VAL_FILE                       REFVAL741
-> missing VAL_CHANGE!
*/

alter table val drop primary key cascade drop index ;
alter table val add constraint pk_val primary key (app_sid, val_id)
using index tablespace indx;
begin
	dbms_stats.gather_table_stats(
		ownname => 'CSR',
		tabname => 'VAL',
		cascade => TRUE,
		method_opt => 'FOR ALL COLUMNS SIZE AUTO'
	);
end;
/


alter table imp_val add app_sid number(10) default sys_context('SECURITY','APP');
update imp_val set app_sid = (select app_sid from imp_session where imp_session.imp_session_sid = imp_val.imp_session_sid);

alter table VAL_ACCURACY add app_sid number(10) default sys_context('SECURITY','APP');
update VAL_ACCURACY set app_sid = (select app_sid from val where VAL_ACCURACY.val_id = val.val_id);
alter table VAL_ACCURACY modify app_sid not null;
alter table VAL_ACCURACY drop primary key drop index;
alter table VAL_ACCURACY add
	CONSTRAINT PK_VAL_ACCURACY PRIMARY KEY (APP_SID, VAL_ID, ACCURACY_TYPE_OPTION_ID);


/* all constraints referencing PK_VAL
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_VAL_CHANGE')
order by table_name, constraint_name;

ERROR_LOG                      REFVAL_CHANGE217
STORED_CALC_JOB                REFVAL_CHANGE34
VAL                            IDX_VAL_CHANGE_VAL_ID
*/
alter table VAL_CHANGE add app_sid number(10) default sys_context('SECURITY','APP');
--update VAL_CHANGE set app_sid = (select app_sid from val where VAL_CHANGE.val_id = val.val_id);
-- (faster with region, probably missing stats)
update VAL_CHANGE set app_sid = (select app_sid from region where VAL_CHANGE.region_sid = region.region_sid);
alter table val_change drop primary key cascade drop index;

--delete from val_change where region_sid not in (select region_sid from region);
create table vc_kill as 
select rowid rid from val_change where region_sid not in (select region_sid from region);
delete from val_change where rowid in (select rid from vc_kill);
drop table vc_kill;

create table vc_kill as 
select rowid rid from val_change where ind_sid not in (select ind_sid from ind);
delete from val_change where rowid in (select rid from vc_kill);
drop table vc_kill;

alter table VAL_CHANGE modify app_sid not null;
alter table VAL_CHANGE add
    CONSTRAINT PK_VAL_CHANGE PRIMARY KEY (APP_SID, VAL_CHANGE_ID)
	using index tablespace indx;


alter table VAL_FILE add app_sid number(10) default sys_context('SECURITY','APP');
update VAL_FILE set app_sid = (select app_sid from val where VAL_FILE.val_id = val.val_id);
alter table VAL_FILE modify app_sid not null;
alter table VAL_FILE drop primary key drop index;
alter table VAL_FILE add
    CONSTRAINT PK_VAL_FILE PRIMARY KEY (APP_SID, VAL_ID, FILE_UPLOAD_SID)
 ;

CREATE OR REPLACE VIEW AUDIT_VAL_LOG AS	   
	SELECT CHANGED_DTM AUDIT_DATE, R.APP_SID, 6 AUDIT_TYPE_ID, vc.IND_SID OBJECT_SID, CHANGED_BY_SID USER_SID,
	 'Set "{0}" ("{1}") to {2}: '||REASON DESCRIPTION, I.DESCRIPTION PARAM_1, R.DESCRIPTION PARAM_2, VAL_NUMBER PARAM_3
	FROM VAL_CHANGE VC, REGION R, IND I
	WHERE VC.APP_SID = R.APP_SID AND VC.REGION_SID = R.REGION_SID
	   AND VC.APP_SID = I.APP_SID AND VC.IND_SID = I.IND_SID AND I.APP_SID = R.APP_SID;


drop index ref2333; 
CREATE INDEX IDX_SCJ_APP_CALC_IND ON STORED_CALC_JOB(APP_SID, CALC_IND_SID)
tablespace indx
 ;

drop index ref4234; 
CREATE INDEX IDX_SCJ_APP_TRIGGER_VCID ON STORED_CALC_JOB(APP_SID, TRIGGER_VAL_CHANGE_ID)
tablespace indx
 ;


begin
	for r in (select constraint_name from user_constraints where constraint_name in (
		'VAL_UNIQUE'
	)) loop
		execute immediate 'alter table val drop constraint '||r.constraint_name||' drop index';
	end loop;
	for r in (select index_name from user_indexes where index_name in (
		'IDX_VAL_LAST_VAL_CHANGE_ID',
		'IDX_VAL_IND_SID',
		'IDX_VAL_REGION_SID',
		'FK_VAL_1',
		'IDX_VAL_PERIOD',
		'REF305',
		'REF376'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/
CREATE INDEX IDX_VAL_REGION_SID ON VAL(APP_SID, REGION_SID)
tablespace indx
 ;

CREATE UNIQUE INDEX IDX_VAL_LAST_VAL_CHANGE_ID ON VAL(APP_SID, LAST_VAL_CHANGE_ID)
TABLESPACE INDX
 ;
 
CREATE INDEX IDX_VAL_IND_SID ON VAL(APP_SID, IND_SID)
TABLESPACE INDX
 ;


CREATE INDEX IDX_VAL_PERIOD ON VAL(APP_SID, PERIOD_END_DTM, PERIOD_START_DTM)
TABLESPACE INDX
 ;
 
 CREATE UNIQUE INDEX UK_VAL_UNIQUE ON VAL(APP_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM)
TABLESPACE INDX
 ;

CREATE INDEX IDX_VAL_EMC ON VAL(APP_SID, ENTRY_MEASURE_CONVERSION_ID)
TABLESPACE INDX
 ;
CREATE INDEX IDX_VAL_SOURCE ON VAL(APP_SID, SOURCE_ID)
TABLESPACE INDX
;


 -- 
 -- TABLE: ERROR_LOG 
 --
 
 ALTER TABLE ERROR_LOG ADD CONSTRAINT RefVAL_CHANGE217 
    FOREIGN KEY (APP_SID, VAL_CHANGE_ID)
    REFERENCES VAL_CHANGE(APP_SID, VAL_CHANGE_ID)
 ;
 
 
 ALTER TABLE STORED_CALC_JOB ADD CONSTRAINT RefVAL_CHANGE728 
    FOREIGN KEY (APP_SID, TRIGGER_VAL_CHANGE_ID)
    REFERENCES VAL_CHANGE(APP_SID, VAL_CHANGE_ID)
 ;
 

begin
	for r in (select 1 from user_tab_columns where table_name='VAL' and column_name='LAST_VAL_CHANGE_ID' and nullable='N') loop
		execute immediate 'alter table val modify last_val_change_id null';
	end loop;
end;
/

ALTER TABLE VAL ADD CHECK 
	(LAST_VAL_CHANGE_ID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;

begin
	dbms_stats.gather_table_stats(
		ownname => 'CSR',
		tabname => 'VAL_CHANGE',
		cascade => TRUE,
		method_opt => 'FOR ALL COLUMNS SIZE AUTO'
	);
end;
/

create table bogus_lvc as
select last_val_change_id from val
minus 
select val_change_id from val_change;

declare
    v_id val.last_val_change_id%TYPE;
begin
    for r in ( select * from val where last_val_change_id in (select * from bogus_lvc) ) loop
        select val_change_id_seq.nextval 
          into v_id 
          from dual;
        insert into val_change
            ( val_change_id, ind_sid, region_sid, val_id, reason, changed_by_sid, changed_dtm, source_type_id, val_number, period_start_dtm, period_end_dtm, 
              entry_measure_conversion_id, entry_val_number, note, status, source_id, app_sid )
        values
            ( v_id, r.ind_sid, r.region_sid, r.val_id, 'None entered', 3, sysdate, r.source_type_id,
              r.val_number, r.period_start_dtm, r.period_end_dtm, r.entry_measure_conversion_id, r.entry_val_number, 
              r.note, 0, r.source_id, r.app_sid );
        update val
           set last_val_change_id = v_id
         where r.val_id = val_id;
    end loop;
end;
/

drop table bogus_lvc;

 -- gak
 ALTER TABLE VAL ADD CONSTRAINT FK_VAL_VAL_CHANGE 
    FOREIGN KEY (APP_SID, LAST_VAL_CHANGE_ID)
    REFERENCES VAL_CHANGE(APP_SID, VAL_CHANGE_ID)
 ;
 
  
ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefREGION960 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

/*
 one set of mixed up change with an ind that belongs to the wrong app,
 pronino.credit360.com has inds from telefonica (!)
 */
delete from val_change where rowid in (
select vc.rowid from val_change vc, ind i
where vc.app_sid <> i.app_sid and vc.ind_sid = i.ind_sid);
ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefIND961 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
;


 ALTER TABLE IMP_VAL ADD CONSTRAINT RefVAL156 
    FOREIGN KEY (APP_SID, SET_VAL_ID)
    REFERENCES VAL(APP_SID, VAL_ID)
 ;

 
BEGIN
    FOR r IN (
        SELECT table_name, constraint_name FROM user_constraints WHERE constraint_name IN (
            'REFSHEET_VALUE439', 
            'REFSHEET_VALUE739',
            'REFVAL441'
        )
    )
    LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE '||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
    END LOOP;
END;
/

 ALTER TABLE SHEET_VALUE_ACCURACY ADD CONSTRAINT RefSHEET_VALUE439 
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
 
 
 ALTER TABLE SHEET_VALUE_FILE ADD CONSTRAINT RefSHEET_VALUE739 
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
 ;
 
 ALTER TABLE VAL_ACCURACY ADD CONSTRAINT RefVAL441 
    FOREIGN KEY (APP_SID, VAL_ID)
    REFERENCES VAL(APP_SID, VAL_ID)
 ;
 

begin
	for r in (select index_name from user_indexes where index_name in(
		'IDX_VAL_CHANGE_1',
		'IX_VAL_CHANGE_USER_DATE',
		'REF335',
		'REF3066',
		'IDX_VAL_CHANGE_REGION_SID',
		'IDX_VAL_CHANGE_VAL_ID'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/

CREATE INDEX IDX_VAL_CHANGE_IRP ON VAL_CHANGE(APP_SID, IND_SID, REGION_SID, PERIOD_END_DTM, PERIOD_START_DTM)
TABLESPACE INDX
;
-- 
-- INDEX: IX_VAL_CHANGE_USER_DATE 
--

CREATE INDEX IDX_VAL_CHANGE_USER_DATE ON VAL_CHANGE(APP_SID, CHANGED_BY_SID, CHANGED_DTM DESC, VAL_CHANGE_ID)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_CHANGE_VAL_ID 
--

CREATE INDEX IDX_VAL_CHANGE_VAL_ID ON VAL_CHANGE(APP_SID, VAL_ID)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_CHANGE_REGION_SID 
--

CREATE INDEX IDX_VAL_CHANGE_REGION_SID ON VAL_CHANGE(APP_SID, REGION_SID)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_CHANGE_EMC 
--

CREATE INDEX IDX_VAL_CHANGE_EMC ON VAL_CHANGE(APP_SID, ENTRY_MEASURE_CONVERSION_ID)
;
-- 
-- INDEX: IDX_VAL_CHANGE_SOURCE_TYPE 
--

CREATE INDEX IDX_VAL_CHANGE_SOURCE_TYPE ON VAL_CHANGE(APP_SID, SOURCE_TYPE_ID)
TABLESPACE INDX
;

CREATE INDEX IDX_APP_VAL_CHANGE ON ERROR_LOG(APP_SID, VAL_CHANGE_ID)
TABLESPACE INDX;
 

/* not required -- we want to keep history in val_change when values are gone from val
 ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefVAL565 
    FOREIGN KEY (APP_SID, VAL_ID)
    REFERENCES VAL(APP_SID, VAL_ID)
 ;
*/
  
 ALTER TABLE VAL_FILE ADD CONSTRAINT RefVAL741 
    FOREIGN KEY (APP_SID, VAL_ID)
    REFERENCES VAL(APP_SID, VAL_ID)
 ;
 
@update_tail
