CREATE OR REPLACE PACKAGE csr.backup_pkg AUTHID CURRENT_USER AS

FUNCTION q( 
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;

FUNCTION dq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;

PROCEDURE EnableTrace;

PROCEDURE DisableTrace;

PROCEDURE EnableTraceOnly;

PROCEDURE DisableTraceOnly;

PROCEDURE Backup(
	in_backup_name					IN	VARCHAR2,
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	in_where						IN	VARCHAR2
);

END backup_pkg;
/
