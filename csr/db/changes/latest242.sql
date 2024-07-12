-- Please update version.sql too -- this keeps clean builds in sync
define version=242
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

alter table ALERT modify APP_SID  DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table alert rename constraint pk111 to pk_alert;
alter index pk111 rename to pk_alert;

--alter TABLE APPROVAL_STEP_MILESTONE modify MILESTONE_SID NOT NULL;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_ATTACHMENT')
order by table_name, constraint_name;
x ATTACHMENT_HISTORY             REFATTACHMENT826
*/

-- alter table  ATTACHMENT add APP_SID                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update attachment set app_sid = (select app_sid from ind where ind.ind_sid = attachment.indicator_sid) where app_sid is null;
update attachment set app_sid = (select app_sid from dataview where dataview.dataview_sid = attachment.dataview_sid) where app_sid is null;
update attachment set app_sid = (
	select min(sv.app_sid)
	  from attachment_history ah, section_version sv
	 where attachment.attachment_id = ah.attachment_id and sv.section_sid = ah.section_sid) where app_sid is null;
alter table attachment modify app_sid not null;
alter table attachment drop primary key cascade drop index;
alter table attachment add 
    CONSTRAINT PK_ATTACHMENT PRIMARY KEY (APP_SID, ATTACHMENT_ID)
using index tablespace indx
 ;
 
 
alter table  ATTACHMENT_HISTORY add APP_SID                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update attachment_history set app_sid = (select app_sid from attachment where attachment.attachment_id = attachment_history.attachment_id);
alter table ATTACHMENT_HISTORY modify app_sid not null;
alter table ATTACHMENT_HISTORY drop primary key drop index;
alter table ATTACHMENT_HISTORY add
    CONSTRAINT PK_ATTACHMENT_HISTORY PRIMARY KEY (SECTION_SID, VERSION_NUMBER, APP_SID, ATTACHMENT_ID)
using index tablespace indx
 ;


alter table autocreate_user drop primary key drop index;
alter table autocreate_user add 
    CONSTRAINT PK_AUTOCREATE_USER PRIMARY KEY (APP_SID, USER_NAME)
    USING INDEX
TABLESPACE INDX
 ;

