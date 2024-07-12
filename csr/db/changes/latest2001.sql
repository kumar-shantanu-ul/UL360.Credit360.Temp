-- Please update version.sql too -- this keeps clean builds in sync
define version=2001
@update_header


alter table csr.issue_rag_status rename to rag_status;
alter table csr.rag_status rename CONSTRAINT PK_ISSUE_RAG_STATUS TO PK_RAG_STATUS;

DROP TABLE CSRIMP.ISSUE_RAG_STATUS PURGE;

CREATE TABLE CSRIMP.RAG_STATUS(
    CSRIMP_SESSION_ID   NUMBER(10)      DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    RAG_STATUS_ID       NUMBER(10, 0)    NOT NULL,
    COLOUR              NUMBER(10, 0)    NOT NULL,
    LABEL               VARCHAR2(255)    NOT NULL,
    LOOKUP_KEY          VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_RAG_STATUS PRIMARY KEY (CSRIMP_SESSION_ID, RAG_STATUS_ID),    
    CONSTRAINT FK_RAG_STATUS_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

DROP TABLE CSRIMP.MAP_ISSUE_RAG_STATUS PURGE;

CREATE TABLE csrimp.map_rag_status (
    CSRIMP_SESSION_ID           NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_rag_status_id           NUMBER(10) NOT NULL,
    new_rag_status_id           NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_rag_status PRIMARY KEY (old_rag_status_id) USING INDEX,
    CONSTRAINT uk_map_rag_status UNIQUE (new_rag_status_id) USING INDEX,
    CONSTRAINT FK_MAP_RAG_STATUS_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

DROP SEQUENCE CSR.ISSUE_RAG_STATUS_ID_SEQ;

CREATE SEQUENCE CSR.RAG_STATUS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

grant select on csr.rag_status_id_seq to csrimp;
grant insert on csr.rag_status to csrimp;

CREATE OR REPLACE VIEW csr.V$issue_type_rag_status AS  
    SELECT itrs.app_sid, itrs.issue_type_id, itrs.rag_status_id, itrs.pos, irs.colour, irs.label, irs.lookup_key
      FROM issue_type_rag_status itrs 
      JOIN rag_status irs ON itrs.rag_status_id = irs.rag_status_id AND itrs.app_sid = irs.app_sid;

@..\schema_pkg

@..\issue_body
@..\schema_body
@..\csrimp\imp_body

@update_tail