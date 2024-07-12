-- Please update version.sql too -- this keeps clean builds in sync
define version=1
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER
grant select,insert on csr.ind_flag to csrimp;
connect csrimp/csrimp@&_CONNECT_IDENTIFIER

CREATE GLOBAL TEMPORARY TABLE IND_FLAG(
    IND_SID          NUMBER(10, 0)    NOT NULL,
    FLAG             NUMBER(10, 0)    NOT NULL,
    DESCRIPTION      VARCHAR2(256)    NOT NULL,
    REQUIRES_NOTE    NUMBER(1, 0)     NOT NULL,
    CONSTRAINT PK105 PRIMARY KEY (IND_SID, FLAG)
)
;

@../imp_body

@update_tail
