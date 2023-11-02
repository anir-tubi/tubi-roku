from result_parser import Parser
from result_updater import Updater, get_all_test_case_ids_in_testrail

print("Updating results to TestRail...")

# For debugging locally
# report_path = "../automated-tests/debugfolder/rtaresult.json"


# report_path
report_path = 'out/ui-tests-output/report.json'

# Parse Mocha JSON report
parse_result = Parser(report_path)
build_version = parse_result.build_version
device_info = parse_result.device_info
parsed_cases = parse_result.parsed_cases
failed_cases = parse_result.failed_cases

# Update results to TestRail
update_result = Updater(build_version, device_info, parsed_cases)
invalid_test_cases = update_result.invalid_test_cases

# Print Logs
# Fetch all test case ids that are added to the created test run in TestRail
test_cases_in_testrail = get_all_test_case_ids_in_testrail(update_result.run_id)

# Get all test case ids that have been found in RTA report
case_ids_extracted_from_report = [case['id'] for case in parsed_cases]

if invalid_test_cases:
    print(f"These test cases could not be found in TestRail, the test case IDs in RTA title are: "
          f"\n{invalid_test_cases}")

seen = set()
dupes_in_log = [x for x in case_ids_extracted_from_report if x in seen or seen.add(x)]
s = set(test_cases_in_testrail)
missed = [x for x in set(case_ids_extracted_from_report) if x not in s]

if dupes_in_log:
    print(f"There are cases with duplicate name in RTA: \n{dupes_in_log}\n, please check them out in the "
          f"RTA suites.")
if missed:
    print(
        f"These cases from RTA were failed to be updated into TestRail, "
        f"please check if the case still exists in TestRail:\n{missed}\n, "
        f"OR you could try adding them manually to see if any error happens."
    )
