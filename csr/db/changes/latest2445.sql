-- Please update version.sql too -- this keeps clean builds in sync
define version=2445
@update_header

ALTER TABLE csr.MODEL ADD (
	LOOKUP_KEY                  VARCHAR2(255)
);
    
CREATE UNIQUE INDEX CSR.IX_MODEL_LOOKUP_KEY ON CSR.MODEL(APP_SID, UPPER(NVL(LOOKUP_KEY, 'MODEL_'||model_sid)));

@..\model_pkg
@..\model_body

@update_tail