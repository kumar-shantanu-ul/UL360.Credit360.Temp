-- Please update version.sql too -- this keeps clean builds in sync
define version=2055
@update_header

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE csrimp.map_plugin';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

CREATE TABLE csrimp.map_plugin (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_plugin_id   NUMBER(10) NOT NULL,
    new_plugin_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_plugin_id PRIMARY KEY (old_plugin_id) USING INDEX,
    CONSTRAINT uk_map_plugin_id UNIQUE (new_plugin_id) USING INDEX,
    CONSTRAINT fk_map_plugin_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

@@../csrimp/rls

@@../csrimp/imp_pkg
@@../csrimp/imp_body

@@../../../aspen2/cms/db/tab_body

@update_tail
