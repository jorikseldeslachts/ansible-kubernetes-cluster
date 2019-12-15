#!/usr/bin/python3
####!/usr/bin/python

ANSIBLE_METADATA = {
    'metadata_version': '1.1',
    'status': ['preview'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: nginx_ingress_controller

short_description: Module for Kubernetes/Nginx-ingress as DaemonSet

version_added: "2.8"

description:
    - "This module transforms the kubernetes/nginx-ingress ingress-controller to a DaemonSet that runs on al nodes with a specified nodeselector"

options:
    git_url:
        description:
            - The git url to the complete yaml file
        required: true

    node_selector:
        description:
            - The DaemonSet will run on all nodes with this label
        required: true

    destination:
        description:
            - Destination path on the target machine
        required: true

    namespace?
    podname?
    daemonsetname?
author:
    - Jorik Seldeslachts (@Jorsel)
'''

EXAMPLES = '''
# Pass in a message
- name: Generate Nginx ingress controller
  nginx_ingress_controller:
    git_url: "{{nginx_url}}"
    node_selector: "infra"
    destination: /etc/kubernetes/
'''

RETURN = '''
original_message:
    description: The original name param that was passed in
    type: str
message:
    description: The output message that the sample module generates
'''

from ansible.module_utils.basic import AnsibleModule
import requests
import yaml


def run_module():
    # available arguments/parameters that a user can pass to the module
    module_args = dict(
        git_url=dict(type='str', required=True),
        node_selector=dict(type='str', required=False, default=None),
        destination=dict(type='str', required=True)
    )

    # seed the result dict in the object
    # we primarily care about changed and state
    # change is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task
    result = dict(
        changed=False,
        original_message='',
        message=''
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        return result

    # manipulate or modify the state as needed (this is going to be the
    # part where your module will do what it needs to do)
    result['original_message'] = module.params['name']
    result['message'] = 'goodbye'


    #############################
    # download original yaml config
    original_yaml = download_original(module_args['git_url'])

    # create custom config
    custom_yaml = create_custom_yaml_content(original_yaml, module_args['node_selector'])

    # put file on destination
    write_file(module_args['destination'], custom_yaml)

    result['message'] = 'Testing output lalala'
    #############################


    # use whatever logic you need to determine whether or not this module
    # made any modifications to your target
    if module.params['new']:
        result['changed'] = True

    # during the execution of the module, if there is an exception or a
    # conditional state that effectively causes a failure, run
    # AnsibleModule.fail_json() to pass in the message and the result
    if module.params['name'] == 'fail me':
        module.fail_json(msg='You requested this to fail', **result)

    # in the event of a successful module execution, you will want to
    # simple AnsibleModule.exit_json(), passing the key/value results
    module.exit_json(**result)


def download_original(url):
    try:
        response = requests.get(url)
        return response.content.decode()
    except Exception as e:
        print("Error downloading the original yaml content")


def create_custom_yaml_content(original_content, node_selector):
    # split in yaml files
    yaml_content = original_content.split("---")[:-1]

    # define result var
    end_result = ""

    # loop over items
    for item in yaml_content:
        if item is not None:
            resource = yaml.load(item, Loader=yaml.FullLoader)
            
            if resource['kind'].lower() == 'deployment':            
                # change to daemonset
                resource['kind'] = "DaemonSet"
                
                # delete replicas
                del resource['spec']['replicas']
                
                # change nodeselector
                if node_selector is not None:
                    resource['spec']['template']['spec']['nodeSelector'] = {
                        node_selector.split('=')[0]: node_selector.split('=')[1]
                    }
                
            # add resource to end_result
            end_result = append_result(end_result, resource)
    
    # return result
    return end_result


def append_result(var_to_append, resource):
    var_to_append += "\n---\n"
    var_to_append += yaml.dump(resource)
    return var_to_append


def write_file(destination, content):
    file = open(destination, "w")
    file.write(content)
    file.close()


def main():
    run_module()


if __name__ == '__main__':
    main()