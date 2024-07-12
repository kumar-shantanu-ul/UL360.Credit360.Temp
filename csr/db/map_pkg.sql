CREATE OR REPLACE PACKAGE CSR.Map_Pkg AS

MAP_CONTEXT_OTHER             CONSTANT NUMBER(2) := 0;
MAP_CONTEXT_DATA_EXPLORER     CONSTANT NUMBER(2) := 1;
MAP_CONTEXT_SNAPSHOT          CONSTANT NUMBER(2) := 2;
MAP_CONTEXT_TARGET_DASHBOARD  CONSTANT NUMBER(2) := 3;
MAP_CONTEXT_INITIATIVES       CONSTANT NUMBER(2) := 4;

PROCEDURE GetMapByContext(
  in_map_context  IN  customer_map.map_context%TYPE,
  out_cur         OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLocationsForCountry(
  in_country_code IN  region.geo_country%TYPE,
  out_cur         OUT   security_pkg.T_OUTPUT_CUR
);

END Map_Pkg;
/

