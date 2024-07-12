-- Please update version.sql too -- this keeps clean builds in sync
define version=217
@update_header

-- these are set by the create script so this tidies up any such problems

-- was: CREATE UNIQUE INDEX IX_PENDING_REG_PARENT_REG ON PENDING_REGION(PARENT_REGION_ID) TABLESPACE INDX
-- but parent_region_id is not unique
begin
	for r in (select * from user_indexes where index_name = 'IX_PENDING_REG_PARENT_REG') loop
		execute immediate 'drop index IX_PENDING_REG_PARENT_REG';
	end loop;
end;
/

begin
	for r in (select * from user_tab_columns where table_name='AUDIT_LOG' and column_name='OBJECT_SID' and nullable='N') loop
		execute immediate 'alter table audit_log modify object_sid null';
	end loop;
end;
/

ALTER TABLE ATTACHMENT ADD (EMBED NUMBER(1, 0)     DEFAULT 0 NOT NULL);

ALTER TABLE SECTION ADD (
    PLUGIN                        VARCHAR2(255),
    PLUGIN_CONFIG                 SYS.XMLType
);


@update_tail