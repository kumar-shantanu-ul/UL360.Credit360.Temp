CREATE OR REPLACE PACKAGE BODY CSR.division_pkg AS

FUNCTION GetRootDivisionSid
RETURN security_pkg.T_SID_ID
AS
	v_root_sid	security_pkg.T_SID_ID;
BEGIN
	-- XXX - just returns SID so we're not doing a security check ATM
	BEGIN
		SELECT region_tree_root_sid
		  INTO v_root_sid
		  FROM region_tree
		  WHERE app_sid = security_pkg.getApp
		    AND is_divisions = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_root_sid := NULL;
	END;
		
	-- create a new secondary tree if one doesn't exist yet
	IF v_root_sid IS NULL THEN
		region_pkg.CreateRegionTreeRoot(security_pkg.getACT, security_pkg.getAPP, 'Divisions', 0, v_root_sid);
		UPDATE region_tree
		   SET is_divisions = 1
		  WHERE region_Tree_root_sid = v_root_sid;
	END IF;
	
	RETURN v_root_sid;
END;

PROCEDURE GetRegion(
	in_division_id		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_sid			security_pkg.T_SID_ID;
BEGIN
	-- some security check
	v_root_sid := GetRootDivisionSid;
	
	OPEN out_cur FOR
	  SELECT region_sid, pos 
	    FROM region r
	    WHERE r.region_sid IN (
		  SELECT region_sid
		    FROM division
		    WHERE division_id = in_division_id
			  AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		START WITH r.parent_sid = v_root_sid
		CONNECT BY PRIOR r.region_sid = r.parent_sid;
END;

PROCEDURE GetDivisions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- security check on root of divisions tree
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, GetRootDivisionSid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to root division tree');
	END IF;		

	OPEN out_cur FOR
		SELECT d.division_id, d.name, d.active, d.hidden
		  FROM division d
		  JOIN region r ON d.app_sid = r.app_sid AND d.region_sid = r.region_sid
		 WHERE d.app_sid = security_pkg.getApp
		   AND r.active = 1;
END;

PROCEDURE ClearDivisions(
	in_division_ids		IN security_pkg.T_SID_IDS
)
IS
	t security.T_SID_TABLE;
BEGIN
	-- security check on root of divisions tree
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, GetRootDivisionSid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to root division tree');
	END IF;		
	
	t := security_pkg.SidArrayToTable(in_division_ids);
	
	-- XXX: don't we need to delete from property_division too?
	-- XXX: It looks like the calling code prevents a divison from being deleted if it's in use by a property.
	
	FOR r IN (
		SELECT d.division_id, d.region_sid
		  FROM division d, region rg
		 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rg.region_sid = d.region_sid
		   AND rg.active = 1
		   AND d.division_id NOT IN (
				SELECT column_value division_id FROM TABLE(t)
		  )
	)
	LOOP
		DELETE FROM division
		 WHERE division_id = r.division_id;
		csr.region_pkg.trashobject(security_pkg.getACT, r.region_sid);
	END LOOP;
END;

PROCEDURE GetNewDivisionId(	
	out_division_id		OUT security_pkg.T_SID_ID
)
AS
BEGIN
	-- some security check
	SELECT division_id_seq.nextval
	  INTO out_division_id
	  FROM DUAL;
END;

PROCEDURE AddDivision(
	in_division_id		IN security_pkg.T_SID_ID,
	in_name				IN VARCHAR2,
	in_active			IN NUMBER
)
AS
	v_region_sid	security_pkg.T_SID_ID;
BEGIN
	-- region_pkg does security checks for us
	region_pkg.createRegion(
		in_parent_sid => GetRootDivisionSid,
		in_name => in_name,
		in_description => in_name,
		in_active => in_active,
		out_region_sid => v_region_sid
	);
	
	-- XXX: why do we keep name + active here? surely we could get from region table?
	INSERT INTO division (division_id, region_sid, app_sid, name, active)
	 VALUES (NVL(in_division_id, division_id_Seq.nextval), v_region_sid, SYS_CONTEXT('SECURITY', 'APP'), in_name, in_active);
END;

PROCEDURE SetDivision(
	in_division_id		IN security_pkg.T_SID_ID,
	in_name				IN VARCHAR2,
	in_active			IN NUMBER
)
AS
BEGIN
	-- some security check
	UPDATE division
	   SET name = in_name, active = in_active
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND division_id = in_division_id;
	
	-- XXX: this circumvents the audit log. bad idea....
	UPDATE region
	   SET active = in_active
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = (
		SELECT region_sid FROM division WHERE division_id = in_division_id
	   );
	   
	-- ick
	UPDATE region_description
	   SET description = in_name
	 WHERE region_sid = (SELECT region_sid 
	 					   FROM division 
	 					  WHERE division_id = in_division_id)
	   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
END;

PROCEDURE AllowDeleteDivision(
	in_division_id		IN security_pkg.T_SID_ID,
	out_count			OUT NUMBER
)
AS
BEGIN
	-- some security check
	SELECT COUNT(*)
	  INTO out_count
	  FROM property_division
	 WHERE division_id = in_division_id;
END;

PROCEDURE SetVisibleDivisions(
	in_division_ids		IN security_pkg.T_SID_IDS
)
IS
	t security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_division_ids);
	
	UPDATE division
	   SET hidden = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND division_id NOT IN (
			SELECT column_value division_id
			  FROM TABLE(t)
	);
	
	UPDATE division
	   SET hidden = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND division_id IN (
			SELECT column_value division_id
			  FROM TABLE(t)
	);
END;

-- -----------------------------------------------------------
-- Properties
-- -----------------------------------------------------------

PROCEDURE GetProperties(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.region_sid, r1.description name
		  FROM property p
		  JOIN v$region r1 ON p.region_sid = r1.region_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetProperty(
	in_region_sid		IN security_pkg.T_SID_ID,
	property_cur		OUT	SYS_REFCURSOR,
	division_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;		
	
	OPEN property_cur FOR
		SELECT p.region_sid, r.description name, r.geo_country, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode
		  FROM property p
			JOIN v$region r ON p.region_sid = r.region_sid
		 WHERE p.region_sid = in_region_Sid;
	
	OPEN division_cur FOR
		SELECT region_sid, division_id, ownership, area, start_dtm, end_dtm
		  FROM property_division
		 WHERE region_sid = in_region_Sid;
END;

PROCEDURE ExistProperty(
	in_region_sid		IN security_pkg.T_SID_ID,
	out_number			OUT NUMBER
)
AS
BEGIN
	SELECT COUNT(*)
	  INTO out_number
	  FROM PROPERTY
	 WHERE region_sid = in_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetProperty(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_street_addr_1	IN	property.street_addr_2%TYPE	DEFAULT NULL, 
	in_street_addr_2	IN	property.street_addr_2%TYPE DEFAULT NULL, 
	in_city				IN	property.city%TYPE DEFAULT NULL, 
	in_state			IN	property.state%TYPE DEFAULT NULL,	 
	in_postcode			IN	property.postcode%TYPE DEFAULT NULL
)
AS
	v_count				NUMBER(10);
	v_property_type_id		property.property_type_id%TYPE;
	v_property_sub_type_id	property.property_sub_type_id%TYPE;
BEGIN
	BEGIN
		SELECT p.property_type_id, p.property_sub_type_id
		  INTO v_property_type_id, v_property_sub_type_id
		  FROM region r
			LEFT JOIN property p ON r.region_sid = p.region_sid AND p.app_sid = r.app_sid
			LEFT JOIN property_type pt ON p.property_type_id = pt.property_Type_id AND p.app_sid = pt.app_sid
			LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_Type_id AND p.app_sid = pst.app_sid
		 WHERE r.region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_property_type_id:= NULL;
			v_property_sub_type_id := NULL;
	END;

	IF v_property_type_id IS NULL THEN 
		BEGIN
		SELECT property_type_id 
			INTO v_property_type_id
			FROM csr.property_type
			WHERE label = 'Default'
			AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN	
			 INSERT INTO csr.property_type (app_sid, property_type_id, label) VALUES (SYS_CONTEXT('SECURITY', 'APP'), csr.property_type_Id_seq.nextval, 'Default') returning property_Type_id INTO v_property_type_id;
		END;
	END IF;
	
	property_pkg.MakeProperty(
		in_act_id				=>	security_pkg.getACT,
		in_region_sid			=>	in_region_sid,
		in_property_type_id		=>	v_property_type_id,
		in_property_sub_type_id	=>	v_property_sub_type_id,
		in_street_addr_1		=>	in_street_addr_1,
		in_street_addr_2		=>	in_street_addr_2,
		in_city					=>	in_city,
		in_state				=>	in_state,
		in_postcode				=>	in_postcode,
		in_is_create			=>	0
	);
END;

PROCEDURE DeleteProperty(
	in_region_sid		IN security_pkg.T_SID_ID
)
AS
	v_root_sid			security_pkg.T_SID_ID;
	v_out_division_ids	security_pkg.T_OUTPUT_CUR;
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;
	
	v_root_sid := GetRootDivisionSid;
	FOR r IN (
		SELECT r.region_sid
		  FROM region r
			JOIN region division ON r.parent_sid = division.region_sid
			JOIN region link ON link.parent_sid = r.region_sid
			JOIN property p ON link.link_to_region_sid = p.region_sid
		 WHERE p.region_sid = in_region_sid
		   AND division.parent_sid = v_root_sid
	)
	LOOP
		region_pkg.trashobject(SYS_CONTEXT('SECURITY', 'ACT'), r.region_sid);
	END LOOP;
	
	ClearPropertyDivisions(in_region_sid, v_out_division_ids);
	 
	property_pkg.UnmakeProperty(
		in_act_id				=>	security_pkg.getACT,
		in_region_sid			=>	in_region_sid,
		in_region_type			=>	csr_data_pkg.REGION_TYPE_NORMAL
	);
END;


-- -----------------------------------------------------------
-- Properties Divisions
-- -----------------------------------------------------------

PROCEDURE ClearPropertyDivisions(
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_sid			security_pkg.T_SID_ID;
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;
	
	v_root_sid := GetRootDivisionSid;
	
	FOR r IN (
		SELECT r.region_sid, pd.start_dtm
		  FROM region r
			JOIN region division ON r.parent_sid = division.region_sid
			JOIN region link ON link.parent_sid = r.region_sid
			JOIN property p ON link.link_to_region_sid = p.region_sid
			JOIN property_division pd ON p.region_sid = pd.region_sid
		 WHERE p.region_Sid = in_region_sid
		   AND division.parent_sid = v_root_sid
	)
	LOOP
		csr.region_pkg.SetPctOwnership(SYS_CONTEXT('SECURITY', 'ACT'),
			r.region_sid, r.start_dtm, NULL);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT division_id
		  FROM property_division
		 WHERE region_sid = in_region_sid;
	
	DELETE FROM property_division
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE GetAllPropertyDivisions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT division_id, region_sid, start_dtm, ownership, area, end_dtm
		  FROM property_division pd;
END;

PROCEDURE GetAllPropDivisionsInPeriod(
	in_start_dtm		IN property_division.end_dtm%TYPE,
	in_end_dtm			IN property_division.start_dtm%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT division_id, region_sid, start_dtm, ownership, area, end_dtm
		  FROM property_division pd
		 WHERE (
				in_end_dtm IS NULL
				OR pd.start_dtm < in_end_dtm
		   )
		   AND (
				in_start_dtm IS NULL
				OR pd.end_dtm IS NULL
				OR pd.end_dtm > in_start_dtm
		   );
END;

PROCEDURE GetPropertyDivisions(
	in_region_sid		IN security_pkg.T_SID_ID,
	in_start_dtm		IN property_division.end_dtm%TYPE,
	in_end_dtm			IN property_division.start_dtm%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT division_id, region_sid, start_dtm, ownership, area, end_dtm
		  FROM property_division pd
		 WHERE pd.region_sid = in_region_sid
		   AND (
				in_end_dtm IS NULL
				OR pd.start_dtm < in_end_dtm
		   )
		   AND (
				in_start_dtm IS NULL
				OR pd.end_dtm IS NULL
				OR pd.end_dtm > in_start_dtm
		   );
END;

FUNCTION AddPropertyDivision(
	in_region_sid		IN security_pkg.T_SID_ID,
	in_division_id		IN security_pkg.T_SID_ID,
	in_ownership		IN NUMBER,
	in_area				IN NUMBER,
	in_start_dtm		IN property_division.start_dtm%TYPE,
	in_end_dtm			IN property_division.end_dtm%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_count						NUMBER(10);
	v_division_region_sid		security_pkg.T_SID_ID;
	v_region_sid				security_pkg.T_SID_ID;
	v_link_name					VARCHAR(1023);
	v_dummy_region_sid			security_pkg.T_SID_ID;
	v_link_region_sid			security_pkg.T_SID_ID;
BEGIN
	-- some security check
	
	BEGIN
		INSERT INTO property_division (region_sid, division_id, ownership, area, start_dtm, end_dtm)
			VALUES (in_region_sid, in_division_id, in_ownership, in_area, in_start_dtm, in_end_dtm);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE property_division
			   SET ownership = in_ownership, area = in_area, end_dtm = in_end_dtm
			 WHERE region_sid = in_region_sid
			   AND division_id = in_division_id
			   AND start_dtm = in_start_dtm;
	END;
	
	SELECT region_sid
	  INTO v_division_region_sid
	  FROM division
	 WHERE division_id = in_division_id;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM (
			SELECT 1
			  FROM dual
			 WHERE EXISTS (
					SELECT 1
					  FROM region
					 WHERE link_to_region_sid = in_region_sid
					   AND parent_sid IN (
							SELECT region_sid
							  FROM region
							 WHERE parent_sid = v_division_region_sid
						)
				)
	);
	
	IF v_count = 0 THEN
		SELECT TRIM(r.description)
		  INTO v_link_name
		  FROM v$region r
			JOIN property p ON r.region_sid = p.region_sid
		 WHERE p.region_sid = in_region_sid;
		
		-- Only create if there isn't one already.
		SELECT COUNT(*)
		  INTO v_count
		  FROM (
				SELECT 1
				  FROM dual
				 WHERE EXISTS (
						SELECT 1
						 FROM v$region
						WHERE parent_sid = v_division_region_sid
						  AND replace(LOWER(description), ' ', '') = replace(LOWER(v_link_name), ' ', '')
					)
			);
		
		IF v_count = 0 THEN
			csr.region_pkg.createRegion(
				in_parent_sid => v_division_region_sid,
				in_name => v_link_name,
				in_description => v_link_name,
				out_region_sid => v_dummy_region_sid
			);
		ELSE
			SELECT region_sid
			  INTO v_dummy_region_sid
			  FROM v$region
			 WHERE parent_sid = v_division_region_sid
			   AND description = v_link_name;
		END IF;
		
		-- Only create link if it doesn't already exist.
		-- This assumes only one link to this region under the parent.
		SELECT COUNT(*)
		  INTO v_count
		  FROM (
				SELECT 1
				  FROM dual
				 WHERE EXISTS (
						SELECT 1
						  FROM v$region
						 WHERE link_to_region_sid = v_link_region_sid
						   AND parent_sid = v_dummy_region_sid
					)
		);
		
		IF v_count = 0 THEN
			csr.region_pkg.CreateLinkToRegion(SYS_CONTEXT('SECURITY', 'ACT'),
				v_dummy_region_sid, in_region_sid, v_link_region_sid);
		END IF;
	ELSE
		SELECT r.region_sid
		  INTO v_dummy_region_sid
		  FROM region r
			JOIN region link ON link.parent_sid = r.region_sid
		 WHERE link.link_to_region_sid = in_region_sid
		   AND r.parent_sid = v_division_region_sid;
	END IF;
		
	csr.region_pkg.SetPctOwnership(SYS_CONTEXT('SECURITY', 'ACT'),
		v_dummy_region_sid, in_start_dtm, in_ownership / 100);
	
	RETURN v_dummy_region_sid;
END;

PROCEDURE RemovePropertyFromDivision(
	in_region_sid		IN security_pkg.T_SID_ID,
	in_division_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	FOR rr IN (
		SELECT r.region_sid
		  FROM region r
			  JOIN region link ON r.region_sid = link.parent_sid
			  JOIN property p ON link.link_to_region_sid = p.region_sid
			  JOIN division d ON r.parent_sid = d.region_sid
		 WHERE p.region_sid = in_region_sid
		   AND d.division_id = in_division_id
	)
	LOOP
		csr.region_pkg.trashobject(SYS_CONTEXT('SECURITY', 'ACT'), rr.region_sid);
	END LOOP;
END;

END;
/