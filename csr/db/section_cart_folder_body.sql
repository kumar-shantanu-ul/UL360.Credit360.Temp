CREATE OR REPLACE PACKAGE BODY CSR.section_cart_folder_Pkg
IS

FUNCTION GetRootFolderId
RETURN NUMBER
AS
	v_root_id	section_cart_folder.section_cart_folder_id%TYPE;
	CURSOR root_cur IS
		SELECT section_cart_folder_id
		  FROM section_cart_folder
		 WHERE is_root = 1;
BEGIN
	OPEN root_cur;
	FETCH root_cur INTO v_root_id;

	IF root_cur%NOTFOUND THEN
	-- if not found, create root folder
		-- For tree views to work, all nodes need a parent node
		INSERT INTO section_cart_folder 
				(section_cart_folder_id, parent_id, name, is_visible, is_root)
		VALUES	(section_cart_folder_id_seq.NEXTVAL, null, 'Carts', 1, 1)
		RETURNING section_cart_folder_id INTO v_root_id;
	END IF;

	RETURN v_root_id;
END;

PROCEDURE GetRootFolder(
	out_cur		OUT	SYS_REFCURSOR
)
AS
	v_root_id	section_cart_folder.section_cart_folder_id%TYPE;
BEGIN
	v_root_id := GetRootFolderId();

	OPEN out_cur FOR
		SELECT	section_cart_folder_id,
				section_cart_folder_id sid,
				parent_id,
				name,
				is_visible,
				is_root
		  FROM	section_cart_folder
		 WHERE	section_cart_folder_id = v_root_id;
END;

