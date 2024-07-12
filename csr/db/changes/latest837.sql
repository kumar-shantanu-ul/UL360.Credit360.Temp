-- Please update version.sql too -- this keeps clean builds in sync
define version=837
@update_header

ALTER TABLE csr.logistics_error_log DROP CONSTRAINT LOGISTICS_TAB_MODE_ERROR_LOG;

ALTER TABLE csr.logistics_tab_mode DROP PRIMARY KEY DROP INDEX;

ALTER TABLE csr.logistics_tab_mode ADD CONSTRAINT PK_LOGISTICS_TAB_MODE PRIMARY KEY (APP_SID, TAB_SID, PROCESSOR_CLASS_ID);

ALTER TABLE CSR.LOGISTICS_ERROR_LOG ADD CONSTRAINT LOGISTICS_TAB_MODE_ERROR_LOG 
    FOREIGN KEY (APP_SID, TAB_SID, PROCESSOR_CLASS_ID)
    REFERENCES CSR.LOGISTICS_TAB_MODE(APP_SID, TAB_SID, PROCESSOR_CLASS_ID)
;

INSERT INTO csr.logistics_processor_class (processor_class_id, label)
	VALUES (5, 'Logistics.Modes.BargeJobProcessor');

INSERT INTO csr.logistics_processor_class (processor_class_id, label)
	VALUES (6, 'Logistics.Modes.RailJobProcessor');

UPDATE csr.logistics_tab_mode
   SET processor_class_id = 6
 WHERE transport_mode_id = 5;

@update_tail
