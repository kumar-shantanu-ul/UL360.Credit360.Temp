-- Please update version.sql too -- this keeps clean builds in sync
define version=1144
@update_header

CREATE GLOBAL TEMPORARY TABLE CSRIMP.IND_DESCRIPTION(
    IND_SID                       NUMBER(10, 0)     NOT NULL,
    LANG					 	  VARCHAR2(10)      NOT NULL,
    DESCRIPTION				 	  VARCHAR2(1023)	NOT NULL,
    CONSTRAINT PK_IND_DESCRIPTION PRIMARY KEY (IND_SID, LANG)
) ON COMMIT DELETE ROWS
;

grant select,insert,update,delete on csr.ind_description to csrimp;

@../csrimp/imp_body

@update_tail
