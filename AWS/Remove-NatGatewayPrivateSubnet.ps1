#get NAT gatway
$NatGateway = Get-EC2NatGateway | ? State -EQ "available"

#get route table
$RouteTable = Get-EC2RouteTable | ? RouteTableId -eq rtb-58688a31

#remove default route
Remove-EC2Route -RouteTableId $RouteTable.RouteTableId -DestinationCidrBlock 0.0.0.0/0 -Confirm:$false
Remove-EC2NatGateway -NatGatewayId $NatGateway.NatGatewayId -Confirm:$false

#wait for the NAT gateway to delete
do
{
    sleep -Seconds 5
}
until ((Get-EC2NatGateway -NatGatewayId $NatGateway.NatGatewayId).State -eq "deleted")

#remove elastic IP
Remove-EC2Address -AllocationId $NatGateway.NatGatewayAddresses.AllocationId -Confirm:$false