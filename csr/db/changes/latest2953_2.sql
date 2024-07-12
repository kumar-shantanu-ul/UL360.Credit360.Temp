-- Please update version.sql too -- this keeps clean builds in sync
define version=2953
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.allowed_sso_login_redirect (
    url                             VARCHAR2(256)  NOT NULL,
    display_name                    VARCHAR2(256)  NOT NULL,
    id                              NUMBER(10, 0) PRIMARY KEY
);

CREATE OR REPLACE TYPE csr.t_sso_log_row AS
    OBJECT (
        saml_log_host               VARCHAR2(256),
        log_dtm                     DATE,
        saml_request_id             NUMBER(10, 0),
        message_sequence            NUMBER(10, 0),
        message                     VARCHAR2(4000),
        saml_log_data               CLOB
    );
/
CREATE OR REPLACE TYPE csr.t_sso_log_table AS
    TABLE OF csr.t_sso_log_row;
/
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.v$sso_log AS
    SELECT c.host AS saml_log_host, log.log_dtm AS LOG_DTM, log.saml_request_id AS saml_request_id,
           log.message_sequence AS message_sequence, log.message AS saml_log_msg, d.saml_assertion AS saml_log_data,
           c.app_sid AS app_sid
      FROM csr.customer c
      JOIN csr.saml_log log
        ON c.app_sid = log.app_sid
        JOIN (
            SELECT saml_request_id, log_dtm
              FROM (
                SELECT SAML_REQUEST_ID, LOG_DTM
                  FROM CSR.SAML_LOG
                 WHERE MESSAGE_SEQUENCE = 1
              ORDER BY LOG_DTM DESC
            )
        ) s
        ON s.saml_request_id = log.saml_request_id
 LEFT JOIN csr.saml_assertion_log d
        ON log.saml_request_id = d.saml_request_id;


-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.allowed_sso_login_redirect (url, display_name, id) VALUES ('/csr/public/sso/InitiateSingleSignOn.aspx', 'Single Sign On', 0);
INSERT INTO csr.allowed_sso_login_redirect (url, display_name, id) VALUES ('/csr/site/login.acds', 'CSR Login', 1);
INSERT INTO csr.allowed_sso_login_redirect (url, display_name, id) VALUES ('/csr/site/chain/public/login.acds', 'Chain Login', 2);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../saml_pkg;
@../saml_body;

@update_tail
