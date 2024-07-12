-- Please update version.sql too -- this keeps clean builds in sync
define version=537
@update_header

-- doclib stuff
ALTER TABLE DOC_NOTIFICATION ADD (
    REASON                 VARCHAR2(32) ,
    CHECK (REASON IN ('NEW_VERSION','DELETED','RESTORED','FOR_APPROVAL'))
);

-- just assume this for now
UPDATE DOC_NOTIFICATION SET REASON = 'NEW_VERSION'; 

ALTER TABLE DOC_NOTIFICATION MODIFY REASON NOT NULL;

ALTER TABLE DOC_CURRENT DROP COLUMN PENDING_APPROVAL;

ALTER TABLE DOC_CURRENT MODIFY VERSION NULL;
 
ALTER TABLE DOC_CURRENT ADD (
    PENDING_VERSION    NUMBER(10, 0)
);

ALTER TABLE DOC_CURRENT ADD CONSTRAINT RefDOC_VERSION1884 
    FOREIGN KEY (APP_SID, DOC_ID, PENDING_VERSION)
    REFERENCES DOC_VERSION(APP_SID, DOC_ID, VERSION);

CREATE TABLE DOC_FOLDER_SUBSCRIPTION(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DOC_FOLDER_SID    NUMBER(10, 0)    NOT NULL,
    NOTIFY_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DOC_FOLDER_SUB PRIMARY KEY (APP_SID, DOC_FOLDER_SID, NOTIFY_SID)
);

ALTER TABLE DOC_FOLDER_SUBSCRIPTION ADD CONSTRAINT FK_DOC_FOLD_DOC_FOLD_SUB 
    FOREIGN KEY (APP_SID, DOC_FOLDER_SID)
    REFERENCES DOC_FOLDER(APP_SID, DOC_FOLDER_SID);

ALTER TABLE DOC_FOLDER_SUBSCRIPTION ADD CONSTRAINT FK_USER_DOC_FOLD_SUB 
    FOREIGN KEY (APP_SID, NOTIFY_SID)
     REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);



-- new stuff for comments / file uploads on sheets
--
-- TABLE: DELEGATION_COMMENT 
--

CREATE TABLE DELEGATION_COMMENT(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEGATION_SID        NUMBER(10, 0)    NOT NULL,
    START_DTM             DATE             NOT NULL,
    END_DTM               DATE             NOT NULL,
    NOTE                  CLOB             NOT NULL,
    POSTED_BY_USER_SID    NUMBER(10, 0)    NOT NULL,
    POSTED_DTM            DATE             DEFAULT SYSDATE NOT NULL
);

-- 
-- TABLE: DELEGATION_FILE_UPLOAD 
--
CREATE TABLE DELEGATION_FILE_UPLOAD(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEGATION_SID    NUMBER(10, 0)    NOT NULL,
    START_DTM         DATE             NOT NULL,
    END_DTM           DATE             NOT NULL,
    FILENAME          VARCHAR2(255)    NOT NULL,
    MIME_TYPE         VARCHAR2(255)    NOT NULL,
    SHA1              RAW(20)          NOT NULL,
    DATA              BLOB             NOT NULL
);

-- 
-- TABLE: DELEGATION_COMMENT 
--
ALTER TABLE DELEGATION_COMMENT ADD CONSTRAINT RefCSR_USER1881 
    FOREIGN KEY (APP_SID, POSTED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE DELEGATION_COMMENT ADD CONSTRAINT RefDELEGATION1882 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID);


-- 
-- TABLE: DELEGATION_FILE_UPLOAD 
--
ALTER TABLE DELEGATION_FILE_UPLOAD ADD CONSTRAINT RefDELEGATION1883 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID);

CREATE OR REPLACE VIEW v$doc_current AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   df.lifespan, 
		   dv.version, dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm, 
		   dd.doc_data_id, dd.data, dd.sha1, dd.mime_type
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version 
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id;


CREATE OR REPLACE VIEW v$doc_approved AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   dc.version,
		   df.lifespan, 
		   dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm, 
		   dd.sha1, dd.mime_type, dd.data, dd.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE	
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version 
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		-- don't return stuff that's added but never approved
	   WHERE dc.version IS NOT NULL; 

-- right -> show the user pending stuff IF:
--   * locked_by_sid => is this user
--   * show filename etc of pending file (but null version) if dc.version is null
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
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') THEN dc.pending_version ELSE dc.version END version,		   
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



@..\csr_data_pkg
@..\doc_pkg
@..\doc_lib_pkg
@..\doc_folder_pkg

@..\doc_body
@..\doc_lib_body
@..\doc_folder_body 

@update_tail