PROCEDURE GetFolderTreeWithDepth(
	in_parent_id	IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_fetch_depth	IN	NUMBER,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT section_cart_folder_id sid_id, parent_id parent_sid_id, name, so_level, is_leaf, is_visible, is_root
		FROM (
				SELECT section_cart_folder_id,
						parent_id,
						name,
						level so_level,
				CONNECT_BY_ISLEAF is_leaf,
						is_visible,
						is_root
				  FROM section_cart_folder
			START WITH (parent_id = in_parent_id)
			CONNECT BY PRIOR section_cart_folder_id = parent_id
				 ORDER SIBLINGS BY LOWER(name)
		) WHERE (in_fetch_depth IS NULL OR so_level <= in_fetch_depth);
END;

PROCEDURE GetFolderTreeTextFiltered(
	in_parent_id		IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t1.section_cart_folder_id sid_id, 
				t1.parent_id parent_sid_id, 
				t1.name, 
				t1.so_level, 
				t1.is_leaf, 
				DECODE(t3.section_cart_folder_id, NULL, 0, 1) is_match,
				t1.is_visible
		  FROM (
					SELECT rownum rn, section_cart_folder_id,
							parent_id,
							name,
							level so_level,
							CONNECT_BY_ISLEAF is_leaf,
							is_visible,
							is_root
					  FROM section_cart_folder
				START WITH (parent_id = 1)
				CONNECT BY PRIOR section_cart_folder_id = parent_id
					 ORDER SIBLINGS BY LOWER(name)
				) t1, -- full tree
				(
					SELECT DISTINCT section_cart_folder_id
					FROM section_cart_folder
					START WITH section_cart_folder_id IN (
								SELECT section_cart_folder_id
								  FROM section_cart_folder
								 WHERE LOWER(name) LIKE '%welsh%'
								  START WITH section_cart_folder_id = 1
							CONNECT BY PRIOR section_cart_folder_id = parent_id
					)
					CONNECT BY PRIOR parent_id = section_cart_folder_id
				) t2, -- ids of folders containing a match in children
				(
					SELECT section_cart_folder_id
					  FROM section_cart_folder
					 WHERE LOWER(name) LIKE '%welsh%'
				START WITH (parent_id = 1)
				CONNECT BY PRIOR section_cart_folder_id = parent_id
				) t3
		 WHERE t1.section_cart_folder_id = t2.section_cart_folder_id
       AND t1.section_cart_folder_id = t3.section_cart_folder_id(+)
		   AND (1 IS NULL OR t1.so_level <= 100)
		 ORDER BY t1.rn;
END;

-- Get tree with depth OR child is selected
PROCEDURE GetFolderTreeWithSelect(
	in_parent_id	IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_select_id	IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_fetch_depth	IN	NUMBER,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT section_cart_folder_id sid_id, 
				parent_id parent_sid_id,
				name,
				so_level,
				is_leaf,
				1 is_match,
				is_visible
		  FROM (
					SELECT section_cart_folder_id,
							parent_id,
							name,
							level so_level,
							CONNECT_BY_ISLEAF is_leaf,
							is_visible,
							is_root
					  FROM section_cart_folder
				START WITH (parent_id = in_parent_id)
				CONNECT BY PRIOR section_cart_folder_id = parent_id
					 ORDER SIBLINGS BY LOWER(name)
				)
		  WHERE so_level <= in_fetch_depth
				OR section_cart_folder_id IN (
						SELECT section_cart_folder_id
						  FROM section_cart_folder
					START WITH section_cart_folder_id = in_select_id
					CONNECT BY PRIOR parent_id = section_cart_folder_id
				);
END;

PROCEDURE GetFolderList(
	in_parent_id		IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t1.section_cart_folder_id sid_id,
				t1.parent_id parent_sid_id,
				t1.name,
				t1.so_level,
				t1.is_leaf,
				SUBSTR(t1.path, 2) path,
				1 is_match,
				t1.is_visible
		  FROM (
					SELECT rownum rn,
							section_cart_folder_id,
							parent_id,
							name,
							level so_level,
							CONNECT_BY_ISLEAF is_leaf,
							SYS_CONNECT_BY_PATH(name,'/') path,
							is_visible,
							is_root
					  FROM section_cart_folder
				START WITH (parent_id = in_parent_id)
				CONNECT BY PRIOR section_cart_folder_id = parent_id
					 ORDER SIBLINGS BY LOWER(name)
				) t1
		 WHERE t1.section_cart_folder_id <> in_parent_id
		   AND (in_search_phrase IS NULL OR LOWER(name) LIKE '%' || LOWER(in_search_phrase) || '%')
		   AND (in_fetch_depth IS NULL OR t1.so_level <= in_fetch_depth)
		 ORDER BY t1.rn;
END;

PROCEDURE CreateFolder(
	in_parent_id	IN section_cart_folder.parent_id%TYPE,
	in_name			IN section_cart_folder.name%TYPE,
	out_folder_id	OUT section_cart_folder.section_cart_folder_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	INSERT INTO section_cart_folder 
				(section_cart_folder_id, parent_id, name, is_visible, is_root)
		VALUES	(section_cart_folder_id_seq.NEXTVAL, in_parent_id, in_name, 1, 0)
	RETURNING section_cart_folder_id INTO out_folder_id;
END;

PROCEDURE RenameFolder(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE,
	in_name			IN section_cart_folder.name%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	UPDATE section_cart_folder
	   SET name = in_name
	 WHERE section_cart_folder_id = in_folder_id;
END;

PROCEDURE MoveFolder(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE,
	in_parent_id	IN section_cart_folder.parent_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	UPDATE section_cart_folder
	   SET parent_id = in_parent_id
	 WHERE section_cart_folder_id = in_folder_id;
END;

PROCEDURE SetFolderVisibility(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE,
	in_is_visible	IN section_cart_folder.is_visible%TYPE
)
AS
BEGIN
	UPDATE section_cart_folder
	   SET is_visible = in_is_visible
	 WHERE section_cart_folder_id = in_folder_id;
END;


PROCEDURE DeleteFolder(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE
)
AS
	v_folders		NUMBER(10);
	v_carts		NUMBER(10);
	v_is_root	section_cart_folder.is_root%TYPE;
	v_root_id	section_cart_folder.section_cart_folder_id%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	-- tweek to check if any child folder has contents and if not, delete child folders too.
	SELECT COUNT(scfc.parent_id), COUNT(sc.section_cart_id), scf.is_root
	  INTO v_folders, v_carts, v_is_root
	  FROM section_cart_folder scf
	  LEFT JOIN section_cart_folder scfc ON scf.section_cart_folder_id = scfc.parent_id
	  LEFT JOIN section_cart sc ON scf.section_cart_folder_id = sc.section_cart_folder_id
	 WHERE scf.section_cart_folder_id = in_folder_id
	 GROUP BY scf.section_cart_folder_id, scf.is_root;

	IF v_folders > 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'Only empty folders can be deleted.');
	END IF;

	IF v_is_root  = 1 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'Root folder cannot be deleted.');
	END IF;

	IF v_carts > 0 THEN
		-- delete carts in this folder
		FOR r IN (
			SELECT section_cart_id
			  FROM section_cart
			 WHERE section_cart_folder_id = in_folder_id
		)
		LOOP
			section_pkg.DeleteCart(r.section_cart_id);
		END LOOP;
	END IF;

	DELETE FROM section_cart_folder WHERE section_cart_folder_id = in_folder_id;
END;

PROCEDURE MoveSectionCart(
	in_cart_id		IN section_cart.section_cart_id%TYPE,
	in_folder_id	IN section_cart.section_cart_folder_id%TYPE
)
AS
BEGIN
	UPDATE section_cart
	   SET section_cart_folder_id = in_folder_id
	 WHERE section_cart_id = in_cart_id;
END;

PROCEDURE GetCarts(
	in_folder_id	IN section_cart.section_cart_folder_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sc.section_cart_id, sc.name, sc.section_cart_folder_id parent_sid, '' description, COUNT(scm.section_cart_id) question_count
		  FROM section_cart sc
	LEFT JOIN section_cart_member scm ON sc.section_cart_id = scm.section_cart_id
		 WHERE sc.section_cart_folder_id = in_folder_id
	 GROUP BY sc.section_cart_id, sc.name, sc.section_cart_folder_id
	 ORDER BY LOWER(name);
END;

END section_cart_folder_Pkg;
/