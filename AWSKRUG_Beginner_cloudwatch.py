#!/usr/bin/python
import json
import boto3
from boto3.session import Session
from botocore.exceptions import ClientError
from colorama import Fore, Back, init

session = boto3.session.Session(profile_name="default")

# Define SNS Topic ARN
Topic = session.client('sns')
CTopic = Topic.create_topic(Name='AWSKRUG-Beginner')
Topic_slack = "arn:aws:sns:ap-northeast-2:239234376445:AWSKRUG-Beginner"

EC2_client = session.client('ec2')
cloudwatch = session.client('cloudwatch')

Instance = {x:y for x,y in EC2_client.describe_instances().items()}
Device_count = 0
for i in range(0,len(Instance['Reservations'])):
    for j in range(0,len(Instance['Reservations'][i]['Instances'])):
        ID = Instance['Reservations'][i]['Instances'][j]['InstanceId']
        V_ID = Instance['Reservations'][i]['Instances'][j]['BlockDeviceMappings']
        Stat = Instance['Reservations'][i]['Instances'][j]['State']['Name']
        Tags = Instance['Reservations'][i]['Instances'][j]['Tags']
        for x in Tags:
            if x['Key'] =='Name' and Stat == "running":    # ex) running instance get
                Device_count = Device_count + 1
                tags = x['Value']
                # PUT EC2 CPU Utilization alarm
                cloudwatch.put_metric_alarm(
                AlarmName=tags+"-"+"EC2"+'-CPU-Utilization',
                ComparisonOperator='GreaterThanThreshold',
                TreatMissingData='notBreaching',
                EvaluationPeriods=1,
                MetricName='CPUUtilization',
                Namespace='AWS/EC2',
                Period=300,
                Statistic='Maximum',
                Threshold=80.0,
                ActionsEnabled=True,
                OKActions=[Topic_slack.format(Topic_slack=Topic_slack)],
                AlarmActions=[Topic_slack.format(Topic_slack=Topic_slack)],
                AlarmDescription='Alarm when server CPU exceeds 80%',
                Dimensions=[{'Name': "InstanceId",'Value': ID},],)
                # PUT EC2 StatusCheckfailed alarm
                cloudwatch.put_metric_alarm(
                AlarmName=tags+"-"+"EC2"+'-StatusCheckFailed',
                ComparisonOperator='GreaterThanThreshold',
                TreatMissingData='breaching',
                EvaluationPeriods=1,
                MetricName='StatusCheckFailed',
                Namespace='AWS/EC2',
                Period=60,
                Statistic='Maximum',
                Threshold=0,
                ActionsEnabled=True,
                OKActions=[Topic_slack.format(Topic_slack=Topic_slack)],
                AlarmActions=[Topic_slack.format(Topic_slack=Topic_slack)],
                AlarmDescription='Instance Check Faild',
                Dimensions=[{'Name': "InstanceId",'Value': ID},],)
