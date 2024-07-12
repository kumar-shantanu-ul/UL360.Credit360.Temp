-- Please update version.sql too -- this keeps clean builds in sync
define version=115
@update_header

VARIABLE version NUMBER
BEGIN :version := 115; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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
	SELECT db_version INTO v_version FROM security.version;
	IF v_version < 4 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A *** SECURITY *** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/


declare
	v_act				security_pkg.T_ACT_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
	for r in (
		select c.app_sid, sid_id, string_value url
		  from security.securable_object_attributes a, csr_user cu, customer c
		 where attribute_id in (
			select attribute_id from security.attributes where class_id = class_pkg.GetClassId('csruser') and name='default-url'
		) 
		and string_value is not null
   	    and cu.csr_user_sid = a.sid_id
 		and cu.csr_root_sid = c.csr_root_sid
	)
	loop
		web_pkg.SetHomePage(v_act, r.app_sid, r.sid_id, r.url);
	end loop;
	security.attribute_pkg.DeleteDefinition(v_act, class_pkg.getClassID('CSRUser'), 'default-url');
end;
/

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
