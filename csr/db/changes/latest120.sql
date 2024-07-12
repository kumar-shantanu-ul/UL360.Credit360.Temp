-- Please update version.sql too -- this keeps clean builds in sync
define version=120
@update_header

VARIABLE version NUMBER
BEGIN :version := 120; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

CREATE TABLE DOC_DATA(
	DOC_DATA_ID			NUMBER(10, 0)	NOT NULL,
	DATA				BLOB			NOT NULL,
    SHA1            	RAW(20)			NOT NULL,
    MIME_TYPE       	VARCHAR2(100)	NOT NULL,	
    CONSTRAINT PK_DOC_DATA PRIMARY KEY (DOC_DATA_ID)
    USING INDEX TABLESPACE INDX
);

CREATE TABLE DOC_VERSION(
	DOC_ID				NUMBER(10, 0)	NOT NULL,
	VERSION				NUMBER(10, 0) 	NOT NULL,
    FILENAME        	VARCHAR2(200)	NOT NULL,
    DESCRIPTION     	CLOB			NOT NULL,
	CHANGE_DESCRIPTION	CLOB			NOT NULL,
	CHANGED_BY_SID		NUMBER(10)		NOT NULL REFERENCES CSR_USER(CSR_USER_SID),
	CHANGED_DTM			TIMESTAMP(6)	DEFAULT SYSTIMESTAMP NOT NULL,
	DOC_DATA_ID			NUMBER(10, 0)	NOT NULL REFERENCES DOC_DATA(DOC_DATA_ID),
	CONSTRAINT PK_DOC_VERSION PRIMARY KEY (DOC_ID, VERSION)
	USING INDEX TABLESPACE INDX
);

CREATE TABLE DOC(
	DOC_ID				NUMBER(10, 0)	NOT NULL,
    VERSION				NUMBER(10, 0)	NOT NULL,
   	PARENT_SID			NUMBER(10, 0)	NOT NULL,
	LOCKED_BY_SID		NUMBER(10, 0)	REFERENCES CSR_USER(CSR_USER_SID),
    CONSTRAINT PK_DOC PRIMARY KEY (DOC_ID)
    USING INDEX TABLESPACE INDX
);
ALTER TABLE DOC ADD CONSTRAINT FK_DOC_VERSION FOREIGN KEY 
(DOC_ID, VERSION) REFERENCES DOC_VERSION (DOC_ID, VERSION);

CREATE TABLE DOC_NOTIFICATION(
	DOC_ID				NUMBER(10, 0)	NOT NULL REFERENCES DOC(DOC_ID),
	NOTIFY_SID			NUMBER(10, 0)	NOT NULL REFERENCES CSR_USER(CSR_USER_SID),
	CONSTRAINT PK_DOC_NOTIFICATION PRIMARY KEY (DOC_ID, NOTIFY_SID)
	USING INDEX TABLESPACE INDX
);

CREATE TABLE DOC_DOWNLOAD(
	DOC_ID				NUMBER(10, 0)	NOT NULL,
	VERSION				NUMBER(10, 0)	NOT NULL,
	DOWNLOADED_DTM		TIMESTAMP(6)	DEFAULT SYSTIMESTAMP NOT NULL,
	DOWNLOADED_BY_SID	NUMBER(10, 0)	NOT NULL REFERENCES CSR_USER(CSR_USER_SID)
);
CREATE INDEX IX_DOC_DOWNLOAD ON DOC_DOWNLOAD(DOC_ID, VERSION, DOWNLOADED_DTM)
TABLESPACE INDX;
ALTER TABLE DOC_DOWNLOAD ADD CONSTRAINT FK_DOC_DOWNLOAD_DOC_VERSION FOREIGN KEY (DOC_ID, VERSION)
REFERENCES DOC_VERSION (DOC_ID, VERSION);

create or replace view v$doc_current as
	select d.parent_sid, dv.doc_id, dv.version, dv.filename, dv.description, dv.change_description, 
		   dv.changed_by_sid, dv.changed_dtm, dd.data, dd.sha1, dd.mime_type, d.locked_by_sid
	  from doc d, doc_version dv, doc_data dd
	 where d.doc_id = dv.doc_id and d.version = dv.version and dv.doc_data_id = dd.doc_data_id;

CREATE SEQUENCE DOC_ID_SEQ;

CREATE SEQUENCE DOC_DATA_ID_SEQ;

CREATE TABLE DOC_FOLDER(
	DOC_FOLDER_SID		NUMBER(10, 0)	NOT NULL,
	DESCRIPTION			CLOB NOT NULL,
	CONSTRAINT PK_DOC_FOLDER PRIMARY KEY (DOC_FOLDER_SID)
	USING INDEX TABLESPACE INDX
);

DECLARE
	v_act_id	security_pkg.T_ACT_ID;
	v_class_id	security_pkg.T_CLASS_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	class_pkg.CreateClass(v_act_id, class_pkg.GetClassId('Container'), 'DocFolder', 'csr.doc_folder_pkg', null, v_class_id);
	COMMIT;
END;
/

@..\doc_pkg
@..\doc_body
@..\doc_folder_pkg
@..\doc_folder_body
@..\create_views

grant execute on doc_folder_pkg to security;

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
