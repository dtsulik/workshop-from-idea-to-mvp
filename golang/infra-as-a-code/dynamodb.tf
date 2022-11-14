# module "dynamodb_table" {
#   source = "terraform-aws-modules/dynamodb-table/aws"
#   name = "dtsulik-workshop-dynamodb-table"
#   hash_key = "id"
#   attributes = [
#     {
#       name = "id"
#       type = "S"
#     },
#     {
#       name = "status"
#       type = "S"
#     },
#     {
#       name = "path"
#       type = "S"
#     }
#   ]
# }