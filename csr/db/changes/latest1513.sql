-- Please update version.sql too -- this keeps clean builds in sync
define version=1513
@update_header

-- Fine to run/skip on live, tables already exist
declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_tables
	 where owner='CSR' and table_name='EXPORT_FEED';
	 
	if v_exists = 0 then
		execute immediate '
		CREATE TABLE CSR.EXPORT_FEED (
			APP_SID						NUMBER(10)		DEFAULT sys_context(''security'',''app'') NOT NULL,
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
		)';
						
		dbms_rls.add_policy(
			object_schema   => 'CSR',
			object_name     => 'EXPORT_FEED',
			policy_name     => 'EXPORT_FEED_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive );
	end if;
	
	select count(*)
	  into v_exists
	  from all_tables
	 where owner='CSR' and table_name='EXPORT_FEED_DATAVIEW';
	 
	if v_exists = 0 then
		execute immediate 'CREATE TABLE CSR.EXPORT_FEED_DATAVIEW (
					    APP_SID				NUMBER(10)			DEFAULT sys_context(''security'',''app'') NOT NULL,
					    EXPORT_FEED_SID		NUMBER(10)			NOT NULL,
					    DATAVIEW_SID		NUMBER(10)			NOT NULL,
					    FILENAME_MASK		VARCHAR2(255)		NOT NULL,
					    FORMAT				NUMBER(1)			NOT NULL,
					    CONSTRAINT PK_DATAVIEW_EXPORT_FEED PRIMARY KEY (APP_SID, EXPORT_FEED_SID, DATAVIEW_SID)
					)';
		
		execute immediate 'ALTER TABLE CSR.EXPORT_FEED_DATAVIEW ADD CONSTRAINT EXP_FEED_DATAVIEW_EXP_FEED 
							FOREIGN KEY (EXPORT_FEED_SID, APP_SID) REFERENCES CSR.EXPORT_FEED (EXPORT_FEED_SID,APP_SID)';

		execute immediate 'ALTER TABLE CSR.EXPORT_FEED_DATAVIEW ADD CONSTRAINT DATAVIEW_DATAVIEW_EXP_FEED 
							FOREIGN KEY (DATAVIEW_SID, APP_SID) REFERENCES CSR.DATAVIEW (DATAVIEW_SID,APP_SID)';
		
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'EXPORT_FEED_DATAVIEW',
		policy_name     => 'EXPORT_FEED_DATAVIEW_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
	end if;
end;
/ 

@update_tail