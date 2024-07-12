-- Please update version.sql too -- this keeps clean builds in sync
define version=164
@update_header

DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM supplier.version;
	IF v_version <> 40 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A ***SUPPLIER*** DATABASE OF VERSION '||v_version||' =======');
	END IF;

	SELECT db_version INTO v_version FROM donations.version;
	IF v_version <> 29 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A ***DONATIONS*** DATABASE OF VERSION '||v_version||' =======');
	END IF;

	SELECT db_version INTO v_version FROM aspen2.version;
	IF v_version <= 3 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A ***ASPEN2*** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

alter table customer drop constraint pk125;

-- redo all the constraints now to convert the uk on app_sid to a primary key
-- could have done this in one step, but oh well
alter table ISSUE_LOG_ALERT_BATCH drop constraint REFCUSTOMER78;
alter table ISSUE_LOG_ALERT_BATCH_RUN drop constraint REFCUSTOMER80;
alter table PENDING_DATASET drop constraint REFCUSTOMER501;
alter table APPROVAL_STEP_TEMPLATE drop constraint REFCUSTOMER498;
alter table AUTOCREATE_USER drop constraint REFCUSTOMER646;
alter table AUTOCREATE_USER drop constraint PK357;
alter table CUSTOMER_ALERT_TYPE drop constraint REFCUSTOMER648;
alter table ALERT_TEMPLATE drop constraint REFCUSTOMER_ALERT_TYPE645;
alter table CUSTOMER_ALERT_TYPE drop constraint PK356;
alter table alert_template drop constraint pk102;
alter table CUSTOMER_HELP_LANG drop constraint REFCUSTOMER420;
alter table customer_help_lang drop constraint pk5_2;
begin
	for r in (select table_name from user_tables where table_name = 'DATA_SOURCE_TYPE') loop
		execute immediate 'alter table DATA_SOURCE_TYPE drop constraint REFCUSTOMER271';
	end loop;
end;
/
alter table DIARY_EVENT drop constraint REFCUSTOMER201;
alter table DOC_LIBRARY drop constraint RefCUSTOMER687 ;
alter table SECTION_MODULE drop constraint REFCUSTOMER840;
alter table section drop constraint REFSECTION_MODULE833;
alter table section_module drop constraint pk427;
alter table REGION_TREE drop constraint REFCUSTOMER243;
alter table ROLE drop constraint REFCUSTOMER766;
alter table SURVEY drop constraint REFCUSTOMER251;
alter table TAG_GROUP drop constraint REFCUSTOMER231;
alter table TEMPLATE drop constraint REFCUSTOMER354;
alter table TEMPLATE drop constraint pk206;
alter table ERROR_LOG drop constraint REFCUSTOMER319;
alter table FEED drop constraint REFCUSTOMER284;
alter table ALERT drop constraint REFCUSTOMER307;
alter table CUSTOMER_PORTLET drop constraint REFCUSTOMER795;
alter table CUSTOMER_PORTLET drop constraint pk412;
alter table TAB drop constraint REFCUSTOMER801;

-- supplier bits
alter table supplier.ALERT_BATCH drop constraint REFCUSTOMER210;
alter table supplier.all_company drop constraint REFCUSTOMER109;
alter table supplier.CUSTOMER_PERIOD drop constraint REFCUSTOMER158;
alter table supplier.CUSTOMER_PERIOD drop constraint PK104;

-- donations bit
alter table donations.filter drop constraint REFCUSTOMER118;

-- just in case we need the csr_root_sid mapping somewhere
create table old_customer as 
	select * from customer;

alter table customer drop constraint pk_customer_app_sid;
alter table customer add constraint pk_customer primary key (app_sid);
alter table customer drop column csr_root_sid;

