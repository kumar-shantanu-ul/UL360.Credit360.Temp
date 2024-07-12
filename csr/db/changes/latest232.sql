-- Please update version.sql too -- this keeps clean builds in sync
define version=232
@update_header

-- create CSRCapability class
DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_class_id          security_pkg.T_CLASS_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
    BEGIN	
        class_pkg.CreateClass(v_act, NULL, 'CSRCapability', null, NULL, v_class_id);
    EXCEPTION
        WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
            v_class_id:=class_pkg.GetClassId('CSRCapability');
    END;
END;
/

CREATE TABLE CAPABILITY(
    NAME                VARCHAR2(255)    NOT NULL,
    ALLOW_BY_DEFAULT    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK536 PRIMARY KEY (NAME)
)
;

BEGIN
    INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Subdelegation', 1);
    INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Delegation reports', 0);
END;
/

@..\csr_data_pkg
@..\csr_data_body
@..\..\..\aspen2\tools\recompile_packages.sql

@update_tail
