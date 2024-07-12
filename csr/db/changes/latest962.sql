-- Please update version.sql too -- this keeps clean builds in sync
define version=962
@update_header

ALTER TABLE CHEM.PROCESS_DESTINATION MODIFY (REMAINING_DEST NULL);

@../chem/substance_pkg
@../chem/substance_body

@update_tail