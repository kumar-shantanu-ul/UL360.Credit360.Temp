CREATE OR REPLACE PACKAGE CSR.Note_Pkg AS

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
	in_note_key			IN note.note_key%TYPE,
	in_note				IN note.note%TYPE,
	out_note_id			OUT note.note_id%TYPE
);

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
	in_note_id			IN note.note_id%TYPE,
	in_note				IN note.note%TYPE
);

/**
 * Delete the note id 
 *
 * @param	in_act_id				Access token
 * @param	in_note_id				The note id
 *
 */
PROCEDURE DeleteNote(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_note_id			IN note.note_id%TYPE
);

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
	in_note_id			IN note.note_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

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
);


END Note_Pkg;
/
