CREATE OR REPLACE PACKAGE CHAIN.dedupe_helper_pkg
IS

FUNCTION GetImportSourceId(
	in_lookup_key					IN import_source.lookup_key%TYPE
)RETURN import_source.import_source_id%TYPE;

FUNCTION IsOwnedBySystem(
	in_import_source_id		IN import_source.import_source_id%TYPE
)RETURN BOOLEAN;

END dedupe_helper_pkg;
/

