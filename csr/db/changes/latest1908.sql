-- Please update version.sql too -- this keeps clean builds in sync
define version=1908
@update_header

ALTER TABLE SUPPLIER.COUNTRY
 ADD (MEANS_VERIFIED  NUMBER(1)                     DEFAULT 1                     NOT NULL);
 
 ALTER TABLE SUPPLIER.COUNTRY
 ADD CHECK (MEANS_VERIFIED IN (1,0));

 ALTER TABLE SUPPLIER.TREE_SPECIES
 ADD (MEANS_VERIFIED  NUMBER(1)                     DEFAULT 1                     NOT NULL);

 ALTER TABLE SUPPLIER.TREE_SPECIES
 ADD CHECK (MEANS_VERIFIED IN (1,0));
 
 	UPDATE supplier.country SET means_verified = 0 WHERE lower(country_code) = ('un');

	UPDATE supplier.tree_species SET means_verified = 0 WHERE lower(species_code) = ('un s');
	
	 --FSC recycled - dont allow user select
ALTER TABLE SUPPLIER.CERT_SCHEME
 ADD (ALLOW_USER_SELECT  NUMBER(1)                     DEFAULT 1                     NOT NULL);
 
 ALTER TABLE SUPPLIER.CERT_SCHEME
 ADD CHECK (ALLOW_USER_SELECT IN (1,0));
 
 UPDATE SUPPLIER.cert_scheme SET allow_user_select = 0 WHERE cert_scheme_id = 6; 

 
@update_tail
