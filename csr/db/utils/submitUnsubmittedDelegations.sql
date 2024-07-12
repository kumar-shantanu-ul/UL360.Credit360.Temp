DECLARE 
    v_act       security_pkg.T_ACT_ID;
    v_user_sid  security_pkg.T_SID_ID;
    v_note      delegation.note%TYPE :='Submitted at request of Duggie Brookes';
    v_cnt       NUMBER(10) := 0;
BEGIN
    user_pkg.logonadmin('imi.credit360.com');
    user_pkg.LogonAuthenticatedPath(0, '/csr/users/richard', 10000, v_act);
    user_pkg.GetSid(v_act, v_user_sid);
    FOR r IN (
        -- find the first non-red, or last red
        SELECT root_delegation_sid, delegation_sid, parent_sid, sheet_id, start_dtm, end_dtm, lvl, last_action_colour
          FROM (
            SELECT root_delegation_sid, delegation_sid, parent_sid, sheet_id, start_dtm, end_dtm, lvl, last_action_colour,
                ROW_NUMBER() OVER (PARTITION BY root_delegation_sid, root_start_dtm, root_end_dtm ORDER BY score DESC) rn -- highest score wins
              FROM (
                 SELECT d.delegation_sid, d.parent_sid, s.sheet_id, s.start_dtm, s.end_dtm, LEVEL lvl, 
                    last_action_colour,
                    CASE 
                        WHEN last_action_colour = 'R' THEN LEVEL -- lower level will score better
                        WHEN last_action_colour != 'R' THEN 100 - LEVEL -- higher level will score better (and always beat red)
                    END score,
                    CONNECT_BY_ROOT d.delegation_Sid root_delegation_sid,
                    CONNECT_BY_ROOT s.start_dtm root_start_dtm,
                    CONNECT_BY_ROOT s.end_dtm root_end_dtm
                   FROM delegation d
                   JOIN sheet_with_last_action s ON d.delegation_sid = s.delegation_sid AND d.app_sid = s.app_sid
                  START WITH d.delegation_sid IN (
                      -- top level energy delegations
                      SELECT delegation_sid 
                        FROM delegation 
                       WHERE app_sid = security_pkg.GetApp
                         AND lower(NAME) LIKE 'health & safety%' --'energy managemen%'
                         AND parent_sid = app_sid
                         AND end_dtm <= '1 jan 2010'
                  )
                CONNECT BY PRIOR d.delegation_sid = d.parent_sid
                    AND s.start_dtm >= PRIOR s.start_dtm
                    AND s.end_dtm <= PRIOR s.end_dtm
             )
         )
        WHERE rn = 1
          AND delegation_sid != root_delegation_sid 
    )
    LOOP
        IF r.last_action_colour IN ('R','G') THEN
            --DBMS_OUTPUT.PUT_LINE('Submitting sheet '||r.sheet_id||' from '||delegation_pkg.ConcatDelegationUsers(r.delegation_Sid) || ' to '||delegation_pkg.ConcatDelegationUsers(r.parent_Sid));
            -- mark values as submitted
            UPDATE SHEET_VALUE
               SET STATUS = csr_data_pkg.SHEET_VALUE_SUBMITTED
             WHERE sheet_id = r.sheet_id;
            -- write a row to the history table for this change - note goes from this user to delegators
            sheet_pkg.CreateHistory(r.sheet_id, csr_data_pkg.ACTION_SUBMITTED, v_user_sid, r.parent_sid, v_note);
        ELSIF r.last_action_colour = 'O' THEN
            -- approve
            --DBMS_OUTPUT.PUT_LINE('Approving sheet '||r.sheet_id||' from '||delegation_pkg.ConcatDelegationUsers(r.delegation_Sid) || ' to '||delegation_pkg.ConcatDelegationUsers(r.parent_Sid));
            sheet_pkg.Accept(v_act, r.sheet_id, v_note);
        END IF;
        v_cnt := v_cnt + 1;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_cnt||' processed');
END;
/

--AND lower(NAME) LIKE 'health & safety%'
