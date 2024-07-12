-- Please update version.sql too -- this keeps clean builds in sync
define version=235
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
select table_name,constraint_name from user_constraints where r_constraint_name='PK_CSR_USER'
order by table_name, constraint_name;

ALERT                          REFCSR_USER187
APPROVAL_STEP_SHEET_LOG        REFCSR_USER548
AUTOCREATE_USER                REFCSR_USER787
AUTOCREATE_USER                REFCSR_USER789
DELEGATION_USER                REFCSR_USER104
DIARY_EVENT                    REFCSR_USER200
DOC_CURRENT                    SYS_C00231985
DOC_DOWNLOAD                   SYS_C00231988
DOC_NOTIFICATION               SYS_C00231992
DOC_SUBSCRIPTION               SYS_C00231995
DOC_VERSION                    SYS_C00231996
FORM_ALLOCATION_USER           REFCSR_USER48
HELP_FILE                      REFCSR_USER421
HELP_TOPIC_TEXT                REFCSR_USER422
IMP_CONFLICT                   REFCSR_USER51
IND_OWNER                      REFCSR_USER49
ISSUE                          FK_ISSUE_CSR_USER
ISSUE                          FK_ISSUE_RES_CSR_USER
ISSUE_LOG                      FK_ISSUE_LOG_CSR_USER
JOB                            REFCSR_USER69
METER_READING                  REFCSR_USER784
OBJECTIVE                      REFCSR_USER61
OBJECTIVE                      REFCSR_USER62
OBJECTIVE_STATUS               REFCSR_USER63
PENDING_VAL_LOG                REFCSR_USER524
REGION_OWNER                   REFCSR_USER73
REGION_ROLE_MEMBER             REFCSR_USER765
ROOT_SECTION_USER              REFCSR_USER828
RSS_FEED                       REFCSR_USER883
RSS_FEED_ITEM                  REFCSR_USER884
SECTION                        REFCSR_USER832
SECTION_APPROVERS              REFCSR_USER835
SECTION_COMMENT                REFCSR_USER838
SECTION_VERSION                REFCSR_USER841
SECTION_VERSION                REFCSR_USER842
SHEET_HISTORY                  REFCSR_USER109
SHEET_VALUE_CHANGE             REFCSR_USER144
SURVEY_ALLOCATION              REFCSR_USER561
SURVEY_RESPONSE                REFCSR_USER249
TAB_USER                       REFCSR_USER859
TEMPLATE                       REFCSR_USER357
TRASH                          REFCSR_USER160
VAL_NOTE                       REFCSR_USER40

alter table CSR_USER add constraint UK_CSR_USER_SID unique (CSR_USER_SID) 
using index tablespace indx;
*/

alter table csr_user drop primary key cascade drop index ;
alter table csr_user add constraint pk_csr_user primary key (app_sid, csr_user_sid)
using index tablespace indx;
alter table csr_user modify app_sid default sys_context('SECURITY','APP');

alter table APPROVAL_STEP_SHEET_LOG add app_sid number(10) default sys_context('SECURITY','APP');
update APPROVAL_STEP_SHEET_LOG aps set app_sid = (
	select app_sid from pending_dataset where pending_dataset_id in (
		select pending_dataset_id from approval_step a where aps.approval_step_id = a.approval_step_id));
alter table APPROVAL_STEP_SHEET_LOG modify app_sid not null;

/* XXX: doesn't exist on live, junk?
alter table AUDIT_SESSION add app_sid number(10) default sys_context('SECURITY','APP');
update AUDIT_SESSION set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = AUDIT_SESSION.csr_user_sid);
alter table AUDIT_SESSION modify app_sid not null;
*/
begin
	for r in (select table_name from user_tables where table_name='AUDIT_SESSION') loop
		execute immediate 'drop table '||r.table_name;
	end loop;
end;
/
 
alter table customer modify app_sid default SYS_CONTEXT('SECURITY','APP');
  
alter table DELEGATION_USER add app_sid number(10) default sys_context('SECURITY','APP');
update DELEGATION_USER set app_sid = (select app_sid from delegation where delegation.delegation_sid = DELEGATION_USER.delegation_sid);
alter table DELEGATION_USER modify app_sid not null;
 
