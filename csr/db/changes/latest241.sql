-- Please update version.sql too -- this keeps clean builds in sync
define version=241
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
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK166', 'PK_ACCURACY_TYPE_OPTION')
order by table_name, constraint_name;

x PENDING_VAL_ACCURACY_TYPE_OPT  REFACCURACY_TYPE_OPTION513
x SHEET_VALUE_ACCURACY           REFACCURACY_TYPE_OPTION438
x VAL_ACCURACY                   REFACCURACY_TYPE_OPTION440
*/

alter table ACCURACY_TYPE_OPTION drop primary key cascade drop index;
alter table ACCURACY_TYPE_OPTION add
    CONSTRAINT PK_ACCURACY_TYPE_OPTION PRIMARY KEY (APP_SID, ACCURACY_TYPE_OPTION_ID)
using index tablespace indx
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK215', 'PK_PENDING_IND')
order by table_name, constraint_name;

x APPROVAL_STEP_IND              REFPENDING_IND463
x APPROVAL_STEP_SHEET            REFPENDING_IND555
x ISSUE_PENDING_VAL              REFPENDING_IND626
x PENDING_IND                    REFPENDING_IND502
x PENDING_IND                    REFPENDING_IND526
x PENDING_IND_ACCURACY_TYPE      REFPENDING_IND511
x PENDING_IND_RULE               REFPENDING_IND478
x PENDING_VAL                    REFPENDING_IND483
x PENDING_VAL_CACHE              REFPENDING_IND578
x PVC_REGION_RECALC_JOB          REFPENDING_IND712
x PVC_STORED_CALC_JOB            REFPENDING_IND715
*/
 
update pending_ind set app_sid = (select app_sid from pending_dataset where pending_dataset.pending_dataset_id = pending_ind.pending_dataset_id) where app_sid is null;
alter table pending_ind modify app_sid not null;
alter table pending_ind drop primary key cascade drop index;
alter table pending_ind add
    CONSTRAINT PK_PENDING_IND PRIMARY KEY (APP_SID, PENDING_IND_ID)
using index tablespace indx
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK216', 'PK_PENDING_REGION')
order by table_name, constraint_name;

x APPROVAL_STEP_REGION           REFPENDING_REGION464
x APPROVAL_STEP_REGION           REFPENDING_REGION465
x APPROVAL_STEP_SHEET            REFPENDING_REGION554
x APPROVAL_STEP_TEMPLATE         REFPENDING_REGION499
x ISSUE_PENDING_VAL              REFPENDING_REGION625
x PENDING_REGION                 REFPENDING_REGION503
x PENDING_VAL                    REFPENDING_REGION482
x PENDING_VAL_CACHE              REFPENDING_REGION576
x PVC_STORED_CALC_JOB            REFPENDING_REGION716
*/
update pending_Region set app_sid = (select app_sid from pending_dataset where pending_dataset.pending_dataset_id = pending_region.pending_dataset_id) where app_sid is null;
alter table pending_region modify app_sid not null;
alter table pending_region drop primary key cascade drop index;
alter table pending_region add 
    CONSTRAINT PK_PENDING_REGION PRIMARY KEY (APP_SID, PENDING_REGION_ID)
using index tablespace indx
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK217', 'PK_PENDING_PERIOD')
order by table_name, constraint_name;
x APPROVAL_STEP_SHEET            REFPENDING_PERIOD553
x ISSUE_PENDING_VAL              REFPENDING_PERIOD627
x PENDING_VAL                    REFPENDING_PERIOD485
x PENDING_VAL_CACHE              REFPENDING_PERIOD577
x PVC_STORED_CALC_JOB            REFPENDING_PERIOD717
*/
alter table pending_period add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update pending_period set app_sid = (select app_sid from pending_dataset where pending_dataset.pending_dataset_id = pending_period.pending_dataset_id);
alter table pending_period modify app_sid not null;
alter table pending_period drop primary key cascade drop index;
alter table pending_period add 
CONSTRAINT PK_PENDING_PERIOD PRIMARY KEY (APP_SID, PENDING_PERIOD_ID)
using index tablespace indx
 ;
  

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK220', 'PK_APPROVAL_STEP')
order by table_name, constraint_name;
 
x APPROVAL_STEP                  REFAPPROVAL_STEP460
x APPROVAL_STEP                  REFAPPROVAL_STEP461
x APPROVAL_STEP_IND              REFAPPROVAL_STEP462
x APPROVAL_STEP_MILESTONE        FK_AP_MILESTONE_AP
x APPROVAL_STEP_REGION           REFAPPROVAL_STEP466
x APPROVAL_STEP_ROLE             REFAPPROVAL_STEP895
x APPROVAL_STEP_SHEET            REFAPPROVAL_STEP546
x APPROVAL_STEP_USER             REFAPPROVAL_STEP468
x PENDING_VAL                    REFAPPROVAL_STEP484
*/

