-- Please update version.sql too -- this keeps clean builds in sync
define version=47
@update_header


-- 
-- TABLE: TEMPLATE 
--

CREATE TABLE TEMPLATE(
    TEMPLATE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CSR_ROOT_SID        NUMBER(10, 0)    NOT NULL,
    DATA                BLOB             NOT NULL,
    MIME_TYPE           VARCHAR2(64)     NOT NULL,
    UPLOADED_DTM        DATE              DEFAULT SYSDATE NOT NULL,
    UPLOADED_BY_SID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK206 PRIMARY KEY (TEMPLATE_TYPE_ID, CSR_ROOT_SID)
)
;



-- 
-- TABLE: TEMPLATE_TYPE 
--

CREATE TABLE TEMPLATE_TYPE(
    TEMPLATE_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    NAME                VARCHAR2(255)     NOT NULL,
    MIME_TYPE           VARCHAR2(64)      NOT NULL,
    DEFAULT_DATA        BLOB              NOT NULL,
    DESCRIPTION         VARCHAR2(2048)    NOT NULL,
    CONSTRAINT PK207 PRIMARY KEY (TEMPLATE_TYPE_ID)
)
;



ALTER TABLE TEMPLATE ADD CONSTRAINT RefTEMPLATE_TYPE353 
    FOREIGN KEY (TEMPLATE_TYPE_ID)
    REFERENCES TEMPLATE_TYPE(TEMPLATE_TYPE_ID)
;

ALTER TABLE TEMPLATE ADD CONSTRAINT RefCUSTOMER354 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;

ALTER TABLE TEMPLATE ADD CONSTRAINT RefCSR_USER357 
    FOREIGN KEY (UPLOADED_BY_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;



BEGIN
INSERT INTO TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, default_Data) VALUES ( 1, 'Chart styles', 'text/xml', 'The default chart stylesheet',EMPTY_BLOB());
INSERT INTO TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, default_Data) VALUES ( 2, 'Excel export', 'application/vnd.ms-excel', 'A template for spreadsheet exports',EMPTY_BLOB());
INSERT INTO TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, default_Data) VALUES ( 3, 'Word export', 'application/msword', 'A template for Word exports', EMPTY_BLOB());
END;
/
commit;


@update_tail
