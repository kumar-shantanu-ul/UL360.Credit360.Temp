-- Please update version.sql too -- this keeps clean builds in sync
define version=163
@update_header

-- select  'alter table '||table_name||' add app_sid number(10);'||chr(10)||'update '||table_name||' set app_sid = (select app_sid from customer where customer.csr_root_sid = '||table_name||'.csr_root_sid);'||chr(10)||'alter table '||table_name||' drop constraint '||constraint_name||';'||chr(10)||'alter table '||table_name||' add constraint '||constraint_name||' foreign key (app_sid) references customer(app_sid);'||chr(10)||'alter table '||table_name||' drop column csr_root_sid;'||chr(10) from user_constraints where r_constraint_name='PK125';

-- drop some old tables that maybe people have locally that have RI on them
begin
	for r in (select table_name from user_tables where table_name in ('REASON','CUSTOMER_DOC_TAG')) loop
		execute immediate 'drop table '||r.table_name;
	end loop;
end;
/

alter table ISSUE_LOG_ALERT_BATCH add app_sid number(10);
update ISSUE_LOG_ALERT_BATCH set app_sid = (select app_sid from customer where customer.csr_root_sid = ISSUE_LOG_ALERT_BATCH.csr_root_sid);
alter table ISSUE_LOG_ALERT_BATCH modify app_sid not null;
alter table ISSUE_LOG_ALERT_BATCH drop constraint REFCUSTOMER78;
alter table ISSUE_LOG_ALERT_BATCH add constraint REFCUSTOMER78 foreign key (app_sid) references customer(app_sid);
alter table ISSUE_LOG_ALERT_BATCH drop column csr_root_sid;

alter table ISSUE_LOG_ALERT_BATCH_RUN add app_sid number(10);
update ISSUE_LOG_ALERT_BATCH_RUN set app_sid = (select app_sid from customer where customer.csr_root_sid = ISSUE_LOG_ALERT_BATCH_RUN.csr_root_sid);
alter table ISSUE_LOG_ALERT_BATCH_RUN modify app_sid not null;
alter table ISSUE_LOG_ALERT_BATCH_RUN drop constraint REFCUSTOMER80;
alter table ISSUE_LOG_ALERT_BATCH_RUN add constraint REFCUSTOMER80 foreign key (app_sid) references customer(app_sid);
alter table ISSUE_LOG_ALERT_BATCH_RUN drop column csr_root_sid;

alter table PENDING_DATASET add app_sid number(10);
update PENDING_DATASET set app_sid = (select app_sid from customer where customer.csr_root_sid = PENDING_DATASET.csr_root_sid);
alter table PENDING_DATASET modify app_sid not null;
alter table PENDING_DATASET drop constraint REFCUSTOMER501;
alter table PENDING_DATASET add constraint REFCUSTOMER501 foreign key (app_sid) references customer(app_sid);
alter table PENDING_DATASET drop column csr_root_sid;

alter table APPROVAL_STEP_TEMPLATE add app_sid number(10);
update APPROVAL_STEP_TEMPLATE set app_sid = (select app_sid from customer where customer.csr_root_sid = APPROVAL_STEP_TEMPLATE.csr_root_sid);
alter table APPROVAL_STEP_TEMPLATE modify app_sid not null;
alter table APPROVAL_STEP_TEMPLATE drop constraint REFCUSTOMER498;
alter table APPROVAL_STEP_TEMPLATE add constraint REFCUSTOMER498 foreign key (app_sid) references customer(app_sid);
alter table APPROVAL_STEP_TEMPLATE drop column csr_root_sid;

alter table AUTOCREATE_USER add app_sid number(10);
update AUTOCREATE_USER set app_sid = (select app_sid from customer where customer.csr_root_sid = AUTOCREATE_USER.csr_root_sid);
alter table AUTOCREATE_USER modify app_sid not null;
alter table AUTOCREATE_USER drop constraint REFCUSTOMER646;
alter table AUTOCREATE_USER add constraint REFCUSTOMER646 foreign key (app_sid) references customer(app_sid);
alter table AUTOCREATE_USER drop constraint PK357;
begin
	for r in (select index_name from user_indexes where index_name='PK357') loop
		execute immediate 'drop index PK357';
	end loop;
