-- Please update version.sql too -- this keeps clean builds in sync
define version=531
@update_header

ALTER TABLE doc_folder
	ADD lifespan_override NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE doc_folder
	ADD lifespan NUMBER(10, 0);
ALTER TABLE doc_folder
	ADD approver_override NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE doc_folder
	ADD approver_sid NUMBER(10, 0);

ALTER TABLE DOC_FOLDER ADD CONSTRAINT RefCSR_USER1873 
    FOREIGN KEY (APP_SID, APPROVER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

@update_tail
