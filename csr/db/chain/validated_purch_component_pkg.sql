CREATE OR REPLACE PACKAGE CHAIN.validated_purch_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE,
	in_rel_pc_id			IN  validated_purchased_component.mapped_purchased_component_id%TYPE,
	in_tag_sids				IN  security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

END validated_purch_component_pkg;
/
