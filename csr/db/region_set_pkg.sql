CREATE OR REPLACE PACKAGE csr.region_set_pkg AS

/**
 * Create a new region set
 *
 * @param	in_app_sid				App sid
 * @param	in_owner_sid			Sid of the user who will own the new region set
 * @param	in_name					Name for the new region set
 * @param	in_region_sids			The regions to include in this set
 * @param	out_region_set_id		The SID of the created object
 */
PROCEDURE CreateRegionSet(
	in_app_sid 						IN	security_pkg.T_SID_ID         DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_owner_sid					IN	csr_user.csr_user_sid%TYPE,
	in_name							IN	region_set.name%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_region_set_id				OUT	region_set.region_set_id%TYPE
);

/**
 * Create or update a region set
 *
 * @param	in_name					Name for the new region set
 * @param	in_shared				Is the region set shared?
 * @param	in_region_sids			The regions to include in this set
 * @param	out_region_set_id		The id of the created object
 */
PROCEDURE SaveRegionSet(
	in_name							IN	region_set.name%TYPE,
	in_shared						IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_region_set_id				OUT	region_set.region_set_id%TYPE
);

/**
 * Mark a region set as disposed/deleted
 *
 * @param	in_region_set_id		The region set to dispose
 * @param	in_disposal_dtm			The disposal date (defaults to SYSDATE)
 */
PROCEDURE DisposeRegionSet(
	in_region_set_id				IN	security_pkg.T_SID_ID,
	in_disposal_dtm					IN	region_set.disposal_dtm%TYPE DEFAULT SYSDATE
);

/**
 * Get all region sets available to the current user
 *
 * @param	out_cur					The IDs and names of the region sets
 */
PROCEDURE GetRegionSets(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get the regions that make up a given region set
 *
 * @param	in_region_set_id		The ID of the region set
 * @param	out_cur					The SIDs and names of the regions in this set
 */
PROCEDURE GetRegionSetRegions(
	in_region_set_id				IN	security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

END region_set_pkg;
/
