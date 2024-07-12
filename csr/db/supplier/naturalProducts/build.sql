set define off

PROMPT Compiling natural_product_pkg
@natural_product_pkg
PROMPT Compiling natural_product_part_pkg
@natural_product_part_pkg
PROMPT Compiling natural_product_component_pkg
@natural_product_component_pkg
PROMPT Compiling natural_product_evidence_pkg
@natural_product_evidence_pkg
PROMPT Compiling report_natural_product_pkg
@report_natural_product_pkg


PROMPT Compiling natural_product_body
@natural_product_body
PROMPT Compiling natural_product_part_body
@natural_product_part_body
PROMPT Compiling natural_product_component_body
@natural_product_component_body
PROMPT Compiling natural_product_evidence_body
@natural_product_evidence_body
PROMPT Compiling report_natural_product_pkg body
@report_natural_product_body

set define on


@web_grants

PROMPT Recompiling invalid packages
@..\..\..\..\aspen2\tools\recompile_packages.sql
