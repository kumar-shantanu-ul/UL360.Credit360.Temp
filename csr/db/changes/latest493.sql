-- Please update version.sql too -- this keeps clean builds in sync
define version=493
@update_header

ALTER TABLE factor
	ADD ORIGINAL_FACTOR_ID NUMBER(10, 0);

ALTER TABLE CSR.FACTOR ADD CONSTRAINT RefFACTOR1735 
    FOREIGN KEY (APP_SID, ORIGINAL_FACTOR_ID)
    REFERENCES CSR.FACTOR(APP_SID, FACTOR_ID)
;

@update_tail
