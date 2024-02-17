# Cicada Scan
Cicada Scan is an Active Directory enumeration tool
![image](https://github.com/TheBlxckCicada/Cicada-Scan/assets/68484817/d74c7953-a097-4be9-9ca2-665ff866b7cd)

# Documentation 
```markdown
Usage: ./cicada_scan.sh -u 'username' -p 'password' -t 'target' -H 'ntlm hash' -w 'wordlist' [--full] [--crack] [--shares] [--ldap] [--smb] [--winrm] [--bloodhound]

Options:
  -u            Username for authentication
  -p            Password for authentication
  -H            NTLM Hash for authentication
  -t            Target host or IP address
  -w            Password list (default: rockyou.txt)
  --kerberos    Enable kerberoasting
  --ldap        Enable LDAP Enumeration
  --smb         Enable SMB Enumeration
  --full        Enable full mode Enumeration
  --winrm       Enable winrm mode Enumeration
  --bloodhound  Enable bloodhound mode Enumeration
  --crack       Crack Found Hashes
  -h            Display this help message
```

