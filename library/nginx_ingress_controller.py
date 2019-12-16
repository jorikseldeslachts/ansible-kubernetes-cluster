#!/usr/bin/python

# https://blog.toast38coza.me/custom-ansible-module-hello-world/


# ANSIBLE_METADATA = {
#     'metadata_version': '1.1',
#     'status': ['preview'],
#     'supported_by': 'community'
# }

# DOCUMENTATION = '''
# ---
# module: nginx_ingress_controller

# short_description: Module for Kubernetes/Nginx-ingress as DaemonSet

# version_added: "2.8"

# description:
#     - "This module transforms the kubernetes/nginx-ingress ingress-controller to a DaemonSet that runs on al nodes with a specified nodeselector"

# options:
#     git_url:
#         description:
#             - The git url to the complete yaml file
#         required: true

#     node_selector:
#         description:
#             - The DaemonSet will run on all nodes with this label
#         required: true

#     destination:
#         description:
#             - Destination path on the target machine
#         required: true

#     namespace?
#     podname?
#     daemonsetname?
# author:
#     - Jorik Seldeslachts (@Jorsel)
# '''

# EXAMPLES = '''
# # Pass in a message
# - name: Generate Nginx ingress controller
#   nginx_ingress_controller:
#     git_url: "{{nginx_url}}"
#     node_selector: "infra"
#     destination: /etc/kubernetes/
# '''

# RETURN = '''
# original_message:
#     description: The original name param that was passed in
#     type: str
# message:
#     description: The output message that the sample module generates
# '''



from ansible.module_utils.basic import *
import requests
import yaml
import sys


def main():

    # Setup module args
    module_args = {
        "git_url": {
            "type": "str",
            "required": True
        },
        "node_selector": {
            "type": "str",
            "required": False,
            "default": None
        },
        "destination" : {
            "type": "str",
            "required": True
        }
    }
    module = AnsibleModule(argument_spec=module_args)

    # download original yaml config
    original_yaml = download_original(module_args['git_url'])

    # create custom config
    custom_yaml = create_custom_yaml_content(original_yaml, module_args['node_selector'])

    # put file on destination
    write_file(module_args['destination'], custom_yaml)

    # return result
    response = {"Status": "Nginx Ingress Controller deployed as DaemonSet"}
    module.exit_json(changed=False, meta=response)


def download_original(url):
    try:
        print("Downloading {0}".format(url))
        response = requests.get(url)
        return response.content.decode()
    except Exception as e:
        print("Error downloading the original yaml content")
        sys.exit(1)


def create_custom_yaml_content(original_content, node_selector):
    # split in yaml files
    yaml_content = original_content.split("---")[:-1]

    # define result var
    end_result = ""

    # loop over items
    print("Looping over items in original file")
    for item in yaml_content:
        if item is not None:
            resource = yaml.load(item, Loader=yaml.FullLoader)
            
            if resource['kind'].lower() == 'deployment':
                print("Found Deployment, turning it into a DaemonSet")

                # change to daemonset
                print("Changing type to Daemonset")
                resource['kind'] = "DaemonSet"
                
                # delete replicas
                print("Deleting replicas section")
                del resource['spec']['replicas']
                
                # change nodeselector
                if node_selector is not None:
                    print("Updating nodeselector to match: {0}".format(node_selector))
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
    print("Writing new content to file {0}".format(destination))
    file = open(destination, "w")
    file.write(content)
    file.close()


if __name__ == '__main__':
    main()