alter table DOC_CURRENT add app_sid number(10) default sys_context('SECURITY','APP');
update doc_current dc
   set app_sid = (select dl.app_sid
  					from v$doc_folder_root dfr, doc_library dl
 				   where dc.parent_sid = dfr.doc_folder_sid and dfr.doc_library_sid = dl.doc_library_sid)
  where locked_by_sid is not null;
--update DOC_CURRENT set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = DOC_CURRENT.locked_by_sid);

alter table DOC_DOWNLOAD add app_sid number(10) default sys_context('SECURITY','APP');
--update DOC_DOWNLOAD set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = DOC_DOWNLOAD.DOWNLOADED_BY_SID);
update doc_download dd
   set app_sid = (select dl.app_sid
  					from doc_version dv, doc_current dc, v$doc_folder_root dfr, doc_library dl
 				   where dd.version = dv.version and dd.doc_id = dv.doc_id and dc.doc_id = dv.doc_id and
 				   		 dc.parent_sid = dfr.doc_folder_sid and dfr.doc_library_sid = dl.doc_library_sid);
delete from doc_download where doc_id not in (select doc_id from doc_current);
alter table DOC_DOWNLOAD modify app_sid not null;
 
alter table DOC_NOTIFICATION add app_sid number(10) default sys_context('SECURITY','APP');
--update DOC_NOTIFICATION set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = DOC_NOTIFICATION.NOTIFY_SID);
update doc_notification dn
   set app_sid = (select dl.app_sid
  					from doc_version dv, doc_current dc, v$doc_folder_root dfr, doc_library dl
 				   where dn.version = dv.version and dn.doc_id = dv.doc_id and dc.doc_id = dv.doc_id and
 				   		 dc.parent_sid = dfr.doc_folder_sid and dfr.doc_library_sid = dl.doc_library_sid);
alter table DOC_NOTIFICATION modify app_sid not null;

alter table DOC_SUBSCRIPTION add app_sid number(10) default sys_context('SECURITY','APP');
update doc_subscription ds
   set app_sid = (select dl.app_sid
  					from doc_current dc, v$doc_folder_root dfr, doc_library dl
 				   where dc.doc_id = ds.doc_id and
 				   		 dc.parent_sid = dfr.doc_folder_sid and dfr.doc_library_sid = dl.doc_library_sid);
--update DOC_SUBSCRIPTION set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = DOC_SUBSCRIPTION.NOTIFY_SID);
alter table DOC_SUBSCRIPTION modify app_sid not null;

alter table DOC_VERSION add app_sid number(10) default sys_context('SECURITY','APP');
--update DOC_VERSION set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = DOC_VERSION.CHANGED_BY_SID);
update doc_version dv
   set app_sid = (select dl.app_sid
  					from doc_current dc, v$doc_folder_root dfr, doc_library dl
 				   where dc.doc_id = dv.doc_id and
 				   		 dc.parent_sid = dfr.doc_folder_sid and dfr.doc_library_sid = dl.doc_library_sid);
delete from doc_version where doc_id not in (select doc_id from doc_current);
alter table DOC_VERSION modify app_sid not null;
 
alter table FORM_ALLOCATION_USER add app_sid number(10) default sys_context('SECURITY','APP');
--update FORM_ALLOCATION_USER set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = FORM_ALLOCATION_USER.USER_SID);
update FORM_ALLOCATION_USER fau set app_sid = (
	select application_sid_id 
	  from security.securable_object so, form_allocation fa
	 where fau.form_allocation_id = fa.form_allocation_id and so.sid_id = fa.form_sid);
