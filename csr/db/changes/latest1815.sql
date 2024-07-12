-- Please update version.sql too -- this keeps clean builds in sync
define version=1815
@update_header


	
CREATE TABLE CSR.EXPORT_FEED_STORED_PROC (
    APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
    EXPORT_FEED_SID		NUMBER(10)			NOT NULL,
    SP_NAME		    	VARCHAR2(100)		NOT NULL,
    SP_PARAMS			VARCHAR2(255)		NOT NULL,
    FILENAME_MASK		VARCHAR2(255)		NOT NULL,
    FORMAT				NUMBER(1)			NOT NULL
);


ALTER TABLE CSR.EXPORT_FEED_STORED_PROC ADD CONSTRAINT FK_EXP_FEED_STORED_PROC
    FOREIGN KEY (EXPORT_FEED_SID, APP_SID) REFERENCES CSR.EXPORT_FEED (EXPORT_FEED_SID,APP_SID);

begin
dbms_rls.add_policy(
	object_schema   => 'CSR',
	object_name     => 'EXPORT_FEED_STORED_PROC',
	policy_name     => 'EXPORT_FEED_STORED_PROC_POLICY',
	function_schema => 'CSR',
	policy_function => 'appSidCheck',
	statement_types => 'select, insert, update, delete',
	update_check	=> true,
	policy_type     => dbms_rls.context_sensitive );

end;
/


@update_tail