alter TABLE APPROVAL_STEP add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP set app_sid = (select app_sid from pending_dataset where pending_dataset.pending_dataset_id = approval_step.pending_dataset_id);
alter table approval_step modify app_sid not null;
alter table approval_step drop primary key cascade drop index;
alter table approval_step add 
    CONSTRAINT PK_APPROVAL_STEP PRIMARY KEY (APP_SID, APPROVAL_STEP_ID)
using index tablespace indx
 ;
 
alter table  APPROVAL_STEP_IND add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_IND set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = APPROVAL_STEP_IND.pending_ind_id);
alter table  APPROVAL_STEP_IND modify app_sid not null;
alter table  APPROVAL_STEP_IND drop primary key drop index;
alter table  APPROVAL_STEP_IND add
    CONSTRAINT PK_APPROVAL_STEP_IND PRIMARY KEY (APP_SID, APPROVAL_STEP_ID, PENDING_IND_ID)
using index tablespace indx
 ;
 
 
alter table  APPROVAL_STEP_MILESTONE add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_MILESTONE set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP_MILESTONE.approval_step_id = approval_step.approval_step_id);
alter table APPROVAL_STEP_MILESTONE modify app_sid not null;
alter table APPROVAL_STEP_MILESTONE drop primary key drop index;
alter table APPROVAL_STEP_MILESTONE add 
    CONSTRAINT PK_APPROVAL_STEP_MILESTONE PRIMARY KEY (APPROVAL_STEP_ID, APP_SID)
using index tablespace indx
 ;
 

alter table  APPROVAL_STEP_REGION add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_REGION set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP.APPROVAL_STEP_ID = APPROVAL_STEP_REGION.APPROVAL_STEP_ID);
alter table  APPROVAL_STEP_REGION modify app_sid not null;
alter table  APPROVAL_STEP_REGION drop primary key drop index;
alter table  APPROVAL_STEP_REGION add
    CONSTRAINT PK_APPROVAL_STEP_REGION PRIMARY KEY (APP_SID, APPROVAL_STEP_ID, PENDING_REGION_ID)
using index tablespace indx
 ;

alter table  APPROVAL_STEP_ROLE add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_ROLE set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP.APPROVAL_STEP_ID = APPROVAL_STEP_ROLE.APPROVAL_STEP_ID);
alter table  APPROVAL_STEP_ROLE modify app_sid not null;
alter table  APPROVAL_STEP_ROLE drop primary key drop index;
alter table  APPROVAL_STEP_ROLE add
CONSTRAINT PK_APPROVAL_STEP_ROLE PRIMARY KEY (APP_SID, APPROVAL_STEP_ID, ROLE_SID)
using index tablespace indx
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK310', 'PK_APPROVAL_STEP_SHEET')
order by table_name, constraint_name;
 
x APPROVAL_STEP_SHEET_LOG        REFAPPROVAL_STEP_SHEET547
*/ 

alter table  APPROVAL_STEP_SHEET add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_SHEET set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP.APPROVAL_STEP_ID = APPROVAL_STEP_SHEET.APPROVAL_STEP_ID);
alter table  APPROVAL_STEP_SHEET modify app_sid not null;
alter table  APPROVAL_STEP_SHEET drop primary key cascade drop index;
alter table  APPROVAL_STEP_SHEET add
CONSTRAINT PK_APPROVAL_STEP_SHEET PRIMARY KEY (APP_SID, APPROVAL_STEP_ID, SHEET_KEY)
using index tablespace indx
 ;
 
--alter table  APPROVAL_STEP_SHEET_LOG add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
--update APPROVAL_STEP_SHEET_LOG set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP.APPROVAL_STEP_ID = APPROVAL_STEP_SHEET_LOG.APPROVAL_STEP_ID);
--alter table  APPROVAL_STEP_SHEET_LOG modify app_sid not null;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK220_1', 'PK_APPROVAL_STEP_TEMPLATE')
order by table_name, constraint_name;
 
x APPROVAL_STEP                  REFAPPROVAL_STEP_TEMPLATE459
x APPROVAL_STEP_TEMPLATE         REFAPPROVAL_STEP_TEMPLATE467
x APPROVAL_STEP_USER_TEMPLATE    REFAPPROVAL_STEP_TEMPLATE469
*/
alter table  APPROVAL_STEP_TEMPLATE drop primary key cascade drop index;
alter table  APPROVAL_STEP_TEMPLATE add
    CONSTRAINT PK_APPROVAL_STEP_TEMPLATE PRIMARY KEY (APP_SID, APPROVAL_STEP_ID)
using index tablespace indx
 ;

 
alter table  APPROVAL_STEP_USER add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_USER set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP.APPROVAL_STEP_ID = APPROVAL_STEP_USER.APPROVAL_STEP_ID);
alter table  APPROVAL_STEP_USER modify app_sid not null;
alter table  APPROVAL_STEP_USER drop primary key drop index;
alter table  APPROVAL_STEP_USER add
    CONSTRAINT PK_APPROVAL_STEP_USER PRIMARY KEY (APP_SID, APPROVAL_STEP_ID, USER_SID)
