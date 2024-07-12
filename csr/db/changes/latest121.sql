-- Please update version.sql too -- this keeps clean builds in sync
define version=121
@update_header

VARIABLE version NUMBER
BEGIN :version := 121; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

CREATE TABLE DOC_LIBRARY(
	CSR_ROOT_SID		NUMBER(10, 0) 	NOT NULL REFERENCES CUSTOMER(CSR_ROOT_SID),
	DOC_LIBRARY_SID		NUMBER(10, 0)	NOT NULL REFERENCES DOC_FOLDER(DOC_FOLDER_SID),
	CONSTRAINT PK_DOC_LIBRARY PRIMARY KEY (DOC_LIBRARY_SID)
	USING INDEX TABLESPACE INDX
);
CREATE INDEX IX_DOC_LIBRARY_CSR_ROOT ON DOC_LIBRARY(CSR_ROOT_SID, DOC_LIBRARY_SID);

delete from doc where parent_sid not in (select doc_folder_sid from doc_folder);

alter table doc add constraint fk_doc_doc_folder foreign key (parent_sid) 
references doc_folder(doc_folder_sid);

-- insert existing libraries
declare
	v_docs_sid 	security_pkg.T_SID_ID;
	v_act_id	security_pkg.T_ACT_ID;
begin
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 86400, v_act_id);
	for r in (select so.parent_sid_id, so.sid_id
				from doc_folder f, security.securable_object so 
			   where f.doc_folder_sid = so.sid_id and 
			   		 so.parent_sid_id not in (select doc_folder_sid from doc_folder)) loop
		insert into doc_library (csr_root_sid, doc_library_sid)
		values (securableobject_pkg.getsidfrompath(v_act_id, r.parent_sid_id, 'CSR'), r.sid_id);
	end loop;
	commit;
end;
/

@..\doc_pkg
@..\doc_folder_pkg
@..\doc_body
@..\doc_folder_body

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
