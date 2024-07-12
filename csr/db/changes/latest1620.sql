-- Please update version.sql too -- this keeps clean builds in sync
define version=1620
@update_header


CREATE TABLE CHAIN.URL_OVERRIDES(
    APP_SID          NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    HOST             VARCHAR2(1000)    NOT NULL,
    KEY              VARCHAR2(100)     NOT NULL,
    SITE_NAME        VARCHAR2(200),
    SUPPORT_EMAIL    VARCHAR2(255),
    CONSTRAINT PK_URL_OVERRIDES PRIMARY KEY (APP_SID, HOST)
);

ALTER TABLE CHAIN.URL_OVERRIDES ADD CONSTRAINT FK_CO_URL_OVERRIDES 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID);

BEGIN
	UPDATE csr.portlet 
	   SET name = 'Invitation Summary'
	 WHERE portlet_id = 543;  --previous: 'Maersk Invitation Summary'
END;
/


@..\chain\helper_pkg

@..\chain\helper_body
@..\chain\invitation_body
@..\chain\newsflash_body

@update_tail

