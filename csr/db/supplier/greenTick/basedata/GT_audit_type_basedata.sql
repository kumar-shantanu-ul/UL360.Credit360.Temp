SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 


SET DEFINE OFF;

BEGIN
    -- wrap these in case we're running clean twice
    BEGIN
        INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, AUDIT_TYPE_GROUP_ID) 
            VALUES (75 , 'GT value saved', 3);
        INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, AUDIT_TYPE_GROUP_ID) 
            VALUES (76 , 'GT score changed', 3);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
END;
/

commit;
exit;