#create elastic IP
$ElasticIP = New-EC2Address -Domain vpc

#get public subnet for NAT gateway
$Subnet_Public = Get-EC2Subnet | ? { $_.Tags.Value -match "Public*" } | select -First 1

#create NAT gateway using public subnet and elastic IP
$NatGateway = New-EC2NatGateway -SubnetId $Subnet_Public.SubnetId -AllocationId $ElasticIP.AllocationId

sleep 5

#add default gateway to private subnets
$RouteTable = Get-EC2RouteTable | ? RouteTableId -eq rtb-58688a31
New-EC2Route -RouteTableId $RouteTable.RouteTableId -DestinationCidrBlock 0.0.0.0/0 -NatGatewayId $NatGateway.NatGateway.NatGatewayId

