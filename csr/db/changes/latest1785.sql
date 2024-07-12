-- Please update version.sql too -- this keeps clean builds in sync
define version=1785
@update_header

BEGIN
EXECUTE IMMEDIATE 
		'UPDATE supplier.gt_sa_question
				 SET default_gt_sa_score = 0, question_name = "FSA 2012 salt reduction target met"
		  WHERE gt_sa_question_id = 17';
EXCEPTION WHEN OTHERS THEN
RETURN;
END;
/

@update_tail