-- Please update version.sql too -- this keeps clean builds in sync
define version=98
@update_header

-- reorder tags
DECLARE
		v_greenTickTagId NUMBER;
       v_prodCatTagGroupSid NUMBER;
BEGIN
    
    user_pkg.logonadmin('bootssupplier.credit360.com');

    v_prodCatTagGroupSid := securableobject_pkg.GetSidFromPath(sys_context('SECURITY','ACT') , sys_context('SECURITY','APP'), 'Supplier/TagGroups/product_category');
    
    SELECT t.tag_id INTO v_greenTickTagId FROM tag t, tag_group_member tgm WHERE t.tag_id = tgm.tag_id AND tgm.TAG_GROUP_SID = v_prodCatTagGroupSid AND tag = 'needsGreenTick';
    DBMS_OUTPUT.PUT_LINE(v_greenTickTagId);
    
    FOR r IN 
    (
        SELECT rownum rn, tag, tag_id FROM
        (
            SELECT distinct t.* FROM tag_group_member tgm, tag t 
            WHERE tag_group_sid =  v_prodCatTagGroupSid
            AND t.TAG_ID = tgm.TAG_ID AND ((t.tag like '(Mn)%') or (tag like '(Pk)%') or (tag like '(Fm)%'))
            ORDER BY tag
        )
     )
     LOOP
        -- must go after needsGrnnTick in pos order 
        UPDATE tag_group_member SET pos = r.rn+v_greenTickTagId WHERE tag_id = r.tag_id;
        --DBMS_OUTPUT.PUT_LINE(r.tag_id);
     END LOOP;
     
END;
/


@update_tail
