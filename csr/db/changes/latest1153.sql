-- Please update version.sql too -- this keeps clean builds in sync
define version=1153
@update_header

ALTER TABLE CSR.SCORE_THRESHOLD ADD (
    BAR_COLOUR              NUMBER(10, 0),
    DASHBOARD_IMAGE         BLOB,
    DASHBOARD_FILENAME      VARCHAR2(255),
    DASHBOARD_MIME_TYPE     VARCHAR2(255)
)
;

grant select, references on csr.supplier to chain;
grant select, references on csr.score_threshold to chain;

@..\quick_survey_pkg
@..\chain\report_pkg

@..\quick_survey_body
@..\chain\dashboard_body
@..\chain\report_body


@update_tail