using index tablespace indx
 ;
 
 
alter table  APPROVAL_STEP_USER_TEMPLATE add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update APPROVAL_STEP_USER_TEMPLATE set app_sid = (select app_sid from APPROVAL_STEP where APPROVAL_STEP.APPROVAL_STEP_ID = APPROVAL_STEP_USER_TEMPLATE.APPROVAL_STEP_ID);
alter table  APPROVAL_STEP_USER_TEMPLATE modify app_sid not null;
alter table  APPROVAL_STEP_USER_TEMPLATE drop primary key drop index;
alter table  APPROVAL_STEP_USER_TEMPLATE add
    CONSTRAINT PK_APPROVAL_STEP_USER_TPL PRIMARY KEY (APP_SID, APPROVAL_STEP_ID, USER_SID)
using index tablespace indx
 ;
 
alter table default_rss_feed rename constraint pk445 to pk_default_rss_feed;
alter index pk445 rename to pk_default_rss_feed ;
alter index pk_default_rss_feed rebuild tablespace indx;
 
 
alter table  ISSUE_PENDING_VAL  add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update ISSUE_PENDING_VAL set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = ISSUE_PENDING_VAL.pending_ind_id);
alter table ISSUE_PENDING_VAL modify app_sid not null;
alter table ISSUE_PENDING_VAL drop primary key drop index;
alter table ISSUE_PENDING_VAL add
    CONSTRAINT PK_ISSUE_PENDING_VAL PRIMARY KEY (PENDING_REGION_ID, PENDING_IND_ID, PENDING_PERIOD_ID, APP_SID)
using index tablespace indx
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK4_1', 'PK_PENDING_DATASET')
order by table_name, constraint_name;

x APPROVAL_STEP                  REFPENDING_DATASET497
x PENDING_IND                    REFPENDING_DATASET476
x PENDING_PERIOD                 REFPENDING_DATASET479
x PENDING_REGION                 REFPENDING_DATASET481
x PVC_REGION_RECALC_JOB          REFPENDING_DATASET722
x PVC_STORED_CALC_JOB            REFPENDING_DATASET721
*/
alter table pending_dataset modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table pending_dataset drop primary  key cascade drop index;
alter table pending_dataset add 
    CONSTRAINT PK_PENDING_DATASET PRIMARY KEY (APP_SID, PENDING_DATASET_ID)
using index tablespace indx
 ;
 

alter table PENDING_IND_RULE  add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PENDING_IND_RULE set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = pending_ind_rule.pending_ind_id);
alter table PENDING_IND_RULE modify app_sid not null;
alter table PENDING_IND_RULE drop primary key drop index;
alter table PENDING_IND_RULE add
    CONSTRAINT PK_PENDING_IND_RULE PRIMARY KEY (APP_SID, PENDING_IND_ID, VALIDATION_RULE_ID)
using index tablespace indx
 ;
 

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_PENDING_VAL')
order by table_name, constraint_name;
x PENDING_VAL_ACCURACY_TYPE_OPT  REFPENDING_VAL512
x PENDING_VAL_FILE_UPLOAD        REFPENDING_VAL515
x PENDING_VAL_LOG                REFPENDING_VAL488
x PENDING_VAL_VARIANCE           REFPENDING_VAL516
*/

update pending_val set app_sid = (select app_sid from pending_ind where pending_val.pending_ind_id = pending_ind.pending_ind_id) where app_sid is null;
alter table pending_val modify app_Sid not null;
alter TABLE PENDING_VAL drop primary key cascade drop index;
alter table PENDING_VAL add
    CONSTRAINT PK_PENDING_VAL PRIMARY KEY (APP_SID, PENDING_VAL_ID)
using index tablespace indx
 ;
 

alter table  PENDING_VAL_ACCURACY_TYPE_OPT add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PENDING_VAL_ACCURACY_TYPE_OPT set app_sid = (select app_sid from pending_val where PENDING_VAL_ACCURACY_TYPE_OPT.pending_val_id = pending_val.pending_val_id);
alter table PENDING_VAL_ACCURACY_TYPE_OPT modify app_sid not null;
alter table PENDING_VAL_ACCURACY_TYPE_OPT drop primary key drop index;
alter table PENDING_VAL_ACCURACY_TYPE_OPT add
    CONSTRAINT PK_PENDING_VAL_ACC_TYPE_OPT PRIMARY KEY (APP_SID, PENDING_VAL_ID, ACCURACY_TYPE_OPTION_ID)
using index tablespace indx
 ;
 
alter table PENDING_VAL_CACHE add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PENDING_VAL_CACHE set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = pending_val_cache.pending_ind_id);
alter table PENDING_VAL_CACHE modify app_sid not null;
alter table PENDING_VAL_CACHE drop primary key drop index;
alter table PENDING_VAL_CACHE add
    CONSTRAINT PK_PENDING_VAL_CACHE PRIMARY KEY (APP_SID, PENDING_IND_ID, PENDING_REGION_ID, PENDING_PERIOD_ID)
