-- Please update version.sql too -- this keeps clean builds in sync
define version=239
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


/* all constraints referencing IMP_SESSION
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_IMP_SESSION')
order by table_name, constraint_name;

x FEED_REQUEST                   REFIMP_SESSION321
x IMP_CONFLICT                   REFIMP_SESSION50
x IMP_VAL                        REFIMP_SESSION11
*/

alter table IMP_SESSION drop primary key cascade drop index;
alter table IMP_SESSION modify app_sid  DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table imp_session add 
    CONSTRAINT PK_IMP_SESSION PRIMARY KEY (APP_SID, IMP_SESSION_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 

alter table feed_request add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update feed_request set app_sid = (select app_sid from imp_session where imp_session.imp_session_sid = feed_request.imp_session_sid);
alter table feed_request drop primary key drop index;
alter table feed_request add
CONSTRAINT PK_FEED_REQUEST PRIMARY KEY (FEED_REQUEST_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/* all constraints referencing imp_conflict
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_IMP_CONFLICT')
order by table_name, constraint_name;

x IMP_CONFLICT_VAL               REFIMP_CONFLICT52

*/

update imp_conflict set app_sid = (select app_sid from imp_session 
where imp_session.imp_session_sid = imp_conflict.imp_session_sid) where app_sid is null;
alter table imp_conflict modify app_sid not null;
alter table imp_conflict drop primary key cascade drop index;
alter table imp_conflict add
    CONSTRAINT PK_IMP_CONFLICT PRIMARY KEY (APP_SID, IMP_CONFLICT_ID)
     USING INDEX
 TABLESPACE INDX
 ;

alter table imp_conflict_val add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update imp_conflict_val set app_sid = (select app_sid from imp_conflict where imp_conflict_val.imp_conflict_id = imp_conflict.imp_conflict_id);
alter table imp_conflict_val modify app_sid not null;
alter table imp_conflict_val drop primary key drop index;
alter table imp_conflict_val add
    CONSTRAINT PK_IMP_CONFLICT_VAL PRIMARY KEY (APP_SID, IMP_CONFLICT_ID, IMP_VAL_ID)
     USING INDEX
 TABLESPACE INDX
 ;

/* all constraints referencing imp_ind
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_IMP_IND')
order by table_name, constraint_name;

x IMP_MEASURE                    REFIMP_IND169
x IMP_VAL                        REFIMP_IND9
*/

alter table imp_ind drop primary key cascade drop index;
alter table imp_ind add
    CONSTRAINT PK_IMP_IND PRIMARY KEY (APP_SID, IMP_IND_ID)
     USING INDEX
 TABLESPACE INDX
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_IMP_IND_1','PK_IMP_MEASURE')
order by table_name, constraint_name;
 
x IMP_VAL                        REFIMP_MEASURE167
*/
--alter table imp_measure add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table imp_measure drop primary key cascade drop index;
alter table imp_measure add
   CONSTRAINT PK_IMP_MEASURE PRIMARY KEY (APP_SID, IMP_MEASURE_ID)
   USING INDEX
TABLESPACE INDX
 ;
 
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_IMP_REGION')
order by table_name, constraint_name;
 
x IMP_VAL                        REFIMP_REGION10
*/
alter table imp_region modify app_sid not null;
alter table imp_region drop primary key cascade drop index;
alter table imp_region add
    CONSTRAINT PK_IMP_REGION PRIMARY KEY (APP_SID, IMP_REGION_ID)
     USING INDEX
 TABLESPACE INDX
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_IMP_VAL')
order by table_name, constraint_name;
 
x IMP_CONFLICT_VAL               REFIMP_VAL53
*/
update imp_val set app_sid = (select app_sid from imp_ind where imp_ind.imp_ind_id = imp_val.imp_ind_id)
where app_sid is null;
alter table imp_val modify app_sid not null;
alter table imp_val drop primary key cascade drop index;
alter table imp_val add
   CONSTRAINT PK_IMP_VAL PRIMARY KEY (APP_SID, IMP_VAL_ID)
     USING INDEX
 TABLESPACE INDX
 ;

 

alter table PENDING_VAL_FILE_UPLOAD add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PENDING_VAL_FILE_UPLOAD pvfu set app_sid = (
	select pr.app_sid
	  from pending_region pr, pending_val pv
	 where pr.pending_region_id = pv.pending_region_id and 
	 	   pv.pending_val_id = pvfu.pending_val_id);
alter table pending_val_file_upload modify app_sid not null;
alter table pending_val_file_upload drop primary key drop index;
alter table pending_val_file_upload add
    CONSTRAINT PK_PENDING_VAL_FILE_UPLOAD PRIMARY KEY (APP_SID, PENDING_VAL_ID, FILE_UPLOAD_SID)
    USING INDEX
TABLESPACE INDX
 ;
 

/* all constraints referencing file_upload
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_FILE_UPLOAD')
order by table_name, constraint_name;

x IMP_VAL                        REFFILE_UPLOAD41
x PENDING_VAL_FILE_UPLOAD        REFFILE_UPLOAD514
x SHEET_VALUE_CHANGE_FILE        REFFILE_UPLOAD736
x SHEET_VALUE_FILE               REFFILE_UPLOAD732
x VAL_FILE                       REFFILE_UPLOAD740
*/

	
/*
select count(*) from (
select file_upload_sid from file_upload
minus
select file_sid from imp_val
minus
select file_upload_sid from pending_val_file_upload
minus
select file_upload_sid from sheet_value_change_file
minus
select file_upload_sid from sheet_value_file
minus
select file_upload_sid from val_file);
*/

alter table file_upload add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update file_upload set app_sid = (select min(app_sid) from imp_val where imp_val.file_sid = file_upload.file_upload_sid) where app_sid is null;
update file_upload set app_sid = (select min(app_sid) from PENDING_VAL_FILE_UPLOAD where PENDING_VAL_FILE_UPLOAD.file_upload_sid = file_upload.file_upload_sid) where app_sid is null;
update file_upload set app_sid = (select min(app_sid) from SHEET_VALUE_CHANGE_FILE where SHEET_VALUE_CHANGE_FILE.file_upload_sid = file_upload.file_upload_sid) where app_sid is null;
update file_upload set app_sid = (select min(app_sid) from SHEET_VALUE_FILE where SHEET_VALUE_FILE.file_upload_sid = file_upload.file_upload_sid) where app_sid is null;
update file_upload set app_sid = (select min(app_sid) from VAL_FILE where VAL_FILE.file_upload_sid = file_upload.file_upload_sid) where app_sid is null;

-- there are 2334 objects in file_upload that are missing from one of the above
-- assuming they are orphans
create table old_file_upload_orphans as
	select * from file_upload where app_sid is null;
delete from file_upload where app_sid is null;

alter table file_upload modify app_sid not null;
alter table file_upload drop primary key cascade drop index;
alter table file_upload add constraint pk_file_upload primary key (app_sid, file_upload_sid) 
using index tablespace indx;


begin
	for r in (select index_name from user_indexes 
			   where index_name IN (
		'REF2150', 'REF551',
		'REF1752', 'Ref2253',
		'REF2313', 'REF3714', 
		'REF199', 'REF2010', 
		'REF2111', 'REF4115', 
		'REF1141', 'REF293', 
		'REF3725', 'FK_MEASURE_CONVERSION'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/
 
CREATE INDEX IDX_IMP_CFLCT_RESLVD_SID ON IMP_CONFLICT(APP_SID, RESOLVED_BY_USER_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_IMP_CFLT_SESSION ON IMP_CONFLICT(APP_SID, IMP_SESSION_SID)
 TABLESPACE INDX
 ;

 
CREATE INDEX IDX_IMP_CONFLICT_VAL_VAL ON IMP_CONFLICT_VAL(APP_SID, IMP_VAL_ID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_IMP_IND_MAP_IND ON IMP_IND(APP_SID, MAPS_TO_IND_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_IMP_REGION_MAPS ON IMP_REGION(APP_SID, MAPS_TO_REGION_SID)
 TABLESPACE INDX
 ;

 
CREATE INDEX IDX_IMP_VAL_REGION ON IMP_VAL(APP_SID, IMP_REGION_ID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IMP_VAL_SESSION ON IMP_VAL(APP_SID, IMP_SESSION_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IMP_VAL_SET_VAL_ID ON IMP_VAL(APP_SID, SET_VAL_ID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_IMP_VAL_FILE ON IMP_VAL(APP_SID, FILE_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_IMP_VAL_IND ON IMP_VAL(APP_SID, IMP_IND_ID)
 TABLESPACE INDX
 ;

 
CREATE INDEX IDX_PENDING_UPLOAD_UPLOAD ON PENDING_VAL_FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
TABLESPACE INDX
;

CREATE INDEX FK_RANGE_IND_IND ON RANGE_IND_MEMBER(APP_SID, IND_SID)
TABLESPACE INDX
 ;

CREATE INDEX IDX_VAL_FILE_FILE ON VAL_FILE(APP_SID, FILE_UPLOAD_SID)
TABLESPACE INDX
;
 
  
ALTER TABLE FEED_REQUEST ADD CONSTRAINT RefIMP_SESSION321 
    FOREIGN KEY (APP_SID, IMP_SESSION_SID)
    REFERENCES IMP_SESSION(APP_SID, IMP_SESSION_SID)
;

ALTER TABLE FILE_UPLOAD ADD CONSTRAINT RefCUSTOMER964 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
 ALTER TABLE IMP_CONFLICT ADD CONSTRAINT RefIMP_SESSION50 
    FOREIGN KEY (APP_SID, IMP_SESSION_SID)
    REFERENCES IMP_SESSION(APP_SID, IMP_SESSION_SID)
 ;
 
 ALTER TABLE IMP_CONFLICT_VAL ADD CONSTRAINT RefIMP_CONFLICT52 
    FOREIGN KEY (APP_SID, IMP_CONFLICT_ID)
    REFERENCES IMP_CONFLICT(APP_SID, IMP_CONFLICT_ID)
 ;
 
 ALTER TABLE IMP_CONFLICT_VAL ADD CONSTRAINT RefIMP_VAL53 
    FOREIGN KEY (APP_SID, IMP_VAL_ID)
    REFERENCES IMP_VAL(APP_SID, IMP_VAL_ID)
 ;
 
 
 ALTER TABLE IMP_MEASURE ADD CONSTRAINT RefIMP_IND169 
    FOREIGN KEY (APP_SID, IMP_IND_ID)
    REFERENCES IMP_IND(APP_SID, IMP_IND_ID)
 ;
 
 
 
ALTER TABLE IMP_SESSION ADD CONSTRAINT RefCUSTOMER965 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
 ALTER TABLE IMP_VAL ADD CONSTRAINT RefIMP_IND9 
    FOREIGN KEY (APP_SID, IMP_IND_ID)
    REFERENCES IMP_IND(APP_SID, IMP_IND_ID)
 ;
 
 ALTER TABLE IMP_VAL ADD CONSTRAINT RefIMP_REGION10 
    FOREIGN KEY (APP_SID, IMP_REGION_ID)
    REFERENCES IMP_REGION(APP_SID, IMP_REGION_ID)
 ;
 
 ALTER TABLE IMP_VAL ADD CONSTRAINT RefIMP_SESSION11 
    FOREIGN KEY (APP_SID, IMP_SESSION_SID)
    REFERENCES IMP_SESSION(APP_SID, IMP_SESSION_SID)
 ;
 
 ALTER TABLE IMP_VAL ADD CONSTRAINT RefFILE_UPLOAD41 
    FOREIGN KEY (APP_SID, FILE_SID)
    REFERENCES FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
 ;
 
 
 ALTER TABLE IMP_VAL ADD CONSTRAINT RefIMP_MEASURE167 
    FOREIGN KEY (APP_SID, IMP_MEASURE_ID)
    REFERENCES IMP_MEASURE(APP_SID, IMP_MEASURE_ID)
 ;
 
 ALTER TABLE PENDING_VAL_FILE_UPLOAD ADD CONSTRAINT RefFILE_UPLOAD514 
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
 ;
 
 
 ALTER TABLE SHEET_VALUE_CHANGE_FILE ADD CONSTRAINT RefFILE_UPLOAD736 
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
 ;
 
 
 ALTER TABLE SHEET_VALUE_FILE ADD CONSTRAINT RefFILE_UPLOAD738 
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
 ;
 
 
 ALTER TABLE VAL_FILE ADD CONSTRAINT RefFILE_UPLOAD740 
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
 ;
 
CREATE OR REPLACE VIEW IMP_VAL_MAPPED
 (IND_DESCRIPTION, REGION_DESCRIPTION, IND_SID, REGION_SID, IMP_IND_DESCRIPTION, IMP_REGION_DESCRIPTION, IMP_VAL_ID, IMP_IND_ID, IMP_REGION_ID, UNKNOWN, START_DTM, END_DTM, VAL, CONVERSION_FACTOR, FILE_SID, IMP_SESSION_SID, SET_VAL_ID, IMP_MEASURE_ID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE) AS
 SELECT i.DESCRIPTION, r.DESCRIPTION, i.IND_SID, r.REGION_SID, ii.DESCRIPTION, ir.DESCRIPTION, iv.IMP_VAL_ID, iv.IMP_IND_ID, iv.IMP_REGION_ID, iv.UNKNOWN, iv.START_DTM, iv.END_DTM, iv.VAL, iv.CONVERSION_FACTOR, iv.FILE_SID, iv.IMP_SESSION_SID, iv.SET_VAL_ID, iv.IMP_MEASURE_ID, i.TOLERANCE_TYPE, i.PCT_UPPER_TOLERANCE, i.PCT_LOWER_TOLERANCE
 FROM imp_val iv, imp_ind ii, imp_region ir, ind i, region r
WHERE ir.APP_SID = r.APP_SID AND ir.MAPS_TO_REGION_SID = r.REGION_SID AND 
	   iv.IMP_REGION_ID = ir.IMP_REGION_ID AND ii.APP_SID = i.APP_SID AND 
	   ii.MAPS_TO_IND_SID = i.IND_SID AND iv.IMP_IND_ID = ii.IMP_IND_ID
 ;

@update_tail
