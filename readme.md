# SSH Key Management Script

A handy script for SSH key management to facilitate secure access to your servers.

## Features

- Update SSH keys for targeted servers.
- Specify custom SSH port and SSH key filename.
- Copy SSH keys to the server with a force option.
- Quiet mode for automation tools.
- Validate both IPv4 and IPv6 addresses.
- Install missing SSH-related commands automatically.

## Usage

```sh
./key_manager.sh server_ip [OPTIONS]
```

### Options

- **server_ip**: The IP address of the target server.
- `-u`: Updates the SSH key for the target server.
- `-p password`: The root user's password (used only with `-c`).
- `-P port`: The SSH port of the target server (default: 22).
- `-c`: Forces the copying of the SSH key to the server.
- `-n keyname`: A custom filename for the SSH key (default: id_rsa).
- `-q`: Quiet mode: suppresses the output for automation tools.
- `-h`: Shows the help message and exits.

## Requirements

The script automatically checks for the presence of necessary commands like `ssh-keygen`, `ssh-copy-id`, `ssh`, `sshpass`, and `ssh-keyscan`, and attempts to install any that are missing.

## Installation

To get started, copy or clone the script to a file, give it execution permissions with `chmod +x ssh_key_manager.sh`, and run it from the terminal.

## Support

For any issues or help using the script, please contact Percio Andrade at:
- Email: [percio@zendev.com.br](mailto:percio@zedev.com.br)

---

This script is provided as-is with no warranty. Use it at your own risk. Contributions and feedback are welcome.