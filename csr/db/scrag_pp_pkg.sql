CREATE OR REPLACE PACKAGE CSR.scrag_pp_pkg IS

PROCEDURE EnableTestCube;

PROCEDURE EnableScragPP(
	in_approved_ref			IN VARCHAR2 DEFAULT NULL
);

END scrag_pp_pkg;
/