alter table FORM_ALLOCATION_USER modify app_sid not null;
alter table FORM_ALLOCATION_USER drop primary key drop index;
alter table FORM_ALLOCATION_USER add
    CONSTRAINT PK_FORM_ALLOCATION_USER PRIMARY KEY (APP_SID, FORM_ALLOCATION_ID, USER_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 
-- TODO: not sure what to do with these yet, help is horribly shared
-- decision was the scrap the uploaded by, etc fields
alter table help_file drop column uploaded_by_sid;
alter table help_topic_text drop column last_updated_by_sid;
/*
alter table HELP_FILE add app_sid number(10) default sys_context('SECURITY','APP');
update HELP_FILE set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = HELP_FILE.UPLOADED_BY_SID);
alter table HELP_FILE modify app_sid not null;

alter table HELP_TOPIC_TEXT add app_sid number(10) default sys_context('SECURITY','APP');
update HELP_TOPIC_TEXT set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = HELP_TOPIC_TEXT.LAST_UPDATED_BY_SID);
alter table HELP_TOPIC_TEXT modify app_sid not null;
*/

alter table IMP_CONFLICT add app_sid number(10) default sys_context('SECURITY','APP');
update IMP_CONFLICT set app_sid = (select app_sid from imp_session where imp_session.imp_session_sid = imp_conflict.imp_session_sid)
where resolved_by_user_sid is not null;
--update IMP_CONFLICT set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = IMP_CONFLICT.RESOLVED_BY_USER_SID);

alter table ISSUE add app_sid number(10) default sys_context('SECURITY','APP');
-- this just works on live since everything has a deliverable set (even though it's not mandatory)
-- otherwise we have to guess
update issue set app_sid = (select app_sid from deliverable where deliverable.deliverable_sid = issue.deliverable_sid) 
where app_sid is null;
alter table ISSUE modify app_sid not null;

alter table ISSUE_LOG add app_sid number(10) default sys_context('SECURITY','APP');
update ISSUE_LOG set app_sid = (select app_sid from issue where issue_log.issue_id = issue.issue_id);
alter table ISSUE_LOG modify app_sid not null;
 
alter table ISSUE_LOG_READ add app_sid number(10) default sys_context('SECURITY','APP');
update ISSUE_LOG_READ set app_sid = (select app_sid from issue_log where issue_log_read.issue_log_id = issue_log.issue_log_id);
-- gak, missing ri, we'll fix it..
delete from issue_log_read where issue_log_id not in (select issue_log_id from issue_log);

DECLARE
    v_cnt NUMBER(10);
BEGIN
    --this was missing on live but is on "clean builds", e.g. DT
    SELECT COUNT(*) INTO v_cnt FROM user_constraints WHERE constraint_name IN ('REFISSUE_LOG624','REFISSUE_LOG76');    
    IF v_cnt = 0 THEN
       EXECUTE IMMEDIATE 'ALTER TABLE ISSUE_LOG_READ ADD CONSTRAINT RefISSUE_LOG624 FOREIGN KEY (ISSUE_LOG_ID) REFERENCES ISSUE_LOG(ISSUE_LOG_ID)';
    END IF;
END;
/
alter table ISSUE_LOG_READ modify app_sid not null;
alter table ISSUE_LOG_READ drop primary key drop index;   
alter table ISSUE_LOG_READ add
    CONSTRAINT PK_ISSUE_LOG_READ PRIMARY KEY (APP_SID, ISSUE_LOG_ID, CSR_USER_SID)
 ;
 
alter table ISSUE_USER add app_sid number(10) default sys_context('SECURITY','APP');
update ISSUE_USER set app_sid = (select app_sid from issue where issue.issue_id = issue_user.issue_id);
alter table ISSUE_USER modify app_sid not null;
alter table ISSUE_USER drop primary key drop index;
alter table ISSUE_USER add
    CONSTRAINT PK_ISSUE_USER PRIMARY KEY (APP_SID, ISSUE_ID, USER_SID)
 ;
 

-- there doesn't seem to be anything we can do here to tie the data back to the site
-- so in effect we'll eat some rows.  doesn't matter really since it's basically unused.
alter table JOB add app_sid number(10) default sys_context('SECURITY','APP');
update JOB set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = JOB.REQUESTED_BY_USER_SID);
alter table JOB modify app_sid not null;

-- hmm, this  is ropey but it works on live (i.e. nothing with app_sid = 0)
alter table OBJECTIVE add app_sid number(10) default sys_context('SECURITY','APP');
update OBJECTIVE set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = OBJECTIVE.RESPONSIBLE_USER_SID);
update OBJECTIVE set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = OBJECTIVE.DELIVERY_USER_SID) where app_sid is null or app_sid=0;
 
