define version=2070
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow sheet to be returned once approved', 1);
INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Only allow bottom delegation to enter data', 0);

@update_tail