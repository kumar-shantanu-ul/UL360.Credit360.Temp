-- Please update version.sql too -- this keeps clean builds in sync
define version=2242
@update_header

UPDATE csr.section SET plugin=null WHERE title_only=1;

@../flow_pkg
@../flow_body

@../chem/substance_body
    	
@update_tail
