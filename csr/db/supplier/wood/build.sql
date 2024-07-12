set define off


PROMPT Compiling part_description_pkg
@part_description_pkg
PROMPT Compiling part_wood_pkg
@part_wood_pkg
PROMPT Compiling product_wood_pkg
@product_wood_pkg
PROMPT Compiling report_wood_pkg
@report_wood_pkg
PROMPT Compiling supplier_questionnaire_pkg
@supplier_questionnaire_pkg
PROMPT Compiling report_wood_pkg
@report_wood_pkg


PROMPT Compiling part_description_body
@part_description_body
PROMPT Compiling part_wood_body
@part_wood_body
PROMPT Compiling product_wood_body
@product_wood_body
PROMPT Compiling report_wood_body
@report_wood_body
PROMPT report_wood_body
@report_wood_body


set define on


@web_grants

PROMPT Recompiling invalid packages
@..\..\..\..\aspen2\tools\recompile_packages.sql
