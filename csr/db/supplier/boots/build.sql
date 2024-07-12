set define off

PROMPT product search pkg
@product_search_pkg


PROMPT product search body
@product_search_body

set define on


@web_grants

PROMPT Recompiling invalid packages
@..\..\..\..\aspen2\tools\recompile_packages.sql

exit