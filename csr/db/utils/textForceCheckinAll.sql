PROMPT ENter host, super-admin user name
DECLARE
    v_act   security_pkg.T_ACT_ID;
BEGIN
    user_pkg.logonadmin('&&host');
    user_pkg.LogonAuthenticatedPath(0, '/csr/users/&&superadminusername', 10000, v_act);
    FOR r IN (
        SELECT section_sid, cov.title, cu.full_name, version_number checked_out_version_number
          FROM v$checked_out_version cov, csr_user cu
         WHERE cov.checked_out_to_sid = cu.csr_user_sid
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('Checking in section "'||r.title||'" checked out to '||r.full_name||'...');
        
        -- Clear the checkout status from the section table
        UPDATE section
           SET checked_out_to_sid = NULL, 
            checked_out_dtm = NULL, 
            checked_out_version_number = NULL,
            visible_version_number = r.checked_out_version_number
         WHERE section_sid = r.section_sid;
 
        -- Update the verison table with the check-in information
        UPDATE section_version
           SET changed_by_sid = security_pkg.getSID, 
            changed_dtm = SYSDATE, 
            reason_for_change = 'Checkin'
         WHERE section_sid = r.section_sid
           AND version_number = r.checked_out_version_number;
     END LOOP;
END;
/

