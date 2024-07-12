-- Please update version.sql too -- this keeps clean builds in sync
define version=1403
@update_header

CREATE SEQUENCE CSR.IND_SET_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.IND_SET(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    IND_SET_ID       NUMBER(10, 0)    NOT NULL,
    OWNER_SID        NUMBER(10, 0),
    NAME             VARCHAR2(255)    NOT NULL,
    DISPOSAL_DTM     DATE,
    CONSTRAINT PK_IND_SET PRIMARY KEY (APP_SID, IND_SET_ID)
)
;

CREATE TABLE CSR.IND_SET_IND(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    IND_SET_ID       NUMBER(10, 0)    NOT NULL,
    IND_SID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_IND_SET_IND PRIMARY KEY (APP_SID, IND_SET_ID, IND_SID)
)
;

ALTER TABLE CSR.IND_SET ADD CONSTRAINT FK_IND_SET_OWNER 
    FOREIGN KEY (APP_SID, OWNER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.IND_SET_IND ADD CONSTRAINT FK_IND_SET_IND_IND
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.IND_SET_IND ADD CONSTRAINT FK_IND_SET_IND_IND_SET
    FOREIGN KEY (APP_SID, IND_SET_ID)
    REFERENCES CSR.IND_SET(APP_SID, IND_SET_ID)
;

create or replace package csr.indicator_set_pkg as
	procedure dummy;
end;
/
create or replace package body csr.indicator_set_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on csr.indicator_set_pkg to web_user;



-- don't forget to run rls too
@..\indicator_set_pkg
@..\indicator_set_body

@update_tail
