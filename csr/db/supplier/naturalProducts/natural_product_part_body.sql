create or replace package body supplier.natural_product_part_pkg
IS

PROCEDURE CreatePart(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_product_id			IN	product_part.product_id%TYPE,
	in_description			IN	np_part_description.description%TYPE,
	in_part_code			IN	np_part_description.part_code%TYPE,
	in_natural_claim		IN	np_part_description.natural_claim%TYPE,
	out_product_part_id		OUT	product_part.product_part_id%TYPE
)
AS
	v_part_type_id			product_part.part_type_id%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
BEGIN
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_DESCRIPTION_CLS;

	-- Security check done inside CreateProductPart
	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_product_id, NULL, out_product_part_id);
	
	INSERT INTO np_part_description
		(product_part_id, description, part_code, natural_claim)
	 	VALUES (out_product_part_id, in_description, in_part_code, in_natural_claim);
	 	
	-- audit log 
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Added Natural Product part {0}', in_description, NULL, NULL, in_product_id);	
END;

-- copies own children as well
PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
)
AS
	v_new_product_part_id			product_part.product_part_id%TYPE;
	v_new_child_product_part_id		product_part.product_part_id%TYPE;
	v_part_type_id					product_part.part_type_id%TYPE;
BEGIN
	
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_DESCRIPTION_CLS;

	-- Security check done inside CreateProductPart
	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_to_product_id, in_new_parent_part_id, v_new_product_part_id);
	
	INSERT INTO np_part_description
		(product_part_id, description, part_code, natural_claim)
	 SELECT v_new_product_part_id, description, part_code, natural_claim
	   FROM np_part_description
	  WHERE product_part_id = in_from_part_id;
	 	
	-- now copies children 
	FOR child IN (
		SELECT product_part_id, package FROM product_part pp, part_type pt
		 WHERE pp.part_type_id = pt.part_type_id
		   AND parent_id = in_from_part_id
		   ORDER BY product_part_id ASC
	)
	LOOP
		    EXECUTE IMMEDIATE 'begin '||child.package||'.CopyPart(:1,:2,:3,:4,:5);end;'
				USING in_act_id, child.product_part_id, in_to_product_id, v_new_product_part_id, OUT v_new_child_product_part_id;
	END LOOP;
	
	out_product_part_id := v_new_product_part_id;
	
END;

PROCEDURE UpdatePart(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_part_id				IN	product_part.product_part_id%TYPE,
	in_description			IN	np_part_description.description%TYPE,
	in_part_code			IN	np_part_description.part_code%TYPE,
	in_natural_claim		IN	np_part_description.natural_claim%TYPE
)
AS

	CURSOR c_old IS 
		SELECT description, part_code, CASE natural_claim WHEN 1 THEN 'Yes' ELSE 'No' END natural_claim 
		    FROM np_part_description
		    WHERE product_part_id = in_part_id;
 
	r_old 					c_old%ROWTYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_product_id 			product.product_id%TYPE;
	v_nat_claim				VARCHAR2(10);		

BEGIN
	
	IF NOT product_part_pkg.IsPartAccessAllowed(in_act_id, in_part_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to part with id '||in_part_id);
	END IF;
	
	-- read some bits about the old part
	OPEN c_old;
	FETCH c_old INTO r_old;
	IF c_old%NOTFOUND THEN
		CLOSE c_old;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The part with id '||in_part_id||' was not found');
	END IF;
	CLOSE c_old;
	 	
	UPDATE np_part_description
	   SET description = in_description,
	   	   part_code = in_part_code,
	   	   natural_claim = in_natural_claim
	 WHERE product_part_id = in_part_id;
	 
	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) 
    	INTO v_product_id
    	FROM product_part
		START WITH product_part_id = in_part_id
		CONNECT BY PRIOR parent_id = product_part_id;
	 
	-- Audit changes
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product part: ' || in_description || ': Part description', r_old.description, in_description, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product part: ' || in_description || ': Part Code', r_old.part_code, in_part_code, v_product_id);
	
	SELECT CASE in_natural_claim WHEN 1 THEN 'Yes' ELSE 'No' END active INTO v_nat_claim FROM DUAL;
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product part: ' || in_description || ': Part description', r_old.natural_claim, v_nat_claim, v_product_id);
	 
END;

PROCEDURE DeletePart(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
)
AS
	v_desc					np_part_description.description%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_product_id 			product.product_id%TYPE;
BEGIN

	SELECT description INTO v_desc FROM np_part_description WHERE product_part_id = in_part_id;

	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) 
    	INTO v_product_id
    	FROM product_part
		START WITH product_part_id = in_part_id
		CONNECT BY PRIOR parent_id = product_part_id;
	 
	-- Audit changes
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;

	DELETE FROM np_part_description
	 WHERE product_part_id IN (
         SELECT product_part_id
               FROM all_product p, product_part pp
              WHERE p.product_id = pp.product_id
         START WITH product_part_id = in_part_id
         CONNECT BY PRIOR product_part_id = parent_id
	);

	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Deleted Natural Product part {0}', v_desc, NULL, NULL, v_product_id);	
	
END;


PROCEDURE GetProductParts(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	all_product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;

	OPEN out_cur FOR
		SELECT p.product_id, p.product_part_id, p.part_type_id, p.parent_id, 
				d.description, d.part_code, d.natural_claim, d.description||DECODE(d.part_code, null, '', ' ('||d.part_code||')') description_with_code
		  FROM product_part p, np_part_description d
		 WHERE p.product_id = in_product_id
		   AND d.product_part_id = p.product_part_id
		   AND p.parent_id IS NULL
		   	ORDER BY d.description;
		 
END;

-- Helper function in all part type spoecific packages to return min
-- doc date for any groups attatched to parts of this type for a product. 
-- If no doc groups for a type return NULL date
PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
)
AS
BEGIN
	out_min_date  := NULL;
END;

END natural_product_part_pkg;
/