using index tablespace indx
 ;


alter table  PENDING_VAL_LOG drop primary key drop index;
alter table  PENDING_VAL_LOG add 
    CONSTRAINT PK_PENDING_VAL_LOG PRIMARY KEY (APP_SID, PENDING_VAL_LOG_ID)
using index tablespace indx
 ;

alter table  PENDING_VAL_VARIANCE  add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PENDING_VAL_VARIANCE set app_sid = (select app_sid from pending_val where pending_val.pending_val_id = PENDING_VAL_VARIANCE.pending_val_id);
alter table PENDING_VAL_VARIANCE modify app_sid not null;
alter table PENDING_VAL_VARIANCE drop primary key drop index;
alter table PENDING_VAL_VARIANCE add
    CONSTRAINT PK_PENDING_VAL_VARIANCE PRIMARY KEY (APP_SID, PENDING_VAL_ID)
using index tablespace indx
 ;
 
 
 
alter TABLE PVC_REGION_RECALC_JOB add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PVC_REGION_RECALC_JOB set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = PVC_REGION_RECALC_JOB.pending_ind_id);
alter table PVC_REGION_RECALC_JOB modify app_sid not null;
alter table PVC_REGION_RECALC_JOB drop primary key drop index;
alter table PVC_REGION_RECALC_JOB add 
    CONSTRAINT PK_PVC_REGION_RECALC_JOB PRIMARY KEY (APP_SID, PENDING_IND_ID, PENDING_DATASET_ID, PROCESSING)
using index tablespace indx
 ;
 
 
alter TABLE PVC_STORED_CALC_JOB add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PVC_STORED_CALC_JOB set app_sid = (select app_sid from PENDING_REGION where PENDING_REGION.PENDING_REGION_ID = PVC_STORED_CALC_JOB.PENDING_REGION_ID);
alter table PVC_STORED_CALC_JOB modify app_sid not null;
alter table PVC_STORED_CALC_JOB drop primary key drop index;
alter table PVC_STORED_CALC_JOB add 
	CONSTRAINT PK_PVC_STORED_CALC_JOB PRIMARY KEY (APP_SID, PENDING_DATASET_ID, CALC_PENDING_IND_ID, PENDING_REGION_ID, PENDING_PERIOD_ID, PROCESSING)
using index tablespace indx
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_ROLE')
order by table_name, constraint_name;
x APPROVAL_STEP_ROLE             REFROLE894
x REGION_ROLE_MEMBER             REFROLE764
*/

--alter table role add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
--update role set app_sid = (select app_sid from region_role_member where region_role_member.role_sid = role.role_sid) where app_sid is null;
--update role set app_sid = (select app_sid from approval_step_role where approval_step_role.role_sid = role.role_sid) where app_sid is null;
--alter table role modify app_sid not null;
alter table role drop primary key cascade drop index;
alter table role add 
    CONSTRAINT PK_ROLE PRIMARY KEY (APP_SID, ROLE_SID)
using index tablespace indx
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_RSS_FEED')
order by table_name, constraint_name;

x RSS_FEED_ITEM                  REFRSS_FEED885
*/

alter table rss_feed modify app_sid  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table  rss_feed drop primary key cascade drop index;
alter table rss_feed add 
    CONSTRAINT PK_RSS_FEED PRIMARY KEY (APP_SID, RSS_FEED_SID)
using index tablespace indx
 ;

 
alter TABLE RSS_FEED_ITEM drop primary key drop index;
alter TABLE RSS_FEED_ITEM add
    CONSTRAINT PK_RSS_FEED_ITEM PRIMARY KEY (APP_SID, RSS_FEED_ITEM_ID)
using index tablespace indx
 ;

 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_TAB','PK410')
order by table_name, constraint_name;
 
x TAB_GROUP                      REFTAB891
x TAB_PORTLET                    REFTAB798
x TAB_USER                       REFTAB858
*/

alter table tab modify app_sid  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table tab drop primary key cascade drop index;
alter table tab add 
    CONSTRAINT PK_TAB PRIMARY KEY (APP_SID, TAB_ID)
using index tablespace indx ;

alter TABLE TAB_GROUP add APP_SID      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update tab_group set app_sid = (select app_sid from tab where tab.tab_id = tab_group.tab_id);
alter table tab_group modify app_sid not null;
alter table tab_group drop primary key drop index;
alter table tab_group add
    CONSTRAINT PK_TAB_GROUP PRIMARY KEY (APP_SID, TAB_ID, GROUP_SID)
using index tablespace indx
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_TAB_PORTLET','PK413')
order by table_name, constraint_name;
x TAB_PORTLET_RSS_FEED           REFTAB_PORTLET886
*/
alter table tab_portlet add APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update tab_portlet set app_sid = (select app_sid from tab where tab.tab_id = tab_portlet.tab_id);
alter table tab_portlet modify app_sid not null;
alter table tab_portlet drop primary key cascade drop index;
alter table tab_portlet add
    CONSTRAINT PK_TAB_PORTLET PRIMARY KEY (APP_SID, TAB_PORTLET_ID)