alter table ISSUE_LOG_ALERT_BATCH add constraint REFCUSTOMER78 foreign key (app_sid) references customer(app_sid);
alter table ISSUE_LOG_ALERT_BATCH_RUN add constraint REFCUSTOMER80 foreign key (app_sid) references customer(app_sid);
alter table PENDING_DATASET add constraint REFCUSTOMER501 foreign key (app_sid) references customer(app_sid);
alter table APPROVAL_STEP_TEMPLATE add constraint REFCUSTOMER498 foreign key (app_sid) references customer(app_sid);
alter table AUTOCREATE_USER add constraint REFCUSTOMER646 foreign key (app_sid) references customer(app_sid);
alter table AUTOCREATE_USER add constraint PK357 primary key (user_name, app_sid) using index tablespace indx;
alter table CUSTOMER_ALERT_TYPE add constraint REFCUSTOMER648 foreign key (app_sid) references customer(app_sid);
alter table CUSTOMER_ALERT_TYPE add constraint PK356 primary key (app_sid, alert_type_id) using index tablespace indx;
alter table ALERT_TEMPLATE add constraint REFCUSTOMER_ALERT_TYPE645 foreign key (app_sid, alert_type_id) references customer_alert_type(app_sid, alert_type_id);
alter table alert_template add constraint pk102 primary key (alert_type_id, app_sid) using index tablespace indx;
alter table customer_help_lang add constraint pk5_2 primary key (app_sid, help_lang_id) using index tablespace indx;
alter table CUSTOMER_HELP_LANG add constraint REFCUSTOMER420 foreign key (app_sid) references customer(app_sid);
begin
	for r in (select table_name from user_tables where table_name = 'DATA_SOURCE_TYPE') loop
		execute immediate 'alter table DATA_SOURCE_TYPE add constraint REFCUSTOMER271 foreign key (app_sid) references customer(app_sid)';
	end loop;
end;
/
alter table DIARY_EVENT add constraint REFCUSTOMER201 foreign key (app_sid) references customer(app_sid);
alter table DOC_LIBRARY add constraint RefCUSTOMER687 foreign key (app_sid) references customer(app_sid);
alter table SECTION_MODULE add constraint REFCUSTOMER840 foreign key (app_sid) references customer(app_sid);
alter table section_module add constraint pk427 primary key (module_root_sid, app_sid) using index tablespace indx;
alter table section add constraint REFSECTION_MODULE833 foreign key (module_root_sid, app_sid) references section_module (module_root_sid, app_sid);
alter table REGION_TREE add constraint REFCUSTOMER243 foreign key (app_sid) references customer(app_sid);
alter table ROLE add constraint REFCUSTOMER766 foreign key (app_sid) references customer(app_sid);
alter table SURVEY add constraint REFCUSTOMER251 foreign key (app_sid) references customer(app_sid);
alter table TAG_GROUP add constraint REFCUSTOMER231 foreign key (app_sid) references customer(app_sid);
alter table TEMPLATE add constraint REFCUSTOMER354 foreign key (app_sid) references customer(app_sid);
alter table TEMPLATE add constraint pk206 primary key (template_type_id, app_sid) using index tablespace indx;
alter table ERROR_LOG add constraint REFCUSTOMER319 foreign key (app_sid) references customer(app_sid);
alter table FEED add constraint REFCUSTOMER284 foreign key (app_sid) references customer(app_sid);
alter table ALERT add constraint REFCUSTOMER307 foreign key (app_sid) references customer(app_sid);
alter table CUSTOMER_PORTLET add constraint pk412 primary key (portlet_id, app_sid) using index tablespace indx;
alter table CUSTOMER_PORTLET add constraint REFCUSTOMER795 foreign key (app_sid) references customer(app_sid);
alter table TAB add constraint REFCUSTOMER801 foreign key (app_sid) references customer(app_sid);

-- supplier bits
alter table supplier.ALERT_BATCH add constraint REFCUSTOMER210 foreign key (app_sid) references csr.customer(app_sid);
alter table supplier.all_company add constraint REFCUSTOMER109 foreign key (app_sid) references csr.customer(app_sid);
alter table supplier.CUSTOMER_PERIOD add constraint REFCUSTOMER158 foreign key (app_sid) references csr.customer(app_sid);
alter table supplier.CUSTOMER_PERIOD add constraint PK104 primary key (app_sid, period_id) using index tablespace indx;

-- donations bit
alter table donations.filter add constraint REFCUSTOMER118 foreign key (app_sid) references csr.customer(app_sid);

@update_tail

prompt enter connection name
prompt (this runs build.sql, type quit afterwards)
host cmd /c "cd .. && sqlplus csr/csr@$$1 @build"
