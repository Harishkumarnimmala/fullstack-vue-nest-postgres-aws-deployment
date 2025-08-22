output "address" { value = aws_db_instance.pg.address }
output "sg_id"   { value = aws_security_group.db.id }
