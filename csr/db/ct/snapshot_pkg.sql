CREATE OR REPLACE PACKAGE ct.snapshot_pkg AS

PROCEDURE SnapshotData;

FUNCTION SnapshotTaken RETURN customer_options.snapshot_taken%TYPE;

END snapshot_pkg;
/
