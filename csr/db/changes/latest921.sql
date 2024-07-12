-- Please update version.sql too -- this keeps clean builds in sync
define version=921
@update_header

GRANT SELECT, REFERENCES ON mail.account TO csr;


CREATE TABLE CSR.METER_EXCEL_MAPPING(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    RAW_DATA_SOURCE_ID    NUMBER(10, 0)    NOT NULL,
    FIELD_NAME            VARCHAR2(256)    NOT NULL,
    COLUMN_NAME           VARCHAR2(256)    NOT NULL,
    COLUMN_INDEX          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK1203 PRIMARY KEY (APP_SID, RAW_DATA_SOURCE_ID, FIELD_NAME)
)
;

CREATE TABLE CSR.METER_EXCEL_OPTION(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    RAW_DATA_SOURCE_ID    NUMBER(10, 0)    NOT NULL,
    WORKSHEET_INDEX       NUMBER(10, 0)    NOT NULL,
    ROW_INDEX             NUMBER(10, 0)    NOT NULL,
    CSV_DELIMITER         VARCHAR2(1)      NULL,
    CONSTRAINT PK1202 PRIMARY KEY (APP_SID, RAW_DATA_SOURCE_ID)
)
;

CREATE TABLE CSR.METER_XML_OPTION(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    RAW_DATA_SOURCE_ID    NUMBER(10, 0)    NOT NULL,
    DATA_TYPE             VARCHAR2(256)    NOT NULL,
    XSLT                  SYS.XMLType      NOT NULL,
    CONSTRAINT PK1207 PRIMARY KEY (APP_SID, RAW_DATA_SOURCE_ID)
)
;

ALTER TABLE CSR.METER_EXCEL_MAPPING ADD CONSTRAINT RefMETER_EXCEL_OPTION2784 
    FOREIGN KEY (APP_SID, RAW_DATA_SOURCE_ID)
    REFERENCES CSR.METER_EXCEL_OPTION(APP_SID, RAW_DATA_SOURCE_ID)
;

ALTER TABLE CSR.METER_EXCEL_OPTION ADD CONSTRAINT RefMETER_RAW_DATA_SOURCE2785 
    FOREIGN KEY (APP_SID, RAW_DATA_SOURCE_ID)
    REFERENCES CSR.METER_RAW_DATA_SOURCE(APP_SID, RAW_DATA_SOURCE_ID)
;

ALTER TABLE CSR.METER_XML_OPTION ADD CONSTRAINT RefMETER_RAW_DATA_SOURCE2787 
    FOREIGN KEY (APP_SID, RAW_DATA_SOURCE_ID)
    REFERENCES CSR.METER_RAW_DATA_SOURCE(APP_SID, RAW_DATA_SOURCE_ID)
;

CREATE INDEX csr.ix_meter_exl_opt_map ON csr.meter_excel_mapping (app_sid, raw_data_source_id);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'METER_EXCEL_MAPPING',
		policy_name     => 'METER_EXCEL_MAPPING_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
	
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'METER_EXCEL_OPTION',
		policy_name     => 'METER_EXCEL_OPTION_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
		
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'METER_XML_OPTION',
		policy_name     => 'METER_XML_OPTION_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

BEGIN
	UPDATE security.menu
	   SET action = '/csr/site/meter/monitor/dataSource/dataSourceList.acds'
	 WHERE LOWER(action) = '/csr/site/meter/monitor/datasourcelist.acds';
END;
/


@../meter_monitor_pkg
@../meter_monitor_body

@update_tail
