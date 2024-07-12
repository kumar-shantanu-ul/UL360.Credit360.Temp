define version=2038
@update_header

ALTER TABLE csr.PROPERTY_OPTIONS ADD 
  (fund_company_type_id NUMBER(10,0) DEFAULT NULL,
    CONSTRAINT fk_fund_company_type_id
    FOREIGN KEY (app_sid, fund_company_type_id)
    REFERENCES chain.company_type(app_sid, company_type_id));

@..\property_body

@update_tail
