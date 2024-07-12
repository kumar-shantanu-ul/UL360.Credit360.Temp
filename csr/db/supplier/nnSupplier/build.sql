set define off


PROMPT Compiling nn_supplier_pkg
@nn_supplier_pkg
PROMPT Compiling nn_man_site_pkg
@nn_man_site_pkg

PROMPT Compiling nn_supplier_body
@nn_supplier_body
PROMPT Compiling nn_man_site_body
@nn_man_site_body


PROMPT Compiling novonordisk_pkg
@../../../clients/novonordisk/db/novonordisk_pkg
PROMPT novonordisk_body
@../../../clients/novonordisk/db/novonordisk_body



set define on


@web_grants

PROMPT Recompiling invalid packages
@..\..\..\..\aspen2\tools\recompile_packages.sql
