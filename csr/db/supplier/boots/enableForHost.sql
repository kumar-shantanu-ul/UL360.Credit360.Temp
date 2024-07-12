SET DEFINE off

CREATE TABLE MERCHANT_IMPORT_DATA(
    MERCHANT_TYPE    VARCHAR2(1024)    NOT NULL
)
;

BEGIN
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Impulse');
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Electrical Beauty');
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Other');
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Seasonal (Gift)');
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Photo');
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Food');
    insert into merchant_import_data (merchant_type) values ('Lifestyle - Baby');
    insert into merchant_import_data (merchant_type) values ('Beauty - Cosmetics / Fragrances');
    insert into merchant_import_data (merchant_type) values ('Beauty - Toiletries');
    insert into merchant_import_data (merchant_type) values ('Health - Dispensary');
    insert into merchant_import_data (merchant_type) values ('Health - Healthcare');
    insert into merchant_import_data (merchant_type) values ('Goods Not for Resale');
    insert into merchant_import_data (merchant_type) values ('Boots Opticians');
    insert into merchant_import_data (merchant_type) values ('Cross Category');
END;
/


SET DEFINE &

DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_app_sid	    security_pkg.T_SID_ID;
	v_tag_group_sid	security_pkg.T_SID_ID;
	v_tag_id		tag.tag_id%TYPE;
    v_pos				NUMBER;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_app_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/&&1');
	
	BEGIN
		-- Product categories
		tag_pkg.CreateTagGroup(v_act, v_app_sid, 'product_category', 0, 1, 'X', 'X', v_tag_group_sid);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
		-- get the product_category tag group sid
		v_tag_group_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/&&1/Supplier/TagGroups/product_category');
	END;
		
	-- done automatically
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'containsWood', 'Contains wood (excluding packaging)', 0, 1, v_tag_id);
	-- wood = 1, 2 = Nat prod, 3 = PE, 4 = Pack
	INSERT INTO questionnaire_tag (tag_id, questionnaire_id) values (v_tag_id, 1);
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 3); --lbl_Sustainable Sourcing
	
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'containsPulp', 'Contains wood pulp or fluff (excluding packaging)', 1, 1, v_tag_id);
	INSERT INTO questionnaire_tag (tag_id, questionnaire_id) values (v_tag_id, 1);
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 3); --lbl_Sustainable Sourcing
	
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'containsPaper', 'Contains paper  (excluding packaging)', 2, 1, v_tag_id);
	INSERT INTO questionnaire_tag (tag_id, questionnaire_id) values (v_tag_id, 1);
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 3); --lbl_Sustainable Sourcing
	
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'containsNaturalProducts', 'Contains natural products (except wood)', 3, 1, v_tag_id);
	INSERT INTO questionnaire_tag (tag_id, questionnaire_id) values (v_tag_id, 2);
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 3); --lbl_Sustainable Sourcing
	

	BEGIN
		-- Sale types
		tag_pkg.CreateTagGroup(v_act, v_app_sid, 'sale_type', 0, 1, 'X', 'X', v_tag_group_sid);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
		-- get the sale_type tag group sid
		v_tag_group_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/&&1/Supplier/TagGroups/sale_type');
	END;
	
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'GNFR', 'GNFR', 0 , 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Boots Brand', 'Boots Brand', 1, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Proprietry', 'Proprietry', 2, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Boots Exclusive', 'Boots Exclusive', 3, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Sub Product', 'Sub Product', 4, 1, v_tag_id);
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 1); --lbl_Sustainable Sourcing
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 4); --no_prodcate_ParentPackaging
	INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 5); --prodcate_withoutPackaging
	
	BEGIN
		-- Merchant types
		tag_pkg.CreateTagGroup(v_act, v_app_sid, 'merchant_type', 0, 1, 'X', 'X', v_tag_group_sid);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
		-- get the merchant_type tag group sid
		v_tag_group_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/&&1/Supplier/TagGroups/merchant_type');
	END;
	
	-- set up tag group members
	SELECT MAX(pos) + 1
      INTO v_pos 
      FROM tag_group_member 
     WHERE tag_group_sid = v_tag_group_sid; 
    --loop
    FOR r IN (
        SELECT * FROM merchant_import_data order by lower(MERCHANT_TYPE)
    )
    LOOP
    	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, r.MERCHANT_TYPE, r.MERCHANT_TYPE, v_pos, 1, v_tag_id);	
		v_pos := v_pos + 1;
    END LOOP;
	
	-- set up at least one period
	BEGIN
	INSERT INTO CUSTOMER_PERIOD (PERIOD_ID, APP_SID) VALUES (1, v_app_sid);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN 
				NULL;
	END;
	
END;
/



commit;


DROP TABLE merchant_import_data;

exit;