end;
/
alter table AUTOCREATE_USER add constraint PK357 primary key (user_name, app_sid) using index tablespace indx;
alter table AUTOCREATE_USER drop column csr_root_sid;


alter table CUSTOMER_ALERT_TYPE add app_sid number(10);
update CUSTOMER_ALERT_TYPE set app_sid = (select app_sid from customer where customer.csr_root_sid = CUSTOMER_ALERT_TYPE.csr_root_sid);
alter table CUSTOMER_ALERT_TYPE modify app_sid not null;
alter table CUSTOMER_ALERT_TYPE drop constraint REFCUSTOMER648;
alter table CUSTOMER_ALERT_TYPE add constraint REFCUSTOMER648 foreign key (app_sid) references customer(app_sid);

alter table ALERT_TEMPLATE add app_sid number(10);
update ALERT_TEMPLATE set app_sid = (select app_sid from customer where customer.csr_root_sid = ALERT_TEMPLATE.csr_root_sid);
alter table ALERT_TEMPLATE modify app_sid not null;
alter table ALERT_TEMPLATE drop constraint REFCUSTOMER_ALERT_TYPE645;
alter table CUSTOMER_ALERT_TYPE drop constraint PK356;
begin
	for r in (select index_name from user_indexes where index_name='PK356') loop
		execute immediate 'drop index PK356';
	end loop;
end;
/
alter table CUSTOMER_ALERT_TYPE add constraint PK356 primary key (app_sid, alert_type_id) using index tablespace indx;
alter table CUSTOMER_ALERT_TYPE drop column csr_root_sid;
alter table ALERT_TEMPLATE add constraint REFCUSTOMER_ALERT_TYPE645 foreign key (app_sid, alert_type_id) references customer_alert_type(app_sid, alert_type_id);
alter table alert_template drop constraint pk102;
begin
	for r in (select index_name from user_indexes where index_name='PK102') loop
		execute immediate 'drop index PK102';
	end loop;
end;
/
alter table alert_template add constraint pk102 primary key (alert_type_id, app_sid) using index tablespace indx;
alter table ALERT_TEMPLATE drop column csr_root_sid;

alter table CUSTOMER_HELP_LANG add app_sid number(10);
update CUSTOMER_HELP_LANG set app_sid = (select app_sid from customer where customer.csr_root_sid = CUSTOMER_HELP_LANG.csr_root_sid);
alter table CUSTOMER_HELP_LANG modify app_sid not null;
alter table CUSTOMER_HELP_LANG drop constraint REFCUSTOMER420;
alter table CUSTOMER_HELP_LANG add constraint REFCUSTOMER420 foreign key (app_sid) references customer(app_sid);
alter table customer_help_lang drop constraint pk5_2;
begin
	for r in (select index_name from user_indexes where index_name='PK5_2') loop
		execute immediate 'drop index PK5_2';
	end loop;
end;
/
alter table customer_help_lang add constraint pk5_2 primary key (app_sid, help_lang_id) using index tablespace indx;
alter table CUSTOMER_HELP_LANG drop column csr_root_sid;

begin
	for r in (select table_name from user_tables where table_name = 'DATA_SOURCE_TYPE') loop
		execute immediate 'alter table DATA_SOURCE_TYPE add app_sid number(10)';
		execute immediate 'update DATA_SOURCE_TYPE set app_sid = (select app_sid from customer where customer.csr_root_sid = DATA_SOURCE_TYPE.csr_root_sid)';
		execute immediate 'alter table DATA_SOURCE_TYPE modify app_sid not null';
		execute immediate 'alter table DATA_SOURCE_TYPE drop constraint REFCUSTOMER271';
		execute immediate 'alter table DATA_SOURCE_TYPE add constraint REFCUSTOMER271 foreign key (app_sid) references customer(app_sid)';
		execute immediate 'alter table DATA_SOURCE_TYPE drop column csr_root_sid';
	end loop;
