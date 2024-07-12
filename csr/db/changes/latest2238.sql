define version=2238
@update_header

BEGIN
	BEGIN
		INSERT INTO csr.tpl_region_type (tpl_region_type_id, label) VALUES ('17', 'Each selected');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	UPDATE csr.tpl_region_type SET label = 'Grandchildren' WHERE TPL_REGION_TYPE_ID = 11;
	UPDATE csr.tpl_region_type SET label = 'One level from bottom' WHERE TPL_REGION_TYPE_ID = 14;
	UPDATE csr.tpl_region_type SET label = 'Bottom of tree' WHERE TPL_REGION_TYPE_ID = 13;
	UPDATE csr.tpl_region_type SET label = 'Immediate children of each selected region' WHERE TPL_REGION_TYPE_ID = 15;
	UPDATE csr.tpl_region_type SET label = 'Grandchildren of each selected region' WHERE TPL_REGION_TYPE_ID = 16;
END;
/

@update_tail
