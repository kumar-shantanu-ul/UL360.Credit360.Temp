-- Please update version.sql too -- this keeps clean builds in sync
define version=1763
@update_header

DROP TABLE CHAIN.TT_FILE_UPLOAD;
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_FILE_UPLOAD
(
	FILE_UPLOAD_SID						NUMBER(10) 		NOT NULL,	
	COMPANY_SID								NUMBER(10) 		NOT NULL,
	FILENAME										VARCHAR2(255)	NOT NULL,
	FOLDER											VARCHAR2(255)	NOT NULL,
	LAST_MODIFIED_DTM					DATE	NOT NULL,
	FILE_SIZE										NUMBER(10) 		NOT NULL,
	CONSTRAINT PK_TT_FILE_UPLOADS PRIMARY KEY (FILE_UPLOAD_SID)
)
ON COMMIT DELETE ROWS; 

@../chain/upload_pkg
@../chain/upload_body
	
@update_tail