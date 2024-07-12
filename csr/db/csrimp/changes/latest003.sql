-- Please update version.sql too -- this keeps clean builds in sync
define version=3
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER
grant select,insert on csr.calc_dependency to csrimp;
connect csrimp/csrimp@&_CONNECT_IDENTIFIER

CREATE GLOBAL TEMPORARY TABLE CALC_DEPENDENCY(
    IND_SID         NUMBER(10, 0)    NOT NULL,
    CALC_IND_SID    NUMBER(10, 0)    NOT NULL,
    DEP_TYPE        NUMBER(10, 0)    DEFAULT (1) NOT NULL,
    CONSTRAINT PK_CALC_DEPENDENCY PRIMARY KEY (IND_SID, CALC_IND_SID, DEP_TYPE)
)
;

connect csr/csr@&_CONNECT_IDENTIFIER
@../../schema_pkg
@../../schema_body
connect csrimp/csrimp@&_CONNECT_IDENTIFIER

@../imp_body

@update_tail
