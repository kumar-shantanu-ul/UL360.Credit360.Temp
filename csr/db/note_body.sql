CREATE OR REPLACE PACKAGE BODY CSR.Note_Pkg AS

/**
 * Set the note for the given indicator, region + note_key
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator sid
 * @param	in_region_sid			The region sid
 * @param	in_note_key				Further textual key to identify the note (e.g. date/period string)
 * @param	in_note					Note body
 * @param	out_note_id				The id of the new note
 *
 */
PROCEDURE CreateNote(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_note_key			IN NOTE.note_key%TYPE,
	in_note				IN NOTE.NOTE%TYPE,
	out_note_id			OUT NOTE.note_id%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_note_id	NUMBER(10);
BEGIN
	user_pkg.getSid(in_act_id, v_user_sid);
	SELECT note_id_seq.NEXTVAL INTO v_note_id FROM DUAL;
	INSERT INTO NOTE
		(note_id, ind_sid, region_sid, note_key, NOTE,
		 last_amended_by_user_sid)
	VALUES
		(v_note_id, in_ind_sid, in_region_sid, in_note_key, in_note,
		 v_user_sid);
	out_note_id := v_note_id;
END;


/**
 * Amend the note id 
 *
 * @param	in_act_id				Access token
 * @param	in_note_id				The note id
 * @param	in_note					Note body
 *
 */
PROCEDURE AmendNote(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_note_id			IN NOTE.note_id%TYPE,
	in_note				IN NOTE.NOTE%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.getSid(in_act_id, v_user_sid);
	UPDATE NOTE 
	   SET NOTE = in_note,
	   	   LAST_AMENDED_BY_USER_SID = v_user_sid,
		   LAST_AMENDED_DTM = SYSDATE
	 WHERE note_id = in_note_id;
END;


/**
 * Delete the note id 
 *
 * @param	in_act_id				Access token
 * @param	in_note_id				The note id
 *
 */
PROCEDURE DeleteNote(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_note_id			IN NOTE.note_id%TYPE
)
AS
BEGIN
	DELETE FROM NOTE WHERE note_id = in_note_id;
END;


/**
 * Get the given note based on id
 *
 * @param	in_act_id				Access token
 * @param	in_note_id				The note to read
 * @param	out_cur					The note details
 *
 * The output rowset is of the form:
 *	note_id, ind_sid, region_sid, note_key, note, last_amended_by_user_sid, last_amended_dtm
 *
 */
PROCEDURE GetNote(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_note_id			IN NOTE.note_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT note_id, ind_sid, region_sid, note_key, NOTE, 
			last_amended_by_user_sid, last_amended_dtm
		  FROM NOTE
		 WHERE note_id = in_note_id;
END;


/**
 * Get notes for the given ind + region sids
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator sid
 * @param	out_formula_cur			The region sid
 *
 * The output rowset is of the form:
 *	note_id, note_key, note, last_amended_by_user_sid, last_amended_dtm
 *
 */
PROCEDURE GetNotes(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT note_id, note_key, NOTE, last_amended_by_user_sid, last_amended_dtm
		  FROM NOTE
		 WHERE ind_sid = in_ind_sid AND region_sid = in_region_sid;
END;

END;
/
