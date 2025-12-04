# Debug k8s

Small scripts to gather different informations on a k8s cluster for debugging purposes.


## Requirements

Have kubectl installed with a configured kubeconfig file.

## Usage

```bash
$ ./get_k8s_info.sh
```

An output directory will be created with multiple sub-directories and a tar.gz file compressing all output in one file will be made if ``--archive=true``.

Get all options with:

```bash
$ ./get_k8s_info.sh --help
```
