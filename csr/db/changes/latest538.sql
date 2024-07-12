-- Please update version.sql too -- this keeps clean builds in sync
define version=538
@update_header

CREATE TABLE POSTIT(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    LABEL             VARCHAR2(1024),
    POSTIT_ID         NUMBER(10, 0)     NOT NULL,
    MESSAGE           CLOB               NULL,
    CREATED_DTM       DATE              DEFAULT SYSDATE NOT NULL,
    CREATED_BY_SID    NUMBER(10, 0)     NOT NULL,
    SECURED_VIA_SID   NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_POSTIT PRIMARY KEY (APP_SID, POSTIT_ID)
)
;

CREATE TABLE CSR.POSTIT_FILE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    POSTIT_FILE_ID    	  NUMBER(10, 0)    NOT NULL,
    POSTIT_ID             NUMBER(10, 0)    NOT NULL,
    FILENAME              VARCHAR2(255)    NOT NULL,
    MIME_TYPE             VARCHAR2(256)    NOT NULL,
    DATA                  BLOB             NOT NULL,
    SHA1                  RAW(20)          NOT NULL,
    UPLOADED_DTM          DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_POSTIT_FILE PRIMARY KEY (APP_SID, POSTIT_FILE_ID)
)
;


DROP TABLE DELEGATION_FILE_UPLOAD PURGE;

ALTER TABLE DELEGATION_COMMENT DROP COLUMN NOTE;
ALTER TABLE DELEGATION_COMMENT DROP CONSTRAINT RefCSR_USER1881 ;
ALTER TABLE DELEGATION_COMMENT DROP COLUMN POSTED_BY_USER_SID;
ALTER TABLE DELEGATION_COMMENT DROP COLUMN POSTED_DTM;
 
ALTER TABLE DELEGATION_COMMENT ADD (
    POSTIT_ID         NUMBER(10, 0)    NOT NULL
)
;
 
ALTER TABLE DELEGATION_COMMENT ADD CONSTRAINT PK_DELEGATION_COMMENT PRIMARY KEY (APP_SID, POSTIT_ID);
 
ALTER TABLE DELEGATION_COMMENT ADD CONSTRAINT FK_POSTIT_DELEG_COMMENT 
    FOREIGN KEY (APP_SID, POSTIT_ID)
    REFERENCES POSTIT(APP_SID, POSTIT_ID) ON DELETE CASCADE;
 
 
ALTER TABLE POSTIT ADD CONSTRAINT FK_CUSTOMER_POSTIT 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID);

ALTER TABLE POSTIT ADD CONSTRAINT FK_USER_POSTIT 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);


ALTER TABLE CSR.POSTIT_FILE ADD CONSTRAINT FK_CUSTOMER_POSTIT_FILE
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE CSR.POSTIT_FILE ADD CONSTRAINT FK_POSTIT_POSTIT_FILE 
    FOREIGN KEY (APP_SID, POSTIT_ID)
    REFERENCES POSTIT(APP_SID, POSTIT_ID) ON DELETE CASCADE
;

CREATE SEQUENCE POSTIT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE POSTIT_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE OR REPLACE VIEW v$postit AS
    SELECT p.app_sid, p.postit_id, p.message, p.label, p.secured_via_sid, p.created_dtm, p.created_by_sid,
        pu.user_name created_by_user_name, pu.full_name created_by_full_name, pu.email created_by_email,
		CASE WHEN p.created_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END can_edit
      FROM postit p 
        JOIN csr_user pu ON p.created_by_sid = pu.csr_user_sid AND p.app_sid = pu.app_sid;



@..\delegation_pkg
@..\sheet_pkg
@..\postit_pkg

@..\delegation_body
@..\sheet_body
@..\postit_body

grant execute on postit_pkg to web_user;


CREATE OR REPLACE VIEW v$doc_current_status AS
	SELECT parent_sid, doc_id, locked_by_sid, pending_version, 
		version, lifespan,
		filename, description, change_description, changed_by_sid, changed_dtm,
		sha1, mime_type, data, doc_data_id,
		locked_by_me, expiry_status
	  FROM v$doc_approved
	   WHERE NVL(locked_by_sid,-1) != SYS_CONTEXT('SECURITY','SID') 
	   UNION ALL
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
			-- if it's the approver then show them the right version, otherwise pass through null (i.e. dc.version) to other users so they can't fiddle
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL THEN dc.pending_version ELSE dc.version END version,		   
		   df.lifespan, 
		   dvp.filename, dvp.description, dvp.change_description, dvp.changed_by_sid, dvp.changed_dtm, 
		   ddp.sha1, ddp.mime_type, ddp.data, ddp.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE	
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status		
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dvp ON dc.doc_id = dvp.doc_id AND dc.pending_version = dvp.version 
		LEFT JOIN doc_data ddp ON dvp.doc_data_id = ddp.doc_data_id
	   WHERE NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') OR dc.version IS null;


@update_tail
