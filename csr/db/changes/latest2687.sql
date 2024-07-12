-- Please update version.sql too -- this keeps clean builds in sync
define version=2687
@update_header

alter table csr.temp_course_schedule add USER_CURRENT_STATE VARCHAR2(50);
alter table csr.temp_course_schedule add USER_SID NUMBER(10);
alter table csr.temp_course_schedule add USER_NAME VARCHAR2(255);
alter table csr.temp_course add USER_SID NUMBER(10);
alter table csr.temp_course add USER_NAME VARCHAR2(255);
alter table csr.temp_course add FLOW_STATE VARCHAR2(255);
alter table csr.temp_course add SCHEDULE_ID_FOR_FLOW_STATE NUMBER(10);
alter table csr.temp_course rename column COURSE_GROUP to REGION_SID;
alter table csr.temp_course rename column COURSE_GROUP_DESCRIPTION to REGION_DESCRIPTION;
alter table csr.course rename column COURSE_GROUP to REGION_SID;
alter table csr.temp_course_schedule drop column REGION_SID;
alter table csr.temp_course_schedule rename column COURSE_GROUP to REGION_SID;
alter table csr.temp_course_schedule rename column COURSE_GROUP_DESCRIPTION to REGION_DESCRIPTION;

@../training_pkg
@../training_body

@update_tail