using index tablespace indx
 ;

 
alter TABLE TAB_PORTLET_RSS_FEED add APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP');
update TAB_PORTLET_RSS_FEED set app_sid = (select app_sid from tab_portlet where tab_portlet.tab_portlet_id = tab_portlet_rss_feed.tab_portlet_id);
alter table tab_portlet_rss_feed modify app_sid not null;
alter table tab_portlet_rss_feed drop primary key drop index;
alter table tab_portlet_rss_feed add
    CONSTRAINT PK_TAB_PORTLET_RSS_FEED PRIMARY KEY (APP_SID, TAB_PORTLET_ID, RSS_URL)
 using index tablespace  indx;
 

alter table tab_user drop primary key drop index;
alter table tab_user add 
    CONSTRAINT PK_TAB_USER PRIMARY KEY (APP_SID, TAB_ID, USER_SID)
using index tablespace indx
 ;
 
  
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK446', 'PK_RSS_CACHE')
order by table_name, constraint_name;
x DEFAULT_RSS_FEED               REFRSS_CACHE881
x TAB_PORTLET_RSS_FEED           REFRSS_CACHE887
*/

alter table RSS_CACHE drop primary key cascade drop index;
alter table RSS_CACHE add 
    CONSTRAINT PK_RSS_CACHE PRIMARY KEY (RSS_URL)
using index tablespace indx
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK1001','PK_TPL_REPORT')
order by table_name, constraint_name;
x TPL_REPORT_TAG                 REFTPL_REPORT1
*/ 
alter table tpl_report modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table tpl_report drop primary key cascade drop index;
alter table tpl_report add 
    CONSTRAINT PK_TPL_REPORT PRIMARY KEY (APP_SID, TPL_REPORT_SID)
using index tablespace indx
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK1004','PK_TPL_REPORT_TAG')
order by table_name, constraint_name;
x TPL_REPORT_TAG_DATAVIEW        REFTPL_REPORT_TAG2
x TPL_REPORT_TAG_IND             REFTPL_REPORT_TAG3
*/

alter table tpl_report_tag add APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update tpl_report_tag set app_sid = (select app_sid from tpl_report where tpl_report.tpl_report_sid = tpl_report_tag.tpl_report_sid);
alter table tpl_report_tag modify app_sid not null;
alter table tpl_report_tag drop primary key cascade drop index;
alter table tpl_report_tag add 
    CONSTRAINT PK_TPL_REPORT_TAG PRIMARY KEY (APP_SID, TPL_REPORT_SID, TAG)
using index tablespace indx
 ;

/* it's empty ! */
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK234','PK_VALIDATION_RULE')
order by table_name, constraint_name;
x PENDING_IND_RULE               REFVALIDATION_RULE477
*/
alter table VALIDATION_RULE add APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL;
alter table validation_rule drop primary key cascade drop index;
alter table validation_rule add
    CONSTRAINT PK_VALIDATION_RULE PRIMARY KEY (APP_SID, VALIDATION_RULE_ID)
using index tablespace indx
 ;

