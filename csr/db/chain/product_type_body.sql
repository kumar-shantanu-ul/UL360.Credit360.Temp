CREATE OR REPLACE PACKAGE BODY CHAIN.product_type_pkg
IS

PROCEDURE INTERNAL_AssertTreeIntegrity (
	in_parent_id			IN	product_type.product_type_id%TYPE
)
AS
	v_app_sid				security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM product_type
	 WHERE product_type_id = in_parent_id
	   AND node_type = PRODUCT_TYPE_LEAF
	   AND app_sid = v_app_sid;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Leaf node '||in_parent_id||' cannot have child elements.');
	END IF;

	BEGIN
		SELECT COUNT(*)
		  INTO v_count
		  FROM product_type
		 START WITH (parent_product_type_id = in_parent_id)
	   CONNECT BY PRIOR product_type_id = parent_product_type_id;
	EXCEPTION
		WHEN OTHERS THEN
		  IF SQLCODE = -01436 THEN --CONNECT BY loop in user data
			RAISE_APPLICATION_ERROR(-20001, 'Assign node '||in_parent_id||' as parent causes a loop in the tree.');
		  ELSE
			 RAISE;
		  END IF;
	END;

END;

PROCEDURE INTERNAL_AssrtValidDescription (
	in_description			IN	product_type_tr.description%TYPE
)
AS
	v_location				NUMBER;
BEGIN

	-- We use '>' to create paths so we don't allow descriptions to contain it.
	v_location := INSTR(in_description, '>');

	IF v_location > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Description cannot contain char: '||'>');
	END IF;

END;

FUNCTION INTERNAL_GetRootProductType
RETURN product_type.product_type_id%TYPE
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_count			NUMBER;
	v_id			product_type.product_type_id%TYPE;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM product_type
	 WHERE parent_product_type_id IS NULL
	   AND app_sid = v_app_sid;

	IF v_count > 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Configuration fault: multiple product type roots.');
	END IF;

	SELECT product_type_id
	  INTO v_id
	  FROM product_type
	 WHERE parent_product_type_id IS NULL
	   AND app_sid = v_app_sid;
	RETURN v_id;
END;

FUNCTION GetRootProductType
RETURN product_type.product_type_id%TYPE
AS
	v_id			product_type.product_type_id%TYPE;
BEGIN
	BEGIN
		v_id := INTERNAL_GetRootProductType;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'No Product Types were found');
	END;
	RETURN v_id;
END;

FUNCTION CreateRootProductType
RETURN product_type.product_type_id%TYPE
AS
	v_id			product_type.product_type_id%TYPE;
BEGIN

BEGIN
	v_id := INTERNAL_GetRootProductType;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			AddProductType (
				in_parent_product_type_id	=> null,
				in_description				=> DEFAULT_ROOT_DESCRIPTION,
				in_node_type				=> product_type_pkg.PRODUCT_TYPE_FOLDER,
				out_product_type_id			=> v_id
			);
	END;

	RETURN v_id;
END;

PROCEDURE AddProductType (
	in_parent_product_type_id	IN	product_type.parent_product_type_id%TYPE,
	in_description				IN	product_type_tr.description%TYPE,
	in_lookup_key				IN	product_type.lookup_key%TYPE DEFAULT NULL,
	in_node_type				IN	product_type.node_type%TYPE DEFAULT product_type_pkg.PRODUCT_TYPE_LEAF,
	in_active					IN	product_type.active%TYPE DEFAULT 1,
	out_product_type_id			OUT	product_type.product_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add product types.');
	END IF;

	INTERNAL_AssrtValidDescription(in_description);

	SELECT product_type_id_seq.NEXTVAL
	  INTO out_product_type_id
	  FROM dual;

	-- Use the product type id in the label field to ensure uniqueness and avoid the messy first name being used but never modifable later.
	INSERT INTO product_type (product_type_id, parent_product_type_id, label, lookup_key, node_type, active)
	VALUES (out_product_type_id, in_parent_product_type_id, out_product_type_id, in_lookup_key, in_node_type, in_active);

	INSERT INTO product_type_tr (product_type_id, lang, description, last_changed_dtm_description)
		SELECT out_product_type_id, lang, in_description, SYSDATE
		  FROM csr.v$customer_lang;

	INTERNAL_AssertTreeIntegrity(in_parent_product_type_id);

	-- audit
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, SYS_CONTEXT('SECURITY','APP'), NULL, 
		'Added Product Type "' || in_description || '" "' || in_lookup_key || '" node_type=' || in_node_type || ' active=' || in_active,
		out_product_type_id);
