-- Please update version.sql too -- this keeps clean builds in sync
define version=210
@update_header

BEGIN
    INSERT INTO AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 16, 'Client specific');
END;
/

@update_tail

