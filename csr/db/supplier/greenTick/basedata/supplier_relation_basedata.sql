SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 

SET DEFINE OFF;

BEGIN
	INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name) values 
	(12	,'gtSupplier',		'Supplier',			'Supplier',			'gt_supplier_pkg');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN  
		null; -- just in case clean is run multiple times
END;
/
	
-- gt_sus_relation_type
BEGIN
	INSERT INTO SUPPLIER.gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (1 , 'Supplier has been selected specificially on sustainability performance', 1, 1);
	INSERT INTO SUPPLIER.gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (2 , 'Supplier has had SUSTAINABILITY AUDIT. Management plan in place - results signed off ', 2, 2);
	INSERT INTO SUPPLIER.gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (3 , 'Supplier has been audited. Management plan in place - results signed off (NB: BM is included in this category - internal audit)', 3, 4);
	INSERT INTO SUPPLIER.gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (4 , 'Supplier known to Boots, meets Boots COC on Ethical trading. Not yet audited', 4, 5);
	INSERT INTO SUPPLIER.gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (5 , 'Supplier reputation unknown, no audit information', 8, 6);
	INSERT INTO SUPPLIER.gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (6 , 'Supplier has been audited. (SA and Quality). Management plan in place - results NOT signed off', 4, 3);
END;
/
commit;
exit;