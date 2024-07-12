SET SERVEROUTPUT ON;

SET DEFINE OFF;

-- set up tag attributes
BEGIN


	-- set up attributes (tag attributes determine the behaviour of the UI)
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(0, 'No Questionnaires', 'A tag that hides the questionnaire tab. e.g. "sub-products"'); 
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(1, 'No Volumes', 'A tag that hides the sales volume tab. e.g. "sub-products"'); 
	 
	-- tag attributes for GT
		 
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(2, 'lbl_Green Tick Assessment', 'A tag that is associated with green tick assessment. e.g. "needsGreenTick"'); 
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(3, 'lbl_Sustainable Sourcing', 'A tag that is associated with sustainable sourcing. e.g. "containsWood"'); 
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(4, 'no_prodcate_ParentPackaging', 'A tag that is not associated with "gift packaging" product category.'); 
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(5, 'prodcate_withoutPackaging', 'A tag that is associated with "without packaging" product category.');
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(6, 'group_or_Product Type', 'A tag that is associated with this attribute is part of a group with OR relationship.');
	--INSERT INTO SUPPLIER.TAG_ATTRIBUTE VALUES(7, 'child_needsGreenTick', 'A tag that is associated with this attribute is a child of needsGreenTick tag');
	NULL;
END;
/

exit;