-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=15
@update_header

create table aspen2.profile
(
	profile_id						number(10) not null,
	dtm								date not null,
	app_sid							number(10) not null,
	url								varchar2(4000) not null,
	elapsed_ms						number(10) not null,
	constraint pk_profile primary key (profile_id)
);

create sequence aspen2.profile_id_seq;

create table aspen2.profile_step
(
	profile_id						number(10) not null,
	profile_step_id					number(10) not null,
	parent_step_id					number(10),
	depth							number(10) not null,
	step							varchar2(4000) not null,
	elapsed_ms						number(10) not null,
	constraint pk_profile_step primary key (profile_id, profile_step_id),
	constraint fk_profile_step_parent_id foreign key (profile_id, parent_step_id)
	references aspen2.profile_step (profile_id, profile_step_id),
	constraint fk_profile_step_profile foreign key (profile_id)
	references aspen2.profile (profile_id) on delete cascade
);

create or replace package aspen2.profile_pkg as end;
/

grant execute on aspen2.profile_pkg to web_user;

CREATE TABLE CSR.SHEET_CHANGE_LOG (
    APP_SID      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_ID	 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CHANGE_LOG PRIMARY KEY (APP_SID, SHEET_ID),
    CONSTRAINT FK_SHEET_CHANGE_LOG_SHEET FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET (APP_SID, SHEET_ID)
);

INSERT INTO CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID, DESCRIPTION, PLUGIN_NAME, ONE_AT_A_TIME)
VALUES (18, 'Sheet completeness calculation', 'sheet-completeness', 1);

CREATE TABLE CSR.SHEET_COMPLETENESS_JOB (
    APP_SID      	NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BATCH_JOB_ID    NUMBER(10, 0)    NOT NULL,
    SHEET_ID	 	NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEET_COMPLETENESS_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID, SHEET_ID),
    CONSTRAINT FK_SHEET_COMPLET_JOB_BTCH_JOB FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB (APP_SID, BATCH_JOB_ID),
    CONSTRAINT FK_SHEET_COMPLET_JOB_SHEET FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET (APP_SID, SHEET_ID)
);
CREATE INDEX CSR.IX_SHEET_COMPLETE_JOB_SHEET ON CSR.SHEET_COMPLETENESS_JOB (APP_SID, SHEET_ID);

DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.QueueSheetCompletenessJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.sheet_pkg.QueueCompletenessJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=SECONDLY;INTERVAL=120',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Scan sheet change logs and produce sheet completeness batch jobs');
END;
/

@../batch_job_pkg
@../csr_data_pkg
@../csr_data_body
@../delegation_pkg
@../delegation_body
@../sheet_pkg
@../sheet_body
@../stored_calc_datasource_body
@../../../aspen2/db/profile_pkg
@../../../aspen2/db/profile_body

@update_tail
