CREATE OR REPLACE PACKAGE CSR.Region_Pkg AS

TYPE T_SID_TO_IDX_MAP IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
TYPE T_SID_TO_NUM_MAP IS TABLE OF NUMBER(24,10) INDEX BY PLS_INTEGER;
	

REGION_GEO_TYPE_LOCATION	CONSTANT NUMBER(2) := 0;
REGION_GEO_TYPE_COUNTRY		CONSTANT NUMBER(2) := 1;
REGION_GEO_TYPE_MAP_ENTITY	CONSTANT NUMBER(2) := 2;
REGION_GEO_TYPE_REGION		CONSTANT NUMBER(2) := 3;
REGION_GEO_TYPE_CITY		CONSTANT NUMBER(2) := 4;
REGION_GEO_TYPE_OTHER		CONSTANT NUMBER(2) := 5;
REGION_GEO_TYPE_INHERITED	CONSTANT NUMBER(2) := 6;

FUNCTION ProcessStartPoints(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_parent_sids	IN	security_pkg.T_SID_IDS,
	in_include_root	IN	NUMBER
)
RETURN security.T_ORDERED_SID_TABLE;

/**
 * Create a new region
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid   		Parent object
 * @param	in_name					Name
 * @param	in_description			Description
 * @param	in_active				Active? (1 = active / 0 = inactive) 
 * @param	out_region_sid_id		The SID of the created object
 *
 */
PROCEDURE CreateRegion(
	in_act_id						IN	security_pkg.T_ACT_ID         DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_parent_sid					IN	security_pkg.T_SID_ID, 
	in_app_sid 						IN	security_pkg.T_SID_ID         DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_name							IN	region.name%TYPE,
	in_description					IN	region_description.description%TYPE,
	in_active						IN	region.active%TYPE			  DEFAULT 1,	      
	in_pos							IN	region.pos%TYPE    			  DEFAULT NULL,	
	in_geo_type         			IN	region.geo_type%TYPE		  DEFAULT region_pkg.REGION_GEO_TYPE_INHERITED,
	in_info_xml						IN	region.info_xml%TYPE          DEFAULT NULL,
	in_geo_country					IN	region.geo_country%TYPE       DEFAULT NULL,
	in_geo_region					IN	region.geo_region%TYPE        DEFAULT NULL,
	in_geo_city						IN	region.geo_city_id%TYPE       DEFAULT NULL,
	in_map_entity					IN	region.map_entity%TYPE        DEFAULT NULL,
	in_geo_longitude				IN  region.geo_longitude%TYPE 	  DEFAULT NULL,	
	in_geo_latitude					IN  region.geo_latitude%TYPE 	  DEFAULT NULL,
	in_egrid_ref					IN 	region.egrid_ref%TYPE         DEFAULT NULL,
	in_region_ref					IN	region.region_ref%TYPE        DEFAULT NULL,
	in_acquisition_dtm				IN	region.acquisition_dtm%TYPE   DEFAULT TRUNC(SYSDATE),
	in_disposal_dtm					IN	region.disposal_dtm%TYPE	  DEFAULT NULL,
	in_region_type					IN	region.region_type%TYPE	      DEFAULT csr_data_pkg.REGION_TYPE_NORMAL,
	in_apply_deleg_plans			IN	NUMBER						  DEFAULT 1,
	in_write_calc_jobs				IN	NUMBER						  DEFAULT 1,
	out_region_sid					OUT	region.region_sid%TYPE
);

