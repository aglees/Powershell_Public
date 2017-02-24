import boto
ec2 = boto.connect_ec2()
ec2.get_all_zones()