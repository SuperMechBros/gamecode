void LOG_TRACE(string s, ...) = #25;
string ftos(float f) = #26;
string vtos(vector v) = #27;
void error(string e) = #10;
float test();

spawnfunc(worldspawn)
{
	float r;
	LOG_TRACE("TESTCASE: START");
	r = test();
	if(r == 1)
		error("TESTCASE: PASS");
	else if(r == 0)
		error("TESTCASE: FAIL");
	else
		error("TESTCASE: INVALID");
}
