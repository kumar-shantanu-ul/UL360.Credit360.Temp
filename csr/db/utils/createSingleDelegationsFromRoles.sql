

CREATE OR REPLACE PROCEDURE CreateSingleDelegsFromRoles(
    v_copy_delegation_sid       IN security_pkg.T_SID_ID,
    v_bottom_to_top_role_sids   IN VARCHAR2
)
AS
    
    v_parent_delegation_sid     security_pkg.T_SID_ID;
    v_new_delegation_sid        security_pkg.T_SID_ID;
    v_delegation_name           delegation.NAME%TYPE;
BEGIN
    -- get hold of the name
    SELECT NAME
      INTO v_delegation_name
      FROM delegation
     WHERE delegation_sid = v_copy_delegation_sid;
    DBMS_OUTPUT.PUT_LINE('COPYING '||UPPER(v_delegation_name));
    -- figure out the optimal structure to create
    FOR r IN (
        --SELECT o.user_sids_path, o.user_names_path, stragg(o.region_sid) region_sids, stragg(o.region_description) region_descriptions
        SELECT o.user_sids_path, o.user_names_path, o.region_sid region_sids, o.region_description region_descriptions
          FROM (
            SELECT n.*, MAX(lvl) OVER () max_lvl
              FROM (
                SELECT m.*, LEVEL lvl, 
                    LTRIM(SYS_CONNECT_BY_PATH(m.user_sids,'|'),'|') user_sids_path,
                    LTRIM(SYS_CONNECT_BY_PATH(m.user_names,'|'),'|') user_names_path
                  FROM (
                    SELECT r.region_sid, r.description region_description, x.seq, stragg(cu.csr_user_sid) user_sids, stragg(cu.full_name) user_names
                      FROM (
                        SELECT CONNECT_BY_ROOT item initial_role_sid, item role_sid, LEVEL seq
                          FROM TABLE(utils_pkg.SplitNumericString(v_bottom_to_top_role_sids)) r 
                         START WITH pos = 1
                        CONNECT BY PRIOR pos = pos -1
                      )x
                      JOIN role ro ON ro.role_sid = x.role_sid
                      JOIN region_role_member rrm ON rrm.role_sid = x.role_sid
                      JOIN region r ON r.region_sid = rrm.region_sid AND r.app_sid = rrm.app_sid
                      JOIN csr_user cu ON cu.csr_user_sid = rrm.user_sid AND cu.app_sid = rrm.app_sid
                     WHERE (x.seq > 1 OR rrm.inherited_from_sid = rrm.region_sid) -- bottom set will be where we are directly responsible -- user can always subdivide themselves
                     GROUP BY r.region_sid, r.description, x.seq
                  )m
                 START WITH seq = 1
                CONNECT BY PRIOR seq = seq - 1
                    AND PRIOR region_sid = region_sid
             )n
         )o
        WHERE lvl = max_lvl
        --GROUP BY o.user_sids_path, o.user_names_path
    )
    LOOP
        -- copy delegation
        DBMS_OUTPUT.PUT_LINE('Creating delegation chain for '||r.region_descriptions);
        v_parent_delegation_sid := null;
        FOR d IN (
            SELECT item user_sids, pos
              FROM TABLE(utils_pkg.SplitString(r.user_sids_path,'|')) 
             ORDER BY pos DESC
        )
        LOOP
            IF v_parent_delegation_sid IS NULL THEN
                -- first one
                delegation_pkg.CopyDelegation(security_pkg.getACT, v_copy_delegation_sid, 
                    v_delegation_name||' - '||r.region_descriptions, v_parent_delegation_sid);
            ELSE
                FOR dd IN (
                    -- this will only ever return a single row, but saves mucking around with cursors
                    SELECT app_sid, NAME, INTERVAL, schedule_xml, note, section_xml, grid_xml, editing_url
                      FROM delegation
                     WHERE delegation_sid = v_parent_delegation_sid
                )
                LOOP
                    delegation_pkg.CreateNonTopLevelDelegation(security_pkg.getACT, v_parent_delegation_sid,
                        dd.app_sid, dd.NAME, NULL, NULL, NULL, d.user_sids, dd.INTERVAL, dd.schedule_xml, dd.note,
                        v_new_delegation_sid);
                    -- copy stuff that create delegation doesn't create for us
                    UPDATE delegation 
                       SET grid_xml = dd.grid_xml, section_xml = dd.section_xml,
                        editing_url = dd.editing_url
                     WHERE delegation_sid = v_new_delegation_sid;
                    -- insert indicators
                    INSERT INTO delegation_ind
                        (delegation_sid, ind_sid, mandatory, description, pos, section_Key)
                        SELECT v_new_delegation_sid, ind_sid, mandatory, description, pos, section_key
                          FROM delegation_ind
                         WHERE delegation_sid = v_parent_delegation_sid;
                    -- set parent
                    v_parent_delegation_sid := v_new_delegation_sid;
                END LOOP;
            END IF;
            -- fix up regions            
            INSERT INTO delegation_region
                (delegation_sid, region_sid, mandatory, description, pos, aggregate_to_region_sid)
                SELECT v_parent_delegation_sid, region_sid, 0, description, rownum, region_sid
                  FROM region
                 WHERE region_sid IN (
                    SELECT item FROM TABLE(utils_pkg.SplitNumericString(r.region_sids))
                );
            -- assign users
            delegation_pkg.SetUsers(security_pkg.getACT, v_parent_delegation_sid, d.user_sids);
            -- mark as fully delegated            
            UPDATE delegation 
               SET fully_delegated = 1 
             WHERE delegation_sid = v_parent_delegation_sid;
            DBMS_OUTPUT.PUT_LINE('-- delegated to '||d.user_sids||' - created delegation sid '||v_parent_delegation_sid);
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('|');
    DBMS_OUTPUT.PUT_LINE('Now run MakeSheets2');
END;
/


