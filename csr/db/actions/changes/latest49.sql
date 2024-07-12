-- Please update version.sql too -- this keeps clean builds in sync
define version=49
@update_header

ALTER TABLE ROOT_IND_TEMPLATE_INSTANCE DROP CONSTRAINT RefIND161
;

ALTER TABLE ROOT_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefIND161 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
    DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE PROJECT_IND_TEMPLATE_INSTANCE DROP CONSTRAINT RefIND157 
;

ALTER TABLE PROJECT_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefIND157 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
	DEFERRABLE INITIALLY DEFERRED    
;


-- run as csr
PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

grant select, references on region_owner to actions;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail
