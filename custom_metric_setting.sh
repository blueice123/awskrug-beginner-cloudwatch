#!/bin/bash

Log_file=`pwd`/custom-metric-setting-$(date +%Y)$(date +%m)$(date +%d).log
crontab_amazon=/var/spool/cron/root
crontab_redhat=/etc/crontab
yum_history=`pwd`/yum_history.log
filesystem_info=`pwd`/Filesystem_info.log
root_check=`pwd`/root_check.log
touch $Log_file

date >> $Log_file
echo -e "Custom metric setting script start" >> $Log_file
echo "" >> $Log_file
## Check the access ID
root_check=$(id |grep "uid=0" | wc -l)
if [ $root_check == 0 ]; then
  echo "Please check the access permissions of the account"
  echo "You need root privileges to run this script"
  echo "Please check the access permissions of the account" >> $Log_file
  echo "You need root privileges to run this script" >> $Log_file
else
  ## OS parsing
  amazone_os_check=$(uname -a | grep amzn | wc -l) > /dev/null 2>&1
  if [ $amazone_os_check == 1 ]; then
        echo "Custom metric setting start ........" >> $Log_file
  	## custom metric setting
        echo "Save the affected version of the package" >> $Log_file
        rpm -qa | grep perl-Switch >> $Log_file
        rpm -qa | grep perl-DateTime >> $Log_file
        rpm -qa | grep perl-Sys-Syslog >> $Log_file
        rpm -qa | grep perl-LWP-Protocol-https >> $Log_file
        yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https > /dev/null 2>&1
        echo "" >> $Log_file
        echo "Save the yum history" >> $Log_file
        yum history > $yum_history
        cat $yum_history >> $Log_file
        yum_install=$(cat $yum_history | awk '{print $1}' | head -n 4 | tail -n 1)
        yum history info $yum_install >> $Log_file

        ## AWS custom metric file download and install
        cd /usr/local/src/
        curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O > /dev/null 2>&1
        unzip -o /usr/local/src/CloudWatchMonitoringScripts-1.2.1.zip > /dev/null 2>&1
        rm -rf /usr/local/src/CloudWatchMonitoringScripts-1.2.1.zip > /dev/null 2>&1
        mv /usr/local/src/aws-scripts-mon/ /root/ > /dev/null 2>&1
        /bin/cp -f /root/aws-scripts-mon/awscreds.template /root/aws-scripts-mon/awscreds.conf > /dev/null 2>&1
        echo "" >> $Log_file

        ## IAM account key insert
        echo "AWS IAM Key(/root/aws-scripts-mon/awscreds.conf) register" >> $Log_file
        echo "AWSAccessKeyId=$AWSAccessKeyId
        AWSSecretKey=$AWSSecretKey" > /root/aws-scripts-mon/awscreds.conf
        echo "" >> $Log_file

        iam_key_check=$(/root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used-incl-cache-buff --mem-used --mem-avail |grep "Successfully reported metrics to CloudWatch." | wc -l)
        if [ 0 == $iam_key_check ]; then
          echo "ERROR: Failed to call CloudWatch: HTTP 400." >> $Log_file
          echo "Plase check the EC2 Role" >> $Log_file
        else
            ## crontab registe
            echo "Crontab /var/spool/cron/root register" >> $Log_file
            touch $crontab_amazon
            echo "#"$(date +%Y)$(date +%m)$(date +%d)"_Custem mtric setting" >> $crontab_amazon
            echo "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --mem-used --mem-avail --disk-space-util --disk-path=/ --from-cron" >> $crontab_amazon
            filesystem_chekc=$(df -h | grep -v "Filesystem" | grep -v "devtmpfs" | grep -v "tmpfs" | grep -v "/dev/xvda" | wc -l)
            if [ 0 -lt $filesystem_chekc ]; then
              df -h | grep -v "Filesystem" | grep -v "devtmpfs" | grep -v "tmpfs" | grep -v "/dev/xvda" | awk '{print $6}' > $filesystem_info
              for i in $(cat $filesystem_info)
              do
                echo "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util --disk-path="$i" --from-cron" >> $crontab_amazon
              done
            fi
          fi
  elif [ $amazone_os_check == 0 ]; then
    redhat_os_check=$(cat /etc/redhat-release | grep "Red Hat Enterprise" | wc -l) > /dev/null 2>&1
    if [ $redhat_os_check == 1 ]; then
        ## Redhat Linux setting

        ## IAM account infomation insert
        echo -n "AWS IAM AWSAccessKeyId : "
        read AWSAccessKeyId
        echo -n "AWS IAM AWSSecretKey : "
        read AWSSecretKey

        echo "Custom metric setting start ........"
        echo "" >> $Log_file
        ## custom metric setting
        echo "Save the affected version of the package" >> $Log_file
        rpm -qa | grep perl-Switch >> $Log_file
        rpm -qa | grep perl-DateTime >> $Log_file
        rpm -qa | grep perl-Sys-Syslog >> $Log_file
        rpm -qa | grep perl-LWP-Protocol-https >> $Log_file
        rpm -qa | grep perl-Digest-SHA >> $Log_file
        rpm -qa | grep gcc >> $Log_file
        rpm -qa | grep perl-Net-SSLeay >> $Log_file
        rpm -qa | grep perl-IO-Socket-SSL >> $Log_file
        rpm -qa | grep zip >> $Log_file
        rpm -qa | grep unzip >> $Log_file
        yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA gcc perl-Net-SSLeay perl-IO-Socket-SSL zip unzip -y  > /dev/null 2>&1
        echo "" >> $Log_file

        echo "Save the yum history" >> $Log_file
        yum history > $yum_history
        cat $yum_history >> $Log_file
        yum_install=$(cat $yum_history | awk '{print $1}' | head -n 4 | tail -n 1)
        yum history info $yum_install >> $Log_file

        ## AWS custom metric file download and install
        cd /usr/local/src/
        curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O > /dev/null 2>&1
        unzip -o /usr/local/src/CloudWatchMonitoringScripts-1.2.1.zip > /dev/null 2>&1
        rm -rf /usr/local/src/CloudWatchMonitoringScripts-1.2.1.zip > /dev/null 2>&1
        mv /usr/local/src/aws-scripts-mon/ /root/ > /dev/null 2>&1
        /bin/cp -f /root/aws-scripts-mon/awscreds.template /root/aws-scripts-mon/awscreds.conf > /dev/null 2>&1
        echo "" >> $Log_file

        ## IAM account key insert
        echo "AWS IAM Key(/root/aws-scripts-mon/awscreds.conf) register" >> $Log_file
        echo "AWSAccessKeyId=$AWSAccessKeyId
        AWSSecretKey=$AWSSecretKey" > /root/aws-scripts-mon/awscreds.conf
        echo "" >> $Log_file

        iam_key_check=$(/root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used-incl-cache-buff --mem-used --mem-avail |grep "Successfully reported metrics to CloudWatch." | wc -l)
        if [ 0 == $iam_key_check ]; then
          echo "ERROR: Failed to call CloudWatch: HTTP 400."
          echo "ERROR: Failed to call CloudWatch: HTTP 400." >> $Log_file
        else
          ## crontab registe
          echo "Crontab /var/spool/cron/root register" >> $Log_file
          touch $crontab_redhat
          echo "#"$(date +%Y)$(date +%m)$(date +%d)"_Custem mtric setting" >> $crontab_redhat
          echo "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --mem-used --mem-avail --disk-space-util --disk-path=/ --from-cron" >> $crontab_redhat
          filesystem_chekc=$(df -h | grep -v "Filesystem" | grep -v "devtmpfs" | grep -v "tmpfs" | grep -v "/dev/xvda" | wc -l)
          if [ 0 -lt $filesystem_chekc ]; then
            df -h | grep -v "Filesystem" | grep -v "devtmpfs" | grep -v "tmpfs" | grep -v "/dev/xvda" | awk '{print $6}' > $filesystem_info
            for i in $(cat $filesystem_info)
            do
              echo "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util --disk-path="$i" --from-cron" >> $crontab_redhat
            done
          fi
        fi
      fi
  elif [ $amazone_os_check == 0 ]; then

    centos_check=$(cat /etc/redhat-release |grep -i "CentOS" | wc -l) > /dev/null 2>&1
    if [ $centos_check == 1 ]; then
        ## CentOS Linux setting

        ## IAM account infomation insert
        echo -n "AWS IAM AWSAccessKeyId : "
        read AWSAccessKeyId
        echo -n "AWS IAM AWSSecretKey : "
        read AWSSecretKey

        echo "Custom metric setting start ........"
        echo "" >> $Log_file
        ## custom metric setting
        echo "Save the affected version of the package" >> $Log_file
        rpm -qa | grep perl-Switch >> $Log_file
        rpm -qa | grep perl-DateTime >> $Log_file
        rpm -qa | grep perl-Sys-Syslog >> $Log_file
        rpm -qa | grep perl-LWP-Protocol-https >> $Log_file
        rpm -qa | grep perl-Digest-SHA >> $Log_file
        rpm -qa | grep gcc >> $Log_file
        rpm -qa | grep perl-Net-SSLeay >> $Log_file
        rpm -qa | grep perl-IO-Socket-SSL >> $Log_file
        rpm -qa | grep zip >> $Log_file
        rpm -qa | grep unzip >> $Log_file
        yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA gcc perl-Net-SSLeay perl-IO-Socket-SSL zip unzip -y  > /dev/null 2>&1
        echo "" >> $Log_file

        echo "Save the yum history" >> $Log_file
        yum history > $yum_history
        cat $yum_history >> $Log_file
        yum_install=$(cat $yum_history | awk '{print $1}' | head -n 4 | tail -n 1)
        yum history info $yum_install >> $Log_file

        ## AWS custom metric file download and install
        cd /usr/local/src/
        curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O > /dev/null 2>&1
        unzip -o /usr/local/src/CloudWatchMonitoringScripts-1.2.1.zip > /dev/null 2>&1
        rm -rf /usr/local/src/CloudWatchMonitoringScripts-1.2.1.zip > /dev/null 2>&1
        mv /usr/local/src/aws-scripts-mon/ /root/ > /dev/null 2>&1
        /bin/cp -f /root/aws-scripts-mon/awscreds.template /root/aws-scripts-mon/awscreds.conf > /dev/null 2>&1

        ## IAM account key insert
        echo "" >> $Log_file
        echo "AWS IAM Key(/root/aws-scripts-mon/awscreds.conf) register" >> $Log_file
        echo "AWSAccessKeyId=$AWSAccessKeyId
        AWSSecretKey=$AWSSecretKey" > /root/aws-scripts-mon/awscreds.conf
        echo "" >> $Log_file
        if [ 0 == $iam_key_check ]; then
          echo "ERROR: Failed to call CloudWatch: HTTP 400." >> $Log_file
          echo "Plase check the EC2 Role" >> $Log_file
        else
          ## crontab registe
          echo "Crontab /var/spool/cron/root register" >> $Log_file
          touch $crontab_redhat
          echo "#"$(date +%Y)$(date +%m)$(date +%d)"_Custem mtric setting" >> $crontab_redhat
          echo "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --mem-used --mem-avail --disk-space-util --disk-path=/ --from-cron" >> $crontab_redhat
          filesystem_chekc=$(df -h | grep -v "Filesystem" | grep -v "devtmpfs" | grep -v "tmpfs" | grep -v "/dev/xvda" | wc -l)
          if [ 0 -lt $filesystem_chekc ]; then
            df -h | grep -v "Filesystem" | grep -v "devtmpfs" | grep -v "tmpfs" | grep -v "/dev/xvda" | awk '{print $6}' > $filesystem_info
            for i in $(cat $filesystem_info)
            do
              echo "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util --disk-path="$i" --from-cron" >> $crontab_redhat
            done
          fi
        fi
      fi
  else
    echo "The operating systems supported by this script are Amazon Linux, Redhat Linux, and CentOS."
    echo "Manual setting Plase"
    echo "The operating systems supported by this script are Amazon Linux, Redhat Linux, and CentOS." >> $Log_file
    echo "Manual setting Please" >> $Log_file
  fi
  echo "Custom metric setting end ........"
  echo "" >> $Log_file
  echo "Custom metric setting end ........" >> $Log_file
  rm -rf $yum_history
fi
