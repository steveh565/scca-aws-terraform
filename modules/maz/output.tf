output "maz_bastion_host_1_addr" { value = aws_instance.az1_bastionHost[0].private_ip }
output "maz_bastion_host_2_addr" { value = aws_instance.az2_bastionHost[0].private_ip }
output "maz_bigip1_addr" { value = aws_instance.az1_maz_bigip.public_ip }
output "maz_bigip2_addr" { value = aws_instance.az2_maz_bigip.public_ip }