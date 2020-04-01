{
  "variables": {
    "aws_region": "us-west-2",
    "ami_name": "eks-k8s-worker-cis-${OS}-${VERSION}-ami-{{timestamp}}",
    "creator": "{{env `USER`}}",
    "encrypted": "false",
    "kms_key_id": "",
    
    "aws_access_key_id": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_access_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
    "aws_session_token": "{{env `AWS_SESSION_TOKEN`}}",

    "binary_bucket_name": "amazon-eks",
    "binary_bucket_region": "us-west-2",
    "kubernetes_version": null,
    "kubernetes_build_date": null,
    "docker_version": null,
    "cni_version": "v0.6.0",
    "cni_plugin_version": "v0.7.5",

    "source_ami_id": "{{user `source_ami_id`}}",
    "arch": null,
    "instance_type": null,
    "ami_description": "EKS Kubernetes Worker AMI with ${OS}-${VERSION} image",

    "ssh_interface": "",
    "ssh_username": "{{ user `ssh_user` }}",
    "temporary_security_group_source_cidrs": "{{ user `temporary_sg_source_cidrs` }}",
    "security_group_id": "",
    "associate_public_ip_address": "",
    "subnet_id": "{{ user `subnet_id` }}",
    "remote_folder": "",
    "launch_block_device_mappings_volume_size": "4",
    "ami_users": "",
    "additional_yum_repos": ""
  },
  "builders": [
    {
      "type": "amazon-ebs",
      "region": "{{user `aws_region`}}",
      "source_ami": "{{user `source_ami_id`}}",
      "ami_users": "{{user `ami_users`}}",
      "snapshot_users": "{{user `ami_users`}}",
      "instance_type": "{{user `instance_type`}}",
      "launch_block_device_mappings": [
        {
          "device_name": "/dev/xvda",
          "volume_type": "gp2",
          "volume_size": "{{user `launch_block_device_mappings_volume_size`}}",
          "delete_on_termination": true
        }
      ],
      "ami_block_device_mappings": [    
        {
          "device_name": "/dev/xvda",
          "volume_type": "gp2",
          "volume_size": 20,
          "delete_on_termination": true
        }
      ],
      "ssh_username": "{{user `ssh_username`}}",
      "ssh_interface": "{{user `ssh_interface`}}",
      "temporary_security_group_source_cidrs": "{{user `temporary_security_group_source_cidrs`}}",
      "security_group_id": "{{user `security_group_id`}}",
      "associate_public_ip_address": "{{user `associate_public_ip_address`}}",
      "ssh_pty": true,
      "encrypt_boot": "{{user `encrypted`}}",
      "kms_key_id": "{{user `kms_key_id`}}",
      "run_tags": {
          "creator": "{{user `creator`}}"
      },
      "subnet_id": "{{user `subnet_id`}}",
      "tags": {
          "Name": "{{user `ami_name`}}",
          "created": "{{timestamp}}",
          "docker_version": "{{ user `docker_version`}}",
          "source_ami_id": "{{ user `source_ami_id`}}",
          "kubernetes": "{{ user `kubernetes_version`}}/{{ user `kubernetes_build_date` }}/bin/linux/{{ user `arch` }}",
          "cni_version": "{{ user `cni_version`}}",
          "cni_plugin_version": "{{ user `cni_plugin_version`}}"
      },
      "ami_name": "{{user `ami_name`}}",
      "ami_description": "{{ user `ami_description` }}, (k8s: {{ user `kubernetes_version`}}, docker:{{ user `docker_version`}})"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "remote_folder": "{{ user `remote_folder`}}",
      "inline": ["mkdir -p /tmp/worker/"]
    },
    {
      "type": "file",
      "source": "{{template_dir}}/files/",
      "destination": "/tmp/worker/"
    },
    {
        "type": "shell",
        "remote_folder": "{{ user `remote_folder`}}",
        "script": "{{template_dir}}/scripts/install_additional_repos.sh",
        "environment_vars": [
          "ADDITIONAL_YUM_REPOS={{user `additional_yum_repos`}}"
        ]
    },
    {
      "type": "shell",
      "remote_folder": "{{ user `remote_folder`}}",
      "script": "{{template_dir}}/scripts/install-worker.sh",
      "environment_vars": [
        "KUBERNETES_VERSION={{user `kubernetes_version`}}",
        "KUBERNETES_BUILD_DATE={{user `kubernetes_build_date`}}",
        "BINARY_BUCKET_NAME={{user `binary_bucket_name`}}",
        "BINARY_BUCKET_REGION={{user `binary_bucket_region`}}",
        "DOCKER_VERSION={{user `docker_version`}}",
        "CNI_VERSION={{user `cni_version`}}",
        "CNI_PLUGIN_VERSION={{user `cni_plugin_version`}}",
        "AWS_ACCESS_KEY_ID={{user `aws_access_key_id`}}",
        "AWS_SECRET_ACCESS_KEY={{user `aws_secret_access_key`}}",
        "AWS_SESSION_TOKEN={{user `aws_session_token`}}",
        "OS=${OS}",
        "VERSION=${VERSION}"
      ]
    },
    {
        "type": "shell",
        "inline": [
            "sudo pip3 install ansible"
        ]
    }, 
    {
        "type": "ansible-local",
        "playbook_file": "ansible/${OS}.yaml",
        "role_paths": [
            "ansible/roles/common"
        ],
        "playbook_dir": "ansible"
    },
    {
      "type": "shell",
      "inline": [
        "rm .ssh/authorized_keys ; sudo rm /root/.ssh/authorized_keys"
      ]
    }
  ],
  "post-processors": [
    {
      "type": "manifest",
      "output": "${OS}-${VERSION}-manifest.json",
      "strip_path": true
    }
  ]
}
