CREATE OR REPLACE PACKAGE csr.test_integration_question_answer_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestAddKeyFields;
PROCEDURE TestAddAllFields;
PROCEDURE TestUpdate;
PROCEDURE TestUpdateAllFields;
PROCEDURE TestDelete;
PROCEDURE TestGetOne;
PROCEDURE TestGetAll;

PROCEDURE TearDownFixture;
END test_integration_question_answer_pkg;
/
