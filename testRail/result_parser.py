import json
import re


class Parser:
    def __init__(self, path):
        self.parsed_cases = []
        self.passed_cases = []
        self.failed_cases = []
        self.pending_cases = []
        self.build_version = ''
        self.device_info = ''

        test_report = open(path)
        test_result = json.load(test_report)
        if not test_result:
            print("No test results found!")

        pass_results = test_result['passes']
        failure_results = test_result['failures']
        pending_results = test_result['pending']

        # Passes cases update with status=1, means Pass in Testrail
        if len(pass_results) > 0:
            for case in pass_results:
                case_ids = re.findall(r"C(\d+)", case['title'])
                for case_id in case_ids:
                    parsed_case = {
                        'id': int(case_id),
                        'result': 1,
                        'comment': 'Automation PASS!'
                    }
                    self.passed_cases.append(parsed_case)

        # Failure cases update with status=5, means Failed in Testrail
        if len(failure_results) > 0:
            for case in failure_results:
                case_ids = re.findall(r"C(\d+)", case['title'])
                for case_id in case_ids:
                    parsed_case = {
                        'id': int(case_id),
                        'result': 5,
                        'comment': case['err']
                    }
                    self.failed_cases.append(parsed_case)

        # Pending cases update with status=4, means retest in Testrail
        if len(pending_results) > 0:
            for case in pending_results:
                case_ids = re.findall(r"\d+\.?\d*", case['title'])
                for case_id in case_ids:
                    parsed_case = {
                        'id': int(case_id),
                        'result': 4,
                        'comment': 'pending cases'
                    }
                    self.pending_cases.append(parsed_case)

        self.parsed_cases = self.passed_cases + self.failed_cases + self.pending_cases

        try:
            self.device_info = test_result['deviceInfo']['modelName'] + test_result['deviceInfo']['modelNumber']
        except:
            self.device_info = "No device info!"

        try:
            self.build_version = test_result['runInfo']['applicationVersion']
        except:
            self.build_version = "No build version!"
