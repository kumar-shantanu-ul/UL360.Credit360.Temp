CREATE OR REPLACE PACKAGE CSR.region_tree_pkg AS

-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
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
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
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

FUNCTION GetPrimaryRegionTreeRootSid
RETURN security_pkg.T_SID_ID;

FUNCTION GetPrimaryRegionTreeRootSid(
	in_region_root_sid		IN	security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID;

FUNCTION GetSecondaryRegionTreeRootSid (
	in_region_name			IN	region.name%TYPE
)RETURN security_pkg.T_SID_ID;

FUNCTION IsInPrimaryTree(
	in_region_sid					IN	security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION IsInSecondaryTree(
	in_region_sid					IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE CreateRefreshBatchJob(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetRefreshBatchJob(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RefreshSecondaryRegionTree(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID
);

/* Legacy versions of the sync functions (used in client folders; these have been refactored to use the newer versions and named parameters) */
/**/
-- no longer used, pending removal
PROCEDURE SynchSecondaryForTag(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_tag_id						IN	tag.tag_id%TYPE,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);

-- no longer used, pending removal
PROCEDURE SynchSecondaryForTagGroup(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN  security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);

-- no longer used, pending removal
PROCEDURE SynchSecondaryActivePropOnly(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);

-- no longer used, pending removal
PROCEDURE SynchSecondaryForTagGroupList(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id_list			IN	VARCHAR2,
	in_active_only					IN	NUMBER DEFAULT 0,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);

-- no longer used, pending removal
PROCEDURE SynchSecondaryPropByFunds(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN  security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);

-- no longer used, pending removal
PROCEDURE SynchPropTreeByMgtCompany(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN  security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);

-- This is for custom tree synchronisation.
PROCEDURE INTERNAL_SynchTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	tbl_primary						IN	OUT NOCOPY T_SID_AND_DESCRIPTION_TABLE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
);


/**/
/* End Legacy versions */

-- This is for custom tree synchronisation.
PROCEDURE Custom_SyncTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_tbl_primary					IN	OUT NOCOPY T_SID_AND_PATH_AND_DESC_TABLE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_no_log						IN	NUMBER DEFAULT 0
);


/* Newer Sync functions */
PROCEDURE CreateSecondarySyncForTag(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_id						IN	tag.tag_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SyncSecondaryForTag(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_id						IN	tag.tag_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

PROCEDURE CreateSecondaryForTagGroup(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SyncSecondaryForTagGroup(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

PROCEDURE CreateSecondaryActivePropOnly(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SyncSecondaryActivePropOnly(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

PROCEDURE CreateSecondaryForTagGroupList(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id_list			IN	VARCHAR2,
	in_active_only					IN	NUMBER DEFAULT NULL,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SyncSecondaryForTagGroupList(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id_list			IN	VARCHAR2,
	in_active_only					IN	NUMBER DEFAULT NULL,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

PROCEDURE CreateSecondaryPropByFunds(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary.
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SyncSecondaryPropByFunds(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

PROCEDURE CreatePropTreeByMgtCompany(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SyncPropTreeByMgtCompany(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

PROCEDURE TriggerRegionTreeSyncJobs;

FUNCTION GetTagGroupNames(in_tag_group_ids	IN	VARCHAR2)
RETURN VARCHAR2;

FUNCTION AreTagGroupsValid(in_tag_group_ids	IN	VARCHAR2)
RETURN NUMBER;

PROCEDURE GetSecondaryRegionTrees(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetSecondaryRegionTreeLogs(
	in_region_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetSecondaryRegionTreeLog(
	in_log_id						IN  NUMBER,
	in_region_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE DeleteSecondaryTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetAllSecondaryTreeRoots(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE DeleteEmptySecondaryTree(
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE SaveSecondaryTree(
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_description					IN  region_description.description%TYPE,
	in_is_system_managed			IN  region_tree.is_system_managed%TYPE
);

END region_tree_pkg;
/