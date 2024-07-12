CREATE OR REPLACE PACKAGE BODY CSR.var_expl_pkg AS

PROCEDURE GetGroups(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT var_expl_group_id, label
		  FROM var_expl_group;
END;

PROCEDURE GetGroupMembers(
	in_var_expl_group_id			IN	var_expl.var_expl_group_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ve.var_expl_id, ve.label, ve.requires_note, ve.pos,
				(SELECT COUNT(*)
				   FROM DUAL
				  WHERE EXISTS (SELECT 1
				  				  FROM sheet_value_var_expl sve
				  				 WHERE sve.var_expl_id = ve.var_expl_id)) in_use
		  FROM var_expl ve
		 WHERE ve.var_expl_group_id = in_var_expl_group_id
		   AND hidden = 0;
END;

PROCEDURE CreateGroup(
	in_label						IN	var_expl_group.var_expl_group_id%TYPE,
	out_var_expl_group_id			OUT	var_expl_group.var_expl_group_id%TYPE
)
AS
BEGIN
	-- TODO: capability check
	
	INSERT INTO var_expl_group (var_expl_group_id, label)
	VALUES (var_expl_group_id_seq.NEXTVAL, in_label)
	RETURNING var_expl_group_id INTO out_var_expl_group_id;
END;

PROCEDURE SetGroupLabel(
	in_var_expl_group_id			IN	var_expl_group.var_expl_group_id%TYPE,
	in_label						IN	var_expl_group.var_expl_group_id%TYPE
)
AS
BEGIN
	-- TODO: capability check
	
	UPDATE var_expl_group
	   SET label = in_label
	 WHERE var_expl_group_id = in_var_expl_group_id;
END;

PROCEDURE SetGroupMembers(
	in_var_expl_group_id			IN	var_expl.var_expl_group_id%TYPE,
	in_var_expl_ids					IN	security_pkg.T_SID_IDS,
	in_labels						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_requires_note				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR	
)
AS
	t_var_expl_ids					security.T_SID_TABLE;
BEGIN
	-- TODO: capability check

	t_var_expl_ids := security_pkg.SidArrayToTable(in_var_expl_ids);

	-- clean up old, unused variance explanations	
	DELETE FROM var_expl ve
	 WHERE var_expl_group_id = in_var_expl_group_id
	   AND var_expl_id NOT IN (
	   		SELECT column_value
	   	 	  FROM TABLE(t_var_expl_ids))
	   AND EXISTS (SELECT 1
	   				 FROM sheet_value_var_expl sve
	   				WHERE ve.var_expl_id = sve.var_expl_id);

	-- hide old, used variance explanations
	UPDATE var_expl
	   SET hidden = 1
	 WHERE var_expl_id NOT IN (
	 		SELECT column_value
	 		  FROM TABLE(t_var_expl_ids))
	   AND var_expl_group_id = in_var_expl_group_id;

	-- store new ones / update existing ones
	FOR i IN 1 .. in_var_expl_ids.COUNT LOOP
		IF in_var_expl_ids(i) IS NOT NULL THEN
			INSERT INTO var_expl (var_expl_group_id, var_expl_id, label, requires_note, pos)
			VALUES (in_var_expl_group_id, var_expl_id_seq.NEXTVAL, in_labels(i), in_requires_note(i), i);
		ELSE
			UPDATE var_expl
			   SET pos = i,
			   	   label = in_labels(i),
			   	   requires_note = in_requires_note(i)
			 WHERE var_expl_id = in_var_expl_ids(i);
		END IF;
	END LOOP;

	-- return the revised group
	GetGroupMembers(in_var_expl_group_id, out_cur);
END;

END var_expl_pkg;
/