end;
/

alter table DIARY_EVENT add app_sid number(10);
update DIARY_EVENT set app_sid = (select app_sid from customer where customer.csr_root_sid = DIARY_EVENT.csr_root_sid);
alter table DIARY_EVENT modify app_sid not null;
alter table DIARY_EVENT drop constraint REFCUSTOMER201;
alter table DIARY_EVENT add constraint REFCUSTOMER201 foreign key (app_sid) references customer(app_sid);
alter table DIARY_EVENT drop column csr_root_sid;

alter table DOC_LIBRARY add app_sid number(10);
update DOC_LIBRARY set app_sid = (select app_sid from customer where customer.csr_root_sid = DOC_LIBRARY.csr_root_sid);
alter table DOC_LIBRARY modify app_sid not null;
begin
	for r in (select distinct constraint_name
				from user_cons_columns
			   where table_name='DOC_LIBRARY' and column_name='CSR_ROOT_SID') loop
		execute immediate 'alter table DOC_LIBRARY drop constraint '||r.constraint_name;
	end loop;
end;
/
alter table DOC_LIBRARY add constraint RefCUSTOMER687 foreign key (app_sid) references customer(app_sid);
alter table DOC_LIBRARY drop column csr_root_sid;

alter table SECTION_MODULE add app_sid number(10);
update SECTION_MODULE set app_sid = (select app_sid from customer where customer.csr_root_sid = SECTION_MODULE.csr_root_sid);
alter table SECTION_MODULE modify app_sid not null;
alter table SECTION_MODULE drop constraint REFCUSTOMER840;
alter table SECTION_MODULE add constraint REFCUSTOMER840 foreign key (app_sid) references customer(app_sid);
alter table section add app_sid number(10);
update section set app_sid = (select app_sid from customer where customer.csr_root_sid = section.csr_root_sid);
alter table SECTION modify app_sid not null;
alter table section drop constraint REFSECTION_MODULE833;
alter table section_module drop constraint PK427;
begin
	for r in (select index_name from user_indexes where index_name='PK427') loop
		execute immediate 'drop index PK427';
	end loop;
end;
/
alter table section_module add constraint pk427 primary key (module_root_sid, app_sid) using index tablespace indx;
alter table section add constraint REFSECTION_MODULE833 foreign key (module_root_sid, app_sid) references section_module (module_root_sid, app_sid);
alter table section drop column csr_root_sid;
alter table SECTION_MODULE drop column csr_root_sid;

alter table REGION_TREE add app_sid number(10);
update REGION_TREE set app_sid = (select app_sid from customer where customer.csr_root_sid = REGION_TREE.csr_root_sid);
alter table REGION_TREE modify app_sid not null;
alter table REGION_TREE drop constraint REFCUSTOMER243;
alter table REGION_TREE add constraint REFCUSTOMER243 foreign key (app_sid) references customer(app_sid);
alter table REGION_TREE drop column csr_root_sid;

alter table ROLE add app_sid number(10);
update ROLE set app_sid = (select app_sid from customer where customer.csr_root_sid = ROLE.csr_root_sid);
alter table ROLE modify app_sid not null;
alter table ROLE drop constraint REFCUSTOMER766;
alter table ROLE add constraint REFCUSTOMER766 foreign key (app_sid) references customer(app_sid);
alter table ROLE drop column csr_root_sid;

alter table SURVEY add app_sid number(10);
update SURVEY set app_sid = (select app_sid from customer where customer.csr_root_sid = SURVEY.csr_root_sid);
alter table SURVEY modify app_sid not null;
alter table SURVEY drop constraint REFCUSTOMER251;
alter table SURVEY add constraint REFCUSTOMER251 foreign key (app_sid) references customer(app_sid);
alter table SURVEY drop column csr_root_sid;

