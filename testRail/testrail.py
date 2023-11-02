"""TestRail API binding for Python 3.x.

(API v2, available since TestRail 3.0)

Compatible with TestRail 3.0 and later.

Learn more:

http://docs.gurock.com/testrail-api2/start
http://docs.gurock.com/testrail-api2/accessing

Copyright Gurock Software GmbH. See license.md for details.
"""

import base64
import json

import requests

# OTT Project ID
project_id = 31
# Default Suite ID
suite_id = 47


class APIClient:
    def __init__(self, base_url):
        self.user = ''
        self.password = ''
        if not base_url.endswith('/'):
            base_url += '/'
        self.__url = base_url + 'index.php?/api/v2/'

    def send_get(self, uri, filepath=None, parameters=None):
        """Issue a GET request (read) against the API.

        Args:
            uri: The API method to call including parameters, e.g. get_case/1.
            filepath: The path and file name for attachment download; used only
                for 'get_attachment/:attachment_id'.

        Returns:
            A dict containing the result of the request.
        """
        return self.__send_request('GET', uri, filepath, parameters)

    def send_post(self, uri, data):
        """Issue a POST request (write) against the API.

        Args:
            uri: The API method to call, including parameters, e.g. add_case/1.
            data: The data to submit as part of the request as a dict; strings
                must be UTF-8 encoded. If adding an attachment, must be the
                path to the file.

        Returns:
            A dict containing the result of the request.
        """
        return self.__send_request('POST', uri, data)

    def __send_request(self, method, uri, data, parameters=None):
        url = self.__url + uri

        auth = str(
            base64.b64encode(
                bytes('%s:%s' % (self.user, self.password), 'utf-8')
            ),
            'ascii'
        ).strip()
        headers = {'Authorization': 'Basic ' + auth}

        if method == 'POST':
            if uri[:14] == 'add_attachment':  # add_attachment API method
                files = {'attachment': (open(data, 'rb'))}
                response = requests.post(url, headers=headers, files=files)
                files['attachment'].close()
            else:
                headers['Content-Type'] = 'application/json'
                payload = bytes(json.dumps(data), 'utf-8')
                response = requests.post(url, headers=headers, data=payload)
        else:
            headers['Content-Type'] = 'application/json'
            response = requests.get(url, headers=headers, params=parameters)

        if response.status_code > 201:
            try:
                error = response.json()
            except:  # response.content not formatted as JSON
                error = str(response.content)
            raise APIError('TestRail API returned HTTP %s (%s)' % (response.status_code, error))
        else:
            if uri[:15] == 'get_attachment/':  # Expecting file, not JSON
                try:
                    open(data, 'wb').write(response.content)
                    return (data)
                except:
                    return ("Error saving attachment.")
            else:
                try:
                    return response.json()
                except:  # Nothing to return
                    return {}


class APIError(Exception):
    pass


client = APIClient('https://tubi.testrail.io/')
client.user = 'build@tubi.tv'
client.password = 'Passw0rd'


def create_test_run(build_ver):
    payload = json.dumps({
        "suite_id": suite_id,
        "name": f"Roku {build_ver} Suitest Run (Hybrid)",
        "description": f"RTA Run Result for {build_ver}",
        "include_all": False
    })
    response = client.send_post(f'/add_run/{project_id}', json.loads(payload))
    test_run_id = response['id']
    print(f"TestRun #{test_run_id} in TestRail Created.")
    return test_run_id


def get_all_test_case_ids_in_testrail(test_run_id):
    test_run_detail = client.send_get(f'get_tests/{str(test_run_id)}')
    test_run_detail_1 = client.send_get(f'get_tests/{str(test_run_id)}', parameters={'offset': 250})

    existing_cases = test_run_detail['tests']
    existing_case_ids = [case['case_id'] for case in existing_cases]

    existing_cases_1 = test_run_detail_1['tests']
    if not existing_cases_1 == []:
        existing_case_ids += [case['case_id'] for case in existing_cases_1]
    return existing_case_ids
