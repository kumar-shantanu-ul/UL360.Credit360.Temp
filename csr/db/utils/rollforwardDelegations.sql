
DECLARE
    -- things to change
    v_new_start_dtm           DATE := DATE '2015-01-01';
    v_new_end_dtm             DATE := DATE '2016-01-01';
    v_host                    VARCHAR2(255) := 'acegroup.credit360.com'; -- put site name here
    -- other stuff
    v_act                   security.security_pkg.T_ACT_ID;
    v_new_delegation_sid    security.security_pkg.T_SID_ID;
    v_app_sid               security.security_pkg.T_SID_ID;
    c_overlaps              csr.delegation_pkg.T_OVERLAP_DELEG_CUR;
    c_overlap_inds          csr.delegation_pkg.T_OVERLAP_DELEG_INDS_CUR;
    c_overlap_regions       csr.delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;
    v_overlap_rec           csr.delegation_pkg.T_OVERLAP_DELEG_REC;
    v_new_indicators        security.security_pkg.T_SID_IDS;
    v_new_regions           security.security_pkg.T_SID_IDS;
BEGIN 
  security.user_pkg.logonadmin(v_host);
  v_act := security_pkg.getact;
  
    FOR d IN (
        -- just select top level delegations that end on the date we want to roll forward from
        SELECT * 
          FROM csr.delegation 
         WHERE parent_sid = SYS_CONTEXT('SECURITY','APP')
           AND end_dtm =  v_new_start_dtm
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('Processing '||d.name||' ('||d.delegation_sid||')');
        
        -- check for overlaps 
        SELECT ind_sid
          BULK COLLECT INTO v_new_indicators
          FROM csr.delegation_ind 
         WHERE delegation_sid = d.delegation_sid;
        
        SELECT region_sid
          BULK COLLECT INTO v_new_regions
          FROM csr.delegation_region
         WHERE delegation_sid = d.delegation_sid;

        
        csr.delegation_pkg.ExFindOverlaps(v_act, NULL, 0, v_app_sid, v_new_start_dtm, v_new_end_dtm, 
      v_new_indicators, v_new_regions, c_overlaps, c_overlap_inds, c_overlap_regions);
        FETCH c_overlaps 
         INTO v_overlap_rec;
        IF c_overlaps%FOUND THEN
      RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_SHEET_OVERLAPS, 'New Delegation from '||v_new_start_dtm||' to '||v_new_end_dtm||' overlaps with an existing Delegation (id '||v_overlap_rec.delegation_sid||', start='||v_overlap_rec.start_dtm||', end='||v_overlap_rec.end_dtm||')');
        ELSE      
      -- move end dtm forward for this and all children
      UPDATE csr.delegation
         SET end_dtm = v_new_end_dtm
       WHERE delegation_sid IN (
            SELECT delegation_sid
              FROM csr.delegation 
              START WITH delegation_sid = d.delegation_sid
            CONNECT BY PRIOR delegation_sid = parent_sid
      );
          
          -- split it
          csr.delegation_pkg.SplitDelegation(v_act, d.delegation_sid, v_new_start_dtm, v_new_delegation_sid);
          csr.delegation_pkg.CreateSheetsForDelegation(v_new_delegation_sid);
          
          -- also need to create the sheets for the child delegations
          FOR cd IN (
            SELECT delegation_sid
              FROM csr.delegation
             START WITH parent_sid = v_new_delegation_sid
           CONNECT BY PRIOR delegation_sid = parent_sid
          )
          LOOP
            csr.delegation_pkg.CreateSheetsForDelegation(cd.delegation_sid);
          END LOOP;
          
    END IF;
    END LOOP;
END;
/
