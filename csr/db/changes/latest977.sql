-- Please update version.sql too -- this keeps clean builds in sync
define version=977
@update_header

CREATE TABLE CSR.RISKS(
    APP_SID        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ORACLE_USER    VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_RISKS PRIMARY KEY (APP_SID)
);

@..\risks_pkg
@..\risks_body

grant execute on csr.risks_pkg to web_user;


@update_tail
