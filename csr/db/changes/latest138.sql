-- Please update version.sql too -- this keeps clean builds in sync
define version=138
@update_header

-- 
-- TABLE: REGION_ROLE_MEMBER 
--

CREATE TABLE REGION_ROLE_MEMBER(
    ROLE_ID       NUMBER(10, 0)    NOT NULL,
    USER_SID      NUMBER(10, 0)    NOT NULL,
    REGION_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REGION_ROLE_MEMBER PRIMARY KEY (ROLE_ID, USER_SID, REGION_SID)
)
;

-- 
-- TABLE: ROLE 
--
CREATE TABLE ROLE(
    ROLE_ID         NUMBER(10, 0)    NOT NULL,
    CSR_ROOT_SID    NUMBER(10, 0)    NOT NULL,
    NAME            VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_ROLE PRIMARY KEY (ROLE_ID)
)
;

-- 
-- TABLE: REGION_ROLE_MEMBER 
--
ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefREGION763 
    FOREIGN KEY (REGION_SID)
    REFERENCES REGION(REGION_SID)
;

ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefROLE764 
    FOREIGN KEY (ROLE_ID)
    REFERENCES ROLE(ROLE_ID)
;

ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefCSR_USER765 
    FOREIGN KEY (USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;


-- 
-- TABLE: ROLE 
--
ALTER TABLE ROLE ADD CONSTRAINT RefCUSTOMER766 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;

CREATE SEQUENCE ROLE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;


@update_tail
