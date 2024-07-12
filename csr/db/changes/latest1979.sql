-- Please update version.sql too -- this keeps clean builds in sync
define version=1979
@update_header

BEGIN
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier)
	VALUES(chain.capability_id_seq.NEXTVAL,'Remove user from company',1,1,0);
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier)
	VALUES(chain.capability_id_seq.NEXTVAL,'Remove user from company',2,1,1);
END;
/

@../chain/chain_pkg
@../chain/company_user_pkg
@../chain/company_user_body
 
@update_tail