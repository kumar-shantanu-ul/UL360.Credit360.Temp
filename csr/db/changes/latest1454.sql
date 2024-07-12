-- Please update version.sql too -- this keeps clean builds in sync
define version=1454
@update_header

ALTER TABLE CSR.TAG_GROUP_MEMBER ADD (
	ACTIVE				NUMBER(1)		DEFAULT 1 NOT NULL
	CONSTRAINT CHK_TAG_GRP_MEM_ACTIVE CHECK ( ACTIVE IN (0,1))
);

/* ---------------------------------------------------------------------- */
/* Sequences                                                              */
/* ---------------------------------------------------------------------- */

CREATE SEQUENCE CSR.IMPORT_FEED_REQUEST_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	nocycle
	CACHE 5
	noorder;

/* ---------------------------------------------------------------------- */
/* Tables                                                                 */
/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/* Add table "IMPORT_FEED"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.IMPORT_FEED (
	APP_SID 			NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
	IMPORT_FEED_SID 	NUMBER(10)		NOT NULL,
	NAME 				VARCHAR2(40) 	NOT NULL,
	CONSTRAINT PK_IMPORT_FEED PRIMARY KEY (APP_SID, IMPORT_FEED_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "IMPORT_FEED_REQUEST"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.IMPORT_FEED_REQUEST (
	APP_SID 				NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
	IMPORT_FEED_SID 		NUMBER(10) 		NOT NULL,
	IMPORT_FEED_REQUEST_ID 	NUMBER(10)		NOT NULL,
	FILE_DATA 				BLOB 			NOT NULL,
	FILENAME 				VARCHAR2(1024)	NOT NULL,
	MIME_TYPE				VARCHAR2(1024)	NOT NULL,
	CREATED_DTM				DATE			NOT NULL,
	PROCESSED_DTM			DATE 			NOT NULL,
	FAILED_DATA 			BLOB,
	FAILED_FILENAME			VARCHAR2(1024),
	FAILED_MIME_TYPE 		VARCHAR2(1024),
	ROWS_IMPORTED NUMBER(10),
	ROWS_UPDATED NUMBER(10),
	ERRORS VARCHAR2(1024),
	CONSTRAINT PK_IMPORT_FEED_REQUEST PRIMARY KEY (APP_SID, IMPORT_FEED_SID, IMPORT_FEED_REQUEST_ID)
);

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */

ALTER TABLE CSR.IMPORT_FEED_REQUEST ADD CONSTRAINT IMP_FEED_IMP_FEED_REQUEST 
	FOREIGN KEY (APP_SID, IMPORT_FEED_SID) REFERENCES CSR.IMPORT_FEED (APP_SID,IMPORT_FEED_SID);
	
/* RLS */   
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'IMPORT_FEED',
		policy_name     => 'IMPORT_FEED_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
		
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'IMPORT_FEED_REQUEST',
		policy_name     => 'IMPORT_FEED_REQUEST_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

create or replace package csr.import_feed_pkg as
	procedure dummy;
end;
/
create or replace package body csr.import_feed_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on csr.import_feed_pkg to web_user;
grant execute on csr.import_feed_pkg to cms;

@..\import_feed_pkg
@..\import_feed_body

@..\tag_pkg
@..\tag_body

@..\strategy_body

@update_tail