alter table CUSTOMER_PORTLET drop primary key drop index;
alter table CUSTOMER_PORTLET add
    CONSTRAINT PK_CUSTOMER_PORTLET PRIMARY KEY (APP_SID, PORTLET_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DELIVERABLE')
order by table_name, constraint_name;
x ISSUE                          FK_ISSUE_DELIVERABLE
+ MILESTONE
*/
alter table DELIVERABLE modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table DELIVERABLE drop primary key cascade drop index;
alter table DELIVERABLE add
    CONSTRAINT PK_DELIVERABLE PRIMARY KEY (APP_SID, DELIVERABLE_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DOC')
order by table_name, constraint_name;
-moved DOC_SUBSCRIPTION               SYS_C00231994
x DOC_VERSION                    FK_DOC_VERSION_DOC
*/
alter table DOC add APP_SID    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update doc set app_sid = (select min(app_sid) from doc_version where doc_version.doc_id = doc.doc_id);
-- totally unreachable docs
delete from doc where app_sid is null;
alter table doc modify app_sid not null;
alter table doc drop primary key cascade drop index;
alter table doc add 
    CONSTRAINT PK_DOC PRIMARY KEY (APP_SID, DOC_ID)
     USING INDEX
 TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DOC_CURRENT')
order by table_name, constraint_name;
+moved DOC_SUBSCRIPTION               SYS_C00231994
*/
alter table  DOC_CURRENT modify APP_SID          DEFAULT SYS_CONTEXT('SECURITY','APP');
update doc_current set app_sid = (select app_sid from doc where doc.doc_id = doc_current.doc_id) where app_sid is null;
alter table doc_current modify app_sid not null;
alter table doc_current drop primary key cascade drop index;
alter table doc_current add
CONSTRAINT PK_DOC_CURRENT PRIMARY KEY (APP_SID, DOC_ID)
     USING INDEX
 TABLESPACE INDX
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DOC_DATA')
order by table_name, constraint_name;
x DOC_VERSION                    SYS_C00231997
*/ 
alter table doc_data add APP_SID        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update doc_data set app_sid = (select min(app_sid) from doc_version where doc_version.doc_data_id =doc_data.doc_data_id);
-- unreachable data
delete from doc_data where app_sid is null;
alter table doc_data modify app_sid not null;
alter table doc_data drop primary key cascade drop index;
alter table doc_data add 
    CONSTRAINT PK_DOC_DATA PRIMARY KEY (APP_SID, DOC_DATA_ID)
     USING INDEX
 TABLESPACE INDX
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DOC_FOLDER')
order by table_name, constraint_name;
x DOC_CURRENT                    FK_DOC_DOC_FOLDER
x DOC_LIBRARY                    SYS_C00231990
+ 1 DOC_LIBRARY
*/
alter TABLE DOC_FOLDER add APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP');
update doc_folder set app_sid = (select application_sid_id from security.securable_object so where so.sid_id = doc_folder.doc_folder_sid);
-- hmm, leftovers from create script leaving app_sid=null in SO
update doc_folder set app_sid = 9101083 where doc_folder_sid in (9279084,9279085);
update doc_folder set app_sid = 9292839 where doc_folder_sid in (9293033,9293034);
-- deleted securable objects => dead
delete from doc_folder where app_sid is null;
alter table doc_folder modify app_sid not null;
alter table doc_folder drop primary key cascade drop index;
alter table doc_folder add 
    CONSTRAINT PK_DOC_FOLDER PRIMARY KEY (APP_SID, DOC_FOLDER_SID)
     USING INDEX
 TABLESPACE INDX
 ;


alter table doc_library modify  APP_SID  DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table doc_library drop primary key drop index;
alter table doc_library add 
    CONSTRAINT PK_DOC_LIBRARY PRIMARY KEY (APP_SID, DOC_LIBRARY_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 
 
alter table DOC_NOTIFICATION drop primary key drop index;
alter table DOC_NOTIFICATION add 
    CONSTRAINT PK_DOC_NOTIFICATION PRIMARY KEY (APP_SID, DOC_NOTIFICATION_ID)
     USING INDEX
 TABLESPACE INDX
 ;

 
alter TABLE DOC_SUBSCRIPTION drop primary key drop index;
alter table DOC_SUBSCRIPTION add
    CONSTRAINT PK_DOC_SUBSCRIPTION PRIMARY KEY (APP_SID, DOC_ID, NOTIFY_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DOC_VERSION')
order by table_name, constraint_name;
x DOC_CURRENT                    FK_DOC_VERSION
x DOC_DOWNLOAD                   FK_DOC_DOWNLOAD_DOC_VERSION
x DOC_NOTIFICATION               FK_DOC_NOTIFICATION_VERSION
*/
alter table DOC_VERSION drop primary key cascade drop index;
alter table DOC_VERSION add
    CONSTRAINT PK_DOC_VERSION PRIMARY KEY (APP_SID, DOC_ID, VERSION)
     USING INDEX
 TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_FORM')
order by table_name, constraint_name;
x FORM_ALLOCATION                REFFORM42
x FORM_COMMENT                   REFFORM43
*/
alter table form modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table form drop primary key cascade drop index;
alter table form add 
    CONSTRAINT PK_FORM PRIMARY KEY (APP_SID, FORM_SID)
     USING INDEX
 TABLESPACE INDX
 ;

/* 
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_FORM_ALLOCATION')
order by table_name, constraint_name;
x FORM_ALLOCATION_ITEM           REFFORM_ALLOCATION45
x FORM_ALLOCATION_USER           REFFORM_ALLOCATION46
x FORM_COMMENT                   REFFORM_ALLOCATION44
*/
alter table form_allocation add  APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update form_allocation set app_sid = (select app_sid from form where form_allocation.form_sid = form.form_sid);
alter table form_allocation modify app_sid not null;
alter table form_allocation drop primary key cascade drop index;
alter table form_allocation add 
    CONSTRAINT PK_FORM_ALLOCATION PRIMARY KEY (APP_SID, FORM_ALLOCATION_ID)
     USING INDEX
 TABLESPACE INDX
 ;
 
 

alter table  FORM_ALLOCATION_ITEM add APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update FORM_ALLOCATION_ITEM set app_sid = (select app_sid from form_allocation where form_allocation.FORM_ALLOCATION_ID = FORM_ALLOCATION_ITEM.FORM_ALLOCATION_ID);
alter table FORM_ALLOCATION_ITEM modify app_sid not null;
alter table FORM_ALLOCATION_ITEM drop primary key drop index;
alter table FORM_ALLOCATION_ITEM add 
    CONSTRAINT PK_FORM_ALLOCATION_ITEM PRIMARY KEY (APP_SID, FORM_ALLOCATION_ID, ITEM_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 
alter table FORM_COMMENT add APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update FORM_COMMENT set app_sid = (select app_sid from form where form.form_sid = form_comment.form_sid);
alter table form_comment modify app_sid not null;
alter table form_comment drop primary key drop index;
alter table form_comment add
    CONSTRAINT PK_FORM_COMMENT PRIMARY KEY (APP_SID, FORM_SID, Z_KEY, FORM_ALLOCATION_ID)
     USING INDEX
 TABLESPACE INDX
 ;


/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_ISSUE','UK_ISSUE_DELIVERABLE')
order by table_name, constraint_name;

x ISSUE_LOG                      FK_ISSUE_LOG_ISSUE
x ISSUE_PENDING_VAL              FK_ISSUE_PENDVAL_ISSUE

,, fallout from missing from last one?
+ ISSUE_USER                     FK_ISSUE_USER_ISSUE
+ MILESTONE_ISSUE                FK_ISSUE_MILE_ISSUE
*/
alter table issue drop primary key cascade drop index;
begin
    -- need to drop this...
	for r in (select * from user_constraints where table_name='MILESTONE_ISSUE' AND constraint_name='FK_ISSUE_MILE_ISSUE') loop
		execute immediate 'ALTER TABLE MILESTONE_ISSUE DROP CONSTRAINT FK_ISSUE_MILE_ISSUE';
	end loop;
	-- ...before we can drop this:
	for r in (select * from user_constraints where table_name='ISSUE' AND constraint_name='UK_ISSUE_DELIVERABLE') loop
		execute immediate 'alter table issue drop constraint uk_issue_deliverable drop index';
	end loop;
end;
/
alter table issue add CONSTRAINT PK_ISSUE PRIMARY KEY (APP_SID, ISSUE_ID)
using index tablespace indx;
alter table issue add CONSTRAINT UK_ISSUE_DELIVERABLE UNIQUE (APP_SID, ISSUE_ID, DELIVERABLE_SID)
using index tablespace indx;

alter table issue_pending_val modify issue_id null;
ALTER TABLE ISSUE_PENDING_VAL ADD CHECK 
	(ISSUE_ID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_ISSUE_LOG')
order by table_name, constraint_name;
x ISSUE_LOG_READ                 REFISSUE_LOG624
*/
alter table issue_log drop primary key cascade drop index;
alter table issue_log add
    CONSTRAINT PK_ISSUE_LOG PRIMARY KEY (APP_SID, ISSUE_LOG_ID)
using index tablespace indx ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_MILESTONE','UK_MILESTONE_DELIVERABLE')
order by table_name, constraint_name;
APPROVAL_STEP_MILESTONE        FK_MILESTONE_AP
more fallout?
+MILESTONE_ISSUE                FK_MILE_ISS_MILESTONE
*/
 
alter table milestone add APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update milestone set app_sid = (select app_sid from deliverable where deliverable.deliverable_sid = milestone.deliverable_sid);
alter table milestone modify app_sid not null;
alter table milestone drop primary key cascade drop index;
alter table milestone add CONSTRAINT PK_MILESTONE PRIMARY KEY (APP_SID, MILESTONE_SID)
using index  tablespace indx;
begin
	for r in (select * from user_constraints where table_name='MILESTONE' AND constraint_name IN ('UK_MILESTONE_DELIVERABLE','SYS_C00225241')) loop
		execute immediate 'alter table milestone drop constraint '||r.constraint_name||' cascade drop index';
	end loop;
end;
/

alter table milestone add constraint UK_MILESTONE_DELIVERABLE
     UNIQUE (APP_SID, MILESTONE_SID, DELIVERABLE_SID)
using index  tablespace indx;

alter table MILESTONE_ISSUE add APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update milestone_issue set app_sid = (select app_sid from milestone where milestone.milestone_sid = milestone_issue.milestone_sid);
-- 3 rows of test data
delete from milestone_issue where app_sid is null;
alter table milestone_issue modify app_sid not null;
alter table milestone_issue drop primary key drop index;
alter table milestone_issue add
    CONSTRAINT PK_MILESTONE_ISSUE PRIMARY KEY (APP_SID, MILESTONE_SID, ISSUE_ID, DELIVERABLE_SID)
using index tablespace indx
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK2','PK_SECTION')
order by table_name, constraint_name;
x ROOT_SECTION_USER              REFSECTION829
x SECTION                        REFSECTION834
x SECTION_APPROVERS              REFSECTION836
x SECTION_COMMENT                REFSECTION837
x SECTION_VERSION                REFSECTION843
*/
  
alter table section modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table section drop primary key cascade drop index;
alter table section add 
    CONSTRAINT PK_SECTION PRIMARY KEY (APP_SID, SECTION_SID)
using index tablespace indx
 ;

begin
	for r in (select 1 from user_tab_columns where column_name='VISIBLE_VERSION_NUMBER' and table_name='SECTION' and nullable='N') loop
		execute immediate 'alter table section modify visible_version_number null';
	end loop;
end;
/

ALTER TABLE SECTION ADD CHECK 
	(VISIBLE_VERSION_NUMBER IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK4','PK_SECTION_COMMENT')
order by table_name, constraint_name;
x SECTION_COMMENT                REFSECTION_COMMENT839
*/

alter table SECTION_COMMENT drop primary key cascade drop index;
alter table SECTION_COMMENT add
    CONSTRAINT PK4 PRIMARY KEY (APP_SID, SECTION_COMMENT_ID)
using index tablespace indx
 ;

 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK427','PK_SECTION_MODULE')
order by table_name, constraint_name;
x SECTION                        REFSECTION_MODULE833
*/
alter TABLE SECTION_MODULE modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table section_module drop primary key cascade drop index;
alter table section_module add
    CONSTRAINT PK_SECTION_MODULE PRIMARY KEY (APP_SID, MODULE_ROOT_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK7','PK_SECTION_VERSION')
order by table_name, constraint_name;
x ATTACHMENT_HISTORY             REFSECTION_VERSION827
x SECTION                        REFSECTION_VERSION830
x SECTION                        REFSECTION_VERSION831*/
alter table SECTION_VERSION modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter TABLE SECTION_VERSION drop primary key cascade drop index;
alter table SECTION_VERSION add
    CONSTRAINT PK_SECTION_VERSION PRIMARY KEY (APP_SID, SECTION_SID, VERSION_NUMBER)
    USING INDEX
TABLESPACE INDX
 ;

 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK439','PK_SNAPSHOT')
order by table_name, constraint_name;
x SNAPSHOT_IND                   REFSNAPSHOT867
*/
alter TABLE SNAPSHOT modify APP_SID         DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table snapshot drop primary key cascade drop index;
alter table snapshot add 
    CONSTRAINT PK_SNAPSHOT PRIMARY KEY (APP_SID, NAME)
    USING INDEX
TABLESPACE INDX
 ;
 
 
 /*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK150','PK_SURVEY')
order by table_name, constraint_name;
x SURVEY_RESPONSE                REFSURVEY192
*/
alter table survey  modify APP_SID         DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table survey drop primary key cascade drop index;
alter table survey add
    CONSTRAINT PK_SURVEY PRIMARY KEY (APP_SID, SURVEY_SID)
    USING INDEX
TABLESPACE INDX
 ;
 

alter table  SURVEY_ALLOCATION  drop primary key drop index;
alter table  SURVEY_ALLOCATION  add
    CONSTRAINT PK_SURVEY_ALLOCATION PRIMARY KEY (APP_SID, CSR_USER_SID, SURVEY_RESPONSE_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
 /*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK151','PK_SURVEY_RESPONSE')
order by table_name, constraint_name;
x SURVEY_ALLOCATION              REFSURVEY_RESPONSE560
*/
alter table  SURVEY_RESPONSE  drop primary key cascade drop index;
alter table  SURVEY_RESPONSE  add
    CONSTRAINT PK_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 /*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK6_1','PK_TAG')
order by table_name, constraint_name;
 
x IND_TAG                        REFTAG228
x REGION_TAG                     REFTAG230
x TAG_GROUP_MEMBER               REFTAG233
*/
 
alter table TAG add APP_SID        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update tag set app_sid = (select min(app_sid) from ind_tag where ind_tag.tag_id = tag.tag_id) where app_sid is null;
update tag set app_sid = (select min(app_sid) from region_tag where region_tag.tag_id = tag.tag_id) where app_sid is null;
update tag set app_sid = (
	select min(tg.app_sid) 
	  from tag_group tg, tag_group_member tgm
	 where tgm.tag_id = tag.tag_id and tg.tag_group_id = tgm.tag_group_id)
where app_sid is null;
-- unreachable  tags
delete from tag where app_sid is null;
alter table tag modify app_sid not null;
alter table TAG drop primary key cascade drop index;
alter table TAG add 
    CONSTRAINT PK_TAG PRIMARY KEY (APP_SID, TAG_ID)
    USING INDEX
TABLESPACE INDX 
 ;
 
 
 /*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK9_1','PK_TAG_GROUP')
order by table_name, constraint_name;
x SNAPSHOT                       REFTAG_GROUP864
x TAG_GROUP_MEMBER               REFTAG_GROUP232
*/
/*
alter table  TAG_GROUP add APP_SID        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update tag_group set app_sid = (
	select app_sid
	  from tag t, tag_group_member tgm
	 where t.tag_id = tgm.tag_id AND tag_group.tag_group_id = tag_group.tag_group_id);
alter table  TAG_GROUP modify app_sid not null;*/
alter table  TAG_GROUP modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table tag_group drop primary key cascade drop index;
alter table tag_group add
    CONSTRAINT PK_TAG_GROUP PRIMARY KEY (APP_SID, TAG_GROUP_ID)
    USING INDEX
TABLESPACE INDX
 ;

alter table  TAG_GROUP_MEMBER add APP_SID        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update tag_group_member set app_sid = (select app_sid from tag_group where tag_group_member.tag_group_id = tag_group.tag_group_id);
alter table  TAG_GROUP_MEMBER modify APP_SID not null;
alter table  TAG_GROUP_MEMBER drop primary key drop index;
alter table  TAG_GROUP_MEMBER  add 
    CONSTRAINT PK_TAG_GROUP_MEMBER PRIMARY KEY (APP_SID, TAG_GROUP_ID, TAG_ID)
    USING INDEX
TABLESPACE INDX
 ;
  
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_TARGET_DASHBOARD')
order by table_name, constraint_name;
x TARGET_DASHBOARD_IND_MEMBER    REFTARGET_DASHBOARD129
x TARGET_DASHBOARD_VALUE         REFTARGET_DASHBOARD132
*/
alter TABLE TARGET_DASHBOARD add  APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update TARGET_DASHBOARD set app_sid = (select application_sid_id from security.securable_object so where so.sid_id = target_dashboard.TARGET_DASHBOARD_sid);
alter table TARGET_DASHBOARD modify app_sid not null;
alter table TARGET_DASHBOARD drop primary key cascade drop index;
alter table TARGET_DASHBOARD add 
   CONSTRAINT PK_TARGET_DASHBOARD PRIMARY KEY (APP_SID, TARGET_DASHBOARD_SID)
    USING INDEX
TABLESPACE INDX
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DASHBOARD')
order by table_name, constraint_name;
x DASHBOARD_ITEM                 REFDASHBOARD56
*/
alter table dashboard add app_sid NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update dashboard set app_sid = (select min(app_sid) from dashboard_item where dashboard.dashboard_sid=dashboard_item.dashboard_sid);
alter table dashboard modify app_sid not null;
alter table dashboard drop primary key cascade drop index;
alter table dashboard add
    CONSTRAINT PK_DASHBOARD PRIMARY KEY (APP_SID, DASHBOARD_SID)
     USING INDEX
 TABLESPACE INDX
 ;

alter table dashboard_item drop primary key drop index;
alter table dashboard_item add 
CONSTRAINT PK_DASHBOARD_ITEM PRIMARY KEY (APP_SID, DASHBOARD_ITEM_ID)
     USING INDEX
 TABLESPACE INDX
 ;
 

begin
	for r in (select index_name from user_indexes where index_name in(
		'IX_REGION_BACK_LINK', 'REF2323', 'SECTION_REF_KEY', 'SHEET_VALUE_ALT_KEY',
		'IDX_REGION_PARENT_SID', 'REF3725', 'REF2465', 'REF2330',
		'REF549', 'REF2329', 'IX_IND_AGGR_EST_IND_SID', 'IND_PARENT_SID',
		'REF293', 'REF1344', 'REF1346', 'REF548', 'REF1243', 'REF1345',
		'REF1242', 'IX_DOC_NOTIFICATION_SENT', 'IX_DOC_DOWNLOAD', 'REF960',
		'REF2359', 'REF3758', 'REF857', 'REF656', 'REF2332', 'REF2317',
		'IDX_AUDIT_LOG_APP_SID', 'IDX_AUDIT_LOG_SUB_OBJECT_ID',
		'IDX_AUDIT_LOG_USER_SID', 'IDX_AUDIT_LOG_OBJECT_SID',
		'IX_ALERT_TYPE_SENT_NTFY_AFTER', 'IX_APP_REGION_PARENT'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/

-- buggered! 
CREATE INDEX IDX_ALERT_TYPE_SENT_NTFY_AFT ON ALERT(APP_SID, ALERT_TYPE_ID, SENT_DTM, SEND_AFTER_DTM, NOTIFY_USER_SID)
TABLESPACE INDX
 ;
  
CREATE INDEX IDX_AUDIT_LOG_OBJECT_SID ON AUDIT_LOG(APP_SID, OBJECT_SID)
TABLESPACE INDX
 ;
 
CREATE INDEX IDX_AUDIT_LOG_USER_SID ON AUDIT_LOG(APP_SID, USER_SID)
TABLESPACE INDX
 ;

 
CREATE INDEX IDX_AUDIT_LOG_SUB_OBJECT_ID ON AUDIT_LOG(APP_SID, SUB_OBJECT_ID)
TABLESPACE INDX
 ;

 CREATE INDEX IDX_AUDIT_LOG_APP_SID ON AUDIT_LOG(APP_SID)
TABLESPACE INDX
 ;
 
CREATE INDEX IDX_CALC_DEP_CALC_IND ON CALC_DEPENDENCY(APP_SID, CALC_IND_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_CALC_DEP_IND ON CALC_DEPENDENCY(APP_SID, IND_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_DASH_ITEM_DATAVIEW ON DASHBOARD_ITEM(APP_SID, DATAVIEW_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_DASH_ITEM_COMP_TYPE ON DASHBOARD_ITEM(COMPARISON_TYPE)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_DASH_ITEM_REG ON DASHBOARD_ITEM(APP_SID, REGION_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_DASH_ITEM_IND ON DASHBOARD_ITEM(APP_SID, IND_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_DASH_ITEM_DASH ON DASHBOARD_ITEM(APP_SID, DASHBOARD_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_DOC_DOWNLOAD ON DOC_DOWNLOAD(APP_SID, VERSION, DOWNLOADED_DTM)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_DOC_NOTIFICATION_SENT ON DOC_NOTIFICATION(APP_SID, SENT_DTM, DOC_NOTIFICATION_ID)
 TABLESPACE INDX
 ; 
 
CREATE INDEX IDX_FORM_ALL_FORM ON FORM_ALLOCATION(APP_SID, FORM_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_FA_USER_FA ON FORM_ALLOCATION_USER(APP_SID, FORM_ALLOCATION_ID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_FA_USER_USER ON FORM_ALLOCATION_USER(APP_SID, USER_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_FORM_COMMENT_FORM ON FORM_COMMENT(APP_SID, FORM_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_FORM_COMMENT_FA ON FORM_COMMENT(APP_SID, FORM_ALLOCATION_ID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IND_MEASURE ON IND(APP_SID, MEASURE_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IND_PARENT_SID ON IND(APP_SID, PARENT_SID)
TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IND_AGGR_EST_IND_SID ON IND(APP_SID, AGGR_ESTIMATE_WITH_IND_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_IND_OWNER_USER ON IND_OWNER(APP_SID, USER_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IND_WINDOW_IND ON IND_WINDOW(APP_SID, IND_SID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_IDX_SECT_ITM_SECT ON INDEX_SECTION_ITEM(INDEX_SECTION_ID)
 TABLESPACE INDX
 ;
 
CREATE INDEX IDX_RNG_REG_MEM_REG ON RANGE_REGION_MEMBER(APP_SID, REGION_SID)
 TABLESPACE INDX
 ;

CREATE INDEX IDX_REGION_PARENT_SID ON REGION(APP_SID, PARENT_SID)
 TABLESPACE INDX
;
 
 CREATE INDEX IDX_REGION_BACK_LINK ON REGION(APP_SID, LINK_TO_REGION_SID, REGION_SID)
 TABLESPACE INDX
 ;


CREATE INDEX IDX_REG_RECALC_IND ON REGION_RECALC_JOB(APP_SID, IND_SID)
 TABLESPACE INDX
 ;

 
/* has dups, removed from model?
alter table section add constraint UK_SECTION_REF_KEY unique (APP_SID, REF)
using index TABLESPACE INDX;
*/

alter table sheet_value add constraint UK_SHT_VAL_SHT_IND_REG unique (APP_SID, SHEET_ID, IND_SID, REGION_SID)
using index TABLESPACE INDX
 ;

 
 ALTER TABLE APPROVAL_STEP_MILESTONE ADD CONSTRAINT FK_MILESTONE_AP 
    FOREIGN KEY (APP_SID, MILESTONE_SID)
    REFERENCES MILESTONE(APP_SID, MILESTONE_SID)
 ;
 
 
 ALTER TABLE ATTACHMENT_HISTORY ADD CONSTRAINT RefATTACHMENT826 
    FOREIGN KEY (APP_SID, ATTACHMENT_ID)
    REFERENCES ATTACHMENT(APP_SID, ATTACHMENT_ID)
 ;
 
 ALTER TABLE ATTACHMENT_HISTORY ADD CONSTRAINT RefSECTION_VERSION827 
    FOREIGN KEY (APP_SID, SECTION_SID, VERSION_NUMBER)
    REFERENCES SECTION_VERSION(APP_SID, SECTION_SID, VERSION_NUMBER)
 ;
 
 

ALTER TABLE DASHBOARD ADD CONSTRAINT RefCUSTOMER1013 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


 
 ALTER TABLE DASHBOARD_ITEM ADD CONSTRAINT RefDASHBOARD56 
    FOREIGN KEY (APP_SID, DASHBOARD_SID)
    REFERENCES DASHBOARD(APP_SID, DASHBOARD_SID)
 ;
 
ALTER TABLE DOC ADD CONSTRAINT RefCUSTOMER1006 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


 
 ALTER TABLE DOC_CURRENT ADD CONSTRAINT RefDOC_VERSION684 
    FOREIGN KEY (APP_SID, DOC_ID, VERSION)
    REFERENCES DOC_VERSION(APP_SID, DOC_ID, VERSION)
 ;
 
 ALTER TABLE DOC_CURRENT ADD CONSTRAINT RefDOC_FOLDER685 
    FOREIGN KEY (APP_SID, PARENT_SID)
    REFERENCES DOC_FOLDER(APP_SID, DOC_FOLDER_SID)
;


ALTER TABLE DOC_DATA ADD CONSTRAINT RefCUSTOMER1007 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
 ;
 
  
 ALTER TABLE DOC_DOWNLOAD ADD CONSTRAINT RefDOC_VERSION672 
    FOREIGN KEY (APP_SID, DOC_ID, VERSION)
    REFERENCES DOC_VERSION(APP_SID, DOC_ID, VERSION)
;


ALTER TABLE DOC_FOLDER ADD CONSTRAINT RefCUSTOMER1008 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
 ;
 
 
 
 ALTER TABLE DOC_LIBRARY ADD CONSTRAINT RefDOC_FOLDER686 
    FOREIGN KEY (APP_SID, DOCUMENTS_SID)
    REFERENCES DOC_FOLDER(APP_SID, DOC_FOLDER_SID)
 ;
 
 
 ALTER TABLE DOC_LIBRARY ADD CONSTRAINT RefDOC_FOLDER688 
    FOREIGN KEY (APP_SID, TRASH_FOLDER_SID)
    REFERENCES DOC_FOLDER(APP_SID, DOC_FOLDER_SID)
 ;
 
 
 ALTER TABLE DOC_NOTIFICATION ADD CONSTRAINT RefDOC_VERSION695 
    FOREIGN KEY (APP_SID, DOC_ID, VERSION)
    REFERENCES DOC_VERSION(APP_SID, DOC_ID, VERSION)
 ;
 
 
 ALTER TABLE DOC_SUBSCRIPTION ADD CONSTRAINT RefDOC_CURRENT689 
    FOREIGN KEY (APP_SID, DOC_ID)
    REFERENCES DOC_CURRENT(APP_SID, DOC_ID)
 ;
 
 
 ALTER TABLE DOC_VERSION ADD CONSTRAINT RefDOC_DATA675 
    FOREIGN KEY (APP_SID, DOC_DATA_ID)
    REFERENCES DOC_DATA(APP_SID, DOC_DATA_ID)
 ;
 
 
 ALTER TABLE DOC_VERSION ADD CONSTRAINT RefDOC691 
    FOREIGN KEY (APP_SID, DOC_ID)
    REFERENCES DOC(APP_SID, DOC_ID)
 ;
 

ALTER TABLE FORM ADD CONSTRAINT RefCUSTOMER1009 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
 ALTER TABLE FORM_ALLOCATION ADD CONSTRAINT RefFORM42 
    FOREIGN KEY (APP_SID, FORM_SID)
    REFERENCES FORM(APP_SID, FORM_SID)
 ;
 
 
 
 ALTER TABLE FORM_ALLOCATION_ITEM ADD CONSTRAINT RefFORM_ALLOCATION45 
    FOREIGN KEY (APP_SID, FORM_ALLOCATION_ID)
    REFERENCES FORM_ALLOCATION(APP_SID, FORM_ALLOCATION_ID)
 ;
 
 
 
 ALTER TABLE FORM_ALLOCATION_USER ADD CONSTRAINT RefFORM_ALLOCATION46 
    FOREIGN KEY (APP_SID, FORM_ALLOCATION_ID)
    REFERENCES FORM_ALLOCATION(APP_SID, FORM_ALLOCATION_ID)
 ;
 
 
 ALTER TABLE FORM_COMMENT ADD CONSTRAINT RefFORM43 
    FOREIGN KEY (APP_SID, FORM_SID)
    REFERENCES FORM(APP_SID, FORM_SID)
 ;
 
 ALTER TABLE FORM_COMMENT ADD CONSTRAINT RefFORM_ALLOCATION44 
    FOREIGN KEY (APP_SID, FORM_ALLOCATION_ID)
    REFERENCES FORM_ALLOCATION(APP_SID, FORM_ALLOCATION_ID)
 ;
 
  
 ALTER TABLE IND_TAG ADD CONSTRAINT RefTAG228 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES TAG(APP_SID, TAG_ID)
 ;
 
 
 ALTER TABLE ISSUE ADD CONSTRAINT FK_ISSUE_DELIVERABLE 
    FOREIGN KEY (APP_SID, DELIVERABLE_SID)
    REFERENCES DELIVERABLE(APP_SID, DELIVERABLE_SID)
 ;
 
 
 
 ALTER TABLE ISSUE_LOG ADD CONSTRAINT FK_ISSUE_LOG_ISSUE 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES ISSUE(APP_SID, ISSUE_ID)
 ;
 
 ALTER TABLE ISSUE_LOG_READ ADD CONSTRAINT RefISSUE_LOG624 
    FOREIGN KEY (APP_SID, ISSUE_LOG_ID)
    REFERENCES ISSUE_LOG(APP_SID, ISSUE_LOG_ID)
 ;

 ALTER TABLE ISSUE_PENDING_VAL ADD CONSTRAINT FK_ISSUE_PENDVAL_ISSUE 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES ISSUE(APP_SID, ISSUE_ID) 
 ;
 
 
 ALTER TABLE ISSUE_USER ADD CONSTRAINT FK_ISSUE_USER_ISSUE 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES ISSUE(APP_SID, ISSUE_ID)
 ;
 
 
 ALTER TABLE MILESTONE ADD CONSTRAINT FK_MILESTONE_DELIVERABLE 
    FOREIGN KEY (APP_SID, DELIVERABLE_SID)
    REFERENCES DELIVERABLE(APP_SID, DELIVERABLE_SID)
 ;
 
 
 ALTER TABLE MILESTONE_ISSUE ADD CONSTRAINT FK_ISSUE_MILE_ISSUE 
    FOREIGN KEY (APP_SID, ISSUE_ID, DELIVERABLE_SID)
    REFERENCES ISSUE(APP_SID, ISSUE_ID, DELIVERABLE_SID)
 ;
 
 ALTER TABLE MILESTONE_ISSUE ADD CONSTRAINT FK_MILE_ISS_MILESTONE 
    FOREIGN KEY (APP_SID, MILESTONE_SID, DELIVERABLE_SID)
    REFERENCES MILESTONE(APP_SID, MILESTONE_SID, DELIVERABLE_SID)
 ;
 
 
/*
 ALTER TABLE RANGE_IND_MEMBER ADD CONSTRAINT RefIND24 
    FOREIGN KEY (APP_SID, MULTIPLIER_IND_SID)
     REFERENCES IND(APP_SID, IND_SID)
 ;
 
 ALTER TABLE RANGE_IND_MEMBER ADD CONSTRAINT RefIND235 
    FOREIGN KEY (APP_SID, IND_SID)
     REFERENCES IND(APP_SID, IND_SID)
 ;
*/ 
 
 ALTER TABLE REGION_TAG ADD CONSTRAINT RefTAG230 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES TAG(APP_SID, TAG_ID)
 ;
 
 ALTER TABLE ROOT_SECTION_USER ADD CONSTRAINT RefSECTION829 
    FOREIGN KEY (APP_SID, ROOT_SECTION_SID)
    REFERENCES SECTION(APP_SID, SECTION_SID)
 ;
 
 
 
 ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_VERSION830 
    FOREIGN KEY (APP_SID, SECTION_SID, CHECKED_OUT_VERSION_NUMBER)
    REFERENCES SECTION_VERSION(APP_SID, SECTION_SID, VERSION_NUMBER)
 ;

 ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_VERSION831 
    FOREIGN KEY (APP_SID, SECTION_SID, VISIBLE_VERSION_NUMBER)
    REFERENCES SECTION_VERSION(APP_SID, SECTION_SID, VERSION_NUMBER)  ;
 
 
 ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_MODULE833 
    FOREIGN KEY (APP_SID, MODULE_ROOT_SID)
    REFERENCES SECTION_MODULE(APP_SID, MODULE_ROOT_SID)
 ;
 
 ALTER TABLE SECTION ADD CONSTRAINT RefSECTION834 
    FOREIGN KEY (APP_SID, PARENT_SID)
    REFERENCES SECTION(APP_SID, SECTION_SID)
 ;
 
 
 ALTER TABLE SECTION_APPROVERS ADD CONSTRAINT RefSECTION836 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES SECTION(APP_SID, SECTION_SID)
 ;
 
 
 ALTER TABLE SECTION_COMMENT ADD CONSTRAINT RefSECTION837 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES SECTION(APP_SID, SECTION_SID)
 ;
 
 
 ALTER TABLE SECTION_COMMENT ADD CONSTRAINT RefSECTION_COMMENT839 
    FOREIGN KEY (APP_SID, IN_REPLY_TO_ID)
    REFERENCES SECTION_COMMENT(APP_SID, SECTION_COMMENT_ID)
 ;
 
 
 ALTER TABLE SECTION_VERSION ADD CONSTRAINT RefSECTION843 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES SECTION(APP_SID, SECTION_SID)
 ;
 
 ALTER TABLE SNAPSHOT ADD CONSTRAINT RefTAG_GROUP868 
    FOREIGN KEY (APP_SID, TAG_GROUP_ID)
    REFERENCES TAG_GROUP(APP_SID, TAG_GROUP_ID)
 ;
 
 ALTER TABLE SNAPSHOT_IND ADD CONSTRAINT RefSNAPSHOT871 
    FOREIGN KEY (APP_SID, NAME)
    REFERENCES SNAPSHOT(APP_SID, NAME)
 ;
 
 
 ALTER TABLE SURVEY_ALLOCATION ADD CONSTRAINT RefSURVEY_RESPONSE560 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID)
    REFERENCES SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID)
 ;
 
 
 ALTER TABLE SURVEY_RESPONSE ADD CONSTRAINT RefSURVEY192 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES SURVEY(APP_SID, SURVEY_SID)
 ;
 

ALTER TABLE TAG ADD CONSTRAINT RefCUSTOMER1010 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
 ALTER TABLE TAG_GROUP_MEMBER ADD CONSTRAINT RefTAG_GROUP232 
    FOREIGN KEY (APP_SID, TAG_GROUP_ID)
    REFERENCES TAG_GROUP(APP_SID, TAG_GROUP_ID)
 ;
 
 ALTER TABLE TAG_GROUP_MEMBER ADD CONSTRAINT RefTAG233 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES TAG(APP_SID, TAG_ID)
 ;
 
ALTER TABLE TARGET_DASHBOARD ADD CONSTRAINT RefCUSTOMER1011 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
 ALTER TABLE TARGET_DASHBOARD_IND_MEMBER ADD CONSTRAINT RefTARGET_DASHBOARD129 
    FOREIGN KEY (APP_SID, TARGET_DASHBOARD_SID)
    REFERENCES TARGET_DASHBOARD(APP_SID, TARGET_DASHBOARD_SID)
 ;
 
 
 ALTER TABLE TARGET_DASHBOARD_VALUE ADD CONSTRAINT RefTARGET_DASHBOARD132 
    FOREIGN KEY (APP_SID, TARGET_DASHBOARD_SID)
    REFERENCES TARGET_DASHBOARD(APP_SID, TARGET_DASHBOARD_SID)
 ;
  
@update_tail
