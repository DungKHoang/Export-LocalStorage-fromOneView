# Export-LocalStorage-fromOneView
The script collects information on local storage ( logical disks and physical disks) of servers managed by OneView
The script requries :
- HPE OneView Library v3.0
- HPE RESTCmdlets v1.x

To run the script:
- Install the pre-requisites
- .\Export-OVLocalStorage.PS1 -OVApplianceIP <OV-IP> -OVAdminName <Admin-name> -OVAdminPassword <Password> -OVAuthDomain <Domain-to-log-on>