alter table TAG_GROUP add app_sid number(10);
update TAG_GROUP set app_sid = (select app_sid from customer where customer.csr_root_sid = TAG_GROUP.csr_root_sid);
alter table TAG_GROUP modify app_sid not null;
alter table TAG_GROUP drop constraint REFCUSTOMER231;
alter table TAG_GROUP add constraint REFCUSTOMER231 foreign key (app_sid) references customer(app_sid);
alter table TAG_GROUP drop column csr_root_sid;

alter table TEMPLATE add app_sid number(10);
update TEMPLATE set app_sid = (select app_sid from customer where customer.csr_root_sid = TEMPLATE.csr_root_sid);
alter table TEMPLATE modify app_sid not null;
alter table TEMPLATE drop constraint REFCUSTOMER354;
alter table TEMPLATE add constraint REFCUSTOMER354 foreign key (app_sid) references customer(app_sid);
alter table TEMPLATE drop constraint pk206;
begin
	for r in (select index_name from user_indexes where index_name='PK206') loop
		execute immediate 'drop index PK206';
	end loop;
end;
/
alter table TEMPLATE add constraint pk206 primary key (template_type_id, app_sid) using index tablespace indx;
alter table TEMPLATE drop column csr_root_sid;

alter table ERROR_LOG add app_sid number(10);
update ERROR_LOG set app_sid = (select app_sid from customer where customer.csr_root_sid = ERROR_LOG.csr_root_sid);
alter table ERROR_LOG modify app_sid not null;
alter table ERROR_LOG drop constraint REFCUSTOMER319;
alter table ERROR_LOG add constraint REFCUSTOMER319 foreign key (app_sid) references customer(app_sid);
alter table ERROR_LOG drop column csr_root_sid;

alter table FEED add app_sid number(10);
update FEED set app_sid = (select app_sid from customer where customer.csr_root_sid = FEED.csr_root_sid);
alter table FEED modify app_sid not null;
alter table FEED drop constraint REFCUSTOMER284;
alter table FEED add constraint REFCUSTOMER284 foreign key (app_sid) references customer(app_sid);
alter table FEED drop column csr_root_sid;

alter table ALERT add app_sid number(10);
update ALERT set app_sid = (select app_sid from customer where customer.csr_root_sid = ALERT.csr_root_sid);
alter table ALERT modify app_sid not null;
alter table ALERT drop constraint REFCUSTOMER307;
alter table ALERT add constraint REFCUSTOMER307 foreign key (app_sid) references customer(app_sid);
alter table ALERT drop column csr_root_sid;

alter table CUSTOMER_PORTLET add app_sid number(10);
update CUSTOMER_PORTLET set app_sid = (select app_sid from customer where customer.csr_root_sid = CUSTOMER_PORTLET.csr_root_sid);
alter table CUSTOMER_PORTLET modify app_sid not null;
alter table CUSTOMER_PORTLET drop constraint REFCUSTOMER795;
alter table CUSTOMER_PORTLET add constraint REFCUSTOMER795 foreign key (app_sid) references customer(app_sid);
alter table CUSTOMER_PORTLET drop constraint pk412;
begin
	for r in (select index_name from user_indexes where index_name='PK412') loop
		execute immediate 'drop index PK412';
	end loop;
end;
/
alter table CUSTOMER_PORTLET add constraint pk412 primary key (portlet_id, app_sid) using index tablespace indx;
alter table CUSTOMER_PORTLET drop column csr_root_sid;

alter table TAB add app_sid number(10);
update TAB set app_sid = (select app_sid from customer where customer.csr_root_sid = TAB.csr_root_sid);
alter table TAB modify app_sid not null;
alter table TAB drop constraint REFCUSTOMER801;
alter table TAB add constraint REFCUSTOMER801 foreign key (app_sid) references customer(app_sid);
alter table TAB drop column csr_root_sid;

