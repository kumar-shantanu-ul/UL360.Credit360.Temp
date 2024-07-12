CONNECT csr/csr@aspen

INSERT INTO csr.AUDIT_TYPE ( AUDIT_TYPE_ID, LABEL ) VALUES (11, 'Action change');
INSERT INTO csr.AUDIT_TYPE ( AUDIT_TYPE_ID, LABEL ) VALUES (12, 'Action progress update');

CONNECT csr/csr@aspen

grant execute on csr_data_pkg to actions;
