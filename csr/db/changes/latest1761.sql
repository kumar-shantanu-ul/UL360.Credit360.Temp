-- Please update version.sql too -- this keeps clean builds in sync
define version=1761
@update_header

@../chain/chain_link_pkg
@../chain/chain_link_body

@../chain/upload_pkg
@../chain/upload_body


--used for generating file download zips
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_FILE_UPLOAD
(
	ACT_ID											CHAR(36 BYTE) 	NOT NULL,
	FILE_UPLOAD_SID						NUMBER(10) 		NOT NULL,	
	COMPANY_SID								NUMBER(10) 		NOT NULL,
	FILENAME										VARCHAR2(255)	NOT NULL,
	FOLDER											VARCHAR2(255)	NOT NULL,
	LAST_MODIFIED_DTM					DATE	NOT NULL,
	FILE_SIZE										NUMBER(10) 		NOT NULL,
	CONSTRAINT PK_TT_FILE_UPLOADS PRIMARY KEY (ACT_ID, FILE_UPLOAD_SID)
)
ON COMMIT PRESERVE ROWS; 
	
@update_tail