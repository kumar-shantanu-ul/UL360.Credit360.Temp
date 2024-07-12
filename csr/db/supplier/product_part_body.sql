CREATE OR REPLACE PACKAGE BODY SUPPLIER.product_part_pkg
IS

	-- to add / remove a product part from a company you need write access on the product supplier company
	-- to delete a product part you need write access on the product supplier company (deletion is setting a flag only)
	-- to update a product part you need write access on the product supplier company
	-- to view a product part you need read access on the product supplier company

PROCEDURE CreateProductPart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_part_type_id			IN product_part.part_type_id%TYPE,
	in_product_id			IN product_part.product_id%TYPE,
	in_parent_part_id		IN product_part.parent_id%TYPE,
	out_product_part_id		OUT product_part.product_part_id%TYPE
)
AS
	v_product_part_id		product.product_id%TYPE;
	v_supplier_company_sid 	security_pkg.T_SID_ID;
BEGIN

	-- get supplier company sid of owner product
	SELECT supplier_company_sid INTO v_supplier_company_sid FROM product
		WHERE product_id =  in_product_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_supplier_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT product_part_id_seq.nextval INTO v_product_part_id FROM DUAL;

	INSERT INTO product_part (product_part_id, part_type_id, product_id, parent_id)
		VALUES (v_product_part_id, in_part_type_id, in_product_id, in_parent_part_id);

	out_product_part_id := v_product_part_id;
	
END;

-- Deletes parts and child parts
-- Actually deleted from the relevent tables. 
PROCEDURE DeleteProductPart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_part_id		IN product_part.product_part_id%TYPE
)
AS
	v_supplier_company_sid 	security_pkg.T_SID_ID;
	v_helper_pkg			part_type.package%TYPE;
BEGIN

	-- get supplier company sid of owner product
	SELECT supplier_company_sid INTO v_supplier_company_sid FROM product p, product_part pp
		WHERE p.product_id = pp.product_id
		  AND pp.product_part_id = in_product_part_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_supplier_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	FOR r IN (
		SELECT product_part_id, part_type_id
		  FROM product_part
         START WITH product_part_id = in_product_part_id
         CONNECT BY PRIOR product_part_id = parent_id
         	ORDER BY LEVEL DESC
    ) LOOP
    	-- Call helper first
    	GetHelperPackage(r.part_type_id, v_helper_pkg);
    	IF v_helper_pkg IS NOT NULL THEN
		    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.DeletePart(:1,:2);end;'
				USING in_act_id, r.product_part_id;
		END IF;
    	-- Now delete the part
    	DELETE FROM product_part
    		WHERE product_part_id = r.product_part_id;
    END LOOP;

END;

PROCEDURE GetHelperPackage(
	in_part_type_id			IN part_type.part_type_id%TYPE,
	out_helper_pkg			OUT part_type.package%TYPE
)
AS
BEGIN
	SELECT package
	  INTO out_helper_pkg
	  FROM part_type
	 WHERE part_type_id = in_part_type_id;
END;

PROCEDURE GetHelperPackage(
	in_class_name			IN part_type.class_name%TYPE,
	out_helper_pkg			OUT part_type.package%TYPE
)
AS
BEGIN
	SELECT package
	  INTO out_helper_pkg
	  FROM part_type
	 WHERE LOWER(class_name) = LOWER(in_class_name);
END;

PROCEDURE DeleteAbsentParts(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product_part.product_id%TYPE,
	in_parent_part_id		IN product_part.parent_id%TYPE,
	in_type_id				IN part_type.part_type_id%TYPE,
	in_part_ids				IN T_PART_IDS
)
AS
	v_current_ids			T_PART_IDS;
	v_idx					NUMBER;
BEGIN
	-- Get existing ids
	FOR r IN (
		SELECT product_part_id
		  FROM product_part
		 WHERE product_id = in_product_id
		   AND NVL(parent_id, -1) = NVL(in_parent_part_id, -1)
		   AND part_type_id = in_type_id
	) LOOP
		v_current_ids(r.product_part_id) := r.product_part_id;
	END LOOP;
	
	-- Remove any part ids present in the input array
	IF in_part_ids(1) IS NOT NULL THEN
		FOR i IN in_part_ids.FIRST .. in_part_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_part_ids(i)) THEN
				v_current_ids.DELETE(in_part_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteProductPart(in_act_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

FUNCTION IsPartAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_part_id				IN 	product_part.product_part_id%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_product_id			all_product.product_id%TYPE;
BEGIN
	SELECT product_id
	  INTO v_product_id
	  FROM product_part
	 WHERE product_part_id = in_part_id;
	 
	 RETURN product_pkg.IsProductAccessAllowed(in_act_id, v_product_id, in_perms);
END;


END product_part_pkg;
/


