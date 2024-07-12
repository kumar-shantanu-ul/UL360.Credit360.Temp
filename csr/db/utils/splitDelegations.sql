DECLARE
    -- things to change
    v_new_start_dtm         DATE := '1 Jan 2008';
    v_host                  VARCHAR2(255) := 'CUSTOMER.credit360.com';
    v_admin_user            VARCHAR2(255) := '//csr/users/richard';
    -- other stuff
    v_act			        security_pkg.T_ACT_ID;
    v_new_delegation_sid	security_pkg.T_SID_ID;
BEGIN	
    -- figure out the host
    SELECT app_sid
      INTO v_app_sid
      FROM CUSTOMER
     WHERE host=v_host;
    user_pkg.LogonAuthenticatedPath(0, v_admin_user, 10000, v_act);
    FOR d IN (
        -- just select top level delegations that we want to split
        SELECT * 
          FROM delegation 
         WHERE parent_sid = v_app_sid 
           AND start_dtm <  v_new_start_dtm 
           AND end_dtm >  v_new_start_dtm
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('Processing '||d.name||' ('||d.delegation_sid||')');
        delegation_pkg.SplitDelegation(v_act, d.delegation_sid, v_new_start_dtm, v_new_delegation_sid);        
    END LOOP;
END;
/