-- sanity:
-- select * from user_cons_columns ucc , user_constraints uc where ucc.column_name='CSR_ROOT_SID' and ucc.constraint_name = uc.constraint_name and uc.constraint_type='R';

-- NO CONSTRAINTS TABLES, fix?
-- select  'alter table '||table_name||' add app_sid number(10);'||chr(10)||'update '||table_name||' set app_sid = (select app_sid from customer where customer.csr_root_sid = '||table_name||'.csr_root_sid);'||chr(10)||'alter table '||table_name||' drop column csr_root_sid;'||chr(10) from user_tab_columns where column_name='CSR_ROOT_SID' and table_name <> 'CUSTOMER';
alter table FORM add app_sid number(10);
update FORM set app_sid = (select app_sid from customer where customer.csr_root_sid = FORM.csr_root_sid);
alter table FORM modify app_sid not null;
alter table FORM drop column csr_root_sid;

-- clean up duff data
delete from imp_conflict_val where imp_val_id in (select imp_val_id from imp_val where imp_ind_id in (select imp_ind_id from imp_ind where csr_root_sid not in (select csr_root_sid from customer)));
delete from imp_conflict_val where imp_val_id in (select imp_val_id from imp_val where imp_region_id in (select imp_region_id from imp_region where csr_root_sid not in (select csr_root_sid from customer)));
delete from imp_conflict_val where imp_val_id in (select imp_val_id from imp_val where imp_measure_id in (select imp_measure_id from imp_measure where csr_root_sid not in (select csr_root_sid from customer)));
delete from imp_val where imp_ind_id in (select imp_ind_id from imp_ind where csr_root_sid not in (select csr_root_sid from customer));
delete from imp_val where imp_region_id in (select imp_region_id from imp_region where csr_root_sid not in (select csr_root_sid from customer));
delete from imp_val where imp_measure_id in (select imp_measure_id from imp_measure where csr_root_sid not in (select csr_root_sid from customer));
delete from imp_measure where csr_root_sid not in (select csr_root_sid from customer);
delete from imp_ind where csr_root_sid not in (select csr_root_sid from customer);
delete from imp_region where csr_root_sid not in (select csr_root_sid from customer);

/*
delete from imp_conflict_val where imp_val_id in (select imp_val_id from imp_val where imp_measure_id in (select imp_measure_id from imp_measure where app_sid is null));
delete from imp_conflict_val where imp_val_id in (select imp_val_id from imp_val where imp_ind_id in (select imp_ind_id from imp_ind where app_sid is null));
delete from imp_conflict_val where imp_val_id in (select imp_val_id from imp_val where imp_region_id in (select imp_region_id from imp_ind where app_sid is null));
delete from imp_val where imp_measure_id in (select imp_measure_id from imp_measure where app_sid is null);
delete from imp_val where imp_ind_id in (select imp_ind_id from imp_ind where app_sid is null);
delete from imp_val where imp_region_id in (select imp_region_id from imp_ind where app_sid is null);
delete from imp_measure where app_sid is null;
delete from imp_ind where app_sid is null;
delete from imp_region where app_sid is null;
*/

alter table IMP_IND add app_sid number(10);
update IMP_IND set app_sid = (select app_sid from customer where customer.csr_root_sid = IMP_IND.csr_root_sid);
alter table IMP_IND modify app_sid not null;
alter table IMP_IND drop column csr_root_sid;

alter table IMP_MEASURE add app_sid number(10);
update IMP_MEASURE set app_sid = (select app_sid from customer where customer.csr_root_sid = IMP_MEASURE.csr_root_sid);
alter table IMP_MEASURE modify app_sid not null;
alter table IMP_MEASURE drop column csr_root_sid;

alter table IMP_REGION add app_sid number(10);
update IMP_REGION set app_sid = (select app_sid from customer where customer.csr_root_sid = IMP_REGION.csr_root_sid);
alter table IMP_REGION modify app_sid not null;
alter table IMP_REGION drop column csr_root_sid;

