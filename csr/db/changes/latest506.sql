-- Please update version.sql too -- this keeps clean builds in sync
define version=506
@update_header

DROP TABLE NORMALIZATION_IND cascade constraints;

ALTER TABLE DATAVIEW_IND_MEMBER ADD CONSTRAINT RefIND1803 
    FOREIGN KEY (APP_SID, NORMALIZATION_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;
 
@update_tail
