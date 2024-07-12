-- Please update version.sql too -- this keeps clean builds in sync
define version=477
@update_header

ALTER TABLE dataview ADD (
	LAST_UPDATED_DTM	DATE,
	LAST_UPDATED_SID	NUMBER(10, 0)
);

UPDATE dataview SET LAST_UPDATED_DTM = SYSDATE;

ALTER TABLE dataview MODIFY LAST_UPDATED_DTM DEFAULT SYSDATE NOT NULL;

ALTER TABLE dataview ADD CONSTRAINT FK_CSR_USER_DATAVIEW 
    FOREIGN KEY (APP_SID, LAST_UPDATED_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

@../dataview_pkg
@../dataview_body

@../gas_pkg
@../gas_body

@../templated_report_pkg
@../templated_report_body

@update_tail
