CREATE OR REPLACE PACKAGE BODY SUPPLIER.company_part_pkg
IS

	-- to add / remove a part from a company you need write access on the company
	-- to delete a part you need write access on the company (deletion is setting a flag only)
	-- to update a part you need write access on the company
	-- to view a part you need read access on the company

PROCEDURE CreateCompanyPart(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_part_type_id				IN company_part.part_type_id%TYPE,
	in_company_sid				IN company_part.company_sid%TYPE,
	in_parent_part_id			IN company_part.parent_id%TYPE,
	out_company_part_id		OUT company_part.company_part_id%TYPE
)
AS
	v_company_part_id		company_part.company_part_id%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT company_part_id_seq.nextval INTO v_company_part_id FROM DUAL;

	INSERT INTO company_part (company_part_id, part_type_id, company_sid, parent_id)
		VALUES (v_company_part_id, in_part_type_id, in_company_sid, in_parent_part_id);

	out_company_part_id := v_company_part_id;
	
END;

-- Deletes parts and child parts
-- Actually deleted from the relevent tables. 
PROCEDURE DeleteCompanyPart(
	in_act_id				IN 		security_pkg.T_ACT_ID,
	in_company_part_id		IN company_part.company_part_id%TYPE
)
AS
	v_company_sid 	security_pkg.T_SID_ID;
	v_helper_pkg			part_type.package%TYPE;
BEGIN

	-- get supplier company sid of owner product
	SELECT company_sid INTO v_company_sid FROM company_part cp
		WHERE cp.company_part_id = in_company_part_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	FOR r IN (
		SELECT company_part_id, part_type_id
		  FROM company_part
         START WITH company_part_id = in_company_part_id
         CONNECT BY PRIOR company_part_id = parent_id
         	ORDER BY LEVEL DESC
    ) LOOP
    	-- Call helper first
    	GetHelperPackage(r.part_type_id, v_helper_pkg);
    	IF v_helper_pkg IS NOT NULL THEN
		    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.DeletePart(:1,:2);end;'
				USING in_act_id, r.company_part_id;
		END IF;
    	-- Now delete the part
    	DELETE FROM company_part
    		WHERE company_part_id = r.company_part_id;
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

PROCEDURE DeleteAbsentParts(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN company_part.company_sid%TYPE,
	in_parent_part_id		IN company_part.parent_id%TYPE,
	in_type_id				IN part_type.part_type_id%TYPE,
	in_part_ids				IN T_PART_IDS
)
AS
	v_current_ids			T_PART_IDS;
	v_idx					NUMBER;
BEGIN
	-- Get existing ids
	FOR r IN (
		SELECT company_part_id
		  FROM company_part
		 WHERE company_sid = in_company_sid
		   AND NVL(parent_id, -1) = NVL(in_parent_part_id, -1)
		   AND part_type_id = in_type_id
	) LOOP
		v_current_ids(r.company_part_id) := r.company_part_id;
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
			DeleteCompanyPart(in_act_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

FUNCTION IsPartAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_part_id			IN 	company_part.company_part_id%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			all_company.company_sid%TYPE;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM company_part
	 WHERE company_part_id = in_part_id;
	
	RETURN security_pkg.IsAccessAllowedSID(in_act_id, v_company_sid, in_perms);
END;

END company_part_pkg;
/


