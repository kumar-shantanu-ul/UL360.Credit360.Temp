-- Please update version.sql too -- this keeps clean builds in sync
define version=2750
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSR.SCHEDULED_STORED_PROC (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SP					VARCHAR2(255)     NOT NULL,
	ARGS				VARCHAR2(1024),
	DESCRIPTION			VARCHAR2(1024),
	INTRVAL				CHAR NOT NULL,
	FREQUENCY			NUMBER(10, 0)	NOT NULL,
	LAST_RUN_DTM		TIMESTAMP,
	LAST_RESULT			NUMBER(10, 0),
	LAST_RESULT_MSG		VARCHAR2(1024),
	LAST_RESULT_EX		CLOB,
	NEXT_RUN_DTM		TIMESTAMP	DEFAULT TRUNC(SYSDATE, 'MI') NOT NULL,
	CONSTRAINT PK_SSP PRIMARY KEY (APP_SID, SP, ARGS)
);

CREATE TABLE CSRIMP.SCHEDULED_STORED_PROC (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SP					VARCHAR2(255)     NOT NULL,
	ARGS				VARCHAR2(1024),
	DESCRIPTION			VARCHAR2(1024),
	INTRVAL				CHAR NOT NULL, 
	FREQUENCY			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SSP PRIMARY KEY (CSRIMP_SESSION_ID, SP, ARGS)
);

CREATE GLOBAL TEMPORARY TABLE CMS.TEMP_TREE_PATH
(
	T_NAME			VARCHAR2(256),
	ID				NUMBER(10),
	DESCRIPTION		VARCHAR2(1023),
	PATH			VARCHAR2(4000)
) ON COMMIT DELETE ROWS;

-- Alter tables

alter table csr.trainer add company varchar2(255);
alter table csr.trainer add address varchar2(2000);
alter table csr.trainer add contact_details varchar2(255);
alter table csr.trainer add notes varchar2(2000);

-- *** Grants ***
create or replace package csr.ssp_pkg as
procedure dummy;
end;
/
create or replace package body csr.ssp_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON csr.ssp_pkg TO web_user;
grant select, insert on csr.scheduled_stored_proc to csrimp;
-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../csrimp/imp_pkg
@../schema_pkg
@../ssp_pkg

@../csrimp/imp_body
@../schema_body
@../ssp_body
@../imp_body

@../region_tree_pkg
@../region_tree_body

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		  job_name            => 'csr.RunClientSPs',
		  job_type            => 'PLSQL_BLOCK',
		  job_action          => 'BEGIN csr.ssp_pkg.RunScheduledStoredProcs(); END;',
		  job_class           => 'low_priority_job',
		  repeat_interval     => 'FREQ=MINUTELY;INTERVAL=15;',
		  enabled             => TRUE,
		  auto_drop           => FALSE,
		  start_date          => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		  comments            => 'Run client store procedures');
END;
/

@update_tail
