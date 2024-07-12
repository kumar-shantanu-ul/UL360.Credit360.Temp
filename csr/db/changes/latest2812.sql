-- Please update version.sql too -- this keeps clean builds in sync
define version=2812
define minor_version=0
@update_header

declare
	v_ver number;
begin
	select db_version into v_ver from security.version;
	if v_ver NOT IN (49, 50) then
		raise_application_error(-20001, 'Security schema is not version 49 or 50');
	end if;
end;
/

declare
	v_cnt number;
begin
	select count(*) into v_cnt from all_tables where owner='SECURITY' and table_name='TOOL_LOG';
	if v_cnt = 0 then
		execute immediate '
CREATE TABLE SECURITY.TOOL_LOG(
    TOOL_LOG_ID    NUMBER(10, 0)     NOT NULL,
    DTM            DATE              DEFAULT SYSDATE NOT NULL,
    TOOL_NAME      VARCHAR2(4000)    NOT NULL,
    USER_NAME      VARCHAR2(4000)    NOT NULL,
    CONSTRAINT PK_TOOL_LOG PRIMARY KEY (TOOL_LOG_ID)
)';
	end if;

	select count(*) into v_cnt from all_tables where owner='SECURITY' and table_name='TOOL_LOG_ENTRY';
	if v_cnt = 0 then
		execute immediate '
CREATE TABLE SECURITY.TOOL_LOG_ENTRY(
    TOOL_LOG_ID          NUMBER(10, 0)     NOT NULL,
    TOOL_LOG_ENTRY_ID    NUMBER(10, 0)     NOT NULL,
    DTM                  DATE              DEFAULT SYSDATE NOT NULL,
    MSG                  VARCHAR2(4000)    NOT NULL,
    CONSTRAINT PK_TOOL_LOG_ENTRY PRIMARY KEY (TOOL_LOG_ID, TOOL_LOG_ENTRY_ID)
)'
;
	end if;
	select count(*) into v_cnt from all_sequences where sequence_owner='SECURITY' and sequence_name='TOOL_LOG_ID_SEQ';
	if v_cnt = 0 then
		execute immediate 'CREATE SEQUENCE security.tool_log_id_seq START WITH 1';
	end if;
	
	select count(*) into v_cnt from all_sequences where sequence_owner='SECURITY' and sequence_name='TOOL_LOG_ENTRY_ID_SEQ';
	if v_cnt = 0 then
		execute immediate 'CREATE SEQUENCE security.tool_log_entry_id_seq START WITH 1';
	end if;
end;
/

@..\..\..\security\db\oracle\tools_pkg
@..\..\..\security\db\oracle\tools_body

@update_tail