alter table IMP_SESSION add app_sid number(10);
update IMP_SESSION set app_sid = (select app_sid from customer where customer.csr_root_sid = IMP_SESSION.csr_root_sid);
alter table IMP_SESSION modify app_sid not null;
alter table IMP_SESSION drop column csr_root_sid;

alter table IND add app_sid number(10);
update IND set app_sid = (select app_sid from customer where customer.csr_root_sid = IND.csr_root_sid);
alter table IND modify app_sid not null;
alter table IND drop column csr_root_sid;

alter table STORED_CALC_JOB add app_sid number(10);
update STORED_CALC_JOB set app_sid = (select app_sid from customer where customer.csr_root_sid = STORED_CALC_JOB.csr_root_sid);
alter table STORED_CALC_JOB modify app_sid not null;
alter table stored_calc_job drop constraint pk_calc_ind_recalc_job;
begin
	for r in (select index_name from user_indexes where index_name='PK_CALC_IND_RECALC_JOB') loop
		execute immediate 'drop index PK_CALC_IND_RECALC_JOB';
	end loop;
end;
/
alter table stored_calc_job add constraint pk_calc_ind_recalc_job primary key (app_sid, calc_ind_sid, trigger_val_change_id, processing, lev) using index tablespace indx;
alter table STORED_CALC_JOB drop column csr_root_sid;

alter table MEASURE add app_sid number(10);
update MEASURE set app_sid = (select app_sid from customer where customer.csr_root_sid = MEASURE.csr_root_sid);
alter table MEASURE modify app_sid not null;
alter table MEASURE drop column csr_root_sid;

alter table REGION_RECALC_JOB add app_sid number(10);
update REGION_RECALC_JOB set app_sid = (select app_sid from customer where customer.csr_root_sid = REGION_RECALC_JOB.csr_root_sid);
alter table REGION_RECALC_JOB modify app_sid not null;
alter table REGION_RECALC_JOB drop constraint PK_REGION_RECALC_JOB;
begin
	for r in (select index_name from user_indexes where index_name='PK_REGION_RECALC_JOB') loop
		execute immediate 'drop index PK_REGION_RECALC_JOB';
	end loop;
end;
/
alter table REGION_RECALC_JOB add constraint PK_REGION_RECALC_JOB primary key (app_sid, ind_sid, processing) using index tablespace indx;
alter table REGION_RECALC_JOB drop column csr_root_sid;

-- clean up duff data
delete from reporting_period where csr_root_sid not in (select csr_root_sid from customer);
-- delete from reporting_period where app_sid is null;
alter table REPORTING_PERIOD add app_sid number(10);
update REPORTING_PERIOD set app_sid = (select app_sid from customer where customer.csr_root_sid = REPORTING_PERIOD.csr_root_sid);
alter table REPORTING_PERIOD modify app_sid not null;
alter table REPORTING_PERIOD drop column csr_root_sid;

-- clean up duff data
delete from accuracy_type where csr_root_sid not in (select csr_root_sid from customer);
-- delete from accuracy_type where app_sid is null;
alter table ACCURACY_TYPE add app_sid number(10);
update ACCURACY_TYPE set app_sid = (select app_sid from customer where customer.csr_root_sid = ACCURACY_TYPE.csr_root_sid);
alter table ACCURACY_TYPE modify app_sid not null;
alter table ACCURACY_TYPE drop column csr_root_sid;

-- clean up duff data
delete from audit_log where csr_root_sid not in (select csr_root_sid from customer);
-- delete from audit_log where app_sid is null;
alter table AUDIT_LOG add app_sid number(10);
update AUDIT_LOG set app_sid = (select app_sid from customer where customer.csr_root_sid = AUDIT_LOG.csr_root_sid);
alter table AUDIT_LOG modify app_sid not null;
alter table AUDIT_LOG drop column csr_root_sid;

