from testrail import *


class Updater:
    def __init__(self, build_version, device_info, cases):
        self.invalid_test_cases = []
        self.logged_updated_cases = []
        self.existing_case_ids = []
        self.build_version = build_version
        self.device_info = device_info
        self.run_id = create_test_run(self.build_version)

        def add_test_case(case_id):
            payload = json.dumps({
                "include_all": False,
                "case_ids": self.existing_case_ids + [case_id]
            })

            try:
                client.send_post(f'update_run/{self.run_id}', json.loads(payload))
            except Exception as adding_case_error:
                raise adding_case_error
            else:
                self.existing_case_ids.append(case_id)
                print(f'TC #{case_id} is added into TestRun #{self.run_id}.')

        for case in cases:
            try:
                add_test_case(case['id'])
            except Exception as e:
                self.invalid_test_cases.append(case['id'])
                print(f'Failed to add TC{case["id"]} into test run! {e}')
                if 'unrecognized case IDs' in e.args[0]:
                    print(f'TC{case["id"]} does not exist in TestRail! Will skip updating it into Testrail.')
                continue
            else:
                try:
                    client.send_post(f'add_result_for_case/{self.run_id}/{case["id"]}',
                                     {'status_id': case["result"],
                                      'comment': f'Device: {self.device_info}; Build: {self.build_version}; Message: {case["comment"]}'})
                except Exception as e:
                    print(f'Failed to update the result of TC #{case["id"]}! {e}')
                else:
                    print(f'TC #{case["id"]} result updated.')
                    self.logged_updated_cases.append(case["id"])
        print('Sync to TestRail Completed!')
