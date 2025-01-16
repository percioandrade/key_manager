SSH Key Manager 🔑

# About 📝
SSH Key Manager is a utility script to manage SSH keys and connections to remote servers. Handles both IPv4 and IPv6 addresses, supports key generation, automatic key copying, and custom SSH ports.

- Automatic SSH key generation and management
- Support for IPv4 and IPv6 addresses
- Custom SSH port configuration
- Password-based key copying
- Quiet mode for automation
- Custom key naming

Manage, generate and connect on server using a key.

- Author 👨‍💻
- Percio Andrade
- Email: percio@zendev.com.br
- Website: Zendev : https://zendev.com.br

## Requirements 🛠️
- ssh-keygen
- ssh-copy-id
- ssh
- sshpass (optional, for password-based auth)
- ssh-keyscan

## Usage 🚀

```bash
./key_manager.sh server_ip [-u] [-p password] [-P port] [-c] [-n keyname] [-q]
```

## Options 🎛️
- `-server_ip`: IP address of target server (IPv4/IPv6)
- `-u`: Update existing SSH key
- `-p` password: Root user password for key copying
- `-P` port: Custom SSH port (default: 22)
- `-c`: Force copy SSH key to server
- `-n` keyname: Custom SSH key filename (default: id_rsa)
- `-q`: Quiet mode for automation
- `-h`: Show help message

## Port - Total Connections (color coded)
Example 🌟

```bash
# Basic usage with IPv4
./key_manager.sh 192.168.1.100

# Using custom port and key name
./key_manager.sh 192.168.1.100 -P 2222 -n custom_key

# Force update with password
./key_manager.sh 192.168.1.100 -u -p mypassword -c
```

## Notes 📌
Ensure you have the necessary permissions to run the script as root.

Make sure all required commands are installed on your system.

# License 📄
This project is licensed under the GNU General Public License v2.0