END;

PROCEDURE DeleteProductType (
	in_product_type_id	IN	product_type.product_type_id%TYPE
)
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_description	product_type_tr.description%TYPE;
	v_lookup_key	product_type.lookup_key%TYPE;
	v_node_type		product_type.node_type%TYPE;
	v_active		product_type.active%TYPE;

	CURSOR c_child IS
	   SELECT product_type_id FROM chain.product_type WHERE parent_product_type_id = in_product_type_id;
	
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can delete product types.');
	END IF;
	

	FOR r_child IN c_child LOOP
       DeleteProductType(r_child.product_type_id);
    END LOOP;

	SELECT description, lookup_key, node_type, active
	  INTO v_description, v_lookup_key, v_node_type, v_active
	  FROM v$product_type
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = v_app_sid;

	/* TODO
	IF r.has_products THEN
		RAISE_APPLICATION_ERROR(-20001, 'Product type ' || in_product_type_id || ' contains product records');
	END IF;
	*/
		
	DELETE FROM product_type
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = v_app_sid;
		   
	-- audit
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, v_app_sid, NULL, 
		'Deleted Product Type "' || v_description || '" "' || v_lookup_key || '" node_type=' || v_node_type || ' active=' || v_active,
		in_product_type_id);
END;

PROCEDURE RenameProductType (
	in_product_type_id	IN	product_type.product_type_id%TYPE,
	in_description 		IN	product_type_tr.description%TYPE,
	in_audit			IN  NUMBER
)
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_description	product_type_tr.description%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;

	INTERNAL_AssrtValidDescription(in_description);

	SELECT description
	  INTO v_description
	  FROM v$product_type
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = v_app_sid;

	IF v_description = in_description THEN
		-- Avoid auditing and updating last changed timestamps if nothing changed.
		RETURN;
	END IF;
	   
	UPDATE product_type_tr
	   SET description = in_description, last_changed_dtm_description = SYSDATE
	 WHERE product_type_id = in_product_type_id
	   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANG'), 'en')
	   AND app_sid = v_app_sid;

	IF in_audit = 1 THEN
		-- audit
		csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, v_app_sid, NULL, 
			'Renamed Product Type from "' || v_description || '" to "' || in_description || '"',
			in_product_type_id);
	END IF;
END;

PROCEDURE RenameProductType (
	in_product_type_id	IN	product_type.product_type_id%TYPE,
	in_description 		IN	product_type_tr.description%TYPE
)
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_description	product_type_tr.description%TYPE;
BEGIN
	RenameProductType(in_product_type_id, in_description, 1);
END;

PROCEDURE MoveProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE,
	in_new_parent_id			IN	product_type.product_type_id%TYPE
)
AS
	v_app_sid 					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_parent_product_type_id	product_type.parent_product_type_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;
	
	SELECT parent_product_type_id
	  INTO v_parent_product_type_id
	  FROM product_type
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = v_app_sid;

	UPDATE product_type
	   SET parent_product_type_id = in_new_parent_id
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	INTERNAL_AssertTreeIntegrity(in_new_parent_id);

	-- audit
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, v_app_sid, NULL, 
		'Moved Product Type ' || in_product_type_id || ' from parent ' || v_parent_product_type_id || ' to ' || in_new_parent_id,
		in_product_type_id);
END;

PROCEDURE AmendProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE,
	in_description				IN	product_type_tr.description%TYPE,
	in_lookup_key				IN	product_type.lookup_key%TYPE,
	in_node_type				IN	product_type.node_type%TYPE,
	in_active					IN	product_type.active%TYPE
)
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_description	product_type_tr.description%TYPE;
	v_lookup_key	product_type.lookup_key%TYPE;
	v_node_type		product_type.node_type%TYPE;
	v_active		product_type.active%TYPE;
	
	v_desc_changed			VARCHAR2(2000);
	v_lookup_key_changed	VARCHAR2(1000);
	v_node_type_changed		VARCHAR2(100);
	v_active_changed		VARCHAR2(100);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;
	
	SELECT description, lookup_key, node_type, active
	  INTO v_description, v_lookup_key, v_node_type, v_active
	  FROM v$product_type
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = v_app_sid;

	IF v_description = in_description AND
	   v_lookup_key = in_lookup_key AND
	   v_node_type = in_node_type AND
	   v_active = in_active
	THEN
		-- Avoid auditing and updating last changed timestamps if nothing changed.
		RETURN;
	END IF;
	
	UPDATE product_type
	   SET lookup_key = in_lookup_key, node_type = in_node_type, active = in_active
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	RenameProductType(in_product_type_id, in_description, 0);
	
	-- audit
	IF v_description != in_description THEN
		v_desc_changed := 'description changed from "' || v_description || '" to "' || in_description || '"; ';
	END IF;
	IF v_lookup_key != in_lookup_key THEN
		v_lookup_key_changed := 'lookup_key changed from "' || v_lookup_key || '" to "' || in_lookup_key || '"; ';
	END IF;
	IF v_node_type != in_node_type THEN
		v_node_type_changed := 'node_type changed from "' || v_node_type || '" to "' || in_node_type || '"; ';
	END IF;
	IF v_active != in_active THEN
		v_active_changed := 'active changed from "' || v_active || '" to "' || in_active || '"; ';
	END IF;
	
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, v_app_sid, NULL, 
		TRIM('Amended Product Type; ' || v_desc_changed || v_lookup_key_changed || v_node_type_changed || v_active_changed),
		in_product_type_id);
