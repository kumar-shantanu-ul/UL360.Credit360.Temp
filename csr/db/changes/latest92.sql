-- Please update version.sql too -- this keeps clean builds in sync
define version=92
@update_header

VARIABLE version NUMBER
BEGIN :version := 92; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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



update pending_element_type set is_string = 1, label='Text entry field' where element_type =1;

CREATE UNIQUE INDEX AK_AT_ID_LABEL ON ACCURACY_TYPE_OPTION(ACCURACY_TYPE_ID, LABEL);

DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
    -- ReportingPeriod
    BEGIN
        class_pkg.CreateClass(v_act, null, 'CSRReportingPeriod', 'csr.reporting_period_pkg', NULL, new_class_id);
    EXCEPTION
        WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
            new_class_id:=class_pkg.GetClassId('CSRReportingPeriod');
    END;
END;
/





UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
