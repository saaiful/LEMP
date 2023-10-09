## PHP-FPM Tuning Utility
### Disclaimer
**Important:** Use of the utilities and scripts provided in this repository is at your own risk. The maintainers and contributors to this repository are not responsible for any downtime, data loss, or issues that may arise from using these tools. Always ensure to have backups and recovery processes in place. There is no warranty provided with these utilities.

### Overview
This section of the repository provides utilities for tuning PHP-FPM. PHP-FPM (FastCGI Process Manager) is an alternative PHP FastCGI implementation with some additional features useful for sites of any size, especially busier sites. Correctly tuning PHP-FPM is crucial for optimizing the performance of your web server and minimizing resource usage.

### Utilities
1. fpm-process-size.sh
#### Purpose
This script assists in determining the memory usage of your PHP-FPM processes, providing insight that is vital for appropriate tuning.

#### Usage
Run the script using the following command in your terminal:

```
bash fpm-process-size.sh
```
After execution, take note of the size reported by the script. This figure represents the average memory usage of a PHP-FPM worker and is a crucial metric for tuning.

2. fpm-tuning.sh
#### Purpose
This utility aims to assist in tuning your PHP-FPM configuration by providing recommendations and performing adjustments based on your inputs and server resources.

#### Usage
Execute the script with the following command:

```
bash fpm-tuning.sh
```
During its execution, the script will prompt you for various inputs, such as the average process size determined earlier and other resource-related details. Ensure to input accurate data for optimal recommendations.

Upon providing the necessary input, the script will generate recommended configurations. Carefully review these suggestions and if you're satisfied, proceed to apply them.

**Note: Applying the recommendations will initiate a restart of the PHP-FPM service. If any errors are encountered, the script is designed to rollback to the original configurations to prevent potential downtime.**

#### Before You Start
* **Backups:** Always ensure that you have up-to-date backups of your configurations and data before making changes.
* **Testing:** Whenever possible, test changes in a non-production environment before applying them to production servers.
* **Knowledge:** Ensure that you have a basic understanding of PHP-FPM and its configuration directives to make informed decisions when using these utilities.
* **Logs:** Keep an eye on logs for any anomalies or issues post-configuration change.

### Contribution
Feel free to contribute to this repository by submitting pull requests. Ensure to test any scripts or changes thoroughly to prevent potential issues for users.

### Support
This utility is provided as-is, and support is not guaranteed. However, you may raise questions and issues in the repository for community assistance.

### License
This project is open source and available under MIT. Use at your own risk and discretion.
