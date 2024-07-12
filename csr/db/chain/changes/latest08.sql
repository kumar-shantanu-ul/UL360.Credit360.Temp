define version=8
@update_header

ALTER TABLE customer_options
ADD  (
    COMPANY_HELPER_SP                VARCHAR2(100)
);

@update_tail