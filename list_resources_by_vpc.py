import boto3

def list_resources_by_vpc():
    ec2 = boto3.client('ec2')
    rds = boto3.client('rds')
    lambda_client = boto3.client('lambda')
    elbv2 = boto3.client('elbv2')  # For Application and Network Load Balancers

    # List VPCs
    print("VPCs:")
    vpcs = ec2.describe_vpcs()['Vpcs']
    for vpc in vpcs:
        print(f"VPC ID: {vpc['VpcId']}")

    # List EC2 Instances by VPC
    print("\nEC2 Instances:")
    reservations = ec2.describe_instances()['Reservations']
    for reservation in reservations:
        for instance in reservation['Instances']:
            print(f"Instance ID: {instance['InstanceId']}, VPC ID: {instance.get('VpcId')}")

    # List RDS Databases by VPC
    print("\nRDS Databases:")
    db_instances = rds.describe_db_instances()['DBInstances']
    for db_instance in db_instances:
        print(f"DB Instance Identifier: {db_instance['DBInstanceIdentifier']}, VPC ID: {db_instance['DBSubnetGroup']['VpcId']}")

    # List Elastic Load Balancers (ELBs) by VPC
    print("\nElastic Load Balancers (ELBs):")
    elbs = elbv2.describe_load_balancers()['LoadBalancers']
    for elb in elbs:
        print(f"Load Balancer Name: {elb['LoadBalancerName']}, VPC ID: {elb['VpcId']}")

    # List VPC Peering Connections
    print("\nVPC Peering Connections:")
    peerings = ec2.describe_vpc_peering_connections()['VpcPeeringConnections']
    for peering in peerings:
        print(f"Peering Connection ID: {peering['VpcPeeringConnectionId']}, Requester VPC ID: {peering['RequesterVpcInfo']['VpcId']}, Acceptor VPC ID: {peering['AccepterVpcInfo']['VpcId']}")

    # List NAT Gateways by VPC
    print("\nNAT Gateways:")
    nat_gateways = ec2.describe_nat_gateways()['NatGateways']
    for nat_gateway in nat_gateways:
        print(f"NAT Gateway ID: {nat_gateway['NatGatewayId']}, VPC ID: {nat_gateway['VpcId']}")

    # List Internet Gateways by VPC
    print("\nInternet Gateways:")
    igws = ec2.describe_internet_gateways()['InternetGateways']
    for igw in igws:
        attachments = igw.get('Attachments', [])
        for attachment in attachments:
            print(f"Internet Gateway ID: {igw['InternetGatewayId']}, VPC ID: {attachment['VpcId']}")

    # List Network Interfaces (ENIs) by VPC
    print("\nNetwork Interfaces (ENIs):")
    enis = ec2.describe_network_interfaces()['NetworkInterfaces']
    for eni in enis:
        print(f"Network Interface ID: {eni['NetworkInterfaceId']}, VPC ID: {eni['VpcId']}")

    # List Lambda Functions (Note: This part checks if Lambda is associated with a VPC)
    print("\nLambda Functions:")
    functions = lambda_client.list_functions()['Functions']
    for function in functions:
        vpc_config = function.get('VpcConfig')
        if vpc_config:
            print(f"Function Name: {function['FunctionName']}, VPC ID: {vpc_config.get('VpcId', 'Associated with VPC but VPC ID not directly available')}")
        else:
            print(f"Function Name: {function['FunctionName']}, VPC ID: Not associated with any VPC")

if __name__ == "__main__":
    list_resources_by_vpc()

