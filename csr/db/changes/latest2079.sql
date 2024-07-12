define version=2079
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) 
SELECT 'Automatically approve Data Change Requests', 0
  FROM dual
 WHERE NOT EXISTS(SELECT * FROM CSR.CAPABILITY WHERE NAME = 'Automatically approve Data Change Requests');

@update_tail
