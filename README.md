dotfiles
========

Setting up a development toolbox
--------------------------------
Use the ansible playbook to get things started:

```
$ sudo dnf install ansible
$ cat /etc/ansible/hosts
# Also works with toolbx
localhost ansible_connection=local
$ ./setup-toolbox.yml
```