begin
	for r in (select index_name from user_indexes where index_name in (
		'AK_AT_ID_LABEL', 'IDX_APPROVAL_STEP_1', 'IX_PEND_IND_MAP_IND',
		'IX_PENDING_REGION_PARENT', 'K2_PENDING_VAL', 'IX_PEND_VAL_PEND_REG'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/

alter table ACCURACY_TYPE_OPTION add constraint  UK_AT_ID_LABEL unique (APP_SID, ACCURACY_TYPE_ID, LABEL)
using index tablespace indx
 ;
 
 
CREATE INDEX IDX_APPROVAL_STEP_DATASET ON APPROVAL_STEP(APP_SID, PENDING_DATASET_ID)
 tablespace indx;
 
 
CREATE INDEX IX_PEND_IND_MAP_IND ON PENDING_IND(APP_SID, MAPS_TO_IND_SID)
 TABLESPACE INDX
 ;

 
CREATE INDEX IDX_PENDING_REGION_PARENT ON PENDING_REGION(APP_SID, PARENT_REGION_ID)
TABLESPACE INDX
 ;


alter table pending_val add constraint  UK_PENDING_VAL_IRP unique(APP_SID, PENDING_IND_ID, PENDING_REGION_ID, PENDING_PERIOD_ID)
 using index tablespace indx;
 
 
CREATE INDEX IDX_PEND_VAL_PEND_REG ON PENDING_VAL(APP_SID, PENDING_REGION_ID)
TABLESPACE INDX;

CREATE INDEX IDX_PEND_VAL_PEND_IND ON PENDING_VAL(APP_SID, PENDING_IND_ID)
TABLESPACE INDX;

CREATE INDEX IDX_PEND_VAL_PEND_PERIOD ON PENDING_VAL(APP_SID, PENDING_PERIOD_ID);

CREATE INDEX IDX_PEND_VAL_MSR_CVT ON PENDING_VAL(APP_SID, FROM_MEASURE_CONVERSION_ID);

 
/*
ALTER TABLE ACCURACY_TYPE_OPTION ADD CONSTRAINT RefACCURACY_TYPE995 
     FOREIGN KEY (APP_SID, ACCURACY_TYPE_ID)
     REFERENCES ACCURACY_TYPE(APP_SID, ACCURACY_TYPE_ID)
 ;
*/ 
 
 
 ALTER TABLE APPROVAL_STEP ADD CONSTRAINT RefAPPROVAL_STEP_TEMPLATE459 
    FOREIGN KEY (APP_SID, BASED_ON_STEP_ID)
    REFERENCES APPROVAL_STEP_TEMPLATE(APP_SID, APPROVAL_STEP_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP ADD CONSTRAINT RefAPPROVAL_STEP460 
    FOREIGN KEY (APP_SID, PARENT_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP ADD CONSTRAINT RefAPPROVAL_STEP461 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP ADD CONSTRAINT RefPENDING_DATASET497 
    FOREIGN KEY (APP_SID, PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(APP_SID, PENDING_DATASET_ID)
 ;
 
 
 
 ALTER TABLE APPROVAL_STEP_IND ADD CONSTRAINT RefPENDING_IND463 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP_MILESTONE ADD CONSTRAINT RefAPPROVAL_STEP614 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
 ;
 
 
 ALTER TABLE APPROVAL_STEP_REGION ADD CONSTRAINT RefPENDING_REGION464 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP_REGION ADD CONSTRAINT RefPENDING_REGION465 
    FOREIGN KEY (APP_SID, ROLLS_UP_TO_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP_ROLE ADD CONSTRAINT RefROLE894 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES ROLE(APP_SID, ROLE_SID)
 ;
 
 ALTER TABLE APPROVAL_STEP_SHEET ADD CONSTRAINT RefPENDING_PERIOD553 
    FOREIGN KEY (APP_SID, PENDING_PERIOD_ID)
    REFERENCES PENDING_PERIOD(APP_SID, PENDING_PERIOD_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP_SHEET ADD CONSTRAINT RefPENDING_REGION554 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP_SHEET ADD CONSTRAINT RefPENDING_IND555 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE APPROVAL_STEP_SHEET_LOG ADD CONSTRAINT RefAPPROVAL_STEP_SHEET547 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID, SHEET_KEY)
    REFERENCES APPROVAL_STEP_SHEET(APP_SID, APPROVAL_STEP_ID, SHEET_KEY)
 ;
 
 ALTER TABLE APPROVAL_STEP_TEMPLATE ADD CONSTRAINT RefAPPROVAL_STEP_TEMPLATE467 
    FOREIGN KEY (APP_SID, PARENT_STEP_ID)
    REFERENCES APPROVAL_STEP_TEMPLATE(APP_SID, APPROVAL_STEP_ID)
 ;
 
 
 ALTER TABLE APPROVAL_STEP_TEMPLATE ADD CONSTRAINT RefPENDING_REGION499 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 
 
ALTER TABLE APPROVAL_STEP_USER ADD CONSTRAINT RefCSR_USER986 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

-- one bad value where fallback_user_sid=0
update approval_step_user set fallback_user_sid=null where fallback_user_sid = 0;
ALTER TABLE APPROVAL_STEP_USER ADD CONSTRAINT RefCSR_USER987 
    FOREIGN KEY (APP_SID, FALLBACK_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

 
ALTER TABLE APPROVAL_STEP_USER_TEMPLATE ADD CONSTRAINT RefCSR_USER988 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;
 
 
 ALTER TABLE DEFAULT_RSS_FEED ADD CONSTRAINT RefRSS_CACHE881 
    FOREIGN KEY (RSS_URL)
    REFERENCES RSS_CACHE(RSS_URL)
 ;
 
 
 
 ALTER TABLE ISSUE_PENDING_VAL ADD CONSTRAINT RefPENDING_REGION625 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 ALTER TABLE ISSUE_PENDING_VAL ADD CONSTRAINT RefPENDING_IND626 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE ISSUE_PENDING_VAL ADD CONSTRAINT RefPENDING_PERIOD627 
    FOREIGN KEY (APP_SID, PENDING_PERIOD_ID)
    REFERENCES PENDING_PERIOD(APP_SID, PENDING_PERIOD_ID)
 ;
 
 
/* 
 
ALTER TABLE OPTION_ITEM ADD CONSTRAINT RefOPTION_SET189 
    FOREIGN KEY (APP_SID, OPTION_SET_ID)
    REFERENCES OPTION_SET(APP_SID, OPTION_SET_ID)
;
*/
 
 ALTER TABLE PENDING_IND ADD CONSTRAINT RefPENDING_DATASET476 
    FOREIGN KEY (APP_SID, PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(APP_SID, PENDING_DATASET_ID)
 ;
 
 ALTER TABLE PENDING_IND ADD CONSTRAINT RefPENDING_IND502 
    FOREIGN KEY (APP_SID, PARENT_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE PENDING_IND ADD CONSTRAINT RefPENDING_IND526 
    FOREIGN KEY (APP_SID, LINK_TO_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE PENDING_IND_ACCURACY_TYPE ADD CONSTRAINT RefPENDING_IND511 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 
 ALTER TABLE PENDING_IND_RULE ADD CONSTRAINT RefVALIDATION_RULE477 
    FOREIGN KEY (APP_SID, VALIDATION_RULE_ID)
    REFERENCES VALIDATION_RULE(APP_SID, VALIDATION_RULE_ID)
 ;
 
 ALTER TABLE PENDING_IND_RULE ADD CONSTRAINT RefPENDING_IND478 
    FOREIGN KEY (APP_SID,PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID,PENDING_IND_ID)
 ;
 
 
 ALTER TABLE PENDING_PERIOD ADD CONSTRAINT RefPENDING_DATASET479 
    FOREIGN KEY (APP_SID, PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(APP_SID, PENDING_DATASET_ID)
 ;
 
 ALTER TABLE PENDING_REGION ADD CONSTRAINT RefPENDING_DATASET481 
    FOREIGN KEY (APP_SID, PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(APP_SID, PENDING_DATASET_ID)
 ;
 
 ALTER TABLE PENDING_REGION ADD CONSTRAINT RefPENDING_REGION503 
    FOREIGN KEY (APP_SID, PARENT_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 
 ALTER TABLE PENDING_VAL ADD CONSTRAINT RefPENDING_REGION482 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 ALTER TABLE PENDING_VAL ADD CONSTRAINT RefPENDING_IND483 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE PENDING_VAL ADD CONSTRAINT RefAPPROVAL_STEP484 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
 ;
 
 ALTER TABLE PENDING_VAL ADD CONSTRAINT RefPENDING_PERIOD485 
    FOREIGN KEY (APP_SID, PENDING_PERIOD_ID)
    REFERENCES PENDING_PERIOD(APP_SID, PENDING_PERIOD_ID)
 ;

/* 
 ALTER TABLE PENDING_VAL ADD CONSTRAINT RefMEASURE_CONVERSION518 
    FOREIGN KEY (APP_SID, FROM_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
*/

ALTER TABLE PENDING_VAL_ACCURACY_TYPE_OPT ADD CONSTRAINT RefACCURACY_TYPE_OPTION996 
    FOREIGN KEY (APP_SID, ACCURACY_TYPE_OPTION_ID)
    REFERENCES ACCURACY_TYPE_OPTION(APP_SID, ACCURACY_TYPE_OPTION_ID)
 ;
 
 
 ALTER TABLE PENDING_VAL_CACHE ADD CONSTRAINT RefPENDING_IND768 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE PENDING_VAL_CACHE ADD CONSTRAINT RefPENDING_REGION769 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 ALTER TABLE PENDING_VAL_CACHE ADD CONSTRAINT RefPENDING_PERIOD770 
    FOREIGN KEY (APP_SID, PENDING_PERIOD_ID)
    REFERENCES PENDING_PERIOD(APP_SID, PENDING_PERIOD_ID)
 ;
 
 
 ALTER TABLE PENDING_VAL_FILE_UPLOAD ADD CONSTRAINT RefPENDING_VAL515 
    FOREIGN KEY (APP_SID, PENDING_VAL_ID)
    REFERENCES PENDING_VAL(APP_SID, PENDING_VAL_ID)
 ;
 
 ALTER TABLE PENDING_VAL_LOG ADD CONSTRAINT RefPENDING_VAL488 
    FOREIGN KEY (APP_SID, PENDING_VAL_ID)
    REFERENCES PENDING_VAL(APP_SID, PENDING_VAL_ID)
 ;
 
 ALTER TABLE PVC_REGION_RECALC_JOB ADD CONSTRAINT RefPENDING_IND712 
    FOREIGN KEY (APP_SID, PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE PVC_REGION_RECALC_JOB ADD CONSTRAINT RefPENDING_DATASET722 
    FOREIGN KEY (APP_SID, PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(APP_SID, PENDING_DATASET_ID)
 ;
 
 ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_PERIOD724 
    FOREIGN KEY (APP_SID, PENDING_PERIOD_ID)
    REFERENCES PENDING_PERIOD(APP_SID, PENDING_PERIOD_ID)
 ;
 
 ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_IND726 
    FOREIGN KEY (APP_SID, CALC_PENDING_IND_ID)
    REFERENCES PENDING_IND(APP_SID, PENDING_IND_ID)
 ;
 
 ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_REGION727 
    FOREIGN KEY (APP_SID, PENDING_REGION_ID)
    REFERENCES PENDING_REGION(APP_SID, PENDING_REGION_ID)
 ;
 
 
 ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefROLE764 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES ROLE(APP_SID, ROLE_SID)
 ;
 
 
 ALTER TABLE RSS_FEED_ITEM ADD CONSTRAINT RefRSS_FEED885 
    FOREIGN KEY (APP_SID, RSS_FEED_SID)
    REFERENCES RSS_FEED(APP_SID, RSS_FEED_SID)
 ;
 
 
ALTER TABLE SHEET_VALUE_ACCURACY ADD CONSTRAINT RefACCURACY_TYPE_OPTION997 
    FOREIGN KEY (APP_SID, ACCURACY_TYPE_OPTION_ID)
    REFERENCES ACCURACY_TYPE_OPTION(APP_SID, ACCURACY_TYPE_OPTION_ID)
;
 
 
 ALTER TABLE TAB_PORTLET ADD CONSTRAINT RefTAB798 
    FOREIGN KEY (APP_SID, TAB_ID)
    REFERENCES TAB(APP_SID, TAB_ID)
 ;
 
 
 ALTER TABLE TAB_PORTLET_RSS_FEED ADD CONSTRAINT RefRSS_CACHE887 
    FOREIGN KEY (RSS_URL)
    REFERENCES RSS_CACHE(RSS_URL)
 ;
 
 
 ALTER TABLE TAB_USER ADD CONSTRAINT RefTAB858 
    FOREIGN KEY (APP_SID, TAB_ID)
    REFERENCES TAB(APP_SID, TAB_ID)
 ;
 
 
 ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD CONSTRAINT REFTPL_REPORT_TAG2 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID, TAG)
    REFERENCES TPL_REPORT_TAG(APP_SID, TPL_REPORT_SID, TAG) ON DELETE CASCADE
 ;
 
 ALTER TABLE TPL_REPORT_TAG_IND ADD CONSTRAINT REFTPL_REPORT_TAG3 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID, TAG)
    REFERENCES TPL_REPORT_TAG(APP_SID, TPL_REPORT_SID, TAG) ON DELETE CASCADE
 ;
 
ALTER TABLE VAL_ACCURACY ADD CONSTRAINT RefACCURACY_TYPE_OPTION998 
    FOREIGN KEY (APP_SID, ACCURACY_TYPE_OPTION_ID)
    REFERENCES ACCURACY_TYPE_OPTION(APP_SID, ACCURACY_TYPE_OPTION_ID)
;

ALTER TABLE VALIDATION_RULE ADD CONSTRAINT RefCUSTOMER994 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE APPROVAL_STEP_IND ADD CONSTRAINT RefAPPROVAL_STEP462 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
;

ALTER TABLE APPROVAL_STEP_REGION ADD CONSTRAINT RefAPPROVAL_STEP466 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
;

ALTER TABLE APPROVAL_STEP_ROLE ADD CONSTRAINT RefAPPROVAL_STEP895 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
;

ALTER TABLE APPROVAL_STEP_SHEET ADD CONSTRAINT RefAPPROVAL_STEP546 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
;

ALTER TABLE APPROVAL_STEP_USER ADD CONSTRAINT RefAPPROVAL_STEP468 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APP_SID, APPROVAL_STEP_ID)
;

ALTER TABLE APPROVAL_STEP_USER_TEMPLATE ADD CONSTRAINT RefAPPROVAL_STEP_TEMPLATE469 
    FOREIGN KEY (APP_SID, APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP_TEMPLATE(APP_SID, APPROVAL_STEP_ID)
;

ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_DATASET725 
    FOREIGN KEY (APP_SID, PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(APP_SID, PENDING_DATASET_ID)
;

ALTER TABLE PENDING_VAL_ACCURACY_TYPE_OPT ADD CONSTRAINT RefPENDING_VAL512 
    FOREIGN KEY (APP_SID, PENDING_VAL_ID)
    REFERENCES PENDING_VAL(APP_SID, PENDING_VAL_ID)
;

ALTER TABLE PENDING_VAL_VARIANCE ADD CONSTRAINT RefPENDING_VAL516 
    FOREIGN KEY (APP_SID, PENDING_VAL_ID)
    REFERENCES PENDING_VAL(APP_SID, PENDING_VAL_ID)
;

ALTER TABLE TAB_GROUP ADD CONSTRAINT RefTAB891 
    FOREIGN KEY (APP_SID, TAB_ID)
    REFERENCES TAB(APP_SID, TAB_ID)
;

ALTER TABLE TAB_PORTLET_RSS_FEED ADD CONSTRAINT RefTAB_PORTLET886 
    FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
    REFERENCES TAB_PORTLET(APP_SID, TAB_PORTLET_ID)
;

ALTER TABLE TPL_REPORT_TAG ADD CONSTRAINT REFTPL_REPORT1 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID)
    REFERENCES TPL_REPORT(APP_SID, TPL_REPORT_SID) ON DELETE CASCADE
;

@update_tail
