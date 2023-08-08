resource "aws_dynamodb_table" "table" {
  name     = "ecs_map"
  hash_key = "repository"

  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "repository"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "item" {
  table_name = aws_dynamodb_table.table.name
  hash_key   = aws_dynamodb_table.table.hash_key

  item = <<ITEM
{
  "repository":  {"S": "svelte-app"},
  "cluster":     {"S": "app-cluster"},
  "service":     {"S": "app-service"},
  "container":   {"S": "app-container"},
  "task":        {"S": "app-task"},
  "account":     {"S": "${var.aws_account_id}"},
  "channel":     {"S": "${var.slack_channel}"},
  "auto-deploy": {"BOOL": false}
}
ITEM
}
