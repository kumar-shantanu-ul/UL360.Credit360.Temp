-- Please update version.sql too -- this keeps clean builds in sync
define version=46
@update_header

-- add greentick tag
DECLARE
	v_tag_id tag.tag_id%TYPE;
	v_tag_group_sid security_pkg.T_SID_ID;
	v_q_group_sid security_pkg.T_SID_ID;
BEGIN

	SELECT MAX(tag_id) INTO v_tag_id FROM tag;
	INSERT INTO tag (tag_id, tag, explanation) VALUES (v_tag_id+1, 'needsGreenTick', 'Product requires a Green Tick assessment');
	SELECT tag_group_sid INTO v_tag_group_sid FROM tag_group WHERE name = 'product_category' AND app_sid = (SELECT app_sid FROM csr.customer WHERE host='bootssupplier.credit360.com'); 
	INSERT INTO tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (v_tag_group_sid, v_tag_id+1, 6, 1);
	
	INSERT INTO tag (tag_id, tag, explanation) VALUES (v_tag_id+2, 'needsGreenTick', 'Product requires a Green Tick assessment');
	SELECT tag_group_sid INTO v_tag_group_sid FROM tag_group WHERE name = 'product_category' AND app_sid = (SELECT app_sid FROM csr.customer WHERE host='bootstest.credit360.com'); 
	INSERT INTO tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (v_tag_group_sid, v_tag_id+2, 6, 1);
	
	INSERT INTO tag (tag_id, tag, explanation) VALUES (v_tag_id+2, 'needsGreenTick', 'Product requires a Green Tick assessment');
	SELECT tag_group_sid INTO v_tag_group_sid FROM tag_group WHERE name = 'product_category' AND app_sid = (SELECT app_sid FROM csr.customer WHERE host='bsstagetest.credit360.com'); 
	INSERT INTO tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (v_tag_group_sid, v_tag_id+2, 6, 1);
	
	INSERT INTO tag (tag_id, tag, explanation) VALUES (v_tag_id+2, 'needsGreenTick', 'Product requires a Green Tick assessment');
	SELECT tag_group_sid INTO v_tag_group_sid FROM tag_group WHERE name = 'product_category' AND app_sid = (SELECT app_sid FROM csr.customer WHERE host='bs.credit360.com'); 
	INSERT INTO tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (v_tag_group_sid, v_tag_id+2, 6, 1);
	
	
	INSERT INTO questionnaire_tag 
		select v_tag_id+1, questionnaire_id from questionnaire
		where class_name like 'gt%';
		
	INSERT INTO questionnaire_tag 
		select v_tag_id+2, questionnaire_id from questionnaire
		where class_name like 'gt%';
	
	select group_id into v_q_group_sid from questionnaire_group where name = 'Green Tick' and app_sid = (SELECT app_sid FROM csr.customer WHERE host='bootssupplier.credit360.com'); 	
	INSERT INTO questionnaire_group_membership
		select questionnaire_id, v_q_group_sid from questionnaire
		where class_name like 'gt%';
			
	select group_id into v_q_group_sid from questionnaire_group where name = 'Green Tick' and app_sid = (SELECT app_sid FROM csr.customer WHERE host='bootstest.credit360.com'); 
	INSERT INTO questionnaire_group_membership
		select questionnaire_id, v_q_group_sid from questionnaire
		where class_name like 'gt%';
		
	select group_id into v_q_group_sid from questionnaire_group where name = 'Green Tick' and app_sid = (SELECT app_sid FROM csr.customer WHERE host='bsstagetest.credit360.com'); 
	INSERT INTO questionnaire_group_membership
		select questionnaire_id, v_q_group_sid from questionnaire
		where class_name like 'gt%';
		
	select group_id into v_q_group_sid from questionnaire_group where name = 'Green Tick' and app_sid = (SELECT app_sid FROM csr.customer WHERE host='bs.credit360.com'); 
	INSERT INTO questionnaire_group_membership
		select questionnaire_id, v_q_group_sid from questionnaire
		where class_name like 'gt%';
		
END;
/

-- don't keep this - data is easy to get and just risk it getting out of sync
ALTER TABLE SUPPLIER.PRODUCT_QUESTIONNAIRE_PROVIDER DROP COLUMN PROVIDER_COMPANY_SID;

@..\build


PROMPT move due date onto questionnaires
-- due date now lives against questionnaire/product not just product
ALTER TABLE SUPPLIER.PRODUCT_QUESTIONNAIRE_LINK ADD (DUE_DATE DATE);

BEGIN

    FOR r IN (select * from all_product)
    LOOP
        UPDATE product_questionnaire_link SET due_date = r.due_date WHERE product_id = r.product_id;     
    END LOOP;

END;
/

--ALTER TABLE SUPPLIER.PRODUCT_QUESTIONNAIRE_LINK
--MODIFY(DUE_DATE  NOT NULL)



CREATE OR REPLACE VIEW PRODUCT_QUESTIONNAIRE
(PRODUCT_ID, QUESTIONNAIRE_ID, QUESTIONNAIRE_STATUS_ID, APPROVER_COMPANY_SID, APPROVER_SID, DUE_DATE)
AS 
SELECT PR.PRODUCT_ID, PR.QUESTIONNAIRE_ID, PR.QUESTIONNAIRE_STATUS_ID, PR.APPROVER_COMPANY_SID, PR.APPROVER_SID, DUE_DATE
FROM PRODUCT_QUESTIONNAIRE_LINK PR
WHERE USED = 1;
/

connect csr/csr@&&1;
grant select, references on audit_type to supplier;

@update_tail
