-- Please update version.sql too -- this keeps clean builds in sync
define version=1498
@update_header

CREATE TABLE CSRIMP.TRANSLATION_APPLICATION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BASE_LANG          				VARCHAR2(10)     NOT NULL,
    CONSTRAINT FK_TRANSLATION_APP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


GRANT SELECT,REFERENCES ON aspen2.translation_application TO csr;
grant insert,select,update,delete on csrimp.translation_application to web_user;

@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body


@update_tail