END;

PROCEDURE ActivateProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE
)
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;
	
   UPDATE product_type
	   SET active = 1
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

   -- audit
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, v_app_sid, NULL, 
		'Activated Product Type ' || in_product_type_id,
		in_product_type_id);
END;

PROCEDURE DeactivateProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE
)
AS
	v_app_sid 		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;
	
	UPDATE product_type
	   SET active = 0
	 WHERE product_type_id = in_product_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

   -- audit
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr.csr_data_pkg.AUDIT_TYPE_CHAIN_PRODUCT_TYPE, v_app_sid, NULL, 
		'Deactivated Product Type ' || in_product_type_id,
		in_product_type_id);
END;


-- Tree functions

PROCEDURE GetTreeWithDepth(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	in_include_root					IN	NUMBER DEFAULT 0,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_type_id,
				parent_product_type_id,
				description,
				level node_level,
				CONNECT_BY_ISLEAF is_leaf,
				SYS_CONNECT_BY_PATH(description, '>') path
		  FROM chain.v$product_type
		 WHERE (node_type = 1 OR in_include_leaf_nodes = 1)
	 	   AND (in_fetch_depth IS NULL OR level <= in_fetch_depth)
		 START WITH ((in_include_root = 1 AND product_type_id = in_parent_sid) OR (in_include_root = 0 AND parent_product_type_id = in_parent_sid))
		CONNECT BY PRIOR product_type_id = parent_product_type_id
		 ORDER SIBLINGS BY LOWER(description);
END;

PROCEDURE GetTreeWithSelect(
	in_parent_sid   				IN	security_pkg.T_SID_ID,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_type_id,
				parent_product_type_id,
				description,
				level node_level,
				CONNECT_BY_ISLEAF is_leaf,
				SYS_CONNECT_BY_PATH(description,'>') path
		  FROM chain.v$product_type
		 WHERE (node_type = 1 OR in_include_leaf_nodes = 1)
	 	   AND (in_fetch_depth IS NULL OR level <= in_fetch_depth)
		 START WITH (parent_product_type_id = in_parent_sid)
		CONNECT BY PRIOR product_type_id = parent_product_type_id
		 ORDER SIBLINGS BY LOWER(description);
END;

PROCEDURE GetTreeTextFiltered(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_fetch_depth NUMBER := NULL;
BEGIN
	OPEN out_cur FOR
		SELECT pt.product_type_id, pt.parent_product_type_id, pt.description, pt.node_level, pt.is_leaf, pt.path
		  FROM (
			SELECT rownum rn, 
					product_type_id,
					parent_product_type_id,
					description,
					level node_level,
					CONNECT_BY_ISLEAF is_leaf,
					SYS_CONNECT_BY_PATH(description,'>') path,
					node_type
			   FROM chain.v$product_type
			  WHERE (node_type = 1 OR in_include_leaf_nodes = 1)
				AND (v_fetch_depth IS NULL OR level <= v_fetch_depth)
			  START WITH (parent_product_type_id = in_parent_sid)
			CONNECT BY PRIOR product_type_id = parent_product_type_id
			 ORDER SIBLINGS BY LOWER(description)
			) pt, (
			SELECT DISTINCT product_type_id
			 FROM chain.v$product_type
			START WITH product_type_id IN (
				SELECT product_type_id
				  FROM chain.v$product_type
				 WHERE LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'
				 START WITH product_type_id = in_parent_sid
				CONNECT BY PRIOR product_type_id = parent_product_type_id)
			CONNECT BY PRIOR parent_product_type_id = product_type_id
			) ptm, (
			SELECT product_type_id, 1 is_match
      		  FROM chain.v$product_type
      	     WHERE LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'
	         START WITH product_type_id = in_parent_sid
		    CONNECT BY PRIOR product_type_id = parent_product_type_id
			) ptmt 
			WHERE pt.product_type_id = ptm.product_type_id 
			  AND pt.product_type_id = ptmt.product_type_id(+) 
			ORDER BY pt.rn;
END;

PROCEDURE GetList(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_type_id,
				parent_product_type_id,
				description,
				level node_level,
				CONNECT_BY_ISLEAF is_leaf,
				SYS_CONNECT_BY_PATH(description,'>') path,
				active is_visible,
				CASE WHEN parent_product_type_id = in_parent_sid THEN 1 ELSE 0 END is_root,
				1 is_match
		  FROM chain.v$product_type
		 WHERE (node_type = 1 OR in_include_leaf_nodes = 1)
		 START WITH (parent_product_type_id = in_parent_sid)
		CONNECT BY PRIOR product_type_id = parent_product_type_id
		  ORDER SIBLINGS BY LOWER(description);
END;

PROCEDURE ExportProductTypes(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_type_id,
				description,
				SYS_CONNECT_BY_PATH(description,'>') path
		  FROM chain.v$product_type
		 WHERE node_type = 1
		 START WITH (parent_product_type_id = in_parent_sid)
		CONNECT BY PRIOR product_type_id = parent_product_type_id
		  ORDER SIBLINGS BY LOWER(description);
END;

PROCEDURE GetListTextFiltered(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_type_id,
				parent_product_type_id,
				description,
				node_level,
				is_leaf,
				path,
				is_visible,
				is_root,
				is_match
		FROM (
			SELECT rownum rn,
					product_type_id,
					parent_product_type_id,
					description,
					level node_level,
					CONNECT_BY_ISLEAF is_leaf,
					SYS_CONNECT_BY_PATH(description,'>') path,
					active is_visible,
					CASE WHEN parent_product_type_id = in_parent_sid THEN 1 ELSE 0 END is_root,
					1 is_match
			  FROM chain.v$product_type
			 WHERE (node_type = 1 OR in_include_leaf_nodes = 1)
			 START WITH (parent_product_type_id = in_parent_sid)
			CONNECT BY PRIOR product_type_id = parent_product_type_id
				 ORDER SIBLINGS BY LOWER(description)
			) unfiltered
		 WHERE unfiltered.product_type_id <> in_parent_sid
		   AND (in_search_phrase IS NULL OR LOWER(description) LIKE '%' || LOWER(in_search_phrase) || '%')
		   AND (in_limit IS NULL OR unfiltered.node_level <= in_limit)
		 ORDER BY unfiltered.rn;
END;

PROCEDURE GetFolderChildren(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_type_id,
				description
		  FROM chain.v$product_type
		 WHERE node_type = 0
		   AND parent_product_type_id = in_parent_sid
		 ORDER BY LOWER(description);
END;

PROCEDURE GetProductTypes(
	in_node_type			IN	NUMBER DEFAULT NULL,
	in_include_inactive		IN	NUMBER DEFAULT 1,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_root_type_id			product_type.product_type_id%TYPE := GetRootProductType;
BEGIN

	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT t.product_type_id, t.parent_product_type_id, t.description, t.lookup_key, t.node_type, t.active,
			   tree.tree_level, tree.tree_path, 
			CASE NVL(MAX(p.product_id), -1) WHEN -1 THEN 0 ELSE 1 END in_use
		  FROM chain.v$product_type t
		  LEFT JOIN chain.company_product p ON p.product_type_id = t.product_type_id
		  JOIN (
				SELECT product_type_id, LEVEL tree_level, REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description, ''), ''), '', ' / ')  tree_path
				  FROM chain.v$product_type
				 START WITH product_type_id = v_root_type_id
			   CONNECT BY parent_product_type_id = PRIOR product_type_id
		  ) tree ON tree.product_type_id = t.product_type_id
		 WHERE (in_include_inactive > 0 OR t.active = 1)
		   AND (in_node_type IS NULL OR t.node_type = in_node_type)
		   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 GROUP BY t.product_type_id, t.parent_product_type_id, t.description, t.lookup_key, t.node_type, t.active, tree.tree_level, tree.tree_path
		 ORDER BY tree.tree_path;
END;

PROCEDURE GetProductType(
	in_product_type_id		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT product_type_id, parent_product_type_id, description, lookup_key, node_type, active
		  FROM chain.v$product_type
		 WHERE product_type_id = in_product_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetAllTranslations(
	in_root_product_type_id	IN	product_type.product_type_id%TYPE,
	in_validation_lang		IN	product_type_tr.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		WITH producttype AS (
			SELECT app_sid, product_type_id, active, lvl, ROWNUM rn
			FROM (
				 SELECT p.app_sid,
						p.product_type_id,
						tr.description,
						p.active,
						LEVEL lvl
				   FROM product_type p
				   JOIN product_type_tr tr 
							 ON p.app_sid = tr.app_sid
							AND p.product_type_id = tr.product_type_id
							AND tr.lang = NVL(in_validation_lang, 'en')
				  WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				  START WITH (p.product_type_id = in_root_product_type_id)
				CONNECT BY PRIOR p.product_type_id = p.parent_product_type_id
				  ORDER SIBLINGS BY LOWER(tr.description)
			)
		)
		SELECT pt.product_type_id, pt.active, ptt.description, ptt.lang, pt.lvl o_level,
			   CASE WHEN ptt.last_changed_dtm_description > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM producttype pt
		  JOIN aspen2.translation_set ts ON pt.app_sid = ts.application_sid
		  LEFT JOIN chain.product_type_tr ptt ON pt.app_sid = ptt.app_sid AND pt.product_type_id = ptt.product_type_id AND ts.lang = ptt.lang
		 ORDER BY rn,
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateTranslations(
	in_product_type_ids		IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	product_type_tr.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_product_type_desc_tbl		T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
	v_can_write					NUMBER(1) := 1;
BEGIN
	IF in_product_type_ids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of product type IDs do not match number of descriptions.');
	END IF;
	
	IF in_product_type_ids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_product_type_desc_tbl.EXTEND(in_product_type_ids.COUNT);

	FOR i IN 1..in_product_type_ids.COUNT
	LOOP
		v_product_type_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_product_type_ids(i), in_descriptions(i));
	END LOOP;

	IF NOT (security_pkg.IsAdmin(SYS_CONTEXT('SECURITY', 'ACT')) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		v_can_write := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT ptt.product_type_id sid,
			   CASE ptt.description WHEN pt.description THEN 0 ELSE 1 END has_changed,
			   v_can_write can_write
		  FROM product_type_tr ptt
		  JOIN TABLE(v_product_type_desc_tbl) pt ON ptt.product_type_id = pt.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = in_validation_lang;
END;

PROCEDURE SetTranslation(
	in_product_type_id	IN	product_type.product_type_id%TYPE,
	in_lang				IN	product_type_tr.LANG%TYPE,
	in_translated		IN	VARCHAR2
)
AS
	v_description	product_type_tr.description%TYPE;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;

	BEGIN
		SELECT description
		  INTO v_description
		  FROM product_type_tr
		 WHERE product_type_id = in_product_type_id 
		   AND lang = in_lang;

		IF v_description != in_translated THEN
			UPDATE product_type_tr
			   SET last_changed_dtm_description = SYSDATE,
			       description = in_translated
			 WHERE product_type_id = in_product_type_id 
			   AND lang = in_lang;
		END IF;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO product_type_tr
				(product_type_id, lang, description, last_changed_dtm_description)
			VALUES
				(in_product_type_id, in_lang, in_translated, SYSDATE);
	END;

END;

PROCEDURE TryGetTypeFromDescription(
	in_description		IN product_type_tr.description%TYPE,
	out_product_type_id	OUT product_type.product_type_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT p.product_type_id INTO out_product_type_id
		  FROM product_type p
		  JOIN product_type_tr t
				 ON p.product_type_id = t.product_type_id
				AND p.app_sid = t.app_sid
		 WHERE LOWER(t.description) = LOWER(in_description)
		   AND p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 GROUP BY p.product_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_product_type_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_product_type_id := -1;
	END;
END;

PROCEDURE TryGetTypeFromLookupKey(
	in_lookup_key			IN product_type.lookup_key%TYPE,
	out_product_type_id		OUT product_type.product_type_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT product_type_id INTO out_product_type_id
		  FROM product_type
		 WHERE LOWER(lookup_key) = LOWER(in_lookup_key)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 GROUP BY product_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_product_type_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_product_type_id := -1;
	END;
END;

PROCEDURE ConfirmProductTypeIdExists(
	in_product_type_id		IN product_type.product_type_id%TYPE,
	out_product_type_id		OUT product_type.product_type_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT product_type_id INTO out_product_type_id
		  FROM product_type
		 WHERE product_type_id = in_product_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_product_type_id := -1;
	END;
END;

END product_type_pkg;
/
