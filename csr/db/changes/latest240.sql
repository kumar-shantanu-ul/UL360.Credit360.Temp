-- Please update version.sql too -- this keeps clean builds in sync
define version=240
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
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK162', 'PK_ACCURACY_TYPE')
order by table_name, constraint_name;

x PENDING_IND_ACCURACY_TYPE      REFACCURACY_TYPE510
*/

alter table ACCURACY_TYPE drop primary key cascade drop index;
alter table ACCURACY_TYPE add
    CONSTRAINT PK_ACCURACY_TYPE PRIMARY KEY (APP_SID, ACCURACY_TYPE_ID)
 ;

alter table ACCURACY_TYPE_OPTION add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update ACCURACY_TYPE_OPTION set app_sid = (select app_sid from ACCURACY_TYPE where ACCURACY_TYPE.accuracy_type_id = ACCURACY_TYPE_OPTION.ACCURACY_TYPE_ID);
--XXX: orphans? 38 of 'em
delete from accuracy_type_option where app_sid is null;
alter table ACCURACY_TYPE_OPTION modify app_sid not null;

/* all constraints referencing 
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_DATAVIEW')
order by table_name, constraint_name;

x ATTACHMENT                     REFDATAVIEW824
x DASHBOARD_ITEM                 REFDATAVIEW60
x DATAVIEW_ZONE                  REFDATAVIEW367
x INSTANCE_DATAVIEW              REFDATAVIEW237
x TPL_REPORT_TAG_DATAVIEW        REFDATAVIEW907
*/
alter table DATAVIEW add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update dataview set app_sid = (select application_sid_id from security.securable_object so where so.sid_id=dataview.dataview_sid);
-- 76 of these that belong to deleted applications (sids not in securable_object)
delete from dataview where app_sid is null;	
alter table dataview modify app_sid not null;
alter table dataview drop primary key cascade drop index;
alter table dataview add
    CONSTRAINT PK_DATAVIEW PRIMARY KEY (APP_SID, DATAVIEW_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 
alter table  DATAVIEW_ZONE drop primary key drop index;
alter table  DATAVIEW_ZONE add 
    CONSTRAINT PK_DATAVIEW_ZONE PRIMARY KEY (APP_SID, DATAVIEW_ZONE_ID)
     USING INDEX
 TABLESPACE INDX
 ;
 
 
alter table ERROR_LOG drop primary key drop index;
alter table ERROR_LOG add
    CONSTRAINT PK_ERROR_LOG PRIMARY KEY (APP_SID, ERROR_LOG_ID)
     USING INDEX
 TABLESPACE INDX
 ;

 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_FEED', 'PK175')
order by table_name, constraint_name;
x FEED_REQUEST                   REFFEED286
*/

alter table feed drop primary key cascade drop index;
alter table feed add 
    CONSTRAINT PK_FEED PRIMARY KEY (APP_SID, FEED_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 

alter TABLE FEED_REQUEST drop primary key drop index;
alter table feed_request modify app_sid not null;
alter table FEED_REQUEST add
    CONSTRAINT PK_FEED_REQUEST PRIMARY KEY (APP_SID, FEED_REQUEST_ID)
     USING INDEX
 TABLESPACE INDX
 ;
 

alter table INSTANCE_DATAVIEW add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update instance_dataview set app_sid = (select app_sid from dataview where dataview.dataview_sid = INSTANCE_DATAVIEW.dataview_sid);
alter table INSTANCE_DATAVIEW modify app_sid not null;
alter TABLE INSTANCE_DATAVIEW drop primary key drop index;
alter TABLE INSTANCE_DATAVIEW add
    CONSTRAINT PK_INSTANCE_DATAVIEW PRIMARY KEY (INSTANCE_ID, CONTEXT, DATAVIEW_SID, APP_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_MEASURE')
order by table_name, constraint_name;

x FACTOR_SET                     FK_FACTOR_SET_MEASURE
x IND                            REFMEASURE3
x MEASURE_CONVERSION             REFMEASURE4
x PCT_OWNERSHIP_CHANGE           REFMEASURE571
x PENDING_IND                    REFMEASURE475
*/

alter table measure drop primary key cascade drop index;
alter table measure add
    CONSTRAINT PK_MEASURE PRIMARY KEY (APP_SID, MEASURE_SID)
     USING INDEX
 TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_MEASURE_CONVERSION')
order by table_name, constraint_name;
 
x ALL_METER                      REFMEASURE_CONVERSION780
x MEASURE_CONVERSION_PERIOD      REFMEASURE_CONVERSION164
x PENDING_VAL                    REFMEASURE_CONVERSION518
x RANGE_IND_MEMBER               SYS_C00232121
x SHEET_VALUE                    REFMEASURE_CONVERSION113
x SHEET_VALUE_CHANGE             REFMEASURE_CONVERSION145
x VAL                            REFMEASURE_CONVERSION5
*/
 
alter table MEASURE_CONVERSION add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update MEASURE_CONVERSION set app_sid = (select app_sid from measure where measure.measure_sid = MEASURE_CONVERSION.measure_sid);
alter table MEASURE_CONVERSION modify app_sid not null;
alter TABLE MEASURE_CONVERSION drop primary key cascade drop index;
alter table MEASURE_CONVERSION add
    CONSTRAINT PK_MEASURE_CONVERSION PRIMARY KEY (APP_SID, MEASURE_CONVERSION_ID)
     USING INDEX
 TABLESPACE INDX
 ;
 
alter table MEASURE_CONVERSION_PERIOD add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update MEASURE_CONVERSION_PERIOD set app_sid = (select app_sid from MEASURE_CONVERSION where MEASURE_CONVERSION.measure_conversion_id = MEASURE_CONVERSION_PERIOD.MEASURE_CONVERSION_id);
alter table MEASURE_CONVERSION_PERIOD modify app_sid not null;
alter table MEASURE_CONVERSION_PERIOD drop primary key drop index;
alter table MEASURE_CONVERSION_PERIOD add
    CONSTRAINT PK_MEASURE_CONVERSION_PERIOD PRIMARY KEY (APP_SID, MEASURE_CONVERSION_ID, START_DTM)
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_OPTION_SET','PK108')
order by table_name, constraint_name;

x MEASURE                        REFOPTION_SET182
x OPTION_ITEM                    REFOPTION_SET183
*/
alter table option_set add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update option_set set app_sid = (select app_sid from measure where measure.option_set_id = option_set.option_set_id);
alter table option_set modify app_sid not null;
alter table option_set drop primary key cascade drop index;
alter table option_set add 
    CONSTRAINT PK_OPTION_SET PRIMARY KEY (APP_SID, OPTION_SET_ID)
using index tablespace indx
 ;
 
 
alter table OPTION_ITEM add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update OPTION_ITEM set app_sid = (select app_sid from option_set where option_set.option_set_id = option_item.option_set_id);
alter table option_item modify app_sid not null;
alter table option_item drop primary key drop index;
alter table option_item add
    CONSTRAINT PK_OPTION_ITEM PRIMARY KEY (APP_SID, OPTION_SET_ID, POS)
using index tablespace indx
 ;
 
 
alter table PENDING_IND_ACCURACY_TYPE add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update PENDING_IND_ACCURACY_TYPE set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = PENDING_IND_ACCURACY_TYPE.pending_ind_id);
alter table PENDING_IND_ACCURACY_TYPE modify app_sid not null;
alter  table PENDING_IND_ACCURACY_TYPE drop primary key drop index;
alter table PENDING_IND_ACCURACY_TYPE add
    CONSTRAINT PK_PENDING_IND_ACCURACY_TYPE PRIMARY KEY (APP_SID, PENDING_IND_ID, ACCURACY_TYPE_ID)
using index tablespace indx 
 ;
 
alter table pending_Val add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update pending_val set app_sid = (select app_sid from pending_ind where pending_ind.pending_ind_id = pending_val.pending_ind_id);
alter table pending_val rename constraint pk214 to pk_pending_val;
 
alter table region_tree drop primary key drop index;
alter table region_tree add 
    CONSTRAINT PK_REGION_TREE PRIMARY KEY (APP_SID, REGION_TREE_ROOT_SID)
using index tablespace indx
 ;
 

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_REPORTING_PERIOD','PK223')
order by table_name, constraint_name;

x CUSTOMER                       REFREPORTING_PERIOD658
x PENDING_DATASET                REFREPORTING_PERIOD473
*/
alter table reporting_period drop primary key cascade drop index;
alter table reporting_period add 
    CONSTRAINT PK_REPORTING_PERIOD PRIMARY KEY (APP_SID, REPORTING_PERIOD_SID)
using index tablespace indx ;
 
 
alter table template drop primary key drop index;
alter table template add 
    CONSTRAINT pk_template PRIMARY KEY (APP_SID, TEMPLATE_TYPE_ID)
using index tablespace indx
 ;
 
alter table TPL_REPORT_TAG_DATAVIEW add app_sid number(10) DEFAULT SYS_CONTEXT('SECURITY','APP');
update TPL_REPORT_TAG_DATAVIEW set app_sid = (select app_sid from dataview where dataview.dataview_sid = TPL_REPORT_TAG_DATAVIEW.dataview_sid);
alter table TPL_REPORT_TAG_DATAVIEW modify app_sid not null;
alter table tpl_report_tag_dataview drop primary key drop index;
alter table TPL_REPORT_TAG_DATAVIEW add
    CONSTRAINT PK_TPL_REPORT_TAG_DATAVIEW PRIMARY KEY (APP_SID, TPL_REPORT_SID, TAG, DATAVIEW_SID)
using index tablespace indx
 ;
 

begin
	for r in (select index_name from user_indexes where index_name in (
		'REF294'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/

CREATE INDEX IDX_MEASURE_CONV_MEASURE ON MEASURE_CONVERSION(APP_SID, MEASURE_SID)
 TABLESPACE INDX
 ;
 
 ALTER TABLE ACCURACY_TYPE_OPTION ADD CONSTRAINT RefACCURACY_TYPE435 
    FOREIGN KEY (APP_SID, ACCURACY_TYPE_ID)
    REFERENCES ACCURACY_TYPE(APP_SID, ACCURACY_TYPE_ID)
 ;
 
 
 ALTER TABLE ALL_METER ADD CONSTRAINT RefMEASURE_CONVERSION849 
    FOREIGN KEY (APP_SID, PRIMARY_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
 
 ALTER TABLE ATTACHMENT ADD CONSTRAINT RefDATAVIEW824 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES DATAVIEW(APP_SID, DATAVIEW_SID)
 ;
 
 
 ALTER TABLE CUSTOMER ADD CONSTRAINT RefREPORTING_PERIOD658 
    FOREIGN KEY (APP_SID, CURRENT_REPORTING_PERIOD_SID)
    REFERENCES REPORTING_PERIOD(APP_SID, REPORTING_PERIOD_SID)
 ;
 
 ALTER TABLE DASHBOARD_ITEM ADD CONSTRAINT RefDATAVIEW60 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES DATAVIEW(APP_SID, DATAVIEW_SID)
;

select app_sid from dataview minus select app_sid from customer;
-- uh, dataviews belonging to botb?
delete from dataview where app_sid not in (select app_sid from customer);

ALTER TABLE DATAVIEW ADD CONSTRAINT RefCUSTOMER970 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
 ;
 
 
 ALTER TABLE DATAVIEW_ZONE ADD CONSTRAINT RefDATAVIEW367 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES DATAVIEW(APP_SID, DATAVIEW_SID)
 ;
 
 
 ALTER TABLE FACTOR_SET ADD CONSTRAINT FK_FACTOR_SET_MEASURE 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES MEASURE(APP_SID, MEASURE_SID)
 ;
 
 
 ALTER TABLE FEED_REQUEST ADD CONSTRAINT RefFEED286 
    FOREIGN KEY (APP_SID, FEED_SID)
    REFERENCES FEED(APP_SID, FEED_SID)
 ;
 
--pronino + tf mixed up again
/*
select i.ind_sid,i.app_sid,i.measure_sid,m.app_sid from ind i, measure m
where i.measure_sid = m.measure_sid and i.app_sid <> m.app_sid and i.measure_sid is not null;
inds are in tf, so set measure to local pct...
*/
update ind set measure_sid = 2267397 where app_sid = 2245515
and ind_sid in (9019717 , 9019721   );
 ALTER TABLE IND ADD CONSTRAINT RefMEASURE3 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES MEASURE(APP_SID, MEASURE_SID)
 ;

 ALTER TABLE IND_ACCURACY_TYPE ADD CONSTRAINT RefACCURACY_TYPE436 
    FOREIGN KEY (APP_SID, ACCURACY_TYPE_ID)
    REFERENCES ACCURACY_TYPE(APP_SID, ACCURACY_TYPE_ID)
 ;
 
 ALTER TABLE INSTANCE_DATAVIEW ADD CONSTRAINT RefDATAVIEW237 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES DATAVIEW(APP_SID, DATAVIEW_SID)
 ;
 
 ALTER TABLE MEASURE ADD CONSTRAINT RefOPTION_SET182 
    FOREIGN KEY (APP_SID, OPTION_SET_ID)
    REFERENCES OPTION_SET(APP_SID, OPTION_SET_ID)
;

ALTER TABLE MEASURE ADD CONSTRAINT RefCUSTOMER971 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
 ;
 
 ALTER TABLE MEASURE_CONVERSION ADD CONSTRAINT RefMEASURE4 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES MEASURE(APP_SID, MEASURE_SID)
 ;
 
 ALTER TABLE MEASURE_CONVERSION_PERIOD ADD CONSTRAINT RefMEASURE_CONVERSION164 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
 
 
ALTER TABLE OPTION_ITEM ADD CONSTRAINT RefCUSTOMER979 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;
ALTER TABLE OPTION_ITEM ADD CONSTRAINT RefOPTION_SET189 
    FOREIGN KEY (APP_SID, OPTION_SET_ID)
    REFERENCES OPTION_SET(APP_SID, OPTION_SET_ID)
;

  
 ALTER TABLE PCT_OWNERSHIP_CHANGE ADD CONSTRAINT RefMEASURE571 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES MEASURE(APP_SID, MEASURE_SID)
 ;
 
 ALTER TABLE PENDING_DATASET ADD CONSTRAINT RefREPORTING_PERIOD473 
    FOREIGN KEY (APP_SID, REPORTING_PERIOD_SID)
    REFERENCES REPORTING_PERIOD(APP_SID, REPORTING_PERIOD_SID)
 ;
 
 ALTER TABLE PENDING_IND ADD CONSTRAINT RefMEASURE475 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES MEASURE(APP_SID, MEASURE_SID)
 ;

 ALTER TABLE PENDING_IND_ACCURACY_TYPE ADD CONSTRAINT RefACCURACY_TYPE510 
    FOREIGN KEY (APP_SID, ACCURACY_TYPE_ID)
    REFERENCES ACCURACY_TYPE(APP_SID, ACCURACY_TYPE_ID)
 ;
 
 ALTER TABLE PENDING_VAL ADD CONSTRAINT RefMEASURE_CONVERSION518 
    FOREIGN KEY (APP_SID, FROM_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
 
 ALTER TABLE RANGE_IND_MEMBER ADD CONSTRAINT RefMEASURE_CONVERSION581 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
 
 ALTER TABLE SHEET_VALUE ADD CONSTRAINT RefMEASURE_CONVERSION113 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
 
 ALTER TABLE SHEET_VALUE_CHANGE ADD CONSTRAINT RefMEASURE_CONVERSION145 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;

 
 ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD CONSTRAINT RefDATAVIEW907 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES DATAVIEW(APP_SID, DATAVIEW_SID)
 ;
 
 ALTER TABLE VAL ADD CONSTRAINT RefMEASURE_CONVERSION5 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;
 

/*
select count(*) from val_change where entry_measure_conversion_id not in (
select measure_conversion_id from measure_conversion) and entry_measure_conversion_id is not null;
only 1 !
*/
delete from val_change where entry_measure_conversion_id not in (
select measure_conversion_id from measure_conversion) and entry_measure_conversion_id is not null;

 ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefMEASURE_CONVERSION66 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
 ;

@update_tail
