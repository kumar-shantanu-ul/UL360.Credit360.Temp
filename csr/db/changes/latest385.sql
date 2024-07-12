-- Please update version.sql too -- this keeps clean builds in sync
define version=385
@update_header

ALTER TABLE UTILITY_CONTRACT MODIFY (
	FROM_DTM               DATE		NULL,
	TO_DTM                 DATE		NULL
);

@../utility_pkg
@../utility_body

@update_tail
