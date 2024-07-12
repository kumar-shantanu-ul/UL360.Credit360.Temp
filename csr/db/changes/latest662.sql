-- Please update version.sql too -- this keeps clean builds in sync
define version=662
@update_header

CREATE OR REPLACE TYPE csr.T_EDIEL_ERROR_ROW AS
	OBJECT (
		POS				NUMBER(10, 0),
		MSG				VARCHAR(4000),
		DTM				DATE
	);
/
GRANT EXECUTE ON csr.T_EDIEL_ERROR_ROW TO PUBLIC;

CREATE OR REPLACE TYPE csr.T_EDIEL_ERROR_TABLE AS
	TABLE OF csr.T_EDIEL_ERROR_ROW;
/

CREATE SEQUENCE csr.METER_RAW_DATA_ERROR_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.METER_ORPHAN_DATA(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SERIAL_ID             VARCHAR2(256)     NOT NULL,
    START_DTM             DATE              NOT NULL,
    METER_RAW_DATA_ID     NUMBER(10, 0)     NOT NULL,
    END_DTM               DATE              NOT NULL,
    CONSUMPTION           NUMBER(24, 10)    NOT NULL,
    RELATED_LOCATION_1    VARCHAR2(256),
    RELATED_LOCATION_2    VARCHAR2(256),
    CONSTRAINT PK930 PRIMARY KEY (APP_SID, SERIAL_ID, START_DTM)
)
;

ALTER TABLE csr.METER_RAW_DATA ADD (
	STATUS_ID             NUMBER(10, 0)    NOT NULL,
	MESSAGE_UID           NUMBER(10, 0)
)
;

ALTER TABLE csr.METER_RAW_DATA MODIFY (
	START_DTM			  DATE			   NULL,
	END_DTM				  DATE			   NULL
)
;

CREATE TABLE csr.METER_RAW_DATA_ERROR(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_RAW_DATA_ID    NUMBER(10, 0)     NOT NULL,
    ERROR_ID             NUMBER(10, 0)     NOT NULL,
    MESSAGE              VARCHAR2(4000)    NOT NULL,
    RAISED_DTM           DATE     		   DEFAULT SYSDATE NOT NULL,
    DATA_DTM             DATE,
    CONSTRAINT PK931 PRIMARY KEY (APP_SID, METER_RAW_DATA_ID, ERROR_ID)
)
;

ALTER TABLE csr.METER_RAW_DATA_SOURCE ADD (
	HELPER_PKG            VARCHAR2(256)     DEFAULT 'meter_monitor_pkg' NOT NULL
)
;

CREATE TABLE csr.METER_RAW_DATA_STATUS(
    STATUS_ID          NUMBER(10, 0)    NOT NULL,
    DESCRIPTION        VARCHAR2(256)    NOT NULL,
    NEEDS_PROCESSING    NUMBER(1, 0)    DEFAULT 1 NOT NULL,
    CHECK (needs_processing IN(0,1)),
    CONSTRAINT PK932 PRIMARY KEY (STATUS_ID)
)
;

CREATE INDEX csr.IDX_ORPHAN_SERIAL ON csr.METER_ORPHAN_DATA(APP_SID, SERIAL_ID)
;

CREATE INDEX csr.IDX_ORPHAN_RAW_DATA_ID ON csr.METER_ORPHAN_DATA(APP_SID, METER_RAW_DATA_ID)
;

CREATE INDEX csr.IDX_ORPHAN_DATE_RANGE ON csr.METER_ORPHAN_DATA(APP_SID, START_DTM, END_DTM)
;

CREATE INDEX csr.IDX_ORPHAN_SOURCE_DATE_RANGE ON csr.METER_ORPHAN_DATA(APP_SID, METER_RAW_DATA_ID, START_DTM, END_DTM)
;

CREATE INDEX csr.IDX_RAW_DATA_SOURCE_ID ON csr.METER_RAW_DATA(APP_SID, RAW_DATA_SOURCE_ID)
;

CREATE INDEX csr.IDX_RAW_DATA_SOURCE_STATUS_ID ON csr.METER_RAW_DATA(APP_SID, RAW_DATA_SOURCE_ID, STATUS_ID)
;

CREATE INDEX csr.IDX_RAW_DATA_STATUS_ID ON csr.METER_RAW_DATA(APP_SID, STATUS_ID)
;

CREATE INDEX csr.IDX_RAW_DATA_ERROR_ID ON csr.METER_RAW_DATA_ERROR(APP_SID, ERROR_ID)
;

CREATE INDEX csr.IDX_RAW_DATA_ERROR_SOURCE_ID ON csr.METER_RAW_DATA_ERROR(APP_SID, METER_RAW_DATA_ID)
;

ALTER TABLE csr.METER_ORPHAN_DATA ADD CONSTRAINT RefMETER_RAW_DATA2053 
    FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
    REFERENCES csr.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;

ALTER TABLE csr.METER_ORPHAN_DATA ADD CONSTRAINT RefCUSTOMER2054 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.METER_RAW_DATA ADD CONSTRAINT RefMETER_RAW_DATA_STATUS2055 
    FOREIGN KEY (STATUS_ID)
    REFERENCES csr.METER_RAW_DATA_STATUS(STATUS_ID)
;

ALTER TABLE csr.METER_RAW_DATA_ERROR ADD CONSTRAINT RefMETER_RAW_DATA2056 
    FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
    REFERENCES csr.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;

CREATE GLOBAL TEMPORARY TABLE csr.LIVE_METER_RAW_PROC
(
	METER_RAW_DATA_ID				NUMBER(10)	NOT NULL,
	POS								NUMBER(10)
) ON COMMIT DELETE ROWS;


BEGIN
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'METER_RAW_DATA_ERROR',
        policy_name     => 'METER_RAW_DATA_ERROR_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );

	dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'METER_ORPHAN_DATA',
        policy_name     => 'METER_ORPHAN_DATA_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
END;
/

-- Insert satate data
BEGIN
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(1, 'New', 1);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(2, 'Retry', 1);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(3, 'Processing', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(4, 'Has errors', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(5, 'Success', 0);
	COMMIT;
END;
/

-- Add mail grants
connect mail/mail@&_CONNECT_IDENTIFIER;
grant execute ON mail_pkg to csr;
grant select, REFERENCES ON mail.message to csr;
connect csr/csr@&_CONNECT_IDENTIFIER;

-- Rebuild mail monitor pkg
@../meter_monitor_pkg
@../meter_monitor_body

@update_tail
