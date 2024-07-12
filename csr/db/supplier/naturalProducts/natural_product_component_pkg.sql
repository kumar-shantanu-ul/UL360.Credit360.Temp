create or replace package supplier.natural_product_component_pkg
IS

COMPONENT_DESCRIPTION_CLS		CONSTANT VARCHAR2(255) := 'NP_COMPONENT_DESCRIPTION';

TYPE T_PROCESS_IDS IS TABLE OF wood_part_description.product_part_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE CreatePartComponent(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN	product_part.product_id%TYPE,
	in_parent_part_id				IN	product_part.product_part_id%TYPE,
	in_common_name					IN	np_component_description.common_name%TYPE,
	in_species						IN	np_component_description.species%TYPE,
	in_genus						IN	np_component_description.genus%TYPE,
	in_description					IN	np_component_description.description%TYPE,
	in_country_of_origin			IN	np_component_description.country_of_origin%TYPE,
	in_region						IN	np_component_description.region%TYPE,
	in_kingdom_id 					IN	np_component_description.np_kingdom_id%TYPE,
	in_natural_claim				IN	np_component_description.natural_claim%TYPE,
	in_component_code				IN	np_component_description.component_code%TYPE,
	in_collection_desc				IN	np_component_description.collection_desc%TYPE,
	in_env_harvest_safeguard_desc	IN	np_component_description.env_harvest_safeguard_desc%TYPE,
	in_env_process_safeguard_desc	IN	np_component_description.env_process_safeguard_desc%TYPE,
	in_pp_group_id					IN	np_component_description.np_production_process_group_id%TYPE,
	out_product_part_id				OUT	product_part.product_part_id%TYPE
);

PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
);

PROCEDURE UpdatePartComponent(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_part_id						IN	product_part.product_part_id%TYPE,
	in_common_name					IN	np_component_description.common_name%TYPE,
	in_species						IN	np_component_description.species%TYPE,
	in_genus						IN	np_component_description.genus%TYPE,
	in_description					IN	np_component_description.description%TYPE,
	in_country_of_origin			IN	np_component_description.country_of_origin%TYPE,
	in_region						IN	np_component_description.region%TYPE,
	in_kingdom_id 					IN	np_component_description.np_kingdom_id%TYPE,
	in_natural_claim				IN	np_component_description.natural_claim%TYPE,
	in_component_code				IN	np_component_description.component_code%TYPE,
	in_collection_desc				IN	np_component_description.collection_desc%TYPE,
	in_env_harvest_safeguard_desc	IN	np_component_description.env_harvest_safeguard_desc%TYPE,
	in_env_process_safeguard_desc	IN	np_component_description.env_process_safeguard_desc%TYPE,
	in_pp_group_id					IN	np_component_description.np_production_process_group_id%TYPE
);

PROCEDURE DeletePart(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_part_id						IN product_part.product_part_id%TYPE
);

PROCEDURE GetPartComponents(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_part_id						IN	product_part.product_part_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductionProcesses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_product_id			IN	product_part.product_id%TYPE,
	in_group_id				IN	np_component_description.np_production_process_group_id%TYPE,
	in_proc_ids				IN 	T_PROCESS_IDS,
	out_group_id			OUT	np_component_description.np_production_process_group_id%TYPE
);

PROCEDURE GetProductionProcesses(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_group_id						IN	np_component_description.np_production_process_group_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
);

END natural_product_component_pkg;
/