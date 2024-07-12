-- Please update version.sql too -- this keeps clean builds in sync
define version=40
@update_header

alter table ALERT_BATCH add app_sid number(10);
update ALERT_BATCH set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = ALERT_BATCH.csr_root_sid);
alter table ALERT_BATCH modify app_sid not null;
alter table ALERT_BATCH drop constraint REFCUSTOMER210;
alter table ALERT_BATCH add constraint REFCUSTOMER210 foreign key (app_sid) references csr.customer(app_sid);
alter table ALERT_BATCH drop column csr_root_sid;

alter table ALL_COMPANY add app_sid number(10);
update ALL_COMPANY set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = ALL_COMPANY.csr_root_sid);
alter table ALL_COMPANY modify app_sid not null;
alter table all_company drop constraint REFCUSTOMER109;
alter table all_company add constraint REFCUSTOMER109 foreign key (app_sid) references csr.customer(app_sid);
alter table ALL_COMPANY drop column csr_root_sid;

-- guff?
drop table all_product_backup;


alter table CUSTOMER_PERIOD add app_sid number(10);
update CUSTOMER_PERIOD set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = CUSTOMER_PERIOD.csr_root_sid);
alter table CUSTOMER_PERIOD modify app_sid not null;
alter table CUSTOMER_PERIOD drop constraint REFCUSTOMER158;
alter table CUSTOMER_PERIOD add constraint REFCUSTOMER158 foreign key (app_sid) references csr.customer(app_sid);
alter table CUSTOMER_PERIOD drop constraint PK104;
begin
	for r in (select index_name from user_indexes where index_name='PK104') loop
		execute immediate 'drop index PK104';
	end loop;
end;
/
alter table CUSTOMER_PERIOD add constraint PK104 primary key (app_sid, period_id) using index tablespace indx;
alter table CUSTOMER_PERIOD drop column csr_root_sid;

-- tables with no RI, TODO: fix??
alter table ALL_PRODUCT add app_sid number(10);
update ALL_PRODUCT set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = ALL_PRODUCT.csr_root_sid);
alter table ALL_PRODUCT modify app_sid not null;
alter table all_product drop column csr_root_sid;

alter table TAG_GROUP add app_sid number(10);
update TAG_GROUP set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = TAG_GROUP.csr_root_sid);
alter table TAG_GROUP modify app_sid not null;
alter table TAG_GROUP drop column csr_root_sid;

alter table CUSTOMER_OPTIONS add app_sid number(10);
update CUSTOMER_OPTIONS set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = CUSTOMER_OPTIONS.csr_root_sid);
alter table CUSTOMER_OPTIONS modify app_sid not null;
alter table CUSTOMER_OPTIONS drop constraint pk168;
begin
	for r in (select index_name from user_indexes where index_name='PK168') loop
		execute immediate 'drop index pk168';
	end loop;
end;
/
alter table CUSTOMER_OPTIONS add constraint pk168 primary key (app_sid) using index tablespace indx;
alter table CUSTOMER_OPTIONS drop column csr_root_sid;

alter table QUESTIONNAIRE_GROUP add app_sid number(10);
update QUESTIONNAIRE_GROUP set app_sid = (select app_sid from csr.customer where customer.csr_root_sid = QUESTIONNAIRE_GROUP.csr_root_sid);
alter table QUESTIONNAIRE_GROUP modify app_sid not null;
alter table QUESTIONNAIRE_GROUP drop column csr_root_sid;

-- VIEW: COMPANY
CREATE or replace VIEW COMPANY AS
SELECT AL.COMPANY_SID, AL.NAME, AL.ADDRESS_1, AL.ADDRESS_2, AL.ADDRESS_3, AL.ADDRESS_4, AL.TOWN, AL.STATE, AL.POSTCODE, AL.COUNTRY_CODE, AL.PHONE, AL.PHONE_ALT, AL.FAX, AL.INTERNAL_SUPPLIER, AL.ACTIVE, AL.DELETED, AL.COMPANY_STATUS_ID, AL.APP_SID
FROM ALL_COMPANY AL
WHERE DELETED = 0
;

-- VIEW: PRODUCT
CREATE or replace VIEW PRODUCT AS
SELECT AL.PRODUCT_ID, AL.PRODUCT_CODE, AL.DESCRIPTION, AL.SUPPLIER_COMPANY_SID, AL.PRODUCT_STATUS_ID, AL.DUE_DATE, AL.ACTIVE, AL.DELETED, AL.STATUS_CHANGED_DTM, AL.DECLARATION_MADE_BY_SID, AL.APP_SID
FROM ALL_PRODUCT AL
WHERE DELETED = 0
;

@update_tail
