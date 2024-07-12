CREATE OR REPLACE PACKAGE csr.test_chain_filter_pkg AS

PROCEDURE SetUp;
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;
PROCEDURE TearDown;

FUNCTION GetFilterFieldId_ (
	in_filter_field_number			IN  NUMBER
) RETURN NUMBER;

PROCEDURE FindTopN1Field;
PROCEDURE FindTopN1TopNField;
PROCEDURE FindTopN2Fields;
PROCEDURE FindTopN2TopNFields;
PROCEDURE FindTopN2TopNFldsWithNoCrumb;
PROCEDURE FindTopN2TopNFldsWithValCrumb;
PROCEDURE FindTopN2TopNFldsWthOtherCrumb;
PROCEDURE FindTopN2TopNFldsWith2Crumbs1;
PROCEDURE FindTopN2TopNFldsWith2Crumbs2;
PROCEDURE FindTopN2TopNFldsWith2Crumbs3;
PROCEDURE FindTopN2TopNFldsWith2Crumbs4;
PROCEDURE FindTopN2TopNFldsWith2Crumbs5;
PROCEDURE FindTopN2TopNFldsWith2Crumbs6;
PROCEDURE FindTopN2TopNFldsWith2Crumbs7;
PROCEDURE FindTopN2TopNFldsWith2Crumbs8;

PROCEDURE TestGetAggregateDataWithFilter;
PROCEDURE TestGetAggregateDataWithNoFilter;

END test_chain_filter_pkg;
/