alter table OBJECTIVE_STATUS add app_sid number(10) default sys_context('SECURITY','APP');
update OBJECTIVE_STATUS set app_sid = (select app_sid from objective where objective.objective_sid = objective_status.objective_sid);
-- hmm, ropey again but gives no zeroes
update OBJECTIVE_STATUS set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = objective_status.updated_by_sid) 
where app_sid is null;
alter table OBJECTIVE_STATUS modify app_sid not null;

alter table PENDING_VAL_LOG add app_sid number(10) default sys_context('SECURITY','APP');
-- update PENDING_VAL_LOG set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = PENDING_VAL_LOG.SET_BY_USER_SID);
update PENDING_VAL_LOG set app_sid = (
	select pds.app_sid from pending_dataset pds, pending_region pr, pending_val pv
	 where pending_val_log.pending_val_id = pv.pending_val_id and
	 	   pv.pending_region_id = pr.pending_region_id and
	 	   pr.pending_dataset_id = pds.pending_dataset_id);
alter table PENDING_VAL_LOG modify app_sid not null;

/* not on live -- has been removed
alter table PROPOSED_USER add app_sid number(10) default sys_context('SECURITY','APP');
update PROPOSED_USER set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = PROPOSED_USER.CSR_USER_SID);
alter table PROPOSED_USER modify app_sid not null;
alter table PROPOSED_USER drop primary key drop index;
alter table PROPOSED_USER add
   CONSTRAINT PK198 PRIMARY KEY (APP_SID, CSR_USER_SID)
 ;
*/

alter table ROOT_SECTION_USER add app_sid number(10) default sys_context('SECURITY','APP');
--update ROOT_SECTION_USER set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = ROOT_SECTION_USER.CSR_USER_SID);
update ROOT_SECTION_USER set app_sid = (select app_sid from section where section.section_sid = ROOT_SECTION_USER.ROOT_SECTION_sid);
alter table ROOT_SECTION_USER modify app_sid not null;
alter table ROOT_SECTION_USER drop primary key drop index;
alter table ROOT_SECTION_USER add
   CONSTRAINT PK9 PRIMARY KEY (APP_SID, CSR_USER_SID, ROOT_SECTION_SID)
 ;

alter table RSS_FEED_ITEM add app_sid number(10) default sys_context('SECURITY','APP');
update RSS_FEED_ITEM set app_sid = (select app_sid from rss_feed where rss_feed.rss_feed_sid = rss_feed_item.rss_feed_sid);
alter table RSS_FEED_ITEM modify app_sid not null;

 
alter table SECTION_APPROVERS add app_sid number(10) default sys_context('SECURITY','APP');
update SECTION_APPROVERS set app_sid = (select app_sid from section where section.section_sid = SECTION_APPROVERS.section_SID);
alter table SECTION_APPROVERS modify app_sid not null;
alter table SECTION_APPROVERS drop primary key drop index;
alter table SECTION_APPROVERS add
   CONSTRAINT PK12 PRIMARY KEY (SECTION_SID, APPROVER_SID, APP_SID)
 ;
 
alter table SECTION_COMMENT add app_sid number(10) default sys_context('SECURITY','APP');
update SECTION_COMMENT set app_sid = (select app_sid from section where section.section_sid = SECTION_COMMENT.section_SID);
--update SECTION_COMMENT set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = SECTION_COMMENT.ENTERED_BY_SID);
alter table SECTION_COMMENT modify app_sid not null;
 
alter table SECTION_VERSION add app_sid number(10) default sys_context('SECURITY','APP');
update SECTION_VERSION set app_sid = (select app_sid from section where section.section_sid = SECTION_VERSION.section_SID);
--update SECTION_VERSION set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = SECTION_VERSION.CHANGED_BY_SID);
 
alter table SHEET_HISTORY add app_sid number(10) default sys_context('SECURITY','APP');
update SHEET_HISTORY set app_sid = (
	select d.app_sid
	  from sheet s, delegation d
	 where sheet_history.sheet_id = s.sheet_id and s.delegation_sid = d.delegation_sid);
--select app_sid from csr_user where csr_user.csr_user_sid = SHEET_HISTORY.FROM_USER_SID);
alter table SHEET_HISTORY modify app_sid not null;

