-- Please update version.sql too -- this keeps clean builds in sync
define version=22
@update_header


-- remove tags linked to product cross applications by mistake
BEGIN

    FOR a IN (
        SELECT app_sid, host FROM csr.customer WHERE host IN 
        		(
        			'bs.credit360.com',
        			'bootstest.credit360.com',
        			'bootssupplier.credit360.com',
        			'bsstage.credit360.com'
        		)
    ) 
    LOOP
        -- get all tags not for this app 
        FOR r IN (
        		SELECT pt.product_id, pt.tag_id, app_sid
        		 -- INTO out_product_type_id, out_product_type, out_product_class_id, out_product_class, out_product_type_unit
        		  FROM product_tag pt, gt_tag_product_type tpt, gt_product_type gpt, gt_product_class gpc, tag_group_member tgm, tag_group tg
        		 WHERE pt.tag_id = tpt.tag_id 
                   AND tgm.TAG_ID = pt.tag_id
                   AND tgm.tag_group_sid = tg.tag_group_sid
        		   AND tpt.gt_product_type_id = gpt.gt_product_type_id
        		   AND gpt.gt_product_class_id = gpc.gt_product_class_id
                   AND app_sid != a.app_sid
                   AND product_id IN 
                   ( select product_id from product where app_sid = a.app_sid)
        ) 
        LOOP
        --DBMS_OUTPUT.PUT_LINE(r.product_id || ','||  r.tag_id);
          DELETE FROM product_tag WHERE product_id = r.product_id and tag_id = r.tag_id;  
        END LOOP;
 
    END LOOP;
    
END;
/

@update_tail