-- clean up duff data
delete from csr_user where csr_root_sid not in (select csr_root_sid from customer);
-- delete from csr_user where app_sid is null;
alter table CSR_USER add app_sid number(10);
update CSR_USER set app_sid = (select app_sid from customer where customer.csr_root_sid = CSR_USER.csr_root_sid);
alter table CSR_USER modify app_sid not null;
alter table CSR_USER drop column csr_root_sid;

-- junk i think
-- alter table JOB_DETAIL_TEST add app_sid number(10);
-- update JOB_DETAIL_TEST set app_sid = (select app_sid from customer where customer.csr_root_sid = JOB_DETAIL_TEST.csr_root_sid);
-- alter table JOB_DETAIL_TEST modify app_sid not null;
-- alter table JOB_DETAIL_TEST drop column csr_root_sid;

alter table DELEGATION add app_sid number(10);
update DELEGATION set app_sid = (select app_sid from customer where customer.csr_root_sid = DELEGATION.csr_root_sid);
alter table DELEGATION modify app_sid not null;
alter table DELEGATION drop column csr_root_sid;

alter table DELIVERABLE add app_sid number(10);
update DELIVERABLE set app_sid = (select app_sid from customer where customer.csr_root_sid = DELIVERABLE.csr_root_sid);
alter table DELIVERABLE modify app_sid not null;
alter table DELIVERABLE drop column csr_root_sid;

-- alter table QWE add app_sid number(10);
-- update QWE set app_sid = (select app_sid from customer where customer.csr_root_sid = QWE.csr_root_sid);
-- alter table QWE modify app_sid not null;
-- alter table QWE drop column csr_root_sid;

-- james had this one in as a unique constraint:
-- sys_c009374 (csr_root_sid, link_to_region_sid, region_sid)
begin
	for r in (select distinct constraint_name 
				from user_cons_columns 
			   where table_name='REGION' and column_name='CSR_ROOT_SID') loop
		execute immediate 'alter table region drop constraint '||r.constraint_name;
	end loop;
end;
/
alter table REGION add app_sid number(10);
update REGION set app_sid = (select app_sid from customer where customer.csr_root_sid = REGION.csr_root_sid);
alter table REGION modify app_sid not null;
alter table REGION drop column csr_root_sid;

-- recreate views
CREATE OR REPLACE VIEW V$ACTIVE_USER AS
	SELECT cu.csr_user_sid, cu.email, cu.region_mount_point_sid,
	  cu.indicator_mount_point_sid, cu.app_sid, cu.full_name,
	  cu.user_name, cu.info_xml, cu.send_alerts,
	  cu.guid, cu.friendly_name
	  FROM csr_user cu, security.user_table ut
	 WHERE cu.csr_user_sid = ut.sid_id
	   AND ut.account_enabled = 1;

CREATE OR REPLACE VIEW AUDIT_VAL_LOG AS	   
	SELECT CHANGED_DTM AUDIT_DATE, R.app_sid, 6 AUDIT_TYPE_ID, vc.IND_SID OBJECT_SID, CHANGED_BY_SID USER_SID,
	 'Set "{0}" ("{1}") to {2}: '||REASON DESCRIPTION, I.DESCRIPTION PARAM_1, R.DESCRIPTION PARAM_2, VAL_NUMBER PARAM_3
	FROM VAL_CHANGE VC, REGION R, IND I
	WHERE VC.REGION_SID = R.REGION_SID
	   AND VC.IND_SID = I.IND_SID;

create or replace view v$issue_log_alert_batch AS
  select ilab.app_sid, ilab.run_at, ilabr.last_ran_at
    from issue_log_alert_batch ilab, issue_log_alert_batch_run ilabr
   where ilab.app_sid = ilabr.app_sid;

create or replace view v$pvc_stored_calc_job as
	select c.host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, processing, pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id
	  from pvc_stored_calc_job cirj, pending_dataset pd, customer c, pending_ind pi, pending_region pr, pending_period pp
	 where cirj.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid
	   and cirj.calc_pending_ind_id = pi.pending_ind_id
	   and cirj.pending_region_id = pr.pending_region_id
	   and cirj.pending_period_id = pp.pending_period_id;

