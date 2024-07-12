-- Please update version.sql too -- this keeps clean builds in sync
define version=36
@update_header

ALTER TABLE SCHEME ADD (
    DESCRIPTION         VARCHAR2(2048)
);
  
-- 
-- TABLE: SCHEME_DONATION_STATUS 
--
CREATE TABLE SCHEME_DONATION_STATUS(
    SCHEME_SID             NUMBER(10, 0)    NOT NULL,
    DONATION_STATUS_SID    NUMBER(10, 0)    NOT NULL,
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CONSTRAINT PK102 PRIMARY KEY (SCHEME_SID, DONATION_STATUS_SID, APP_SID)
)
;

 
-- 
-- TABLE: SCHEME_DONATION_STATUS 
--
ALTER TABLE SCHEME_DONATION_STATUS ADD CONSTRAINT RefDONATION_STATUS156 
    FOREIGN KEY (APP_SID, DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(APP_SID, DONATION_STATUS_SID)
;

ALTER TABLE SCHEME_DONATION_STATUS ADD CONSTRAINT RefSCHEME157 
    FOREIGN KEY (APP_SID, SCHEME_SID)
    REFERENCES SCHEME(APP_SID, SCHEME_SID)
;


INSERT INTO scheme_donation_status 
    (scheme_sid, donation_status_sid, app_sid)
    SELECT scheme_sid, donation_status_sid, s.app_sid
      FROM donation_status ds, scheme s
     WHERE ds.app_sid = s.app_sid;

commit;    

@../fields_body
@../scheme_pkg
@../scheme_body
@../status_pkg
@../status_body



@@../rls

@update_tail
