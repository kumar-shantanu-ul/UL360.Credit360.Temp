DECLARE
  v_act         security_pkg.T_ACT_ID;
  v_score       varchar2(50);
BEGIN
    -- log on admin user
    user_pkg.logonauthenticatedpath(0,'//csr/users/james',500,v_act);
  
    FOR P IN
    (
        SELECT p.app_sid, p.product_id, revision_id, DECODE(SCORE_RECYCLED_PACK, -1, 'Not set', SCORE_RECYCLED_PACK) SCORE_RECYCLED_PACK FROM gt_scores gt, product p WHERE p.product_id = gt.product_id
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('product_id = ' ||  p.product_id || '; revision_id = ' || p.revision_id);
        model_pkg.CalcProductScores(v_act, p.product_id, p.revision_id);
        
        select DECODE(SCORE_RECYCLED_PACK, -1, 'Not set', SCORE_RECYCLED_PACK) INTO v_score FROM gt_scores WHERE product_id = p.product_id  AND revision_id = p.revision_id;
        
       audit_pkg.WriteAuditLogEntry(v_act, 76, p.app_sid, p.app_sid, 'Recalc''d scores for revision {0} as model (Recycled packaging calculation) updated. Score changed from {1} to {2}',p.revision_id,  p.SCORE_RECYCLED_PACK, v_score, p.product_id);
    END LOOP;

END;
