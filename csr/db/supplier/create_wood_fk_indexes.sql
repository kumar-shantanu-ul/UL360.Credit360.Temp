create index supplier.ix_wood_part_des_post_cert_sch on supplier.wood_part_description (post_cert_scheme_id);
create index supplier.ix_wood_part_des_pre_cert_sche on supplier.wood_part_description (pre_cert_scheme_id);
create index supplier.ix_wood_part_des_pre_recycled_ on supplier.wood_part_description (pre_recycled_country_code);
create index supplier.ix_wood_part_des_post_recycled on supplier.wood_part_description (post_recycled_country_code);
create index supplier.ix_wood_part_des_pre_recycled_ on supplier.wood_part_description (pre_recycled_doc_group_id);
create index supplier.ix_wood_part_des_post_recycled on supplier.wood_part_description (post_recycled_doc_group_id);
create index supplier.ix_wood_part_des_weight_unit_i on supplier.wood_part_description (weight_unit_id);
create index supplier.ix_wood_part_woo_bleaching_pro on supplier.wood_part_wood (bleaching_process_id);
create index supplier.ix_wood_part_woo_cert_scheme_i on supplier.wood_part_wood (cert_scheme_id);
create index supplier.ix_wood_part_woo_country_code on supplier.wood_part_wood (country_code);
create index supplier.ix_wood_part_woo_cert_doc_grou on supplier.wood_part_wood (cert_doc_group_id);
create index supplier.ix_wood_part_woo_forest_source on supplier.wood_part_wood (forest_source_cat_code);
create index supplier.ix_wood_part_woo_species_code on supplier.wood_part_wood (species_code);
create index supplier.ix_wood_part_woo_wrme_wood_typ on supplier.wood_part_wood (wrme_wood_type_id);

create index supplier.ix_cert_scheme_verified_fscc on supplier.cert_scheme (verified_fscc);
create index supplier.ix_cert_scheme_non_verified_ on supplier.cert_scheme (non_verified_fscc);

create index supplier.ix_recyc_fscc_cs_cert_scheme_i on supplier.recyc_fscc_cs_map (cert_scheme_id);