alter table SURVEY_ALLOCATION add app_sid number(10) default sys_context('SECURITY','APP');
update SURVEY_ALLOCATION set app_sid = (
	select app_sid from survey_response where survey_response.survey_response_id = SURVEY_ALLOCATION.survey_response_id);
alter table SURVEY_ALLOCATION modify app_sid not null;
alter table SURVEY_ALLOCATION drop primary key drop index;
alter table SURVEY_ALLOCATION add
   CONSTRAINT PK313 PRIMARY KEY (APP_SID, CSR_USER_SID, SURVEY_RESPONSE_ID)
 ;
 
alter table TAB_USER add app_sid number(10) default sys_context('SECURITY','APP');
update TAB_USER set app_sid = (select app_sid from tab where tab.tab_id = TAB_USER.tab_id);
alter table TAB_USER modify app_sid not null;
alter table TAB_USER drop primary key drop index;
alter table TAB_USER add
   CONSTRAINT PK437 PRIMARY KEY (APP_SID, TAB_ID, USER_SID)
 ;
 
 
alter table TRASH add app_sid number(10) default sys_context('SECURITY','APP');
update TRASH tx set app_sid = (
	select application_sid_id 
	  from security.securable_object so, trash t
	 where tx.trash_sid = t.trash_sid and so.sid_id = t.trash_sid);
--update TRASH set app_sid = (select app_sid from csr_user where csr_user.csr_user_sid = TRASH.trashed_by_SID);
 
CREATE OR REPLACE VIEW v$checked_out_version AS
SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, 
	   s.checked_out_dtm, s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only  
  FROM section s, section_version sv
 WHERE s.section_sid = sv.section_sid
   AND s.checked_out_version_number = sv.version_number;

CREATE OR REPLACE VIEW v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, 
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only  
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

CREATE TABLE SUPERADMIN(
    CSR_USER_SID     NUMBER(10, 0)    NOT NULL,
    EMAIL            VARCHAR2(256),
    GUID             CHAR(36)         NOT NULL,
    FULL_NAME        VARCHAR2(256),
    USER_NAME        VARCHAR2(256)    NOT NULL,
    FRIENDLY_NAME    VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_SUPERADMIN PRIMARY KEY (CSR_USER_SID)
);

insert into superadmin (csr_user_sid,email,guid,full_name,user_name,friendly_name)
	select csr_user_sid,email,guid,full_name,user_name,friendly_name
	  from csr_user
	 where app_sid=0;
	 
insert into csr_user (
CSR_USER_SID,
EMAIL,
REGION_MOUNT_POINT_SID,
INDICATOR_MOUNT_POINT_SID,
FULL_NAME,
USER_NAME,
SEND_ALERTS,
GUID,
FRIENDLY_NAME,
INFO_XML,
SHOW_PORTAL_HELP,
APP_SID,
DONATIONS_BROWSE_FILTER_ID,
DONATIONS_REPORTS_FILTER_ID
)
select
cu.CSR_USER_SID,
cu.EMAIL,
cu.REGION_MOUNT_POINT_SID,
cu.INDICATOR_MOUNT_POINT_SID,
cu.FULL_NAME,
cu.USER_NAME,
cu.SEND_ALERTS,
cu.GUID,
cu.FRIENDLY_NAME,
cu.INFO_XML,
cu.SHOW_PORTAL_HELP,
c.APP_SID,
cu.DONATIONS_BROWSE_FILTER_ID,
cu.DONATIONS_REPORTS_FILTER_ID
from csr_user cu, customer c
where cu.app_sid = 0 and c.app_sid <> 0;

alter table csr_user add
    HIDDEN                         NUMBER(1, 0)     DEFAULT 0 NOT NULL;
update csr_user set hidden=1 where csr_user_sid in (select csr_user_sid from superadmin);    

update csr_user set hidden=1 where LOWER(user_name)='usercreatordaemon';
-- builtin/admin, builtin/guest
update csr_user set hidden=1 where csr_user_sid in (3,5);

