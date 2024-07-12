-- Please update version.sql too -- this keeps clean builds in sync
define version=3
@update_header

CREATE OR REPLACE VIEW supplier.v$wood_part_wood AS 
SELECT  
   product_part_id, species_code, country_code, 
   region, cert_doc_group_id, bleaching_process_id, 
   wrme_wood_type_id, cert_scheme_id, part_wood_pkg.GetForestSourceCatCode(security.security_pkg.getAct, product_part_id) forest_source_cat_code
FROM supplier.wood_part_wood;

@..\report_wood_body


@update_tail