-- Please update version.sql too -- this keeps clean builds in sync
define version=281
@update_header


ALTER TABLE help_file ADD DATA_HASH RAW(20);

UPDATE help_file
   SET data_hash = dbms_crypto.HASH(DATA, 3);	
      
ALTER TABLE help_file MODIFY data_hash NOT NULL;


@..\help\help_pkg
@..\help\help_body
		
@update_tail
