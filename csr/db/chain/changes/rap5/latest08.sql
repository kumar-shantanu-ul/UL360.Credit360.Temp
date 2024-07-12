define rap5_version=8
@update_header

BEGIN
	FOR r IN (
		SELECT host 
		  FROM v$chain_host 
	) LOOP
		user_pkg.LogonAdmin(r.host);
		
		DECLARE
			v_class_id		security_pkg.T_CLASS_ID;
		BEGIN
			class_pkg.CreateClass(security_pkg.getACT, null, 'ChainFileUpload', 'chain.upload_pkg', null, v_class_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
	END LOOP;
END;
/

connect aspen2/aspen2@&_CONNECT_IDENTIFIER

grant select, references on aspen2.filecache to chain;

connect chain/chain@&_CONNECT_IDENTIFIER

CREATE TABLE FILE_UPLOAD(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILE_UPLOAD_SID      NUMBER(10, 0)    NOT NULL,
    COMPANY_SID          NUMBER(10, 0)    NOT NULL,
    FILENAME             VARCHAR2(255)    NOT NULL,
    MIME_TYPE            VARCHAR2(255)    NOT NULL,
    DATA                 BLOB             NOT NULL,
    SHA1                 RAW(20)          NOT NULL,
    LAST_MODIFIED_DTM    TIMESTAMP(6)     DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_FILE_UPLOAD PRIMARY KEY (APP_SID, FILE_UPLOAD_SID)
)
;

@..\..\upload_pkg
@..\..\upload_body



grant execute on upload_pkg to web_user;
grant execute on upload_pkg to security;

@update_tail