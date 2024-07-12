-- Please update version.sql too -- this keeps clean builds in sync
define version=1432
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_sequences
	 where sequence_owner = 'CSR'
	   and sequence_name = 'SECTION_TRANS_COMMENT_ID_SEQ';

	if v_exists = 0 then
		execute immediate 'CREATE SEQUENCE CSR.SECTION_TRANS_COMMENT_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tables
	 where owner='CSR' and table_name = 'SECTION_TRANS_COMMENT';
	 
	if v_exists = 0 then
		execute immediate '
CREATE TABLE CSR.SECTION_TRANS_COMMENT(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
    SECTION_TRANS_COMMENT_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID                 NUMBER(10, 0)    NOT NULL,
    ENTERED_BY_SID              NUMBER(10, 0)    NOT NULL,
    ENTERED_DTM                 DATE             NOT NULL,
    COMMENT_TEXT                CLOB             NOT NULL,
    CONSTRAINT PK_SECTION_TRANS_COMMENT PRIMARY KEY (APP_SID, SECTION_TRANS_COMMENT_ID)
)'
;
		execute immediate '
ALTER TABLE CSR.SECTION_TRANS_COMMENT ADD CONSTRAINT FK_ST_COMMENT_SECTION 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
';

		execute immediate '
ALTER TABLE CSR.SECTION_TRANS_COMMENT ADD CONSTRAINT FK_ST_COMMENT_USER 
    FOREIGN KEY (APP_SID, ENTERED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
';
	end if;
end;
/

@../section_pkg
@../section_body

@update_tail
