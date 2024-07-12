-- Please update version.sql too -- this keeps clean builds in sync
define version=830
@update_header

CREATE TABLE CSR.LOGISTICS_PROCESSOR_CLASS(
    PROCESSOR_CLASS_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                 VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_LOGISTICS_PROCESSOR_CLASS PRIMARY KEY (PROCESSOR_CLASS_ID)
);

BEGIN
	INSERT INTO csr.logistics_processor_class (processor_class_id, label) VALUES (1, 'Logistics.Modes.AirportJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id, label) VALUES (2, 'Logistics.Modes.AirCountryJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id, label) VALUES (3, 'Logistics.Modes.RoadJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id, label) VALUES (4, 'Logistics.Modes.SeaJobProcessor');
END;
/

ALTER TABLE csr.logistics_error_log ADD PROCESSOR_CLASS_ID NUMBER(10, 0) DEFAULT 1 NOT NULL;

BEGIN
	UPDATE csr.logistics_error_log SET processor_class_id = 1 WHERE processor_class = 'Logistics.Modes.AirportJobProcessor';
	UPDATE csr.logistics_error_log SET processor_class_id = 2 WHERE processor_class = 'Logistics.Modes.AirCountryJobProcessor';
	UPDATE csr.logistics_error_log SET processor_class_id = 3 WHERE processor_class = 'Logistics.Modes.RoadJobProcessor';
	UPDATE csr.logistics_error_log SET processor_class_id = 4 WHERE processor_class = 'Logistics.Modes.SeaJobProcessor';
END;
/

ALTER TABLE csr.logistics_error_log MODIFY PROCESSOR_CLASS_ID NUMBER(10, 0);

ALTER TABLE csr.logistics_error_log DROP COLUMN processor_class CASCADE CONSTRAINTS;

ALTER TABLE CSR.LOGISTICS_ERROR_LOG ADD CONSTRAINT FK_LOGISTICS_PROC_ERR_CLASS 
    FOREIGN KEY (PROCESSOR_CLASS_ID)
    REFERENCES CSR.LOGISTICS_PROCESSOR_CLASS(PROCESSOR_CLASS_ID)
;

ALTER TABLE CSR.LOGISTICS_ERROR_LOG ADD CONSTRAINT FK_TAB_LOGISTICS_ERR_LOG
	FOREIGN KEY (APP_SID, TAB_SID)
	REFERENCES CMS.TAB(APP_SID, TAB_SID)
;

ALTER TABLE csr.logistics_tab_mode DROP CONSTRAINT FK_LOG_DEFLT_LOG_TAB_TYPE;

ALTER TABLE csr.logistics_tab_mode DROP PRIMARY KEY;

ALTER TABLE csr.logistics_tab_mode ADD PROCESSOR_CLASS_ID NUMBER(10, 0) DEFAULT 1 NOT NULL;

BEGIN
	UPDATE csr.logistics_tab_mode SET processor_class_id = 1 WHERE processor_class = 'Logistics.Modes.AirportJobProcessor';
	UPDATE csr.logistics_tab_mode SET processor_class_id = 2 WHERE processor_class = 'Logistics.Modes.AirCountryJobProcessor';
	UPDATE csr.logistics_tab_mode SET processor_class_id = 3 WHERE processor_class = 'Logistics.Modes.RoadJobProcessor';
	UPDATE csr.logistics_tab_mode SET processor_class_id = 4 WHERE processor_class = 'Logistics.Modes.SeaJobProcessor';
END;
/

ALTER TABLE csr.logistics_tab_mode MODIFY PROCESSOR_CLASS_ID NUMBER(10, 0);

ALTER TABLE csr.logistics_tab_mode DROP COLUMN processor_class CASCADE CONSTRAINTS;

ALTER TABLE CSR.LOGISTICS_TAB_MODE ADD CONSTRAINT FK_LOGISTICS_PROC_TAB_MODE 
    FOREIGN KEY (PROCESSOR_CLASS_ID)
    REFERENCES CSR.LOGISTICS_PROCESSOR_CLASS(PROCESSOR_CLASS_ID)
;

ALTER TABLE csr.logistics_tab_mode ADD CONSTRAINT PK_LOGISTICS_TAB_MODE PRIMARY KEY (APP_SID, TAB_SID, PROCESSOR_CLASS_ID, START_JOB_SP);

@update_tail