PROCEDURE PropagateGeoProp(
	in_region_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE GetRegionTrees(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CreateRegionTreeRoot(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	security_pkg.T_SO_NAME,
	in_is_primary				IN	region_tree.is_primary%TYPE,
	out_region_tree_root_sid	OUT	security_pkg.T_SID_ID
);

PROCEDURE CopyRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_new_parent_sid	IN	security_pkg.T_SID_ID,
	out_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE AmendRegionTreeRoot(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_tree_root_sid		IN	security_pkg.T_SID_ID,
	in_name						IN	security_pkg.T_SO_NAME,
	in_is_primary				IN	region_tree.is_primary%TYPE
);

/**
 * Returns the path of a region
 * 	
 * @param 	in_act_id 	Access token
 * @param 	in_sid_id 	The sid of the object
 * @return 	A string containing the path of the object relative to <app>/regions
 */
FUNCTION GetFlattenedRegionPath(
    in_act 		IN Security_Pkg.T_ACT_ID,
	in_sid_id 	IN Security_Pkg.T_SID_ID
) RETURN VARCHAR2;


FUNCTION UNSEC_GetFlattenedRegionPath2(
	in_sid_id 	IN Security_Pkg.T_SID_ID
) RETURN VARCHAR2;

/**
 * GetRegionPath
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param out_cur			The rowset
 */
PROCEDURE GetRegionPath(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE DisposeRegion(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_disposal_dtm					IN	region.disposal_dtm%TYPE DEFAULT NULL
);

/**
 * Update a region
 *
 * @param	in_act_id				Access token
 * @param	in_region_sid			The region to update
 * @param	in_description			The new region description
 * @param	in_active				Active? (1 = active / 0 = inactive)
 */
PROCEDURE AmendRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	region_description.description%TYPE,
	in_active			IN	region.active%TYPE,
	in_pos				IN	region.pos%TYPE,
	in_geo_type         IN	region.geo_type%TYPE,
	in_info_xml			IN	region.info_xml%TYPE,
	in_geo_country		IN	region.geo_country%TYPE,
	in_geo_region		IN	region.geo_region%TYPE,
	in_geo_city			IN	region.geo_city_id%TYPE,
	in_map_entity		IN	region.map_entity%TYPE,
	in_egrid_ref		IN	region.egrid_ref%TYPE,
	in_region_ref		IN	region.region_ref%TYPE,
	in_acquisition_dtm	IN	region.acquisition_dtm%TYPE DEFAULT NULL,	
	in_disposal_dtm		IN	region.disposal_dtm%TYPE DEFAULT NULL,
	in_region_type		IN	region.region_type%TYPE	DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
);

PROCEDURE SetLatLong(
	in_region_sid		 			IN	security_pkg.T_SID_ID,
	in_latitude						IN	region.geo_latitude%TYPE,
	in_longitude					IN	region.geo_longitude%TYPE
);

PROCEDURE RenameRegion(
	in_region_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	region_description.description%TYPE
);

/**
 * Set a translation for a region
 *
 * @param	in_region_sid			The region to set a translation for
 * @param	in_culture				The culture the translation is for
 * @param	in_translation			The translation
 */
PROCEDURE SetTranslation(
	in_region_sid		IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
);

/**
 * Get translations for a region description
 *
 * @param	in_region_sid			The region to set a translation for
 * @param	out_cur					Output rowset of the form culture, translated
 */
PROCEDURE GetTranslations(
	in_region_sid		IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid   		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid   		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);


/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);


/**
 * Move an existing region
 *
 * @param	in_act_id				Access token
 * @param	in_move_region_sid		Region to move
 * @param   in_parent_sid 			New parent object
 *
 */
PROCEDURE MoveRegion(
	in_act_id 						IN 	security_pkg.T_ACT_ID,
	in_region_sid 					IN 	security_pkg.T_SID_ID,
	in_parent_sid 					IN 	security_pkg.T_SID_ID
);

/** 
 * HasLinksToSubtree
 *
 * Check if the subtree rooted at the given region has
 * links to it from outside the subtree
 *
 * @param in_region_sid				The subtree root
 */
FUNCTION HasLinksToSubtree(
	in_region_sid					IN security_pkg.T_SID_ID
) RETURN NUMBER;

/**
 * RestoreFromTrash
 * 
 * @param in_object_sids			The objects being restored
 */
PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
);

/**
 * TrashObject
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 */
PROCEDURE TrashObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_region_sid					IN security_pkg.T_SID_ID
);

/**
 * Write aggregation jobs for the given region
 *
 * @param	in_app_sid			App Sid
 * @param	in_region_sid		The region sid (or NULL)
 */
