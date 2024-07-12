CREATE OR REPLACE PACKAGE csr.indicator_set_pkg AS

/**
 * Create a new indicator set
 *
 * @param	in_app_sid				App sid
 * @param	in_owner_sid			Sid of the user who will own the new indicator set
 * @param	in_name					Name for the new indicator set
 * @param	in_ind_sids				The indicators to include in this set
 * @param	out_ind_set_id			The SID of the created object
 */
PROCEDURE CreateIndicatorSet(
	in_app_sid 						IN	security_pkg.T_SID_ID         DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_owner_sid					IN	csr_user.csr_user_sid%TYPE,
	in_name							IN	ind_set.name%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_ind_set_id					OUT	ind_set.ind_set_id%TYPE
);

/**
 * Create or update an indicator set
 *
 * @param	in_name					Name for the new indicator set
 * @param	in_ind_sids				The indicators to include in this set
 * @param	in_shared				Is the indicator set shared?
 * @param	out_ind_set_id			The SID of the created object
 */
PROCEDURE SaveIndicatorSet(
	in_name							IN	ind_set.name%TYPE,
	in_shared						IN	NUMBER,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_ind_set_id					OUT	ind_set.ind_set_id%TYPE
);

/**
 * Mark a indicator set as disposed/deleted
 *
 * @param	in_ind_set_id			The indicator set to dispose
 * @param	in_disposal_dtm			The disposal date (defaults to SYSDATE)
 */
PROCEDURE DisposeIndicatorSet(
	in_ind_set_id					IN	security_pkg.T_SID_ID,
	in_disposal_dtm					IN	ind_set.disposal_dtm%TYPE DEFAULT SYSDATE
);

/**
 * Get all indicator sets owned by the current user
 *
 * @param	out_cur					The IDs and names of the indicator sets
 */
PROCEDURE GetIndicatorSets(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get the indicators that make up a given indicator set
 *
 * @param	in_ind_set_id			The ID of the indicator set
 * @param	out_cur					The SIDs and names of the indicators in this set
 */
PROCEDURE GetIndicatorSetIndicators(
	in_ind_set_id					IN	security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

END indicator_set_pkg;
/
