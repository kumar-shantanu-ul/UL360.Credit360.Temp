-- Please update version.sql too -- this keeps clean builds in sync
define version=50
@update_header

BEGIN


    FOR r IN (SELECT * FROM product_questionnaire_provider order by product_id)
    LOOP
    
        DELETE FROM product_questionnaire_provider WHERE product_id = r.product_id;
        
        INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid) VALUES (r.product_id, 1, r.provider_sid);
         INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid) VALUES (r.product_id, 2, r.provider_sid);
         INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid) VALUES (r.product_id, 3, r.provider_sid);
                INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid) VALUES (r.product_id, 4, r.provider_sid);
    
       -- dbms_output.put_line(r.product_id);
    
    END LOOP;


END ;
/

BEGIN


    FOR r IN (SELECT * FROM product_questionnaire_approver order by product_id)
    LOOP
    
        DELETE FROM product_questionnaire_approver WHERE product_id = r.product_id;
        
        INSERT INTO product_questionnaire_approver (product_id, questionnaire_id, approver_sid) VALUES (r.product_id, 1, r.approver_sid);
         INSERT INTO product_questionnaire_approver (product_id, questionnaire_id, approver_sid) VALUES (r.product_id, 2, r.approver_sid);
         INSERT INTO product_questionnaire_approver (product_id, questionnaire_id, approver_sid) VALUES (r.product_id, 3, r.approver_sid);
                INSERT INTO product_questionnaire_approver (product_id, questionnaire_id, approver_sid) VALUES (r.product_id, 4, r.approver_sid);
    
        --dbms_output.put_line(r.product_id);
    
    END LOOP;


END ;

@update_tail
