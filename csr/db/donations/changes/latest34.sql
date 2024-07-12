-- Please update version.sql too -- this keeps clean builds in sync
define version=34
@update_header

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK13','PK_BUDGET')
order by table_name, constraint_name;

x BUDGET_CONSTANT                REFBUDGET112
x DONATION                       REFBUDGET50
*/

 
alter TABLE BUDGET add APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP');
update budget set app_sid = (select app_sid from scheme where scheme.scheme_sid = budget.scheme_sid);
alter table budget modify app_sid not null;
alter table budget drop primary key cascade drop index;
alter table budget add 
    CONSTRAINT PK_BUDGET PRIMARY KEY (APP_SID, BUDGET_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter TABLE BUDGET_CONSTANT add APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP');
update BUDGET_CONSTANT set app_sid = (select app_sid from budget where BUDGET_CONSTANT.budget_id = budget.budget_id);
alter table BUDGET_CONSTANT modify app_sid not null;
alter table BUDGET_CONSTANT drop primary key drop index;
alter table BUDGET_CONSTANT add 
    CONSTRAINT PK_BUDGET_CONSTANT PRIMARY KEY (APP_SID, BUDGET_ID, CONSTANT_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK82','PK_CONSTANT')
order by table_name, constraint_name;

x BUDGET_CONSTANT                REFCONSTANT111
*/ 
alter TABLE CONSTANT modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP') not null;
alter table CONSTANT drop primary key cascade drop index;
alter table CONSTANT add 
    CONSTRAINT PK_CONSTANT PRIMARY KEY (APP_SID, CONSTANT_ID)
    USING INDEX
TABLESPACE INDX
 ;
 

alter index pk_country rebuild tablespace indx;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK51','PK_CURRENCY')
order by table_name, constraint_name;
x BUDGET                         REFCURRENCY103
x CUSTOMER_DEFAULT_EXRATE        REFCURRENCY105
*/
alter table CURRENCY drop primary key cascade drop index;
alter table CURRENCY add
    CONSTRAINT PK_CURRENCY PRIMARY KEY (CURRENCY_CODE)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK76','PK_CUSTOM_FIELD')
order by table_name, constraint_name;
x SCHEME_FIELD                   REFCUSTOM_FIELD126
*/
alter table custom_field modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
alter TABLE CUSTOM_FIELD drop primary key cascade drop index;
alter table CUSTOM_FIELD add
    CONSTRAINT PK_CUSTOM_FIELD PRIMARY KEY (APP_SID, FIELD_NUM)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter table CUSTOMER_DEFAULT_EXRATE modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
alter TABLE CUSTOMER_DEFAULT_EXRATE drop primary key drop index;
alter TABLE CUSTOMER_DEFAULT_EXRATE add
    CONSTRAINT PK_CUSTOMER_DEFAULT_EXRATE PRIMARY KEY (APP_SID, CURRENCY_CODE)
    USING INDEX
TABLESPACE INDX
 ;
 
alter TABLE CUSTOMER_FILTER_FLAG modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');
alter TABLE CUSTOMER_FILTER_FLAG drop primary key drop index;
alter TABLE CUSTOMER_FILTER_FLAG add
    CONSTRAINT PK_CUSTOMER_FILTER_FLAG PRIMARY KEY (APP_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK2','PK_DONATION')
order by table_name, constraint_name;
x DONATION                       REFDONATION51
x DONATION_DOC                   REFDONATION124
x DONATION_TAG                   REFDONATION56
*/

alter TABLE DONATION add APP_SID NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP');
update donation set  app_sid=  (select app_sid from scheme where scheme.scheme_sid = donation.scheme_sid);
alter table donation modify app_sid not null;
alter table donation drop primary key cascade drop index;
alter table donation add
    CONSTRAINT PK_DONATION PRIMARY KEY (APP_SID, DONATION_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
alter TABLE DONATION_DOC add APP_SID NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP');
update DONATION_DOC set  app_sid=  (select app_sid from donation where DONATION_DOC.donation_id = DONATION.donation_id);
alter table DONATION_DOC modify app_sid not null;
alter table DONATION_DOC drop primary key drop index;
alter table DONATION_DOC add
    CONSTRAINT PK_DONATION_DOC PRIMARY KEY (APP_SID, DONATION_ID, DOCUMENT_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('ENTITY1PK','PK_DONATION_STATUS')
order by table_name, constraint_name;
x DONATION                       REFDONATION_STATUS52
x LETTER_BODY_TEXT               REFDONATION_STATUS95
x TRANSITION                     REFDONATION_STATUS129
x TRANSITION                     REFDONATION_STATUS130
*/

alter TABLE DONATION_STATUS modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table DONATION_STATUS drop primary key cascade drop index;
alter table DONATION_STATUS add
    CONSTRAINT PK_DONATION_STATUS PRIMARY KEY (APP_SID, DONATION_STATUS_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter TABLE DONATION_TAG add  APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update donation_tag set app_sid = (select app_sid from donation where donation_tag.donation_id = donation.donation_id);
alter table donation_Tag modify app_sid not null;
alter table donation_Tag drop primary key drop index;
alter table donation_tag add 
    CONSTRAINT PK_DONATION_TAG PRIMARY KEY (APP_SID, DONATION_ID, TAG_ID)
    USING INDEX
TABLESPACE INDX
 ;

alter table FILTER modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table FILTER drop primary key drop index;
alter table FILTER add
    CONSTRAINT PK_FILTER PRIMARY KEY (APP_SID, FILTER_ID)
    USING INDEX
TABLESPACE INDX
 ;
 

 
alter TABLE REGION_GROUP_MEMBER add APP_SID number(10)  DEFAULT SYS_CONTEXT('SECURITY','APP');
update region_group_member set app_sid = (select app_sid from csr.region where region.region_sid=region_group_member.region_sid);
alter table region_group_member modify app_sid NOT NULL;
alter table region_group_member drop primary key drop index;
alter table region_group_member add
    CONSTRAINT PK_REGION_GROUP_MEMBER PRIMARY KEY (APP_SID, REGION_SID, REGION_GROUP_SID)
    USING INDEX
TABLESPACE INDX
 ;

 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('ENTITY2PK','PK_REGION_GROUP')
order by table_name, constraint_name;
x BUDGET                         REFREGION_GROUP67
x LETTER_BODY_REGION_GROUP       REFREGION_GROUP94
x REGION_GROUP_MEMBER            REFREGION_GROUP59
x REGION_GROUP_RECIPIENT         REFREGION_GROUP78
*/ 
alter TABLE REGION_GROUP modify APP_SID     DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update region_group set app_sid = (select min(app_sid) from region_group_member where region_group_member.region_group_sid=region_group.region_group_sid);
alter table region_group modify app_sid not null;
alter table region_group drop primary key cascade drop index;
alter table region_group add 
    CONSTRAINT PK_REGION_GROUP PRIMARY KEY (APP_SID, REGION_GROUP_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
alter table LETTER_BODY_REGION_GROUP add APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update LETTER_BODY_REGION_GROUP set app_sid = (select app_sid from region_group where region_group.region_group_sid = letter_body_region_group.region_group_sid);
alter table LETTER_BODY_REGION_GROUP modify app_sid not null;
alter table LETTER_BODY_REGION_GROUP drop primary key drop index;
alter table LETTER_BODY_REGION_GROUP add
    CONSTRAINT PK_LETTER_BODY_REGION_GROUP PRIMARY KEY (APP_SID, REGION_GROUP_SID, LETTER_BODY_TEXT_ID, DONATION_STATUS_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK60','PK_LETTER_BODY_TEXT')
order by table_name, constraint_name;
x LETTER_BODY_REGION_GROUP       REFLETTER_BODY_TEXT93
*/
alter table LETTER_BODY_TEXT add APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update LETTER_BODY_TEXT set app_sid = (select min(app_sid) from LETTER_BODY_REGION_GROUP where LETTER_BODY_TEXT.LETTER_BODY_TEXT_ID = LETTER_BODY_REGION_GROUP.LETTER_BODY_TEXT_ID);
-- orphans  22/54
delete from letter_body_text where app_sid is null;
alter table LETTER_BODY_TEXT modify app_sid not null;
alter table LETTER_BODY_TEXT drop primary key cascade drop index;
alter table LETTER_BODY_TEXT add
    CONSTRAINT PK_LETTER_BODY_TEXT PRIMARY KEY (APP_SID, LETTER_BODY_TEXT_ID, DONATION_STATUS_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK57','PK_LETTER_TEMPLATE')
order by table_name, constraint_name;
x REGION_GROUP                   REFLETTER_TEMPLATE96
*/

/* strange, this was missing locally...
alter table LETTER_TEMPLATE add APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update LETTER_TEMPLATE set app_sid = (select min(app_sid) from REGION_GROUP where LETTER_TEMPLATE.LETTER_TEMPLATE_ID = REGION_GROUP.LETTER_TEMPLATE_ID);
-- orphans 3/16
delete from letter_template where app_sid is null;
*/
alter table LETTER_TEMPLATE modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table LETTER_TEMPLATE modify app_sid not null;
alter table LETTER_TEMPLATE drop primary key cascade drop index;
alter table LETTER_TEMPLATE add
    CONSTRAINT PK_LETTER_TEMPLATE PRIMARY KEY (APP_SID, LETTER_TEMPLATE_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK_ADDRESS','PK_RECIPIENT')
order by table_name, constraint_name;
x DONATION                       REFRECIPIENT54
x RECIPIENT                      REFRECIPIENT70
x RECIPIENT_TAG                  REFRECIPIENT58
x REGION_GROUP_RECIPIENT         REFRECIPIENT77
*/
alter  table RECIPIENT modify APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table recipient drop primary key cascade drop index;
alter table recipient add
    CONSTRAINT PK_RECIPIENT PRIMARY KEY (APP_SID, RECIPIENT_SID)
    USING INDEX
TABLESPACE INDX
 ;
 

alter table RECIPIENT_TAG add APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update RECIPIENT_TAG set app_sid = (select app_sid from RECIPIENT where RECIPIENT_TAG.RECIPIENT_SID = RECIPIENT.RECIPIENT_SID);
alter table RECIPIENT_TAG modify app_sid not null;
alter table RECIPIENT_TAG drop primary key drop index;
alter table RECIPIENT_TAG add
    CONSTRAINT PK_RECIPIENT_TAG PRIMARY KEY (APP_SID, RECIPIENT_SID, TAG_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
alter table REGION_GROUP_RECIPIENT add APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update REGION_GROUP_RECIPIENT set app_sid = (select app_sid from RECIPIENT where REGION_GROUP_RECIPIENT.RECIPIENT_SID = RECIPIENT.RECIPIENT_SID);
alter table REGION_GROUP_RECIPIENT modify app_sid not null;
alter table REGION_GROUP_RECIPIENT drop primary key drop index;
alter table REGION_GROUP_RECIPIENT add
	CONSTRAINT PK_REGION_GROUP_RECIPIENT PRIMARY KEY (APP_SID, REGION_GROUP_SID, RECIPIENT_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK11','PK_SCHEME')
order by table_name, constraint_name;
x BUDGET                         REFSCHEME48
x DONATION                       REFSCHEME53
x SCHEME_FIELD                   REFSCHEME125
x SCHEME_TAG_GROUP               REFSCHEME60
*/

alter table SCHEME modify APP_SID  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update scheme set app_sid = (select app_sid from donation where scheme.scheme_sid = donation.scheme_sid) where app_sid is null;
update scheme set app_sid = (select app_sid from budget where scheme.scheme_sid = budget.scheme_sid) where app_sid is null;
--update scheme set app_sid = (select app_sid from SCHEME_FIELD where scheme.scheme_sid = SCHEME_FIELD.scheme_sid) where app_sid is null;
--update scheme set app_sid = (select app_sid from donation where SCHEME_TAG_GROUP.scheme_sid = SCHEME_TAG_GROUP.scheme_sid) where app_sid is null;
alter table scheme modify app_sid not null;
alter table scheme drop primary key cascade drop index;
alter table scheme add
    CONSTRAINT PK_SCHEME PRIMARY KEY (APP_SID, SCHEME_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
alter table SCHEME_FIELD modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
alter table SCHEME_FIELD drop primary key drop index;
alter table SCHEME_FIELD add
    CONSTRAINT PK_SCHEME_FIELD PRIMARY KEY (APP_SID, FIELD_NUM, SCHEME_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter table SCHEME_TAG_GROUP add app_sid number(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP');
update SCHEME_TAG_GROUP set app_sid = (select app_sid from scheme where scheme.scheme_sid = SCHEME_TAG_GROUP.scheme_sid);
alter table SCHEME_TAG_GROUP modify app_sid not null;
alter table SCHEME_TAG_GROUP  drop primary key drop index;
alter table SCHEME_TAG_GROUP  add
    CONSTRAINT PK_SCHEME_TAG_GROUP PRIMARY KEY (APP_SID, SCHEME_SID, TAG_GROUP_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK9','PK_TAG_GROUP')
order by table_name, constraint_name;
x SCHEME_TAG_GROUP               REFTAG_GROUP61
x TAG_GROUP_MEMBER               REFTAG_GROUP62
*/
alter TABLE TAG_GROUP modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter table TAG_GROUP drop primary key cascade drop index;
alter table TAG_GROUP add
    CONSTRAINT PK_TAG_GROUP PRIMARY KEY (APP_SID, TAG_GROUP_SID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter table TAG_GROUP_MEMBER add app_sid number(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP');
update TAG_GROUP_MEMBER set app_sid = (select app_sid from TAG_GROUP where TAG_GROUP_MEMBER.TAG_GROUP_SID = TAG_GROUP.TAG_GROUP_SID);
alter table TAG_GROUP_MEMBER modify app_sid not null;
alter table TAG_GROUP_MEMBER  drop primary key drop index;
alter table TAG_GROUP_MEMBER  add
    CONSTRAINT PK_TAG_GROUP_MEMBER PRIMARY KEY (APP_SID, TAG_GROUP_SID, TAG_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK6','PK_TAG')
order by table_name, constraint_name;
x DONATION_TAG                   REFTAG55
x RECIPIENT_TAG                  REFTAG57
x TAG_GROUP_MEMBER               REFTAG63
*/
alter table TAG add app_sid number(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP');
update TAG set app_sid = (select min(app_sid) from TAG_GROUP_MEMBER where TAG_GROUP_MEMBER.TAG_ID = TAG.TAG_ID) where app_sid is null;
update TAG set app_sid = (select min(app_sid) from RECIPIENT_TAG where RECIPIENT_TAG.TAG_ID = TAG.TAG_ID) where app_sid is null;
update TAG set app_sid = (select min(app_sid) from DONATION_TAG where DONATION_TAG.TAG_ID = TAG.TAG_ID) where app_sid is null;
-- orphans - 332/854
delete from tag where app_sid is null;
alter table TAG modify app_sid not null;
alter table TAG  drop primary key cascade drop index;
alter table TAG  add
    CONSTRAINT PK_TAG PRIMARY KEY (APP_SID, TAG_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
alter TABLE TRANSITION modify  APP_SID  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
-- XXX: mising on live
begin
	for r in (select 1 from user_constraints where table_name = 'TRANSITION' and constraint_type = 'P') loop
		execute immediate 'alter TABLE TRANSITION drop primary key drop index';
	end loop;
end;
/

alter TABLE TRANSITION add
    CONSTRAINT PK_TRANSITION PRIMARY KEY (APP_SID, TRANSITION_SID)
    USING INDEX
TABLESPACE INDX
 ;

/*
select table_name,constraint_name from user_constraints where r_constraint_name in ('PK69','PK_USER_FIELDSET')
order by table_name, constraint_name;
x USER_FIELDSET_FIELD            REFUSER_FIELDSET101
*/
alter table USER_FIELDSET modify APP_SID  DEFAULT SYS_CONTEXT('SECURITY','APP') ;
alter TABLE USER_FIELDSET drop primary key cascade drop index;
alter TABLE USER_FIELDSET add
	CONSTRAINT PK_USER_FIELDSET PRIMARY KEY (APP_SID, USER_FIELDSET_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
alter table USER_FIELDSET_FIELD add APP_SID number(10) DEFAULT SYS_CONTEXT('SECURITY','APP') ;
update USER_FIELDSET_FIELD set app_sid = (select  app_sid from USER_FIELDSET where USER_FIELDSET_FIELD.USER_FIELDSET_ID = USER_FIELDSET.USER_FIELDSET_ID);
alter table USER_FIELDSET_FIELD modify app_sid not null;
alter TABLE USER_FIELDSET_FIELD drop primary key drop index;
alter TABLE USER_FIELDSET_FIELD add
    CONSTRAINT PK_USER_FIELDSET_FIELD PRIMARY KEY (APP_SID, FIELD_NAME, USER_FIELDSET_ID)
    USING INDEX
TABLESPACE INDX
 ;
 
 
begin
	for r in (select index_name from user_indexes where index_name in(
		'UNIQUE_APP_CONSTANT', 'AK_CUSTOM_VALUE'
	)) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/
 
 
CREATE UNIQUE INDEX UK_CONSTANT_KEY ON CONSTANT(APP_SID, LOOKUP_KEY)
TABLESPACE INDX
 ;

 
CREATE UNIQUE INDEX UK_CUSTOM_FIELD_LOOKUP_KEY ON CUSTOM_FIELD(APP_SID, LOOKUP_KEY)
TABLESPACE INDX
 ;

 ALTER TABLE BUDGET ADD CONSTRAINT RefSCHEME48 
    FOREIGN KEY (APP_SID, SCHEME_SID)
    REFERENCES SCHEME(APP_SID, SCHEME_SID)
 ;
 
 ALTER TABLE BUDGET ADD CONSTRAINT RefREGION_GROUP67 
    FOREIGN KEY (APP_SID, REGION_GROUP_SID)
    REFERENCES REGION_GROUP(APP_SID, REGION_GROUP_SID)
 ;
 
 
 ALTER TABLE BUDGET_CONSTANT ADD CONSTRAINT RefCONSTANT111 
    FOREIGN KEY (APP_SID, CONSTANT_ID)
    REFERENCES CONSTANT(APP_SID, CONSTANT_ID)
 ;
 
 ALTER TABLE BUDGET_CONSTANT ADD CONSTRAINT RefBUDGET112 
    FOREIGN KEY (APP_SID, BUDGET_ID)
    REFERENCES BUDGET(APP_SID, BUDGET_ID)
 ;

delete from customer_filter_flag where app_sid not in (select app_sid from csr.customer); 
ALTER TABLE CUSTOMER_FILTER_FLAG ADD CONSTRAINT RefCUSTOMER143 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;


 ALTER TABLE DONATION ADD CONSTRAINT RefCSR_USER134 
    FOREIGN KEY (APP_SID, LAST_STATUS_CHANGED_BY)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE DONATION ADD CONSTRAINT RefCSR_USER135 
    FOREIGN KEY (APP_SID, ENTERED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE DONATION ADD CONSTRAINT RefBUDGET50 
    FOREIGN KEY (APP_SID, BUDGET_ID)
    REFERENCES BUDGET(APP_SID, BUDGET_ID)
 ;
 
 ALTER TABLE DONATION ADD CONSTRAINT RefDONATION51 
    FOREIGN KEY (APP_SID, ALLOCATED_FROM_DONATION_ID)
    REFERENCES DONATION(APP_SID, DONATION_ID)
 ;
 
 ALTER TABLE DONATION ADD CONSTRAINT RefDONATION_STATUS52 
    FOREIGN KEY (APP_SID, DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(APP_SID, DONATION_STATUS_SID)
 ;
 
 ALTER TABLE DONATION ADD CONSTRAINT RefSCHEME53 
    FOREIGN KEY (APP_SID, SCHEME_SID)
    REFERENCES SCHEME(APP_SID, SCHEME_SID)
 ;
 
 ALTER TABLE DONATION ADD CONSTRAINT RefRECIPIENT54 
    FOREIGN KEY (APP_SID, RECIPIENT_SID)
    REFERENCES RECIPIENT(APP_SID, RECIPIENT_SID)
 ;
 
 
 ALTER TABLE DONATION_DOC ADD CONSTRAINT RefDONATION124 
    FOREIGN KEY (APP_SID, DONATION_ID)
    REFERENCES DONATION(APP_SID, DONATION_ID)
;

ALTER TABLE DONATION_STATUS ADD CONSTRAINT RefCUSTOMER144 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
 ;
 
 
 ALTER TABLE DONATION_TAG ADD CONSTRAINT RefTAG55 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES TAG(APP_SID, TAG_ID)
 ;
 
 ALTER TABLE DONATION_TAG ADD CONSTRAINT RefDONATION56 
    FOREIGN KEY (APP_SID, DONATION_ID)
    REFERENCES DONATION(APP_SID, DONATION_ID)
 ;
 
 
 ALTER TABLE FILTER ADD CONSTRAINT RefCSR_USER116 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE LETTER_BODY_REGION_GROUP ADD CONSTRAINT RefLETTER_BODY_TEXT93 
    FOREIGN KEY (APP_SID, LETTER_BODY_TEXT_ID, DONATION_STATUS_SID)
    REFERENCES LETTER_BODY_TEXT(APP_SID, LETTER_BODY_TEXT_ID, DONATION_STATUS_SID)
 ;
 
 ALTER TABLE LETTER_BODY_REGION_GROUP ADD CONSTRAINT RefREGION_GROUP94 
    FOREIGN KEY (APP_SID, REGION_GROUP_SID)
    REFERENCES REGION_GROUP(APP_SID, REGION_GROUP_SID)
 ;
 
 
 ALTER TABLE LETTER_BODY_TEXT ADD CONSTRAINT RefDONATION_STATUS95 
    FOREIGN KEY (APP_SID, DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(APP_SID, DONATION_STATUS_SID)
;


delete from letter_template where app_sid not in (select app_sid from csr.customer);
ALTER TABLE LETTER_TEMPLATE ADD CONSTRAINT RefCUSTOMER145 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
 ;
  
 ALTER TABLE RECIPIENT ADD CONSTRAINT RefRECIPIENT70 
    FOREIGN KEY (APP_SID, PARENT_SID)
    REFERENCES RECIPIENT(APP_SID, RECIPIENT_SID)
 ;

 ALTER TABLE RECIPIENT_TAG ADD CONSTRAINT RefTAG57 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES TAG(APP_SID, TAG_ID)
 ;
 
 ALTER TABLE RECIPIENT_TAG ADD CONSTRAINT RefRECIPIENT58 
    FOREIGN KEY (APP_SID, RECIPIENT_SID)
    REFERENCES RECIPIENT(APP_SID, RECIPIENT_SID)
 ;
 
 ALTER TABLE REGION_GROUP ADD CONSTRAINT RefLETTER_TEMPLATE96 
    FOREIGN KEY (APP_SID, LETTER_TEMPLATE_ID)
    REFERENCES LETTER_TEMPLATE(APP_SID, LETTER_TEMPLATE_ID)
 ;
 
 ALTER TABLE REGION_GROUP_MEMBER ADD CONSTRAINT RefREGION_GROUP59 
    FOREIGN KEY (APP_SID, REGION_GROUP_SID)
    REFERENCES REGION_GROUP(APP_SID, REGION_GROUP_SID)
;

ALTER TABLE REGION_GROUP_MEMBER ADD CONSTRAINT RefREGION146 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
 ;
 
 ALTER TABLE REGION_GROUP_RECIPIENT ADD CONSTRAINT RefRECIPIENT79 
    FOREIGN KEY (APP_SID, RECIPIENT_SID)
    REFERENCES RECIPIENT(APP_SID, RECIPIENT_SID)
 ;
 
 ALTER TABLE REGION_GROUP_RECIPIENT ADD CONSTRAINT RefREGION_GROUP80 
    FOREIGN KEY (APP_SID, REGION_GROUP_SID)
    REFERENCES REGION_GROUP(APP_SID, REGION_GROUP_SID)
 ;
 
 ALTER TABLE SCHEME_FIELD ADD CONSTRAINT RefSCHEME125 
    FOREIGN KEY (APP_SID, SCHEME_SID)
    REFERENCES SCHEME(APP_SID, SCHEME_SID)
 ;

 ALTER TABLE SCHEME_TAG_GROUP ADD CONSTRAINT RefSCHEME60 
    FOREIGN KEY (APP_SID, SCHEME_SID)
    REFERENCES SCHEME(APP_SID, SCHEME_SID)
 ;
 
 ALTER TABLE SCHEME_TAG_GROUP ADD CONSTRAINT RefTAG_GROUP61 
    FOREIGN KEY (APP_SID, TAG_GROUP_SID)
    REFERENCES TAG_GROUP(APP_SID, TAG_GROUP_SID)
;


ALTER TABLE TAG ADD CONSTRAINT RefCUSTOMER147 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE TAG_GROUP ADD CONSTRAINT RefCUSTOMER148 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
 ;
 
  
 ALTER TABLE TAG_GROUP_MEMBER ADD CONSTRAINT RefTAG_GROUP62 
    FOREIGN KEY (APP_SID, TAG_GROUP_SID)
    REFERENCES TAG_GROUP(APP_SID, TAG_GROUP_SID)
 ;
 
 ALTER TABLE TAG_GROUP_MEMBER ADD CONSTRAINT RefTAG63 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES TAG(APP_SID, TAG_ID)
 ;
 
 ALTER TABLE TRANSITION ADD CONSTRAINT RefDONATION_STATUS129 
    FOREIGN KEY (APP_SID, FROM_DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(APP_SID, DONATION_STATUS_SID)
 ;
 
 ALTER TABLE TRANSITION ADD CONSTRAINT RefDONATION_STATUS130 
    FOREIGN KEY (APP_SID, TO_DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(APP_SID, DONATION_STATUS_SID)
 ;
 
 ALTER TABLE USER_FIELDSET ADD CONSTRAINT RefCSR_USER136 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
 ;
 
 ALTER TABLE USER_FIELDSET_FIELD ADD CONSTRAINT RefUSER_FIELDSET101 
    FOREIGN KEY (APP_SID, USER_FIELDSET_ID)
    REFERENCES USER_FIELDSET(APP_SID, USER_FIELDSET_ID)
 ;
 
ALTER TABLE BUDGET ADD CONSTRAINT RefCURRENCY103 
    FOREIGN KEY (CURRENCY_CODE)
    REFERENCES CURRENCY(CURRENCY_CODE)
;

ALTER TABLE CUSTOMER_DEFAULT_EXRATE ADD CONSTRAINT RefCURRENCY105 
    FOREIGN KEY (CURRENCY_CODE)
    REFERENCES CURRENCY(CURRENCY_CODE)
;
 
ALTER TABLE SCHEME_FIELD ADD CONSTRAINT RefCUSTOM_FIELD126 
    FOREIGN KEY (APP_SID, FIELD_NUM)
    REFERENCES CUSTOM_FIELD(APP_SID, FIELD_NUM)
;

@..\rls
@update_tail
