-- Please update version.sql too -- this keeps clean builds in sync
define version=1273
@update_header

/* ---------------------------------------------------------------------- */
/* Tables                                                                 */
/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/* Add table "EXPORT_FEED"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.EXPORT_FEED (
    APP_SID						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
    EXPORT_FEED_SID 			NUMBER(10)		NOT NULL,
    NAME			 			VARCHAR2(100)	NOT NULL,
    PROTOCOL					NUMBER(1)		NOT NULL,
    URL							VARCHAR2(1024) 	NOT NULL,
    USERNAME					VARCHAR2(40) 	NOT NULL,
    INTERVAL					VARCHAR2(2)		NOT NULL,
    START_DTM					DATE			NOT NULL,
    END_DTM						DATE,
    LAST_SUCCESS_ATTEMPT_DTM	DATE,
    LAST_ATTEMPT_DTM			DATE,
    CONSTRAINT PK_EXPORT_FEED PRIMARY KEY (APP_SID, EXPORT_FEED_SID),
    CONSTRAINT CHK_EXPORT_FEED_DTM CHECK ((END_DTM IS NULL) OR (START_DTM < END_DTM))
);

/* ---------------------------------------------------------------------- */
/* Add table "EXPORT_FEED_DATAVIEW"                                       */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.EXPORT_FEED_DATAVIEW (
    APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
    EXPORT_FEED_SID		NUMBER(10)			NOT NULL,
    DATAVIEW_SID		NUMBER(10)			NOT NULL,
    FILENAME_MASK		VARCHAR2(255)		NOT NULL,
    FORMAT				NUMBER(1)			NOT NULL,
    CONSTRAINT PK_DATAVIEW_EXPORT_FEED PRIMARY KEY (APP_SID, EXPORT_FEED_SID, DATAVIEW_SID)
);

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */

ALTER TABLE CSR.EXPORT_FEED_DATAVIEW ADD CONSTRAINT EXP_FEED_DATAVIEW_EXP_FEED 
    FOREIGN KEY (EXPORT_FEED_SID, APP_SID) REFERENCES CSR.EXPORT_FEED (EXPORT_FEED_SID,APP_SID);

ALTER TABLE CSR.EXPORT_FEED_DATAVIEW ADD CONSTRAINT DATAVIEW_DATAVIEW_EXP_FEED 
    FOREIGN KEY (DATAVIEW_SID, APP_SID) REFERENCES CSR.DATAVIEW (DATAVIEW_SID,APP_SID);
 
/* RLS */   
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'EXPORT_FEED',
		policy_name     => 'EXPORT_FEED_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
		
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'EXPORT_FEED_DATAVIEW',
		policy_name     => 'EXPORT_FEED_DATAVIEW_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

create or replace package csr.export_feed_pkg as
	procedure dummy;
end;
/
create or replace package body csr.export_feed_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on csr.export_feed_pkg to web_user;

@..\export_feed_pkg
@..\export_feed_body

@update_tail