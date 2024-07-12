CREATE OR REPLACE PACKAGE CSR.factor_set_group_pkg AS

PROCEDURE GetFactorSetGroups(
	out_factor_set_groups		OUT SYS_REFCURSOR
);

PROCEDURE GetFactorSetGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RenameFactorSetGroup(
	in_factor_set_group_id	IN factor_set_group.factor_set_group_id%TYPE,
	in_new_name				IN factor_set_group.name%TYPE
);

PROCEDURE DeleteFactorSetGroup(
	in_factor_set_group_id	IN factor_set_group.factor_set_group_id%TYPE
);

PROCEDURE SaveFactorSetGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	in_name					IN	factor_set_group.name%TYPE,
	in_custom				IN	factor_set_group.custom%TYPE,
	out_factor_set_group	OUT	SYS_REFCURSOR	
);

PROCEDURE GetFactorSetsForGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFactorSetsForGroupPaged(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	out_total_rows			OUT	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFactorSet(
	in_factor_set_id		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetFactorSetVisibility(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	in_visible			IN	NUMBER
);

PROCEDURE SetFactorSetActive(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	in_active			IN	NUMBER
);

PROCEDURE SetFactorSetVisibilityGlobal(
	in_std_factor_set_id	IN std_factor_set.std_factor_set_id%TYPE,
	in_visible				IN std_factor_set.visible%TYPE
);

PROCEDURE DeleteFactorSet(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	in_is_custom		IN	NUMBER
);

PROCEDURE PublishFactorSet(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE
);

PROCEDURE UnpublishFactorSet(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE
);

PROCEDURE SetFactorSetsActiveOnMigration;

PROCEDURE UpdateStdFactorSetInfoNote(
	in_factor_set_id			IN std_factor_set.std_factor_set_id%TYPE,
	in_info_note				IN std_factor_set.info_note%TYPE
);

END factor_set_group_pkg;
/
