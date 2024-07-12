-- Please update version.sql too -- this keeps clean builds in sync
define version=821
@update_header

ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD (
    MONTH_DURATION                    NUMBER(10, 0)    DEFAULT 12 NOT NULL
);

-- update duration based on its parent's report's interval
UPDATE csr.tpl_report_tag_logging_form trl
   SET (month_duration) = (
	SELECT CASE (tpl.interval)
			WHEN 'y' THEN 12
			WHEN 'q' THEN 3
			WHEN 'm' THEN 1
			WHEN 'h' THEN 6
			WHEN '3' THEN 9
			END
	  FROM csr.tpl_report tpl
	  JOIN csr.tpl_report_tag tag ON tpl.tpl_report_sid = tag.tpl_report_sid and tpl.app_sid = tag.app_sid
	 WHERE tag.tpl_report_tag_logging_form_id = trl.tpl_report_tag_logging_form_id and tag.app_sid = trl.app_sid
	)
 WHERE trl.tpl_report_tag_logging_form_id IN (
	SELECT tpl_report_tag_logging_form_id
	  FROM csr.tpl_report_tag
 );


@..\templated_report_pkg
@..\templated_report_body

@update_tail