PROCEDURE AddAggregateJobs(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID
);

/**
 * Return a row set containing info about a region
 *
 * @param	in_act_id		Access token
 * @param	in_region_sid	The region
 */
PROCEDURE GetRegion(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

FUNCTION GetRegionIsSystemManaged(
	in_region_sid				IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER;

/**
 * Return a row set containing info about multiple regions
 *
 * @param	in_region_sids		The region sids
 * @param	in_skip_missing		Just skip missing regions (otherwise raises security_pkg.OBJECT_NOT_FOUND)
 * @param	in_skip_denid		Just skip regions without read permission (otherwise raises security_pkg.ACCESS_DENIED)
 * @param	out_region_cur		Region details
 * @param	out_tag_cur			Region tags
 */
PROCEDURE GetRegions(
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
);

/**
 * Return a row set containing info about a region
 *
 * @param	in_act_id		Access token
 * @param	in_app_sid		App Sid
 * @param   in_lookup_key	Lookup key
 * @param	out_cur			Cursor
 */
PROCEDURE GetRegionFromKey(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_lookup_key		IN region.lookup_key%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE INTERNAL_GetCoreRegionsBySids(
	in_region_sids				IN	security.T_SID_TABLE,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR
);

PROCEDURE INTERNAL_GetCoreRegions(
	in_include_all				IN	NUMBER,
	in_include_null_lookup_keys	IN	NUMBER,
	in_lookup_keys				IN	security.T_VARCHAR2_TABLE,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCoreRegions(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetCoreRegionsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreRegionsByDescrptn(
	in_description			IN	region_description.description%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreRegionBySid(
	in_sid					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreRegionByPath(
	in_path					IN	VARCHAR2,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
);

PROCEDURE FindCoreRegionPath(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreRegionsByGeoCtry(
	in_geo_country			IN	region.geo_country%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreRegionsByGeoRegn(
	in_geo_region			IN	region.geo_region%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreRegionsByGeoCity(
	in_geo_city_id			IN	region.geo_city_id%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

/**
 * Return the region sid
 *
 * @param	in_act_id		Access token
 * @param	in_app_sid		App Sid
 * @param   in_region_ref	Region Reference
 */

FUNCTION GetRegionSidFromRef(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_region_ref		IN region.region_ref%TYPE
) RETURN security_pkg.T_SID_ID;

/**
 * Return the region sids for a given ref
 *
 * @param	in_app_sid		App Sid
 * @param   in_region_ref	Region Reference
 */
PROCEDURE GetRegionSidsFromRef (
	in_region_ref		IN region.region_ref%TYPE,
	out_regions_cur		OUT	SYS_REFCURSOR
);

/**
 * Return a row set containing info about a region
 *
 * @param	in_act_id		Access token
 * @param	in_app_sid		App Sid
 * @param   in_region_ref	Region Reference
 * @param	out_cur			Cursor
 */
PROCEDURE GetRegionFromRef(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_region_ref		IN region.region_ref%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetRegions(
	in_region_sids	IN	security_pkg.T_SID_IDS,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * Get things that depend on the given region
 *
 * @param 	in_act_id		Access token
 * @param	in_region_sid	The region
 * @param	out_delegations	Delegations that involve this region
 */
PROCEDURE GetDependencies(
	in_act			IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_delegations	OUT	SYS_REFCURSOR
);


PROCEDURE GetGeoData(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetGeoDataLowBound(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE LookupRegion(
	in_text				IN	region_description.description%TYPE,
	in_ancestors		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_region_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE FindRegionPath(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT SYS_REFCURSOR
);


FUNCTION CountChildren(
	in_parent_sids 	IN	security_pkg.T_SID_IDS
) RETURN NUMBER;

-- for report
PROCEDURE UNSEC_GetIndentation(
	in_parent_sids 	IN	security_pkg.T_SID_IDS,
	out_cur			OUT	SYS_REFCURSOR
);


/**
 * Returns active children of the given region
 * 
 * @param in_act_id				Access token
 * @param in_root_region_sid	The region to return the children of
 * @param out_cur				The rowset containing region details
 */
PROCEDURE GetChildren(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
);

/**
 * Returns both active and inactive children of the given region
 * 
 * @param in_act_id				Access token
 * @param in_root_region_sid	The region to return the children of
 * @param out_cur				The rowset containing region details
 */
PROCEDURE GetChildrenInclInactive(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
);

/**
 * Returns only the inactive children of the given region
 * 
 * @param in_act_id				Access token
 * @param in_root_region_sid	The region to return the children of
 * @param out_cur				The rowset containing region details
 */
PROCEDURE GetInactiveChildren(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
);

/**
 * Searches through regions
 *
 * @param	in_act_id			Access token
 * @param   in_app_sid 	CSR Root SID
 * @param	in_phrase			Search phrase (or null)
 */
PROCEDURE Search(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_phrase		 	IN VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * GetRegionsForList
 * 
 * @param in_act_id			Access token
 * @param in_region_list	The list
 * @param out_cur			The rowset
 */
PROCEDURE GetRegionsForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_list	IN	VARCHAR2,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * SetOwners
 * 
 * @param in_act_id			Access token
 * @param in_user_sid		.
 * @param in_region_list	.
 */
PROCEDURE SetOwners(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_list	IN	VARCHAR2
);
   
/**
 * Returns a list of owners for an regionicator
 *
 * @param	in_act_id			Access token
 * @param   in_region_sid 	regionicator SID
 */
PROCEDURE GetRegionsForUser(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_user_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);


/**
 * FilterRegions
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_filter				.
 * @param out_cur				The rowset
 */
PROCEDURE FilterRegions(  
	in_act_id			IN 	security_pkg.T_ACT_ID,	 
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE FilterRegionsLimit(  
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,	 
	in_filter			IN	VARCHAR2,
	in_limit			IN	NUMBER,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE FilterRegions(
	in_filter		IN	region_description.description%TYPE,
	in_region_type	IN	region.region_type%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * GetActiveUsersForRegion
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param out_cur			The rowset
 */
PROCEDURE GetActiveUsersForRegion(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

/**
 * AddUserToRegion
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param in_user_sid		.
 */
PROCEDURE AddUserToRegion(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_user_sid			IN security_pkg.T_SID_ID
);


/**
 * RemoveUserFromRegion
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param in_user_sid		.
 */
PROCEDURE RemoveUserFromRegion(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_user_sid			IN security_pkg.T_SID_ID
);



/**
 * ParseLink
 * 
 * @param in_sid	The sid of the object
 * @return 			.
 */
FUNCTION ParseLink(
	in_sid	IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(ParseLink, WNDS, WNPS);



/**
 * CreateLinkToRegion
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_link_to_sid	.
 * @param in_link_name		.
 * @param out_region_sid	.
 */
PROCEDURE CreateLinkToRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID, 
	in_link_to_sid		IN	security_pkg.T_SID_ID, 
	out_region_sid		OUT security_pkg.T_SID_ID 
);

PROCEDURE GetReportingRegions(
	in_root_sid						IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_onlyActive					IN	NUMBER DEFAULT 0,
	out_cur							OUT SYS_REFCURSOR,
	desc_cur						OUT SYS_REFCURSOR,
	tag_cur							OUT SYS_REFCURSOR
);

/* parses LINK_TO_REGION_SID */
/**
 * GetTree
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 * @param in_depth		.
 * @param out_cur		The rowset
 */
PROCEDURE GetTree(
	in_act_id   	IN  security_pkg.T_ACT_ID,
	in_sid_id 		IN  security_pkg.T_SID_ID,
	in_depth 		IN  NUMBER,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetRegionTree(
	in_root_sid						IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT SYS_REFCURSOR,
	out_tag_groups_cur				OUT SYS_REFCURSOR,
	out_tag_cur						OUT SYS_REFCURSOR,
	out_roles_cur					OUT SYS_REFCURSOR,
	out_role_members_cur			OUT SYS_REFCURSOR
);

/**
 * INTERNAL
 * 
 * @param in_region_sid		The sid of the object
 * @return 					.
 */
FUNCTION INTERNAL_GetRegionPathString(
	in_region_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(INTERNAL_GetRegionPathString, WNDS);

FUNCTION GetRegionPathStringFromStPt(
	in_region_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2 DETERMINISTIC;

FUNCTION INTERNAL_GetPctOwnershipString(
	in_region_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(INTERNAL_GetPctOwnershipString, WNDS);

-- Called from the stored calc / regional aggregator process to process % ownership changes
PROCEDURE ProcessPctOwnership(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
);

PROCEDURE SetPctOwnershipApplies(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_measure_sid_id			IN	security_pkg.T_SID_ID,
	in_pct_ownership_applies	IN	pct_ownership_change.PCT_OWNERSHIP_APPLIES%TYPE
);

PROCEDURE UNSEC_SetPctOwnership(
    in_act_id     	 		IN  security_pkg.T_ACT_ID,	   
    in_region_sid   	    IN	security_pkg.T_SID_ID,
    in_start_dtm			IN	date,
    in_pct          		IN	pct_ownership.pct%TYPE
);

PROCEDURE SetPctOwnership(
    in_act_id     	 		IN  security_pkg.T_ACT_ID,	   
    in_region_sid   	    IN	security_pkg.T_SID_ID,
    in_start_dtm			IN	date,
    in_pct          		IN	pct_ownership.pct%TYPE
);


PROCEDURE GetPctOwnership(
    in_act_id       			IN  security_pkg.T_ACT_ID,
    in_region_sid           	IN	security_pkg.T_SID_ID,
	out_cur						OUT SYS_REFCURSOR
);

FUNCTION GetPctOwnership(
    in_ind_sid          IN	security_pkg.T_SID_ID,
    in_region_sid       IN	security_pkg.T_SID_ID,
    in_dtm              IN  date
) RETURN pct_ownership.pct%TYPE;

PROCEDURE GetTreeForMap(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeSinceDate(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_modified_since_dtm			IN	audit_log.audit_date%TYPE,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithDepth(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithSelect( 
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	in_class_filter					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_fetch_limit					IN	NUMBER,
	in_class_filter					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDescendants(
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	in_region_type_filter			IN	region.region_type%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetExtraInfoValue(
	in_act		    IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_key		    IN	VARCHAR2,		
	in_value	    IN	VARCHAR2
);

PROCEDURE GetGeoTree(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeAtAbsLevel(
	in_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	in_abs_level	IN	NUMBER,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SearchTreeAtAbsLevel(
	in_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	in_abs_level	IN	NUMBER,
	in_search		IN	region_description.description%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE FastMoveRegion(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID
);


FUNCTION GetRegionTypeName (
	in_region_type			IN	region.region_type%TYPE
) RETURN VARCHAR2;

PROCEDURE SetRegionType (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_type			IN	region.region_type%TYPE
);

PROCEDURE GetRegionTypes (
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllEGrids(
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION GetRegionDescription(
	in_region_sid		IN security_pkg.T_SID_ID
) RETURN region_description.description%type;

PROCEDURE GetRegionDescriptions(
	in_region_sids			IN security_pkg.T_SID_IDS,
	out_region_desc_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionDescriptions_UNSEC(
	in_region_sids			IN security_pkg.T_SID_IDS,
	out_region_desc_cur		OUT	SYS_REFCURSOR
);

PROCEDURE CopyValues(
	in_from_region_sid	IN	security_pkg.T_SID_ID,
	in_new_region_sid	IN	security_pkg.T_SID_ID,
	in_period_start_dtm	IN	DATE 			DEFAULT NULL,
	in_period_end_dtm	IN	DATE 			DEFAULT NULL,
	in_reason			IN	VARCHAR2		DEFAULT NULL,
	in_move				IN	NUMBER			DEFAULT 0
);

PROCEDURE ApplyDynamicPlans(
	in_region_sid					IN	region.region_sid%TYPE,
	in_source_msg					IN	VARCHAR2
);

PROCEDURE UNSEC_AmendRegionActive(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_active				IN	region.active%TYPE,
	in_old_acquisition_dtm	IN	region.acquisition_dtm%TYPE,
	in_old_disposal_dtm		IN	region.disposal_dtm%TYPE,
	in_fast					IN	NUMBER
);

/**
 * Sets a region's active/inactive status.
 * NB: it also sets all the decendent regions to the same active/inactive status.
 * @param   in_region_sid           The region to set active/inactive
 * @param   in_active               Set active=1, inactive=0
 * @param   in_fast                 0 = rerun delegation plans
 *                                  1 = suppress running delegation plans (faster!)
 */
PROCEDURE SetRegionActive(
	in_region_sid	IN	region.region_sid%TYPE,
	in_active		IN	region.active%TYPE,
	in_fast			IN	NUMBER					-- Fast because it does not apply delegation plans afterwards
);

FUNCTION ConcatRegionTags(
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

/**
 * Update a region
 *
 * @param	in_act_id				Access token
 * @param	in_region_sid			The region to update
 * @param	in_description			The new region description
 * @param	in_active				Active? (1 = active / 0 = inactive)
 * @param	in_pos					Position
 * @param	in_geo_type				Geo Type
 * @param	in_info_xml				Region Info
 * @param	in_geo_country			Geo Country
 * @param	in_geo_region			Geo Region
 * @param	in_geo_city				Geo City
 * @param	in_map_entity			Map Entity
 * @param	in_egrid_ref			EGrid Reference
 * @param	in_region_ref			Region Reference
 * @param	in_acquisition_dtm		Acquisition Date
 * @param	in_region_type			Region Type
 */
PROCEDURE AmendRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	region_description.description%TYPE,
	in_active			IN	region.active%TYPE,
	in_pos				IN	region.pos%TYPE,
	in_geo_type         IN	region.geo_type%TYPE,
	in_info_xml			IN	region.info_xml%TYPE,
	in_geo_country		IN	region.geo_country%TYPE,
	in_geo_region		IN	region.geo_region%TYPE,
	in_geo_city			IN	region.geo_city_id%TYPE,
	in_map_entity		IN	region.map_entity%TYPE,
	in_egrid_ref		IN	region.egrid_ref%TYPE,
	in_region_ref		IN	region.region_ref%TYPE,
	in_acquisition_dtm	IN	region.acquisition_dtm%TYPE DEFAULT NULL,	
	in_region_type		IN	region.region_type%TYPE	DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
);

PROCEDURE SetRegionRef(
	in_region_sid	IN region.region_sid%TYPE,
	in_region_ref	IN region.region_ref%TYPE
);

PROCEDURE SetLookupKey(
	in_region_sid	IN region.region_sid%TYPE,
	in_lookup_key	IN region.lookup_key%TYPE
);

FUNCTION IsHiddenOnDelegationForm(
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE FindCommonAncestor(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	out_region_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE GetAllTranslations(
	in_root_region_sids		IN	security.security_pkg.T_SID_IDS,
	in_validation_lang		IN	region_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTranslations(
	in_region_sids			IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetUsedCountries(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetUsedGeoRegions(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionMapTypes(
	in_filter					IN VARCHAR2,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetRegionMapTypes(
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetRegionMapData(
	in_region_sid					IN	region.region_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetRegionMapData(
	in_region_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RegionHasTag(
	in_region_sid				IN	region.region_sid%TYPE,
	in_tag_id					IN	tag.tag_id%type,
	out_has_tag					OUT NUMBER
);

PROCEDURE UNSEC_RegionHasTag(
	in_region_sid				IN	region.region_sid%TYPE,
	in_tag_id					IN	tag.tag_id%type,
	out_has_tag					OUT NUMBER
);

PROCEDURE GetRegionRecord(
	in_region_sid		IN	region.region_sid%TYPE,
	out_region			OUT	csr.T_REGION
);

PROCEDURE UNSEC_GetRegionRecord(
	in_region_sid		IN	region.region_sid%TYPE,
	out_region			OUT	csr.T_REGION
);

END Region_Pkg;
/