create or replace view v$pvc_region_recalc_job as
	select c.host, pi.description ind_description, processing, pi.pending_ind_id, pd.pending_dataset_id
	  from pvc_region_recalc_job rrj, pending_dataset pd, customer c, pending_ind pi
	 where rrj.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid
	   and rrj.pending_ind_id = pi.pending_ind_id;

create or replace view v$pending_val_cache as
	select host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, val_number,
		pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id, pd.pending_dataset_id
	  from pending_val_cache pvc, pending_ind pi, pending_region pr, pending_period pp, pending_dataset pd, customer c
	 where pvc.pending_ind_Id = pi.pending_ind_id
	   and pvc.pending_region_id = pr.pending_region_id
	   and pvc.pending_period_id = pp.pending_period_id
	   and pi.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid;

create or replace view v$pending_val as
	select host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, val_number,
		val_string, from_val_number, from_measure_conversion_id, action, note, pv.approval_step_id,
		pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id, pd.pending_dataset_id
	  from pending_val pv, pending_ind pi, pending_region pr, pending_period pp, pending_dataset pd, customer c
	 where pv.pending_ind_Id = pi.pending_ind_id
	   and pv.pending_region_id = pr.pending_region_id
	   and pv.pending_period_id = pp.pending_period_id
	   and pi.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid;


CREATE or replace VIEW v$checked_out_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, checked_out_dtm, app_sid, section_position, active, module_root_sid, title_only  
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.checked_out_version_number = sv.version_number;

CREATE or replace VIEW v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, checked_out_dtm, app_sid, section_position, active, module_root_sid, title_only  
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

-- sanity
-- select table_name from user_tab_columns where column_name='CSR_ROOT_SID';

-- select  'alter table '||table_name||' add column app_sid number(10);'||chr(10)||'update '||table_name||' set app_sid = (select app_sid from customer where customer.csr_root_sid = '||table_name||'.csr_root_sid);'||chr(10)||'alter table '||table_name||' drop constraint '||constraint_name||';'||chr(10)||'alter table '||table_name||' add constraint '||constraint_name||' foreign key (app_sid) references customer(app_sid);'||chr(10)||'alter table '||table_name||' drop csr_root_sid;'||chr(10) from user_constraints where r_constraint_name='PK125';

-- ok, move all the children of app/csr up one level
begin
	for r in (select csr_root_sid, app_sid from customer where host <> 'SuperAdmins') loop
		update security.securable_object
		   set parent_sid_id = r.app_sid
		 where parent_sid_id = r.csr_root_sid;
	end loop;
end;
/

-- clean up some junk tables that have csr_root_sid set
begin
	for r in (select table_name from user_tables where table_name in ('FOO_DELEGATION', 'RBS_TEMP')) loop
		execute immediate 'drop table '||r.table_name;
	end loop;
end;
/
-- more sanity (= supplier, donations, csr.customer)
-- select owner,table_name,column_name from all_tab_columns  where column_name='CSR_ROOT_SID';
@update_tail

set define off
set define $

prompt enter connection name
prompt (this runs build.sql, type quit afterwards)
host cmd /c "cd .. && sqlplus csr/csr@$$1 @build"

PROMPT Now go and run supplier/latest40.sql and donations/latest29.sql
PROMPT And then security/latest18.sql, then aspen2/latest03.sql
PROMPT And possibly also acona/latest01.sql and rebuild ing/INGQualitative/ing_pkg
PROMPT And possibly csr/db/hsbc_pkg and novonordisk/db/novonordisk_pkg
PROMPT depending on if you have those
PROMPT And then run latest164->169.sql
PROMPT And then run 19-21 out of security.sql and 04 out of aspen2.
PROMPT And then install a new gnomon, aspen2, aspen2Net and csr.
