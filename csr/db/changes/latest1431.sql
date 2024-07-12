-- Please update version.sql too -- this keeps clean builds in sync
define version=1431
@update_header

create sequence csr.alert_bounce_id_seq;
alter table csr.alert_bounce add alert_bounce_id number(10);
update csr.alert_bounce
   set alert_bounce_id = csr.alert_bounce_id_seq.nextval;
alter table csr.alert_bounce modify alert_bounce_id not null;
alter table csr.alert_bounce add constraint pk_alert_bounce primary key (app_sid, alert_bounce_id);

alter table csr.alert add subject varchar2(4000);

alter table csrimp.alert add subject varchar2(4000);
alter table csrimp.alert_bounce add alert_bounce_id number(10) not null;
alter table csrimp.alert_bounce add CONSTRAINT PK_ALERT_BOUNCE PRIMARY KEY (CSRIMP_SESSION_ID, ALERT_BOUNCE_ID);

alter table csrimp.cms_alert_helper drop primary key drop index;
alter table csrimp.cms_alert_helper add constraint pk_cms_alert_helper primary key (csrimp_session_id, helper_sp);
alter table csrimp.cms_alert_type drop primary key drop index;
alter table csrimp.cms_alert_type add constraint pk_cms_alert_type primary key (csrimp_session_id, tab_sid, customer_alert_type_id);

INSERT INTO csr.capability (name, allow_by_default) VALUES ('View alert bounces', 0);

grant select on csr.alert_bounce_id_seq to csrimp;	  

@../alert_pkg
@../alert_body
@../schema_body
@../csrimp/imp_body

@update_tail