update customer set current_reporting_period_sid=null where app_sid=0;
delete from reporting_period where app_sid=0;
delete from csr_user where app_sid=0;
delete from customer_alert_type where app_sid=0;
update customer set ind_root_sid = null,region_root_sid=null where app_sid = 0;
-- gah, missing ri 
delete from region where app_sid=0;
-- ditto
delete from ind where app_sid = 0;
-- these audits can't be seen (checked, all have object_sid,app_sid is a superadmin!)
delete from audit_log where app_sid = 0;
delete from customer_alert_type where app_sid=0;
delete from customer where app_sid=0;

ALTER TABLE ALERT ADD CONSTRAINT RefCSR_USER187 
    FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE APPROVAL_STEP_SHEET_LOG ADD CONSTRAINT RefCSR_USER548 
    FOREIGN KEY (APP_SID, BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
/*
update audit_log al set app_sid = nvl((
	select application_sid_id 
	  from security.securable_object so
	 where al.object_sid = so.sid_id), 0)
 where app_sid = 0;
*/

delete from audit_log where app_sid not in (select app_sid from customer);
delete from audit_log where user_sid not in (select sid_id from security.securable_object);

-- there are still some user rows missing from csr_user
-- //Aspen/Applications/test.ica.credit360.com
-- //Aspen/Applications/ica.credit360.com/Trash
-- //Aspen/Applications/vancity.credit360.com
-- //Aspen/Applications/vancity.credit360.com/Users/autoLoginDaemon
insert into csr_user (
CSR_USER_SID,
EMAIL,
REGION_MOUNT_POINT_SID,
INDICATOR_MOUNT_POINT_SID,
FULL_NAME,
USER_NAME,
SEND_ALERTS,
GUID,
FRIENDLY_NAME,
INFO_XML,
SHOW_PORTAL_HELP,
APP_SID,
DONATIONS_BROWSE_FILTER_ID,
DONATIONS_REPORTS_FILTER_ID
)
select 6697076, 'support@credit360.com', null, null, 'Auto-authenticate user', 'autoLoginDaemon', 0,
user_pkg.generateact, 'Auto-authenticate user', null, 0, 4778731, null, null
from security.securable_object where sid_id=6697076;

-- user in trash in ica.credit360.com , audits for site test.ica.credit360.com (!)
delete from audit_log where user_sid=4959582;

-- XXX: TODO: want this constraint?
 ALTER TABLE AUDIT_LOG ADD CONSTRAINT RefCSR_USER345 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 /* not on live
 ALTER TABLE AUDIT_SESSION ADD CONSTRAINT RefCSR_USER579 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;*/
 
  
 ALTER TABLE AUTOCREATE_USER ADD CONSTRAINT RefCSR_USER787 
    FOREIGN KEY (APP_SID, APPROVED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE AUTOCREATE_USER ADD CONSTRAINT RefCSR_USER789 
    FOREIGN KEY (APP_SID, CREATED_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE DELEGATION ADD CONSTRAINT RefCSR_USER162 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 
 ALTER TABLE DELEGATION_USER ADD CONSTRAINT RefCSR_USER104 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE DIARY_EVENT ADD CONSTRAINT RefCSR_USER200 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE DOC_CURRENT ADD CONSTRAINT RefCSR_USER683 
    FOREIGN KEY (APP_SID, LOCKED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE DOC_DOWNLOAD ADD CONSTRAINT RefCSR_USER451 
    FOREIGN KEY (APP_SID, DOWNLOADED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 
 ALTER TABLE DOC_NOTIFICATION ADD CONSTRAINT RefCSR_USER694 
    FOREIGN KEY (APP_SID, NOTIFY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE DOC_SUBSCRIPTION ADD CONSTRAINT RefCSR_USER690 
    FOREIGN KEY (APP_SID, NOTIFY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 
 ALTER TABLE DOC_VERSION ADD CONSTRAINT RefCSR_USER676 
    FOREIGN KEY (APP_SID, CHANGED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE FORM_ALLOCATION_USER ADD CONSTRAINT RefCSR_USER48 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE IMP_CONFLICT ADD CONSTRAINT RefCSR_USER51 
    FOREIGN KEY (APP_SID, RESOLVED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE IND_OWNER ADD CONSTRAINT RefCSR_USER49 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 
 ALTER TABLE ISSUE ADD CONSTRAINT RefCSR_USER616 
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE ISSUE ADD CONSTRAINT RefCSR_USER617 
    FOREIGN KEY (APP_SID, RESOLVED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE ISSUE_LOG ADD CONSTRAINT RefCSR_USER619 
    FOREIGN KEY (APP_SID, LOGGED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE ISSUE_LOG_READ ADD CONSTRAINT RefCSR_USER623 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE ISSUE_USER ADD CONSTRAINT RefCSR_USER629 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;

delete from job where app_sid=0; 
 ALTER TABLE JOB ADD CONSTRAINT RefCSR_USER69 
    FOREIGN KEY (APP_SID, REQUESTED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE METER_READING ADD CONSTRAINT RefCSR_USER784 
    FOREIGN KEY (APP_SID, ENTERED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE OBJECTIVE ADD CONSTRAINT RefCSR_USER61 
    FOREIGN KEY (APP_SID, RESPONSIBLE_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE OBJECTIVE ADD CONSTRAINT RefCSR_USER62 
    FOREIGN KEY (APP_SID, DELIVERY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 

-- jlp 203969         
-- ian blythe from boots 685536
update objective_status set updated_by_sid=203981 where updated_by_sid=685536
and app_sid=203969; 
 ALTER TABLE OBJECTIVE_STATUS ADD CONSTRAINT RefCSR_USER63 
    FOREIGN KEY (APP_SID, UPDATED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE PENDING_VAL_LOG ADD CONSTRAINT RefCSR_USER524 
    FOREIGN KEY (APP_SID, SET_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 
/* junk ALTER TABLE PROPOSED_USER ADD CONSTRAINT RefCSR_USER651 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
*/

-- x-app junk on charlotte.credit360.com (probably from import)
delete from region_owner where app_sid = 3732452    and user_sid in (1682482, 1716347);
 
 ALTER TABLE REGION_OWNER ADD CONSTRAINT RefCSR_USER73 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefCSR_USER765 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE ROOT_SECTION_USER ADD CONSTRAINT RefCSR_USER828 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE RSS_FEED ADD CONSTRAINT RefCSR_USER883 
    FOREIGN KEY (APP_SID, OWNER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE RSS_FEED_ITEM ADD CONSTRAINT RefCSR_USER884 
    FOREIGN KEY (APP_SID, OWNER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE SECTION ADD CONSTRAINT RefCSR_USER832 
    FOREIGN KEY (APP_SID, CHECKED_OUT_TO_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE SECTION_APPROVERS ADD CONSTRAINT RefCSR_USER835 
    FOREIGN KEY (APP_SID, APPROVER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE SECTION_COMMENT ADD CONSTRAINT RefCSR_USER838 
    FOREIGN KEY (APP_SID, ENTERED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE SECTION_VERSION ADD CONSTRAINT RefCSR_USER841 
    FOREIGN KEY (APP_SID, CHANGED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE SECTION_VERSION ADD CONSTRAINT RefCSR_USER842 
    FOREIGN KEY (APP_SID, APPROVED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE SHEET_HISTORY ADD CONSTRAINT RefCSR_USER109 
    FOREIGN KEY (APP_SID, FROM_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE SHEET_VALUE_CHANGE ADD CONSTRAINT RefCSR_USER144 
    FOREIGN KEY (APP_SID, CHANGED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE SURVEY_ALLOCATION ADD CONSTRAINT RefCSR_USER561 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE SURVEY_RESPONSE ADD CONSTRAINT RefCSR_USER249 
    FOREIGN KEY (APP_SID, LAST_SAVED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE TAB_USER ADD CONSTRAINT RefCSR_USER859 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE TEMPLATE ADD CONSTRAINT RefCSR_USER357 
    FOREIGN KEY (APP_SID, UPLOADED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 
 ALTER TABLE TRASH ADD CONSTRAINT RefCSR_USER160 
    FOREIGN KEY (APP_SID, TRASHED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE VAL_NOTE ADD CONSTRAINT RefCSR_USER40 
    FOREIGN KEY (APP_SID, ENTERED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
 ;

@update_tail
