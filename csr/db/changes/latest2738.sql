define version=2738
@update_header

ALTER TABLE chain.filtersupplierreportlinks
  ADD position NUMBER(10) NULL;

@..\chain\helper_body
@..\chain\filter_pkg
@..\chain\filter_body

@update_tail
